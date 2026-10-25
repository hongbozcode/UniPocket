import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../semesters/model.dart';
import '../timetable/model.dart';
import '../tasks/model.dart';
import '../events/model.dart';
import '../timetable/course_change.dart';

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
  int get schemaVersion => 8;

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
