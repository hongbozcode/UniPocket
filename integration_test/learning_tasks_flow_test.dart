import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/tasks/model.dart';
import 'package:unipocket/timetable/model.dart';

import '../test/support/semester_fixture.dart';
import '../test/support/widget_actions.dart';

const databaseName = String.fromEnvironment(
  'ACCEPTANCE_DATABASE',
  defaultValue: 'unipocket_tasks_acceptance',
);
const restore = bool.fromEnvironment('ACCEPTANCE_RESTORE');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  testWidgets('Android 学习任务真实表单管理与新进程恢复', (tester) async {
    Future<void> capture(String name) async {
      await tester.pump(const Duration(seconds: 1));
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      await binding.takeScreenshot(name);
    }

    final store = PlannerStore.open(name: databaseName);
    final planner = SemesterPlanner(store);
    try {
      if (!restore) {
        final semester = await planner.saveSemester(semesterDraft('2026 秋季学期'));
        final names = ['大学物理', '高等数学', '大学英语'];
        final titles = ['物理实验报告', '高数习题 第五章', '英语阅读笔记'];
        for (var i = 0; i < 3; i++) {
          final course = await planner.saveCourse(
            CourseDraft(
              semesterId: semester,
              name: names[i],
              colorIndex: [0, 0, 1][i],
              schedules: [
                ScheduleDraft(
                  weekday: i + 1,
                  startPeriod: 1,
                  endPeriod: 1,
                  location: 'A201',
                  weeks: {8},
                ),
              ],
            ),
          );
          await planner.saveTask(
            LearningTaskDraft(
              title: titles[i],
              dueDate: DateTime(2026, 10, [22, 23, 26][i]),
              courseId: course,
            ),
          );
        }
      }
      await tester.pumpWidget(
        UniPocketApp(
          planner: planner,
          clock: () => DateTime.utc(2026, 10, 23, 4),
        ),
      );
      await waitFor(tester, find.text('查看全部任务'));
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('查看全部任务'));
      await waitFor(tester, find.text('每一个小目标，\n都值得完成'));
      expect(find.textContaining('已逾期'), findsWidgets);
      expect(find.text('物理实验报告'), findsOneWidget);
      await capture(
        restore ? '03-android-process-restored' : '03-reference-tasks',
      );
      if (!restore) {
        await tapVisible(tester, find.byTooltip('创建任务'));
        await tester.enterText(
          find.byKey(const ValueKey('task-title')),
          '独立论文初稿',
        );
        await tester.enterText(
          find.byKey(const ValueKey('task-notes')),
          '完成文献综述与参考文献',
        );
        await tapVisible(tester, find.text('保存任务'));
        await waitFor(tester, find.text('独立论文初稿'));
        await tapVisible(tester, find.text('独立论文初稿'));
        await tester.enterText(
          find.byKey(const ValueKey('task-title')),
          '独立论文终稿',
        );
        await tapVisible(tester, find.text('保存任务'));
        await waitFor(tester, find.text('独立论文终稿'));
        await tapVisible(tester, find.byTooltip('完成：独立论文终稿'));
        await waitFor(tester, find.text('任务已完成'));
        await tapVisible(tester, find.text('撤销'));
        await waitFor(tester, find.text('独立论文终稿'));
        await tapVisible(tester, find.byTooltip('完成：独立论文终稿'));
        await waitFor(tester, find.text('任务已完成'));
      }
      await tapVisible(tester, find.text('已完成  1'));
      await waitFor(tester, find.text('独立论文终稿'));
      await capture(
        restore ? '03-android-completed-restored' : '03-android-completed',
      );
      final task = (await planner.load()).tasks.singleWhere(
        (t) => t.title == '独立论文终稿',
      );
      expect(task.notes, '完成文献综述与参考文献');
      expect(task.courseId, isNull);
      expect(task.isCompleted, isTrue);
      expect(task.dueMinutes, 1439);
      if (!restore) {
        await tapVisible(tester, find.text('独立论文终稿'));
        await capture('03-android-editor');
        await tapVisible(tester, find.byTooltip('返回'));
        await tapVisible(tester, find.byTooltip('返回'));
        await waitFor(tester, find.text('首页'));
        expect(find.text('撤销'), findsNothing);
      } else {
        await tapVisible(tester, find.byTooltip('撤销完成：独立论文终稿'));
        await waitFor(tester, find.text('已撤销完成'));
        await tapVisible(tester, find.text('未完成  4'));
        await tapVisible(tester, find.text('独立论文终稿'));
        await tapVisible(tester, find.text('删除任务'));
        await tapVisible(tester, find.text('取消'));
        expect((await planner.load()).tasks, hasLength(4));
        await tapVisible(tester, find.text('删除任务'));
        await tapVisible(tester, find.text('确认删除'));
        await waitFor(tester, find.text('未完成  3'));
        expect((await planner.load()).tasks, hasLength(3));
        await tapVisible(tester, find.byTooltip('返回'));
        await tapVisible(tester, find.text('课表'));
        await tapVisible(tester, find.byTooltip('学习任务'));
        await waitFor(tester, find.text('每一个小目标，\n都值得完成'));
        await capture('03-android-from-timetable');
      }
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await store.close();
    }
  });
}
