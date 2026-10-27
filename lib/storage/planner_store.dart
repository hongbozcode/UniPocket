import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../semesters/model.dart';
import '../timetable/model.dart';
import '../tasks/model.dart';
import '../events/model.dart';
import '../timetable/course_change.dart';
import '../random_tools/wheel_list.dart';
import '../random_tools/roll_call.dart';
import '../random_tools/lottery.dart';
import '../random_tools/groups.dart';
import '../random_tools/tool_library.dart';

part 'planner_store.g.dart';

@DataClassName('StoredSemester')
class SemesterRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get firstMonday => text()();
  IntColumn get totalWeeks => integer()();
}

@DataClassName('StoredPeriod')
class PeriodRecords extends Table {
  IntColumn get semesterId => integer().references(SemesterRecords, #id)();
  IntColumn get weekday => integer()();
  IntColumn get number => integer()();
  IntColumn get startMinutes => integer()();
  IntColumn get endMinutes => integer()();

  @override
  Set<Column<Object>> get primaryKey => {semesterId, weekday, number};
}

@DataClassName('StoredSettings')
class SettingsRecords extends Table {
  IntColumn get id => integer()();
  IntColumn get currentSemesterId =>
      integer().nullable().references(SemesterRecords, #id)();
  TextColumn get campusTimeZone =>
      text().withDefault(const Constant('Asia/Shanghai'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('StoredCourse')
class CourseRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get semesterId => integer().references(SemesterRecords, #id)();
  TextColumn get name => text()();
  TextColumn get teacher => text()();
  IntColumn get colorIndex => integer()();
  IntColumn get reminderMinutesBefore =>
      integer().nullable().withDefault(const Constant(10))();
}

@DataClassName('StoredSchedule')
class ScheduleRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get courseId => integer().references(CourseRecords, #id)();
  IntColumn get weekday => integer()();
  IntColumn get startPeriod => integer()();
  IntColumn get endPeriod => integer()();
  TextColumn get location => text()();
  TextColumn get weeks => text()();
}

@DataClassName('StoredLearningTask')
class LearningTaskRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get dueDate => text()();
  IntColumn get dueMinutes => integer()();
  TextColumn get notes => text()();
  IntColumn get courseId => integer().nullable().references(
    CourseRecords,
    #id,
    onDelete: KeyAction.setNull,
  )();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get reminderMinutesBefore =>
      integer().nullable().withDefault(const Constant(1440))();
}

@DataClassName('StoredCountdownEvent')
class CountdownEventRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get targetDate => text()();
  TextColumn get kind => text()();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  IntColumn get reminderMinutes =>
      integer().nullable().withDefault(const Constant(540))();
}

@DataClassName('StoredClassException')
class ClassExceptionRecords extends Table {
  IntColumn get scheduleId =>
      integer().references(ScheduleRecords, #id, onDelete: KeyAction.cascade)();
  TextColumn get originalDate => text()();
  TextColumn get targetDate => text()();
  IntColumn get startMinutes => integer()();
  IntColumn get endMinutes => integer()();
  TextColumn get location => text()();
  BoolColumn get isCancelled => boolean()();

  @override
  Set<Column<Object>> get primaryKey => {scheduleId, originalDate};
}

@DataClassName('StoredIndependentLesson')
class IndependentLessonRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get courseId =>
      integer().references(CourseRecords, #id, onDelete: KeyAction.cascade)();
  TextColumn get date => text()();
  IntColumn get startMinutes => integer()();
  IntColumn get endMinutes => integer()();
  TextColumn get location => text()();
}

@DataClassName('StoredWheelList')
class WheelListRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get items => text()();
}

@DataClassName('StoredRollCallList')
class RollCallListRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get members => text()();
  BoolColumn get repeat => boolean().withDefault(const Constant(false))();
  IntColumn get round => integer().withDefault(const Constant(1))();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  TextColumn get drawn => text().withDefault(const Constant('[]'))();
}

@DataClassName('StoredLotteryPool')
class LotteryPoolRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get items => text()();
  BoolColumn get repeat => boolean().withDefault(const Constant(false))();
  IntColumn get round => integer().withDefault(const Constant(1))();
  IntColumn get revision => integer().withDefault(const Constant(0))();
  TextColumn get drawn => text().withDefault(const Constant('[]'))();
}

@DataClassName('StoredGroupList')
class GroupListRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get members => text()();
}

@DataClassName('StoredToolUsage')
class ToolUsageRecords extends Table {
  TextColumn get toolId => text()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  IntColumn get lastOpened => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {toolId};
}

@DriftDatabase(
  tables: [
    SemesterRecords,
    PeriodRecords,
    SettingsRecords,
    CourseRecords,
    ScheduleRecords,
    LearningTaskRecords,
    CountdownEventRecords,
    ClassExceptionRecords,
    IndependentLessonRecords,
    WheelListRecords,
    RollCallListRecords,
    LotteryPoolRecords,
    GroupListRecords,
    ToolUsageRecords,
  ],
)
class PlannerStore extends _$PlannerStore {
  PlannerStore(super.executor);

  factory PlannerStore.open({String name = 'unipocket'}) => PlannerStore(
    driftDatabase(
      name: name,
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    ),
  );

  @override
  int get schemaVersion => 14;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await into(settingsRecords)
          .insert(const SettingsRecordsCompanion(id: Value(1)));
    },
    onUpgrade: (m, from, to) async {
      if (from < 14) await m.createTable(toolUsageRecords);
      if (from < 13) await m.createTable(groupListRecords);
      if (from < 12) await m.createTable(lotteryPoolRecords);
      if (from < 11) await m.createTable(rollCallListRecords);
      if (from < 10) await m.createTable(wheelListRecords);
      if (from < 2) {
        await m.createTable(courseRecords);
        await m.createTable(scheduleRecords);
      }
      if (from < 3) await m.createTable(learningTaskRecords);
      if (from < 4) await m.createTable(countdownEventRecords);
      if (from < 5) await m.createTable(classExceptionRecords);
      if (from < 6) await m.createTable(independentLessonRecords);
      if (from >= 3 && from < 7) {
        await m.addColumn(
          learningTaskRecords,
          learningTaskRecords.reminderMinutesBefore,
        );
      }
      if (from >= 2 && from < 8) {
        await m.addColumn(courseRecords, courseRecords.reminderMinutesBefore);
      }
      if (from >= 4 && from < 9) {
        await m.addColumn(
          countdownEventRecords,
          countdownEventRecords.reminderMinutes,
        );
      }
    },
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );

  GroupList _groupList(StoredGroupList row) => GroupList(
    id: row.id,
    name: row.name,
    members: [
      for (final m in jsonDecode(row.members) as List)
        GroupMember(
          id: m['id'] as int,
          name: m['name'] as String,
          detail: m['detail'] as String,
        ),
    ],
  );

  Future<List<GroupList>> readGroupLists() async => (await (select(
    groupListRecords,
  )..orderBy([(t) => OrderingTerm.asc(t.id)])).get()).map(_groupList).toList();

  Future<ToolLibrary> readToolLibrary() async {
    final rows = await select(toolUsageRecords).get();
    return ToolLibrary({
      for (final tool in RandomTool.values)
        for (final row in rows)
          if (row.toolId == tool.name)
            tool: ToolUsage(
              isFavorite: row.isFavorite,
              lastOpened: row.lastOpened,
            ),
    });
  }

  Future<void> writeToolFavorite(RandomTool tool, bool favorite) async {
    await into(toolUsageRecords).insertOnConflictUpdate(
      ToolUsageRecordsCompanion(
        toolId: Value(tool.name),
        isFavorite: Value(favorite),
      ),
    );
  }

  Future<void> recordToolUse(RandomTool tool) => transaction(() async {
    final rows = await select(toolUsageRecords).get();
    final latest = rows.fold<int>(
      0,
      (value, row) => row.lastOpened > value ? row.lastOpened : value,
    );
    await into(toolUsageRecords).insertOnConflictUpdate(
      ToolUsageRecordsCompanion(
        toolId: Value(tool.name),
        lastOpened: Value(latest + 1),
      ),
    );
  });

  Future<GroupList> readGroupList(int id) async => _groupList(
    await (select(groupListRecords)..where((t) => t.id.equals(id))).getSingle(),
  );

  Future<GroupList> writeGroupList({
    int? id,
    required String name,
    required List<GroupMember> members,
  }) => transaction(() async {
    final entry = GroupListRecordsCompanion(
      name: Value(name),
      members: Value(
        jsonEncode([
          for (final m in members)
            {'id': m.id, 'name': m.name, 'detail': m.detail},
        ]),
      ),
    );
    if (id == null) {
      id = await into(groupListRecords).insert(entry);
    } else {
      await (update(
        groupListRecords,
      )..where((t) => t.id.equals(id!))).write(entry);
    }
    return readGroupList(id!);
  });

  LotteryPool _lotteryPool(StoredLotteryPool row) => LotteryPool(
    id: row.id,
    name: row.name,
    repeat: row.repeat,
    round: row.round,
    revision: row.revision,
    items: (jsonDecode(row.items) as List).cast<String>(),
    drawn: (jsonDecode(row.drawn) as List).cast<int>(),
  );

  Future<List<LotteryPool>> readLotteryPools() async =>
      (await (select(
            lotteryPoolRecords,
          )..orderBy([(t) => OrderingTerm.asc(t.id)])).get())
          .map(_lotteryPool)
          .toList();

  Future<LotteryPool> readLotteryPool(int id) async => _lotteryPool(
    await (select(
      lotteryPoolRecords,
    )..where((t) => t.id.equals(id))).getSingle(),
  );

  Future<LotteryPool> writeLotteryPool({
    int? id,
    required String name,
    required List<String> items,
  }) => transaction(() async {
    final before = id == null ? null : await readLotteryPool(id!);
    final values = LotteryPoolRecordsCompanion(
      name: Value(name),
      items: Value(jsonEncode(items)),
      drawn: const Value('[]'),
      round: Value(before == null ? 1 : before.round + 1),
      revision: Value(before == null ? 0 : before.revision + 1),
    );
    if (id == null) {
      id = await into(lotteryPoolRecords).insert(values);
    } else {
      await (update(
        lotteryPoolRecords,
      )..where((t) => t.id.equals(id!))).write(values);
    }
    return readLotteryPool(id!);
  });

  Future<LotteryPool> commitLottery(LotteryPool before, int index) =>
      transaction(() async {
        final count =
            await (update(lotteryPoolRecords)..where(
                  (t) =>
                      t.id.equals(before.id) &
                      t.revision.equals(before.revision),
                ))
                .write(
                  LotteryPoolRecordsCompanion(
                    drawn: Value(jsonEncode([...before.drawn, index])),
                    revision: Value(before.revision + 1),
                  ),
                );
        if (count != 1) throw StateError('签池或轮次已改变，请重新抽签');
        return readLotteryPool(before.id);
      });

  Future<LotteryPool> resetLottery(int id, {bool? repeat}) =>
      transaction(() async {
        final before = await readLotteryPool(id);
        await (update(lotteryPoolRecords)..where((t) => t.id.equals(id))).write(
          LotteryPoolRecordsCompanion(
            drawn: const Value('[]'),
            round: Value(before.round + 1),
            revision: Value(before.revision + 1),
            repeat: repeat == null ? const Value.absent() : Value(repeat),
          ),
        );
        return readLotteryPool(id);
      });

  RollCallList _rollCallList(StoredRollCallList row) => RollCallList(
    id: row.id,
    name: row.name,
    repeat: row.repeat,
    round: row.round,
    revision: row.revision,
    drawn: (jsonDecode(row.drawn) as List).cast<int>(),
    members: [
      for (final m in jsonDecode(row.members) as List)
        RollCallMember(
          id: m['id'] as int,
          name: m['name'] as String,
          detail: m['detail'] as String,
        ),
    ],
  );

  Future<List<RollCallList>> readRollCallLists() async =>
      (await (select(
            rollCallListRecords,
          )..orderBy([(t) => OrderingTerm.asc(t.id)])).get())
          .map(_rollCallList)
          .toList();

  Future<RollCallList> readRollCallList(int id) async => _rollCallList(
    await (select(
      rollCallListRecords,
    )..where((t) => t.id.equals(id))).getSingle(),
  );

  Future<RollCallList> writeRollCallList({
    int? id,
    required String name,
    required List<RollCallMember> members,
  }) => transaction(() async {
    final old = id == null ? null : await readRollCallList(id!);
    final entry = RollCallListRecordsCompanion(
      name: Value(name),
      members: Value(
        jsonEncode([
          for (final m in members)
            {'id': m.id, 'name': m.name, 'detail': m.detail},
        ]),
      ),
      drawn: const Value('[]'),
      round: Value(old == null ? 1 : old.round + 1),
      revision: Value(old == null ? 0 : old.revision + 1),
    );
    if (id == null) {
      id = await into(rollCallListRecords).insert(entry);
    } else {
      await (update(
        rollCallListRecords,
      )..where((t) => t.id.equals(id!))).write(entry);
    }
    return readRollCallList(id!);
  });

  Future<RollCallList> commitRollCall(RollCallList before, int memberId) =>
      transaction(() async {
        final count =
            await (update(rollCallListRecords)..where(
                  (t) =>
                      t.id.equals(before.id) &
                      t.revision.equals(before.revision),
                ))
                .write(
                  RollCallListRecordsCompanion(
                    drawn: Value(jsonEncode([...before.drawn, memberId])),
                    revision: Value(before.revision + 1),
                  ),
                );
        if (count != 1) throw StateError('名单或轮次已改变，请重新点名');
        return readRollCallList(before.id);
      });

  Future<RollCallList> resetRollCall(int id, {bool? repeat}) => transaction(
    () async {
      final before = await readRollCallList(id);
      await (update(rollCallListRecords)..where((t) => t.id.equals(id))).write(
        RollCallListRecordsCompanion(
          drawn: const Value('[]'),
          round: Value(before.round + 1),
          revision: Value(before.revision + 1),
          repeat: repeat == null ? const Value.absent() : Value(repeat),
        ),
      );
      return readRollCallList(id);
    },
  );

  Future<List<WheelList>> readWheelLists() async =>
      (await (select(
            wheelListRecords,
          )..orderBy([(t) => OrderingTerm.asc(t.id)])).get())
          .map(
            (row) => WheelList(
              id: row.id,
              name: row.name,
              items: (jsonDecode(row.items) as List).cast<String>(),
            ),
          )
          .toList();

  Future<WheelList> writeWheelList({
    int? id,
    required String name,
    required List<String> items,
  }) => transaction(() async {
    final entry = WheelListRecordsCompanion(
      name: Value(name),
      items: Value(jsonEncode(items)),
    );
    if (id == null) {
      id = await into(wheelListRecords).insert(entry);
    } else {
      final changed = await (update(
        wheelListRecords,
      )..where((t) => t.id.equals(id!))).write(entry);
      if (changed != 1) throw StateError('转盘列表不存在，请重新打开');
    }
    return WheelList(id: id!, name: name, items: items);
  });

  Future<PlannerState> readState() => transaction(() async {
    final settings = await select(settingsRecords).getSingle();
    final rows = await (select(
      semesterRecords,
    )..orderBy([(s) => OrderingTerm.desc(s.id)])).get();
    final periods =
        await (select(periodRecords)..orderBy([
              (p) => OrderingTerm.asc(p.weekday),
              (p) => OrderingTerm.asc(p.number),
            ]))
            .get();
    final courses = await select(courseRecords).get();
    final tasks = await select(learningTaskRecords).get();
    final events = await select(countdownEventRecords).get();
    final exceptions = await select(classExceptionRecords).get();
    final independent = await select(independentLessonRecords).get();
    final schedules = await (select(
      scheduleRecords,
    )..orderBy([(s) => OrderingTerm.asc(s.id)])).get();
    return PlannerState(
      independentLessons: [
        for (final l in independent)
          IndependentLesson(
            id: l.id,
            courseId: l.courseId,
            date: DateTime.parse(l.date),
            startMinutes: l.startMinutes,
            endMinutes: l.endMinutes,
            location: l.location,
          ),
      ],
      classExceptions: [
        for (final e in exceptions)
          ClassExceptionDraft(
            scheduleId: e.scheduleId,
            originalDate: DateTime.parse(e.originalDate),
            targetDate: DateTime.parse(e.targetDate),
            startMinutes: e.startMinutes,
            endMinutes: e.endMinutes,
            location: e.location,
            isCancelled: e.isCancelled,
          ),
      ],
      events: [
        for (final event in events)
          CountdownEvent(
            id: event.id,
            title: event.title,
            targetDate: DateTime.parse(event.targetDate),
            kind: EventKind.values.byName(event.kind),
            isPinned: event.isPinned,
            reminderMinutes: event.reminderMinutes,
          ),
      ],
      tasks: [
        for (final task in tasks)
          LearningTask(
            id: task.id,
            title: task.title,
            dueDate: DateTime.parse(task.dueDate),
            dueMinutes: task.dueMinutes,
            notes: task.notes,
            courseId: task.courseId,
            isCompleted: task.isCompleted,
            reminderMinutesBefore: task.reminderMinutesBefore,
          ),
      ],
      courses: [
        for (final course in courses)
          Course(
            id: course.id,
            semesterId: course.semesterId,
            name: course.name,
            teacher: course.teacher,
            colorIndex: course.colorIndex,
            reminderMinutesBefore: course.reminderMinutesBefore,
            schedules: [
              for (final schedule in schedules)
                if (schedule.courseId == course.id)
                  ClassSchedule(
                    id: schedule.id,
                    weekday: schedule.weekday,
                    startPeriod: schedule.startPeriod,
                    endPeriod: schedule.endPeriod,
                    location: schedule.location,
                    weeks: (jsonDecode(schedule.weeks) as List)
                        .cast<int>()
                        .toSet(),
                  ),
            ],
          ),
      ],
      semesters: [
        for (final row in rows)
          Semester(
            id: row.id,
            name: row.name,
            firstMonday: DateTime.parse(row.firstMonday),
            totalWeeks: row.totalWeeks,
            periods: {
              for (var day = 1; day <= 7; day++)
                day: [
                  for (final period in periods)
                    if (period.semesterId == row.id && period.weekday == day)
                      PeriodTime(period.startMinutes, period.endMinutes),
                ],
            },
          ),
      ],
      currentSemesterId: settings.currentSemesterId,
      campusTimeZone: settings.campusTimeZone,
    );
  });

  Future<int> save(SemesterDraft draft, {int? id, bool makeCurrent = false}) =>
      transaction(() async {
        final values = SemesterRecordsCompanion(
          name: Value(draft.name.trim()),
          firstMonday: Value(draft.firstMonday.toIso8601String()),
          totalWeeks: Value(draft.totalWeeks),
        );
        final int savedId;
        if (id == null) {
          savedId = await into(semesterRecords).insert(values);
        } else {
          final changed = await (update(
            semesterRecords,
          )..where((s) => s.id.equals(id))).write(values);
          if (changed == 0) throw const InputProblem('学期不存在，请返回后重试。');
          savedId = id;
          await (delete(
            periodRecords,
          )..where((p) => p.semesterId.equals(id))).go();
        }
        await batch((b) {
          for (final entry in draft.periods.entries) {
            for (var i = 0; i < entry.value.length; i++) {
              b.insert(
                periodRecords,
                PeriodRecordsCompanion.insert(
                  semesterId: savedId,
                  weekday: entry.key,
                  number: i + 1,
                  startMinutes: entry.value[i].startMinutes,
                  endMinutes: entry.value[i].endMinutes,
                ),
              );
            }
          }
        });
        final settings = await select(settingsRecords).getSingle();
        if (makeCurrent || settings.currentSemesterId == null) {
          await (update(settingsRecords)..where((s) => s.id.equals(1))).write(
            SettingsRecordsCompanion(currentSemesterId: Value(savedId)),
          );
        }
        return savedId;
      });

  Future<void> selectCurrent(int id) => transaction(() async {
    final semester = await (select(
      semesterRecords,
    )..where((s) => s.id.equals(id))).getSingleOrNull();
    if (semester == null) throw const InputProblem('学期不存在，请刷新后重试。');
    await (update(settingsRecords)..where((s) => s.id.equals(1))).write(
      SettingsRecordsCompanion(currentSemesterId: Value(id)),
    );
  });

  Future<int> saveCourse(CourseDraft draft) => transaction(() async {
    final id = await into(courseRecords).insert(
      CourseRecordsCompanion.insert(
        semesterId: draft.semesterId,
        name: draft.name.trim(),
        teacher: draft.teacher.trim(),
        colorIndex: draft.colorIndex,
        reminderMinutesBefore: Value(draft.reminderMinutesBefore),
      ),
    );
    await appendImportedSchedules(id, draft.schedules);
    return id;
  });

  Future<void> appendImportedSchedules(
    int courseId,
    List<ScheduleDraft> schedules,
  ) async {
    for (final schedule in schedules) {
      await into(scheduleRecords).insert(
        ScheduleRecordsCompanion.insert(
          courseId: courseId,
          weekday: schedule.weekday,
          startPeriod: schedule.startPeriod,
          endPeriod: schedule.endPeriod,
          location: schedule.location.trim(),
          weeks: jsonEncode(schedule.weeks.toList()..sort()),
        ),
      );
    }
  }

  Future<void> writeTimeZone(String zone) =>
      (update(settingsRecords)..where((s) => s.id.equals(1))).write(
        SettingsRecordsCompanion(campusTimeZone: Value(zone)),
      );

  Future<void> applyCourseChange(
    CourseChangeImpact impact,
    Map<(int, DateTime), OrphanChoice> choices,
  ) async {
    final id = impact.course.id;
    await updateCourseDetails(
      id,
      name: impact.draft.name,
      teacher: impact.draft.teacher,
      colorIndex: impact.draft.colorIndex,
      reminderMinutesBefore: impact.draft.reminderMinutesBefore,
    );
    for (final exception in impact.orphaned) {
      if (choices[exception.key] == OrphanChoice.keepIndependent) {
        await into(independentLessonRecords).insert(
          IndependentLessonRecordsCompanion.insert(
            courseId: id,
            date: exception.targetDate.toIso8601String(),
            startMinutes: exception.startMinutes,
            endMinutes: exception.endMinutes,
            location: exception.location,
          ),
        );
      }
      await (delete(classExceptionRecords)..where(
            (e) =>
                e.scheduleId.equals(exception.scheduleId) &
                e.originalDate.equals(exception.originalDate.toIso8601String()),
          ))
          .go();
    }
    final retainedIds = impact.draft.schedules
        .whereType<ClassSchedule>()
        .map((s) => s.id)
        .toSet();
    await (delete(
      scheduleRecords,
    )..where((s) => s.courseId.equals(id) & s.id.isNotIn(retainedIds))).go();
    for (final schedule in impact.draft.schedules) {
      final values = ScheduleRecordsCompanion(
        courseId: Value(id),
        weekday: Value(schedule.weekday),
        startPeriod: Value(schedule.startPeriod),
        endPeriod: Value(schedule.endPeriod),
        location: Value(schedule.location.trim()),
        weeks: Value(jsonEncode(schedule.weeks.toList()..sort())),
      );
      if (schedule is ClassSchedule) {
        await (update(
          scheduleRecords,
        )..where((s) => s.id.equals(schedule.id))).write(values);
      } else {
        await into(scheduleRecords).insert(values);
      }
    }
  }

  Future<void> deleteCourse(int id) async {
    await (delete(scheduleRecords)..where((s) => s.courseId.equals(id))).go();
    final count = await (delete(
      courseRecords,
    )..where((c) => c.id.equals(id))).go();
    if (count == 0) throw const InputProblem('课程不存在，请返回后重试。');
  }

  Future<void> saveIndependentLesson(IndependentLesson lesson) async {
    final count =
        await (update(
          independentLessonRecords,
        )..where((l) => l.id.equals(lesson.id))).write(
          IndependentLessonRecordsCompanion(
            date: Value(lesson.date.toIso8601String()),
            startMinutes: Value(lesson.startMinutes),
            endMinutes: Value(lesson.endMinutes),
            location: Value(lesson.location.trim()),
          ),
        );
    if (count == 0) throw const InputProblem('独立补课不存在，请返回后重试。');
  }

  Future<void> deleteIndependentLesson(int id) async {
    final count = await (delete(
      independentLessonRecords,
    )..where((l) => l.id.equals(id))).go();
    if (count == 0) throw const InputProblem('独立补课不存在，请返回后重试。');
  }

  Future<void> saveClassException(ClassExceptionDraft draft) =>
      into(classExceptionRecords).insertOnConflictUpdate(
        ClassExceptionRecordsCompanion.insert(
          scheduleId: draft.scheduleId,
          originalDate: draft.originalDate.toIso8601String(),
          targetDate: draft.targetDate.toIso8601String(),
          startMinutes: draft.startMinutes,
          endMinutes: draft.endMinutes,
          location: draft.location.trim(),
          isCancelled: draft.isCancelled,
        ),
      );

  Future<int> saveEvent(CountdownEventDraft draft, {int? id}) async {
    final values = CountdownEventRecordsCompanion(
      title: Value(draft.title.trim()),
      targetDate: Value(draft.targetDate.toIso8601String()),
      kind: Value(draft.kind.name),
      isPinned: Value(draft.isPinned),
      reminderMinutes: Value(draft.reminderMinutes),
    );
    if (id == null) return into(countdownEventRecords).insert(values);
    final count = await (update(
      countdownEventRecords,
    )..where((e) => e.id.equals(id))).write(values);
    if (count == 0) throw const InputProblem('事件不存在，请返回后重试。');
    return id;
  }

  Future<int> saveTask(LearningTaskDraft draft, {int? id}) async {
    final values = LearningTaskRecordsCompanion(
      title: Value(draft.title.trim()),
      dueDate: Value(draft.dueDate.toIso8601String()),
      dueMinutes: Value(draft.dueMinutes),
      notes: Value(draft.notes.trim()),
      courseId: Value(draft.courseId),
      reminderMinutesBefore: Value(draft.reminderMinutesBefore),
    );
    if (id == null) return into(learningTaskRecords).insert(values);
    final count = await (update(
      learningTaskRecords,
    )..where((t) => t.id.equals(id))).write(values);
    if (count == 0) throw const InputProblem('任务不存在，请返回后重试。');
    return id;
  }

  Future<void> setEventPinned(int id, bool pinned) async {
    final count =
        await (update(countdownEventRecords)..where((e) => e.id.equals(id)))
            .write(CountdownEventRecordsCompanion(isPinned: Value(pinned)));
    if (count == 0) throw const InputProblem('事件不存在，请返回后重试。');
  }

  Future<void> deleteEvent(int id) async {
    final count = await (delete(
      countdownEventRecords,
    )..where((e) => e.id.equals(id))).go();
    if (count == 0) throw const InputProblem('事件不存在，请返回后重试。');
  }

  Future<void> setTaskCompleted(int id, bool completed) async {
    final count =
        await (update(learningTaskRecords)..where((t) => t.id.equals(id)))
            .write(LearningTaskRecordsCompanion(isCompleted: Value(completed)));
    if (count == 0) throw const InputProblem('任务不存在，请返回后重试。');
  }

  Future<void> deleteTask(int id) async {
    final count = await (delete(
      learningTaskRecords,
    )..where((t) => t.id.equals(id))).go();
    if (count == 0) throw const InputProblem('任务不存在，请返回后重试。');
  }

  Future<void> updateCourseDetails(
    int id, {
    required String name,
    required String teacher,
    required int colorIndex,
    required int? reminderMinutesBefore,
  }) async {
    final count = await (update(courseRecords)..where((c) => c.id.equals(id)))
        .write(
          CourseRecordsCompanion(
            name: Value(name.trim()),
            teacher: Value(teacher.trim()),
            colorIndex: Value(colorIndex),
            reminderMinutesBefore: Value(reminderMinutesBefore),
          ),
        );
    if (count == 0) throw const InputProblem('课程不存在，请返回后重试。');
  }
}
