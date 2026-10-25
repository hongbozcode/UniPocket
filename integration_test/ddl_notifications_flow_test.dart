import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/reminders/android_notifications.dart';
import 'package:unipocket/reminders/notifications.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/tasks/model.dart';

import '../test/support/widget_actions.dart';

const databaseName = String.fromEnvironment(
  'ACCEPTANCE_DATABASE',
  defaultValue: 'unipocket_ddl_acceptance',
);
const restore = bool.fromEnvironment('ACCEPTANCE_RESTORE');
const blocked = bool.fromEnvironment('ACCEPTANCE_BLOCKED');
const delivery = bool.fromEnvironment('ACCEPTANCE_DELIVERY');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  if (const bool.fromEnvironment('ACCEPTANCE_CLEANUP')) {
    testWidgets('仅清理本轮验收命名空间的系统提醒', (tester) async {
      await const AndroidNotifications(namespace: databaseName)
          .replace('ddl', []);
    });
    return;
  }
  testWidgets('Android DDL 提醒配置、真实权限及新进程恢复', (tester) async {
    final store = PlannerStore.open(name: databaseName);
    final planner = SemesterPlanner(
      store,
      notifications: const AndroidNotifications(namespace: databaseName),
    );
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));
      await binding.takeScreenshot(name);
    }

    try {
      if (!restore) {
        final state = await planner.load();
        final date = state.campusTime(
          DateTime.now().add(const Duration(days: 3)),
        );
        await planner.saveTask(LearningTaskDraft(title: '论文终稿', dueDate: date));
      }
      await tester.pumpWidget(UniPocketApp(planner: planner));
      await waitFor(tester, find.textContaining('校园时间'));
      await binding.convertFlutterSurfaceToImage();
      await tapVisible(tester, find.text('查看全部任务'));
      await waitFor(tester, find.text('论文终稿'));
      await tapVisible(tester, find.text('论文终稿'));
      expect(find.byKey(const ValueKey('task-reminder-lead')), findsOneWidget);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('task-reminder-lead')),
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.ensureVisible(
        find.byKey(const ValueKey('task-reminder-enabled')),
      );
      await capture(
        restore ? '07-android-editor-restored' : '07-android-editor',
      );
      if (!restore) {
        await tester.enterText(
          find.byKey(const ValueKey('task-reminder-lead')),
          '30',
        );
        await tapVisible(tester, find.text('保存任务'));
        await waitFor(tester, find.textContaining('任务已保存到本机'));
      } else {
        expect((await planner.load()).tasks.first.reminderMinutesBefore, 30);
        await tapVisible(tester, find.byTooltip('返回'));
      }
      await waitFor(tester, find.text('每一个小目标，\n都值得完成'));
      await tapVisible(tester, find.byTooltip('返回'));
      await waitFor(tester, find.byKey(const ValueKey('main-navigation')));
      await tapVisible(tester, find.text('设置'));
      await waitFor(tester, find.text('通知权限'));
      await tapVisible(tester, find.text('刷新提醒状态'));
      expect(
        planner.notificationAccess,
        blocked ? NotificationAccess.blocked : NotificationAccess.enabled,
      );
      await capture(
        blocked ? '07-android-permission-blocked' : '07-android-settings',
      );
      await planner.notifications.openSettings();
      // The driver returns with Android's real app notification settings visible.
      // Host-side evidence records the OS screen, then returns to the app.
      if ((!restore || delivery) && !blocked) {
        final state = await planner.load();
        final at = state.campusTime(
          DateTime.now().add(const Duration(minutes: 2)),
        );
        await planner.saveTask(
          LearningTaskDraft(
            title: '任务7·送达验收',
            dueDate: at,
            dueMinutes: at.hour * 60 + at.minute,
            reminderMinutesBefore: 0,
          ),
        );
        // Send a stable, human-readable planned instant to the driver output.
        debugPrint(
          'DDL_DELIVERY_AT=${taskReminderAt((await planner.load()).tasks.last, state.campusTimeZone)!.toIso8601String()}',
        );
      }
      if (blocked) {
        await planner.saveTask(
          LearningTaskDraft(title: '权限关闭仍保存', dueDate: DateTime(2026, 12, 31)),
        );
        expect(
          (await planner.load()).tasks.any((t) => t.title == '权限关闭仍保存'),
          isTrue,
        );
      }
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await store.close();
    }
  });
}
