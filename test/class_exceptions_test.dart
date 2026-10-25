import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/semesters/model.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/timetable/model.dart';

import 'support/semester_fixture.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('跨周调课保留原课次关联、目标周原课与其他安排，真实文件重启后仍生效', () async {
    final directory = await Directory.systemTemp.createTemp(
      'unipocket_exceptions_',
    );
    final file = File('${directory.path}/planner.sqlite');
    var store = PlannerStore(NativeDatabase(file));
    addTearDown(() async {
      await store.close();
      await directory.delete(recursive: true);
    });
    var planner = SemesterPlanner(store);
    final semester = await planner.saveSemester(semesterDraft('秋季'));
    await planner.saveCourse(
      CourseDraft(
        semesterId: semester,
        name: '数学',
        schedules: [
          ScheduleDraft(
            weekday: 1,
            startPeriod: 1,
            endPeriod: 2,
            location: 'A201',
            weeks: {1, 2, 3},
          ),
          ScheduleDraft(
            weekday: 3,
            startPeriod: 3,
            endPeriod: 3,
            location: 'B302',
            weeks: {1, 2},
          ),
        ],
      ),
    );
    final original = (await planner.load())
        .today(DateTime.utc(2026, 8, 31))
        .single;
    await planner.saveClassException(
      ClassExceptionDraft(
        scheduleId: (original.schedule as ClassSchedule).id,
        originalDate: original.date,
        targetDate: DateTime.utc(2026, 9, 7),
        startMinutes: 660,
        endMinutes: 720,
        location: ' C401 ',
      ),
    );
    await store.close();
    store = PlannerStore(NativeDatabase(file));
    planner = SemesterPlanner(store);
    final state = await planner.load();
    expect(state.today(DateTime.utc(2026, 8, 31)), isEmpty);
    final target = state.today(DateTime.utc(2026, 9, 7));
    expect(target.map((o) => o.startMinutes), [480, 660]);
    expect(target.map((o) => o.location), ['A201', 'C401']);
    expect(target.last.originalDate, DateTime.utc(2026, 8, 31));
    expect(
      (target.last.schedule as ClassSchedule).id,
      (original.schedule as ClassSchedule).id,
    );
    expect(state.today(DateTime.utc(2026, 9, 14)).single.location, 'A201');
    expect(state.today(DateTime.utc(2026, 9, 2)).single.location, 'B302');
    expect(state.timetable!.inWeek(2).length, 3);
    expect(state.classExceptions.single.originalDate, original.date);
    expect(state.courses.single.schedules.length, 2);
  });

  test('停课仅取消原课次，调课冲突确认前不写入；有效课表用于后续录课冲突判断', () async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    final semester = await planner.saveSemester(semesterDraft('秋季'));
    CourseDraft course(String name, int day, Set<int> weeks) => CourseDraft(
      semesterId: semester,
      name: name,
      schedules: [
        ScheduleDraft(
          weekday: day,
          startPeriod: 1,
          endPeriod: 1,
          location: 'A201',
          weeks: weeks,
        ),
      ],
    );
    await planner.saveCourse(course('数学', 1, {1, 2, 3}));
    await planner.saveCourse(course('英语', 2, {2}));
    final original = (await planner.load())
        .today(DateTime.utc(2026, 8, 31))
        .single;
    final scheduleId = (original.schedule as ClassSchedule).id;
    ClassExceptionDraft change({
      bool cancelled = false,
      int day = 8,
      int start = 480,
    }) => ClassExceptionDraft(
      scheduleId: scheduleId,
      originalDate: original.date,
      targetDate: DateTime.utc(2026, 9, day),
      startMinutes: start,
      endMinutes: start + 45,
      location: 'C401',
      isCancelled: cancelled,
    );
    await expectLater(
      planner.saveClassException(change()),
      throwsA(isA<CourseConflict>()),
    );
    expect((await planner.load()).classExceptions, isEmpty);
    await planner.saveClassException(change(), allowConflicts: true);
    expect((await planner.load()).today(DateTime.utc(2026, 9, 8)).length, 2);
    await planner.saveClassException(change(cancelled: true));
    var state = await planner.load();
    expect(state.classExceptions.length, 1);
    expect(state.today(DateTime.utc(2026, 8, 31)), isEmpty);
    expect(state.today(DateTime.utc(2026, 9, 8)).single.course.name, '英语');
    expect(state.today(DateTime.utc(2026, 9, 7)).single.course.name, '数学');
    await planner.saveCourse(course('补入原空位', 1, {1}));
    await planner.saveClassException(change(day: 9, start: 600));
    await expectLater(
      planner.saveCourse(
        CourseDraft(
          semesterId: semester,
          name: '与调课重叠',
          schedules: [
            ScheduleDraft(
              weekday: 3,
              startPeriod: 3,
              endPeriod: 3,
              location: '',
              weeks: {2},
            ),
          ],
        ),
      ),
      throwsA(isA<CourseConflict>()),
    );
    await expectLater(
      planner.saveClassException(change(start: 1430)),
      throwsA(isA<InputProblem>()),
    );
    state = await planner.load();
    expect(state.classExceptions.single.startMinutes, 600);
    expect(state.courses.length, 3);
  });

  test('已有 schema 4 升级保留任务、事件、课程与校园时区，停课和再次调课经文件重开保留', () async {
    final directory = await Directory.systemTemp.createTemp(
      'exceptions_migration_',
    );
    final file = File('${directory.path}/planner.sqlite');
    var store = PlannerStore(
      NativeDatabase(
        file,
        setup: (db) {
          db.execute(File('test/fixtures/planner_v4.sql').readAsStringSync());
        },
      ),
    );
    addTearDown(() async {
      await store.close();
      await directory.delete(recursive: true);
    });
    var planner = SemesterPlanner(store);
    var state = await planner.load();
    expect(state.classExceptions, isEmpty);
    expect(state.events.single.title, '期中考试');
    expect(state.events.single.isPinned, isTrue);
    expect(state.tasks.single.isCompleted, isTrue);
    expect(state.tasks.single.courseId, state.courses.single.id);
    expect(state.campusTimeZone, 'Asia/Tokyo');
    final schedule = state.courses.single.schedules.single as ClassSchedule;
    ClassExceptionDraft change(
      DateTime original, {
      bool cancelled = false,
      int targetDay = 15,
    }) => ClassExceptionDraft(
      scheduleId: schedule.id,
      originalDate: original,
      targetDate: DateTime.utc(2026, 9, targetDay),
      startMinutes: 600,
      endMinutes: 645,
      location: '补课教室',
      isCancelled: cancelled,
    );
    await planner.saveClassException(
      change(DateTime.utc(2026, 8, 31), cancelled: true),
    );
    await planner.saveClassException(change(DateTime.utc(2026, 9, 14)));
    await planner.saveClassException(
      change(DateTime.utc(2026, 9, 14), targetDay: 16),
    );
    await expectLater(
      planner.saveClassException(change(DateTime.utc(2026, 9, 1))),
      throwsA(isA<InputProblem>()),
    );
    await expectLater(
      planner.saveClassException(
        ClassExceptionDraft(
          scheduleId: -1,
          originalDate: DateTime.utc(2026, 8, 31),
          targetDate: DateTime.utc(2026, 9, 1),
          startMinutes: 600,
          endMinutes: 645,
          location: '',
        ),
      ),
      throwsA(isA<InputProblem>()),
    );
    await store.close();
    store = PlannerStore(NativeDatabase(file));
    planner = SemesterPlanner(store);
    state = await planner.load();
    expect(state.classExceptions.length, 2);
    expect(state.today(DateTime.utc(2026, 8, 31)), isEmpty);
    expect(state.today(DateTime.utc(2026, 9, 14)), isEmpty);
    expect(state.today(DateTime.utc(2026, 9, 15)), isEmpty);
    expect(
      state.today(DateTime.utc(2026, 9, 16)).single.originalDate,
      DateTime.utc(2026, 9, 14),
    );
    expect(state.today(DateTime.utc(2026, 9, 28)).single.location, 'A201');
    expect(state.events.single.title, '期中考试');
    expect(state.tasks.single.notes, '保留实验数据');
  });

  test('调到未配置节次的日期或学期外仍可见，校园日期不随手机时区改变', () async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    final semester = await planner.saveSemester(
      SemesterDraft(
        name: '短学期',
        firstMonday: DateTime.utc(2026, 8, 31),
        totalWeeks: 1,
        periods: {
          1: [const PeriodTime(480, 525)],
        },
      ),
    );
    await planner.saveCourse(
      CourseDraft(
        semesterId: semester,
        name: '数学',
        schedules: [
          ScheduleDraft(
            weekday: 1,
            startPeriod: 1,
            endPeriod: 1,
            location: 'A201',
            weeks: {1},
          ),
        ],
      ),
    );
    final original = (await planner.load())
        .today(DateTime.utc(2026, 8, 31))
        .single;
    await planner.saveClassException(
      ClassExceptionDraft(
        scheduleId: (original.schedule as ClassSchedule).id,
        originalDate: original.date,
        targetDate: DateTime.utc(2026, 9, 13),
        startMinutes: 1140,
        endMinutes: 1200,
        location: '夜间补课',
      ),
    );
    final state = await planner.load();
    expect(state.timetable!.inWeek(2).single.location, '夜间补课');
    expect(
      state
          .today(DateTime.parse('2026-09-13T01:00:00-10:00'))
          .single
          .startMinutes,
      1140,
    );
    expect(state.today(DateTime.parse('2026-09-13T16:00:00Z')), isEmpty);
  });
}
