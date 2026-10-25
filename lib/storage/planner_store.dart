import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../semesters/model.dart';
import '../timetable/model.dart';
import '../tasks/model.dart';

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
}

@DriftDatabase(
  tables: [
    SemesterRecords,
    PeriodRecords,
    SettingsRecords,
    CourseRecords,
    ScheduleRecords,
    LearningTaskRecords,
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
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await into(settingsRecords)
          .insert(const SettingsRecordsCompanion(id: Value(1)));
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(courseRecords);
        await m.createTable(scheduleRecords);
      }
      if (from < 3) await m.createTable(learningTaskRecords);
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
    final courses = await select(courseRecords).get();
    final tasks = await select(learningTaskRecords).get();
    final schedules = await (select(
      scheduleRecords,
    )..orderBy([(s) => OrderingTerm.asc(s.id)])).get();
    return PlannerState(
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
      ),
    );
    for (final schedule in draft.schedules) {
      await into(scheduleRecords).insert(
        ScheduleRecordsCompanion.insert(
          courseId: id,
          weekday: schedule.weekday,
          startPeriod: schedule.startPeriod,
          endPeriod: schedule.endPeriod,
          location: schedule.location.trim(),
          weeks: jsonEncode(schedule.weeks.toList()..sort()),
        ),
      );
    }
    return id;
  });

  Future<void> writeTimeZone(String zone) =>
      (update(settingsRecords)..where((s) => s.id.equals(1))).write(
        SettingsRecordsCompanion(campusTimeZone: Value(zone)),
      );

  Future<int> saveTask(LearningTaskDraft draft, {int? id}) async {
    final values = LearningTaskRecordsCompanion(
      title: Value(draft.title.trim()),
      dueDate: Value(draft.dueDate.toIso8601String()),
      dueMinutes: Value(draft.dueMinutes),
      notes: Value(draft.notes.trim()),
      courseId: Value(draft.courseId),
    );
    if (id == null) return into(learningTaskRecords).insert(values);
    final count = await (update(
      learningTaskRecords,
    )..where((t) => t.id.equals(id))).write(values);
    if (count == 0) throw const InputProblem('任务不存在，请返回后重试。');
    return id;
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
  }) async {
    final count = await (update(courseRecords)..where((c) => c.id.equals(id)))
        .write(
          CourseRecordsCompanion(
            name: Value(name.trim()),
            teacher: Value(teacher.trim()),
            colorIndex: Value(colorIndex),
          ),
        );
    if (count == 0) throw const InputProblem('课程不存在，请返回后重试。');
  }
}
