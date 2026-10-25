import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/tasks/model.dart';
import 'package:unipocket/timetable/model.dart';

import 'class_exception_flow.dart';
import 'widget_actions.dart';

Future<void> seedScheduleImpact(SemesterPlanner planner) async {
  await seedExceptionCourses(planner);
  final state = await planner.load();
  final math = state.courses.singleWhere((c) => c.name == '高等数学');
  final english = state.courses.singleWhere((c) => c.name == '大学英语');
  final schedules = math.schedules.cast<ClassSchedule>().toList();
  await planner.saveClassException(
    ClassExceptionDraft(
      scheduleId: schedules.first.id,
      originalDate: DateTime.utc(2026, 10, 19),
      targetDate: DateTime.utc(2026, 10, 20),
      startMinutes: 720,
      endMinutes: 780,
      location: '保留的跨日调课',
    ),
  );
  await planner.saveClassException(
    ClassExceptionDraft(
      scheduleId: schedules.first.id,
      originalDate: DateTime.utc(2026, 11, 2),
      targetDate: DateTime.utc(2026, 11, 2),
      startMinutes: 480,
      endMinutes: 580,
      location: 'A201',
      isCancelled: true,
    ),
  );
  await planner.saveClassException(
    ClassExceptionDraft(
      scheduleId: schedules.last.id,
      originalDate: DateTime.utc(2026, 10, 23),
      targetDate: DateTime.utc(2026, 10, 26),
      startMinutes: 480,
      endMinutes: 580,
      location: '数学楼 C401',
    ),
    allowConflicts: true,
  );
  await planner.saveClassException(
    ClassExceptionDraft(
      scheduleId: schedules.last.id,
      originalDate: DateTime.utc(2026, 10, 30),
      targetDate: DateTime.utc(2026, 10, 30),
      startMinutes: 480,
      endMinutes: 580,
      location: 'A201',
      isCancelled: true,
    ),
  );
  final task = await planner.saveTask(
    LearningTaskDraft(
      title: '英语阅读报告',
      dueDate: DateTime.utc(2026, 10, 28),
      courseId: english.id,
      notes: '保留全文及完成状态',
    ),
  );
  await planner.setTaskCompleted(task, true);
  await planner.saveTask(
    LearningTaskDraft(
      title: '英语听力练习',
      dueDate: DateTime.utc(2026, 10, 29),
      courseId: english.id,
    ),
  );
  await planner.saveTask(
    LearningTaskDraft(
      title: '高数习题 第五章',
      dueDate: DateTime.utc(2026, 10, 27),
      courseId: math.id,
    ),
  );
}

Future<void> _top(WidgetTester tester) async {
  final scroll = find
      .byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      )
      .first;
  await tester.drag(scroll, const Offset(0, 10000));
  await tester.pumpAndSettle();
}

Future<void> runScheduleImpactCreation(
  WidgetTester tester,
  SemesterPlanner planner, {
  Future<void> Function(String)? capture,
}) async {
  Future<void> shot(String name) async {
    if (capture != null) await capture(name);
  }

  await waitFor(tester, find.byKey(const ValueKey('main-navigation')));
  await shot('06-android-home-before');
  await tapVisible(tester, find.text('课表'));
  await shot('06-android-week-before');
  await tapVisible(tester, find.text('本学期课程'));
  await tapVisible(tester, find.text('高等数学').last);
  await tapVisible(tester, find.text('修改重复安排'));
  await tapVisible(tester, find.byKey(const ValueKey('remove-schedule-1')));
  await tapVisible(tester, find.byKey(const ValueKey('save-course')));
  await waitFor(tester, find.text('确认安排变更'));
  await shot('06-android-impact-summary');
  expect((await planner.load()).classExceptions.length, 4);
  await tapVisible(tester, find.text('返回修改'));
  expect((await planner.load()).courses.first.schedules.length, 2);
  await tapVisible(tester, find.byKey(const ValueKey('save-course')));
  await waitFor(tester, find.text('确认安排变更'));
  await tapVisible(tester, find.byKey(const ValueKey('orphan-choice-0')));
  await tapVisible(tester, find.text('保留为独立补课').last);
  await shot('06-android-orphan-move-choice');
  await tapVisible(tester, find.byKey(const ValueKey('orphan-choice-1')));
  await tapVisible(tester, find.text('删除此例外').last);
  await shot('06-android-orphan-cancellation-choice');
  await tapVisible(tester, find.text('确认变更'));
  await waitFor(tester, find.text('上课时间冲突'));
  await shot('06-android-conflict');
  await tapVisible(tester, find.text('返回修改').last);
  expect((await planner.load()).classExceptions.length, 4);
  expect((await planner.load()).independentLessons, isEmpty);
  await tapVisible(tester, find.text('确认变更'));
  await tapVisible(tester, find.text('仍然保存'));
  await waitFor(tester, find.byKey(const ValueKey('main-navigation')));
  var state = await planner.load();
  expect(state.classExceptions.length, 2);
  expect(state.independentLessons.length, 1);
  expect(state.courses.first.schedules.length, 1);
  await _top(tester);
  await shot('06-android-week-independent');
  await tapVisible(tester, find.text('补 · 高等数学'));
  await tapVisible(tester, find.text('编辑独立补课'));
  await tester.enterText(
    find.byKey(const ValueKey('exception-location')),
    '数学楼 C402 独立补课',
  );
  await shot('06-android-independent-editor');
  await tapVisible(tester, find.text('保存补课'));
  await tapVisible(tester, find.text('仍然保存'));
  await waitFor(tester, find.byKey(const ValueKey('main-navigation')));
  // Only the English course is deleted; mathematics retains the independent lesson.
  await tapVisible(tester, find.text('本学期课程'));
  await tapVisible(tester, find.text('大学英语').last);
  await tapVisible(tester, find.text('删除课程'));
  await waitFor(tester, find.text('确认删除课程'));
  await shot('06-android-delete-impact');
  await tapVisible(tester, find.text('取消'));
  expect((await planner.load()).courses.length, 5);
  await tapVisible(tester, find.text('删除课程'));
  await tapVisible(tester, find.text('确认删除'));
  await waitFor(tester, find.byKey(const ValueKey('main-navigation')));
  state = await planner.load();
  expect(state.courses.length, 4);
  expect(state.tasks.where((t) => t.courseId == null).length, 2);
  expect(
    state.tasks.singleWhere((t) => t.title == '英语阅读报告').isCompleted,
    isTrue,
  );
  await tapVisible(tester, find.byTooltip('学习任务'));
  await waitFor(tester, find.text('英语听力练习'));
  await shot('06-android-ddl-retained');
  expect(tester.takeException(), isNull);
}

Future<void> verifyScheduleImpactRestoration(
  WidgetTester tester,
  SemesterPlanner planner, {
  Future<void> Function(String)? capture,
}) async {
  await waitFor(tester, find.byKey(const ValueKey('main-navigation')));
  final state = await planner.load();
  expect(state.courses.length, 4);
  final math = state.courses.singleWhere((c) => c.name == '高等数学');
  expect(math.schedules.length, 1);
  expect(state.classExceptions.length, 2);
  expect(state.independentLessons.single.location, '数学楼 C402 独立补课');
  expect(state.independentLessons.single.courseId, math.id);
  final lessons = state.timetable!.onDate(DateTime.utc(2026, 10, 26));
  expect(lessons.length, 2);
  expect(
    lessons.where((o) => o.isIndependent).single.location,
    '数学楼 C402 独立补课',
  );
  expect(state.timetable!.onDate(DateTime.utc(2026, 11, 2)), isEmpty);
  expect(
    state.timetable!.onDate(DateTime.utc(2026, 10, 20)).last.location,
    '保留的跨日调课',
  );
  expect(state.tasks.where((t) => t.courseId == null).length, 2);
  expect(
    state.tasks.singleWhere((t) => t.title == '英语阅读报告').isCompleted,
    isTrue,
  );
  expect(
    state.tasks.singleWhere((t) => t.title == '英语阅读报告').notes,
    '保留全文及完成状态',
  );
  expect(
    state.tasks.singleWhere((t) => t.title == '高数习题 第五章').courseId,
    math.id,
  );
  await tapVisible(tester, find.text('课表'));
  await waitFor(tester, find.text('补 · 高等数学'));
  if (capture != null) await capture('06-android-process-restored');
  await tapVisible(tester, find.text('补 · 高等数学'));
  expect(find.text('独立补课'), findsOneWidget);
  await tapVisible(tester, find.text('编辑独立补课'));
  expect(find.text('独立补课 · 不关联重复安排'), findsOneWidget);
  await tapVisible(tester, find.text('取消编辑'));
  expect(
    (await planner.load()).independentLessons.single.location,
    '数学楼 C402 独立补课',
  );
  expect(tester.takeException(), isNull);
}
