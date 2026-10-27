import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:timezone/timezone.dart' as tz;

import '../storage/planner_store.dart';
import '../timetable/model.dart';
import '../random_tools/tool_library.dart';

class _ValidatedRollback implements Exception {}

/// Storage snapshot includes every registered application table. Identifiers
/// always come from the compiled schema, never from document SQL or filenames.
extension BackupStore on PlannerStore {
  Future<Map<String, Object?>> backupSnapshot(DateTime now) =>
      transaction(() async {
        final tables = <String, Object?>{};
        for (final table in allTables) {
          tables[table.actualTableName] = (await customSelect(
            'SELECT * FROM "${table.actualTableName}"',
          ).get()).map((row) => row.data).toList();
        }
        return {
          'format': 'unipocket-backup',
          'version': 1,
          'schema': schemaVersion,
          'createdAt': now.toUtc().toIso8601String(),
          'tables': tables,
        };
      });

  Future<void> applyBackup(
    Map<String, dynamic> archive, {
    bool validateOnly = false,
  }) async {
    try {
      await transaction(() async {
        if (archive['schema'] != schemaVersion) {
          throw const FormatException('备份数据版本不兼容，请使用相同数据版本的应用');
        }
        final data = archive['tables'] as Map<String, dynamic>;
        if (data.length != allTables.length ||
            allTables.any((t) => !data.containsKey(t.actualTableName))) {
          throw const FormatException('备份缺少完整数据');
        }
        // This flag is transaction-local and resets on commit/rollback.
        await customStatement('PRAGMA defer_foreign_keys = ON');
        for (final table in allTables.toList().reversed) {
          await customStatement('DELETE FROM "${table.actualTableName}"');
        }
        for (final table in allTables) {
          final columns = table.$columns;
          final names = columns.map((c) => '"${c.$name}"').join(',');
          final placeholders = List.filled(columns.length, '?').join(',');
          for (final raw in data[table.actualTableName] as List) {
            final row = raw as Map<String, dynamic>;
            if (row.length != columns.length ||
                columns.any((c) => !row.containsKey(c.$name))) {
              throw const FormatException('备份字段不完整');
            }
            final values = <Object?>[];
            for (final column in columns) {
              final value = row[column.$name];
              // The current schema contains SQLite TEXT and INTEGER only.
              final type = column.type;
              if (value == null
                  ? !column.$nullable
                  : type == DriftSqlType.string
                  ? value is! String
                  : value is! int) {
                throw const FormatException('备份字段类型不正确');
              }
              if (value != null &&
                  type == DriftSqlType.bool &&
                  value != 0 &&
                  value != 1) {
                throw const FormatException('备份开关值不正确');
              }
              if (column.$name == 'id' && value is int && value < 1) {
                throw const FormatException('备份记录身份不正确');
              }
              if (value is String &&
                  (column.$name.endsWith('_date') ||
                      column.$name == 'date' ||
                      column.$name == 'first_monday')) {
                final date = DateTime.parse(value);
                if (value != date.toIso8601String() ||
                    !date.isUtc ||
                    date.hour != 0 ||
                    date.minute != 0 ||
                    date.second != 0 ||
                    date.millisecond != 0 ||
                    date.microsecond != 0) {
                  throw const FormatException('备份日期不正确');
                }
              }
              values.add(value);
            }
            await customStatement(
              'INSERT INTO "${table.actualTableName}" ($names) VALUES ($placeholders)',
              values,
            );
          }
        }
        if ((await customSelect('PRAGMA foreign_key_check').get()).isNotEmpty) {
          throw const FormatException('备份包含断开的数据关系');
        }
        await _validateBackupDomain();
        if (validateOnly) throw _ValidatedRollback();
        for (final table in allTables) {
          markTablesUpdated({table});
        }
      });
    } on _ValidatedRollback {
      // Validation deliberately rolls back the complete transaction. Existing
      // records, autoincrement counters and observers remain unchanged.
    }
  }

  Future<void> _validateBackupDomain() async {
    final settings = await select(settingsRecords).getSingle();
    if (settings.id != 1) throw const FormatException('应用设置不完整');
    final state = await readState();
    tz.getLocation(state.campusTimeZone);
    final semesters = {for (final s in state.semesters) s.id: s};
    for (final s in state.semesters) {
      s.validate();
    }
    for (final c in state.courses) {
      c.validate(semesters[c.semesterId]!);
    }
    for (final t in state.tasks) {
      t.validate();
    }
    for (final e in state.events) {
      e.validate();
    }
    for (final e in state.classExceptions) {
      e.validate();
      final course = state.courses.singleWhere(
        (c) => c.schedules.any((s) => (s as ClassSchedule).id == e.scheduleId),
      );
      if (!Timetable(semesters[course.semesterId]!, [course])
          .onDate(e.originalDate)
          .any((o) => (o.schedule as ClassSchedule).id == e.scheduleId)) {
        throw const FormatException('调停课原课次不存在');
      }
    }
    for (final l in state.independentLessons) {
      l.validate();
    }
    final periods = await select(periodRecords).get();
    for (final p in periods) {
      if (p.weekday < 1 ||
          p.weekday > 7 ||
          p.number < 1 ||
          p.number > semesters[p.semesterId]!.periods[p.weekday]!.length) {
        throw const FormatException('学期节次不连续');
      }
    }
    for (final list in await readWheelLists()) {
      _checkText(list.name, list.items);
    }
    for (final list in await readGroupLists()) {
      _checkMembers(list.name, list.members.map((m) => (m.id, m.name)));
    }
    for (final list in await readRollCallLists()) {
      _checkMembers(list.name, list.members.map((m) => (m.id, m.name)));
      _checkRound(
        list.round,
        list.revision,
        list.drawn,
        list.members.map((m) => m.id).toSet(),
        list.repeat,
      );
    }
    for (final pool in await readLotteryPools()) {
      _checkText(pool.name, pool.items);
      _checkRound(pool.round, pool.revision, pool.drawn, {
        for (var i = 0; i < pool.items.length; i++) i,
      }, pool.repeat);
    }
    for (final row in await select(toolUsageRecords).get()) {
      if (!RandomTool.values.any((t) => t.name == row.toolId) ||
          row.lastOpened < 0) {
        throw const FormatException('工具收藏或最近使用不正确');
      }
    }
    // Preserve the exact serialized week collection, including its validity.
    for (final row in await select(scheduleRecords).get()) {
      final weeks = jsonDecode(row.weeks) as List;
      if (weeks.toSet().length != weeks.length) {
        throw const FormatException('教学周重复');
      }
    }
  }
}

void _checkText(String name, Iterable<String> entries) {
  if (name.trim().isEmpty || entries.any((s) => s.trim().isEmpty)) {
    throw const FormatException('工具列表名称或内容为空');
  }
}

void _checkMembers(String name, Iterable<(int, String)> members) {
  final entries = members.toList();
  _checkText(name, entries.map((m) => m.$2));
  if (entries.any((m) => m.$1 < 1) ||
      entries.map((m) => m.$1).toSet().length != entries.length) {
    throw const FormatException('名单成员身份不正确');
  }
}

void _checkRound(
  int round,
  int revision,
  List<int> drawn,
  Set<int> candidates,
  bool repeat,
) {
  if (round < 1 ||
      revision < 0 ||
      drawn.any((id) => !candidates.contains(id)) ||
      (!repeat && drawn.toSet().length != drawn.length)) {
    throw const FormatException('抽取轮次不完整');
  }
}
