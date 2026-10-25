import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unipocket/semesters/model.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/timetable/model.dart';

import 'widget_actions.dart';

Future<void> seedExceptionCourses(SemesterPlanner planner) async {
  final semester = await planner.saveSemester(
    SemesterDraft(
      name: '2026 秋季学期',
      firstMonday: DateTime.utc(2026, 8, 31),
      totalWeeks: 20,
      periods: {
        for (var day = 1; day <= 7; day++)
          day: [
            const PeriodTime(480, 525),
            const PeriodTime(535, 580),
            const PeriodTime(600, 645),
            const PeriodTime(655, 700),
            const PeriodTime(840, 885),
            const PeriodTime(895, 940),
            const PeriodTime(960, 1005),
            const PeriodTime(1015, 1060),
          ],
      },
    ),
  );
  ScheduleDraft schedule(int day, int start, String location) => ScheduleDraft(
    weekday: day,
    startPeriod: start,
    endPeriod: start + 1,
    location: location,
    weeks: {8, 9, 10},
  );
  await planner.saveCourse(
    CourseDraft(
      semesterId: semester,
      name: '高等数学',
      teacher: '李老师',
      schedules: [schedule(1, 1, 'A201'), schedule(5, 1, 'A201')],
    ),
  );
  await planner.saveCourse(
    CourseDraft(
      semesterId: semester,
      name: '程序设计',
      colorIndex: 1,
      schedules: [schedule(3, 1, '机房203')],
    ),
  );
  await planner.saveCourse(
    CourseDraft(
      semesterId: semester,
      name: '大学物理',
      colorIndex: 2,
      schedules: [schedule(2, 3, 'C103')],
    ),
  );
  await planner.saveCourse(
    CourseDraft(
      semesterId: semester,
      name: '体育',
      colorIndex: 3,
      schedules: [schedule(4, 5, '体育馆')],
    ),
  );
  await planner.saveCourse(
    CourseDraft(
      semesterId: semester,
      name: '大学英语',
      colorIndex: 4,
      schedules: [schedule(5, 5, 'B302')],
    ),
  );
}

Future<void> pickExceptionTime(
  WidgetTester tester,
  String key,
  String hour,
  String minute,
) async {
  await tapVisible(tester, find.byKey(ValueKey(key)));
  await tapVisible(tester, find.byIcon(Icons.keyboard_outlined));
  final fields = find.descendant(
    of: find.byType(TimePickerDialog),
    matching: find.byType(TextField),
  );
  await tester.enterText(fields.at(0), hour);
  await tester.enterText(fields.at(1), minute);
  await tapVisible(tester, find.text('确定'));
}

Future<void> runExceptionCreation(
  WidgetTester tester,
  SemesterPlanner planner, {
  Future<void> Function(String)? capture,
}) async {
  Future<void> shot(String name) async {
    if (capture != null) await capture(name);
  }

  await waitFor(tester, find.text('高等数学'));
  await shot('05-reference-home');
  await tapVisible(tester, find.text('课表'));
  await shot('05-reference-week');
  await tapVisible(tester, find.text('首页'));
  await tapVisible(tester, find.text('高等数学'));
  await tapVisible(tester, find.text('单次调课'));
  // Cancel a real edited draft before saving anything.
  await tester.enterText(
    find.byKey(const ValueKey('exception-location')),
    '未保存',
  );
  await tapVisible(tester, find.text('取消编辑'));
  expect((await planner.load()).classExceptions, isEmpty);
  await tapVisible(tester, find.text('单次调课'));
  await tapVisible(tester, find.byKey(const ValueKey('exception-date')));
  await tapVisible(tester, find.text('26'));
  await tapVisible(tester, find.text('确定'));
  await tester.enterText(
    find.byKey(const ValueKey('exception-location')),
    '数学楼 C401',
  );
  await shot('05-android-editor');
  await tapVisible(tester, find.text('保存调课'));
  await waitFor(tester, find.text('调课时间冲突'));
  await shot('05-android-conflict');
  expect((await planner.load()).classExceptions, isEmpty);
  await tapVisible(tester, find.text('返回修改'));
  await tapVisible(tester, find.text('保存调课'));
  await waitFor(tester, find.text('仍然保存'));
  await tapVisible(tester, find.text('仍然保存'));
  await waitFor(tester, find.byKey(const ValueKey('main-navigation')));
  expect(
    (await planner.load()).today(DateTime.utc(2026, 10, 23)).single.course.name,
    '大学英语',
  );
  await tapVisible(tester, find.text('大学英语'));
  await tapVisible(tester, find.text('单次停课'));
  await shot('05-android-cancel-confirmation');
  await tapVisible(tester, find.text('取消编辑'));
  expect((await planner.load()).classExceptions.length, 1);
  await tapVisible(tester, find.text('单次停课'));
  await tapVisible(tester, find.text('确认停课'));
  await waitFor(tester, find.byKey(const ValueKey('main-navigation')));
  expect((await planner.load()).today(DateTime.utc(2026, 10, 23)), isEmpty);
  await shot('05-android-home-saved');
  await tapVisible(tester, find.text('课表'));
  await tapVisible(tester, find.byTooltip('下一周'));
  await waitFor(tester, find.text('调 · 高等数学'));
  await shot('05-android-week-conflict');
  expect(
    (await planner.load()).timetable!.onDate(DateTime.utc(2026, 10, 26)).length,
    2,
  );
  // Change the already-moved lesson's time using the real time picker. Its
  // original identity must remain Oct 23, rather than becoming Oct 26.
  await tapVisible(tester, find.text('调 · 高等数学'));
  await tapVisible(tester, find.text('单次调课'));
  await pickExceptionTime(tester, 'exception-end', '11', '40');
  await pickExceptionTime(tester, 'exception-start', '10', '00');
  await tapVisible(tester, find.text('保存调课'));
  await waitFor(tester, find.byKey(const ValueKey('main-navigation')));
  final state = await planner.load();
  final move = state.classExceptions.singleWhere((e) => !e.isCancelled);
  expect(move.originalDate, DateTime.utc(2026, 10, 23));
  expect(move.startMinutes, 600);
  expect(move.endMinutes, 700);
  expect(state.classExceptions.length, 2);
  await tester.drag(
    find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .first,
    const Offset(0, 10000),
  );
  await tester.pumpAndSettle();
  await shot('05-android-week-saved');
  expect(tester.takeException(), isNull);
}

Future<void> verifyExceptionRestoration(
  WidgetTester tester,
  SemesterPlanner planner, {
  Future<void> Function(String)? capture,
}) async {
  await waitFor(tester, find.byKey(const ValueKey('main-navigation')));
  var state = await planner.load();
  expect(state.classExceptions.length, 2);
  expect(state.today(DateTime.utc(2026, 10, 23)), isEmpty);
  final target = state.timetable!.onDate(DateTime.utc(2026, 10, 26));
  expect(target.map((o) => o.startMinutes), [480, 600]);
  expect(target.last.originalDate, DateTime.utc(2026, 10, 23));
  expect(target.last.location, '数学楼 C401');
  expect(
    state.timetable!
        .onDate(DateTime.utc(2026, 10, 30))
        .map((o) => o.course.name),
    ['高等数学', '大学英语'],
  );
  await tapVisible(tester, find.text('课表'));
  await tapVisible(tester, find.text('今日'));
  expect(find.text('今天没有课程，可以从容安排时间。'), findsOneWidget);
  await tapVisible(tester, find.text('周课表'));
  await tapVisible(tester, find.byTooltip('下一周'));
  await waitFor(tester, find.text('调 · 高等数学'));
  if (capture != null) await capture('05-android-process-restored');
  // Cancelled lessons stay manageable even though they leave the timetable.
  await tapVisible(tester, find.text('本学期课程'));
  await tapVisible(tester, find.text('大学英语').last);
  await tapVisible(tester, find.text('重新安排这次上课'));
  await tapVisible(tester, find.text('取消编辑'));
  await tapVisible(tester, find.byType(BackButton));
  await tester.pumpAndSettle();
  state = await planner.load();
  expect(
    state.classExceptions.singleWhere((e) => e.isCancelled).originalDate,
    DateTime.utc(2026, 10, 23),
  );
  expect(tester.takeException(), isNull);
}
