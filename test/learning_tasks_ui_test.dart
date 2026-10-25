import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/tasks/model.dart';
import 'package:unipocket/tasks/tasks_page.dart';
import 'package:unipocket/timetable/model.dart';
import 'package:unipocket/ui/design.dart';

import 'support/widget_actions.dart';
import 'support/semester_fixture.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  for (final width in [320.0, 393.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$width 宽度、$scale 倍文字下完整列表、长标题、筛选及表单可滚动访问', (tester) async {
        tester.view.physicalSize = Size(width, 852);
        tester.view.devicePixelRatio = 1;
        tester.view.padding = const FakeViewPadding(top: 28, bottom: 24);
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.view.resetPadding();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });
        await tester.runAsync(() async {
          final store = PlannerStore(NativeDatabase.memory());
          final planner = SemesterPlanner(store);
          final semester = await planner.saveSemester(semesterDraft('历史学期'));
          final course = await planner.saveCourse(
            CourseDraft(
              semesterId: semester,
              name: '高等数学与数学分析很长的课程名称',
              schedules: [
                ScheduleDraft(
                  weekday: 1,
                  startPeriod: 1,
                  endPeriod: 1,
                  location: '',
                  weeks: {1},
                ),
              ],
            ),
          );
          for (var i = 0; i < 8; i++) {
            await planner.saveTask(
              LearningTaskDraft(
                title: '第 $i 项学习任务的长标题需要完整展示且可以点击编辑',
                dueDate: DateTime(2026, 10, 24 + i),
                courseId: i.isEven ? course : null,
              ),
            );
          }
          try {
            await tester.pumpWidget(
              UniPocketApp(
                planner: planner,
                clock: () => DateTime.utc(2026, 10, 25, 4),
              ),
            );
            await waitFor(tester, find.textContaining('校园时间'));
            await tapVisible(tester, find.textContaining('查看全部任务'));
            await waitFor(tester, find.byType(TasksPage));
            expect(tester.takeException(), isNull);
            await tapVisible(tester, find.text('第 7 项学习任务的长标题需要完整展示且可以点击编辑'));
            await tapVisible(tester, find.byKey(const ValueKey('task-notes')));
            await tester.enterText(
              find.byKey(const ValueKey('task-notes')),
              '末项任务的备注',
            );
            await tapVisible(tester, find.byKey(const ValueKey('task-course')));
            await tapVisible(tester, find.text('高等数学与数学分析很长的课程名称 · 历史学期').last);
            await tapVisible(tester, find.text('保存任务'));
            await waitFor(tester, find.byType(TasksPage));
            expect((await planner.load()).tasks.last.notes, '末项任务的备注');
            expect((await planner.load()).tasks.last.courseId, course);
            await tapVisible(tester, find.byTooltip('筛选课程'));
            await tapVisible(tester, find.text('高等数学与数学分析很长的课程名称 · 历史学期'));
            expect(find.text('第 1 项学习任务的长标题需要完整展示且可以点击编辑'), findsNothing);
            await tapVisible(tester, find.text('第 0 项学习任务的长标题需要完整展示且可以点击编辑'));
            await tapVisible(tester, find.byTooltip('返回'));
            await tapVisible(tester, find.byTooltip('筛选课程'));
            await tapVisible(tester, find.text('独立任务'));
            expect(find.text('第 0 项学习任务的长标题需要完整展示且可以点击编辑'), findsNothing);
            await tapVisible(
              tester,
              find.byTooltip('完成：第 1 项学习任务的长标题需要完整展示且可以点击编辑'),
            );
            await waitFor(tester, find.text('任务已完成'));
            await tapVisible(tester, find.text('已完成  1'));
            expect(find.text('第 1 项学习任务的长标题需要完整展示且可以点击编辑'), findsOneWidget);
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await store.close();
          }
        });
      });
    }
  }

  testWidgets('任务页停留时跨过截止时间，刷新后显示已逾期且不自动完成', (tester) async {
    final store = PlannerStore(NativeDatabase.memory());
    final planner = SemesterPlanner(store);
    var instant = DateTime.utc(2026, 10, 25, 15, 59);
    addTearDown(store.close);
    await tester.runAsync(() async {
      await planner.saveTask(
        LearningTaskDraft(title: '即将逾期', dueDate: DateTime(2026, 10, 25)),
      );
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(),
        home: TasksPage(planner: planner, clock: () => instant),
      ),
    );
    await tester.runAsync(() => waitFor(tester, find.text('即将逾期')));
    expect(find.text('今天'), findsOneWidget);
    instant = DateTime.utc(2026, 10, 25, 16);
    await tester.pump(const Duration(seconds: 31));
    expect(find.text('已逾期'), findsOneWidget);
    expect(find.text('今天'), findsNothing);
    await tester.runAsync(() async {
      expect((await planner.load()).tasks.single.isCompleted, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
  testWidgets('无需学期也能从首页创建独立任务，默认 23:59 并完成、撤销及编辑删除', (tester) async {
    await tester.runAsync(() async {
      final store = PlannerStore(NativeDatabase.memory());
      final planner = SemesterPlanner(store);
      try {
        await tester.pumpWidget(
          UniPocketApp(
            planner: planner,
            clock: () => DateTime.utc(2026, 10, 25, 4),
          ),
        );
        await waitFor(tester, find.text('创建任务'));
        await tapVisible(tester, find.text('创建任务'));
        expect(find.textContaining('默认 23:59'), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('task-title')),
          '阅读笔记',
        );
        await tester.enterText(find.byKey(const ValueKey('task-notes')), '第三章');
        await tapVisible(tester, find.text('保存任务'));
        await waitFor(tester, find.text('阅读笔记'));
        expect((await planner.load()).tasks.single.notes, '第三章');
        expect((await planner.load()).tasks.single.dueMinutes, 1439);
        await tapVisible(tester, find.byTooltip('完成：阅读笔记'));
        await waitFor(tester, find.text('任务已完成'));
        await tapVisible(tester, find.text('撤销'));
        await waitFor(tester, find.text('阅读笔记'));
        expect((await planner.load()).tasks.single.isCompleted, isFalse);
        await tapVisible(tester, find.text('查看全部任务'));
        await waitFor(tester, find.text('每一个小目标，\n都值得完成'));
        await tapVisible(tester, find.text('阅读笔记'));
        await tester.enterText(
          find.byKey(const ValueKey('task-title')),
          '更新笔记',
        );
        await tapVisible(tester, find.byKey(const ValueKey('task-time')));
        await tapVisible(tester, find.byIcon(Icons.keyboard_outlined));
        final timeFields = find.descendant(
          of: find.byType(TimePickerDialog),
          matching: find.byType(TextField),
        );
        await tester.enterText(timeFields.first, '10');
        await tester.enterText(timeFields.last, '30');
        await tapVisible(tester, find.text('确定'));
        expect(find.text('10:30'), findsOneWidget);
        await tapVisible(tester, find.text('2026-10-25'));
        await tapVisible(tester, find.text('26'));
        await tapVisible(tester, find.text('确定'));
        await tapVisible(tester, find.text('保存任务'));
        await waitFor(tester, find.text('更新笔记'));
        expect((await planner.load()).tasks.single.dueMinutes, 630);
        expect(
          (await planner.load()).tasks.single.dueDate,
          DateTime.utc(2026, 10, 26),
        );
        await tapVisible(tester, find.text('更新笔记'));
        await tapVisible(tester, find.text('删除任务'));
        await tapVisible(tester, find.text('取消'));
        expect((await planner.load()).tasks, hasLength(1));
        await tapVisible(tester, find.text('删除任务'));
        await tapVisible(tester, find.text('确认删除'));
        await waitFor(tester, find.text('还没有学习任务'));
        expect((await planner.load()).tasks, isEmpty);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
      }
    });
  });
}
