import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../semesters/model.dart';

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

@DriftDatabase(tables: [SemesterRecords, PeriodRecords, SettingsRecords])
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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await into(settingsRecords)
          .insert(const SettingsRecordsCompanion(id: Value(1)));
    },
    beforeOpen: (_) => customStatement('PRAGMA foreign_keys = ON'),
  );

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
    return PlannerState(
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

  Future<void> writeTimeZone(String zone) =>
      (update(settingsRecords)..where((s) => s.id.equals(1))).write(
        SettingsRecordsCompanion(campusTimeZone: Value(zone)),
      );
}
