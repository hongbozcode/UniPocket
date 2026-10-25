import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/semesters/model.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/timetable/model.dart';

import 'support/semester_fixture.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('任务 1 数据库升级保留学期、节次和时区，且可新增课程', () async {
    final store = PlannerStore(
      NativeDatabase.memory(
        setup: (database) {
          database.execute(
            File('test/fixtures/planner_v1.sql').readAsStringSync(),
          );
        },
      ),
    );
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    final state = await planner.load();
    expect(state.currentSemester!.name, '升级前的秋季');
    expect(state.currentSemester!.periods[1]!.single.startMinutes, 480);
    expect(state.campusTimeZone, 'Asia/Tokyo');
    expect(state.courses, isEmpty);
    await planner.saveCourse(
      CourseDraft(
        semesterId: state.currentSemesterId!,
        name: '升级后课程',
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
    expect(
      (await planner.load())
          .today(DateTime.utc(2026, 8, 31))
          .single
          .course
          .name,
      '升级后课程',
    );
  });

  test('切换学期只显示当前课程；编辑基本信息保留安排，非法录入及破坏课程的学期变更不写入', () async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    final autumn = await planner.saveSemester(semesterDraft('秋季'));
    final spring = await planner.saveSemester(semesterDraft('春季'));
    CourseDraft draft(
      int semesterId, {
      String name = '数学',
      int start = 1,
      int end = 1,
      int weekday = 1,
      Set<int> weeks = const {1},
    }) => CourseDraft(
      semesterId: semesterId,
      name: name,
      schedules: [
        ScheduleDraft(
          weekday: weekday,
          startPeriod: start,
          endPeriod: end,
          location: 'A201',
          weeks: weeks,
        ),
      ],
    );
    final id = await planner.saveCourse(draft(autumn));
    await planner.saveCourse(draft(spring, name: '历史'));
    await planner.updateCourseDetails(
      id,
      name: '数学分析',
      teacher: '王老师',
      colorIndex: 4,
      reminderMinutesBefore: 10,
    );
    var state = await planner.load();
    expect(
      state.today(DateTime.utc(2026, 8, 30, 16)).single.course.name,
      '数学分析',
    );
    expect(state.today(DateTime.utc(2026, 8, 30, 15, 59)), isEmpty);
    expect(
      state.courses.singleWhere((c) => c.id == id).schedules.single.location,
      'A201',
    );
    await planner.setCurrentSemester(spring);
    state = await planner.load();
    expect(state.today(DateTime.utc(2026, 8, 31)).single.course.name, '历史');
    expect(state.today(DateTime.utc(2026, 9, 1)), isEmpty);
    for (final invalid in [
      draft(autumn, name: ' '),
      draft(autumn, weekday: 8),
      draft(autumn, start: 0),
      draft(autumn, start: 3, end: 2),
      draft(autumn, end: 4),
      draft(autumn, weeks: {}),
      draft(autumn, weeks: {0}),
      draft(autumn, weeks: {21}),
      draft(9999),
      CourseDraft(semesterId: autumn, name: '空安排', schedules: []),
    ]) {
      await expectLater(
        planner.saveCourse(invalid, allowConflicts: true),
        throwsA(isA<InputProblem>()),
      );
      expect((await planner.load()).courses, hasLength(2));
    }
    await expectLater(
      planner.updateCourseDetails(
        id,
        name: '',
        teacher: '',
        colorIndex: 0,
        reminderMinutesBefore: 10,
      ),
      throwsA(isA<InputProblem>()),
    );
    await expectLater(
      planner.updateCourseDetails(
        9999,
        name: '不存在',
        teacher: '',
        colorIndex: 0,
        reminderMinutesBefore: 10,
      ),
      throwsA(isA<InputProblem>()),
    );
    await expectLater(
      planner.saveSemester(
        SemesterDraft(
          name: '不能清空周一节次',
          firstMonday: DateTime.utc(2026, 8, 31),
          totalWeeks: 20,
          periods: {
            2: [const PeriodTime(480, 525)],
          },
        ),
        id: autumn,
      ),
      throwsA(isA<InputProblem>()),
    );
    expect(
      (await planner.load()).semesters.singleWhere((s) => s.id == autumn).name,
      '秋季',
    );
  });

  test('相同教学周的时间冲突须确认，取消不写入；确认后重开仍保留两课', () async {
    final directory = await Directory.systemTemp.createTemp('conflicts-');
    final file = File('${directory.path}/planner.sqlite');
    var store = PlannerStore(NativeDatabase(file));
    try {
      final planner = SemesterPlanner(store);
      final semester = await planner.saveSemester(semesterDraft('秋季'));
      CourseDraft course(String name, int start, int end, Set<int> weeks) =>
          CourseDraft(
            semesterId: semester,
            name: name,
            schedules: [
              ScheduleDraft(
                weekday: 1,
                startPeriod: start,
                endPeriod: end,
                location: 'A201',
                weeks: weeks,
              ),
            ],
          );
      await planner.saveCourse(course('数学', 1, 2, {1, 3}));
      await planner.saveCourse(course('英语', 1, 2, {2, 4}));
      await planner.saveCourse(course('物理', 3, 3, {1}));
      final overlapping = course('程序设计', 2, 3, {3});
      await expectLater(
        planner.saveCourse(overlapping),
        throwsA(
          isA<CourseConflict>().having(
            (e) => e.message,
            '冲突课程',
            contains('数学'),
          ),
        ),
      );
      expect((await planner.load()).courses, hasLength(3));
      await planner.saveCourse(overlapping, allowConflicts: true);
      await store.close();
      store = PlannerStore(NativeDatabase(file));
      final restored = await SemesterPlanner(store).load();
      expect(restored.timetable!.inWeek(3).map((o) => o.course.name), [
        '数学',
        '程序设计',
      ]);
      expect(restored.courses, hasLength(4));
    } finally {
      await store.close();
      await directory.delete(recursive: true);
    }
  });

  test('多安排课程重开后保留教师、颜色、不同地点及任意教学周，按周一基准生成课次', () async {
    final directory = await Directory.systemTemp.createTemp('timetable-');
    final file = File('${directory.path}/planner.sqlite');
    var store = PlannerStore(NativeDatabase(file));
    try {
      var planner = SemesterPlanner(store);
      final semester = await planner.saveSemester(semesterDraft('秋季'));
      await planner.saveCourse(
        CourseDraft(
          semesterId: semester,
          name: '高等数学',
          teacher: '李老师',
          colorIndex: 2,
          schedules: [
            ScheduleDraft(
              weekday: 1,
              startPeriod: 1,
              endPeriod: 2,
              location: '数学楼 A201',
              weeks: {1, 3, 5, 8},
            ),
            ScheduleDraft(
              weekday: 3,
              startPeriod: 3,
              endPeriod: 3,
              location: '实验楼 B302',
              weeks: {2, 4, 8},
            ),
          ],
        ),
      );
      await store.close();
      store = PlannerStore(NativeDatabase(file));
      planner = SemesterPlanner(store);
      final state = await planner.load();
      final course = state.courses.single;
      expect(course.name, '高等数学');
      expect(course.teacher, '李老师');
      expect(course.colorIndex, 2);
      expect(course.schedules.map((s) => s.location), ['数学楼 A201', '实验楼 B302']);
      expect(course.schedules.first.weeks, {1, 3, 5, 8});
      final timetable = state.timetable!;
      expect(timetable.weekOf(DateTime.utc(2026, 8, 30)), 0);
      expect(timetable.weekOf(DateTime.utc(2026, 9, 6)), 1);
      expect(timetable.weekOf(DateTime.utc(2026, 9, 7)), 2);
      final firstMonday = timetable.onDate(DateTime.utc(2026, 8, 31)).single;
      expect(firstMonday.startMinutes, 480);
      expect(firstMonday.endMinutes, 580);
      expect(firstMonday.location, '数学楼 A201');
      expect(timetable.onDate(DateTime.utc(2026, 9, 7)), isEmpty);
      final secondWednesday = timetable.onDate(DateTime.utc(2026, 9, 9)).single;
      expect(secondWednesday.location, '实验楼 B302');
      expect(secondWednesday.startMinutes, 600);
      expect(timetable.inWeek(8), hasLength(2));
      expect(timetable.inWeek(0), isEmpty);
      expect(timetable.inWeek(21), isEmpty);
    } finally {
      await store.close();
      await directory.delete(recursive: true);
    }
  });
}
