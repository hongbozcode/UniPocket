import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/events/model.dart';
import 'package:unipocket/reminders/android_notifications.dart';
import 'package:unipocket/reminders/notifications.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/tasks/model.dart';

import '../test/support/semester_fixture.dart';
import '../test/support/widget_actions.dart';

const databaseName = String.fromEnvironment(
  'ACCEPTANCE_DATABASE',
  defaultValue: 'unipocket_event_acceptance',
);
const phase = String.fromEnvironment(
  'ACCEPTANCE_PHASE',
  defaultValue: 'create',
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  testWidgets('Android 事件提醒表单、跨学期保留、进程恢复与系统调度', (tester) async {
    const notifications = AndroidNotifications(namespace: databaseName);
    if (phase == 'cleanup') {
      for (final scope in ['event', 'ddl', 'course']) {
        await notifications.replace(scope, []);
      }
      return;
    }
    final store = PlannerStore.open(name: databaseName);
    final planner = SemesterPlanner(store, notifications: notifications);
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      await binding.takeScreenshot(name);
    }

    try {
      var state = await planner.load();
      final now = state.campusTime(DateTime.now().toUtc());
      final today = DateTime.utc(now.year, now.month, now.day);
      if (phase == 'create') {
        expect(state.events, isEmpty, reason: '使用本轮专用空数据库');
        await planner.saveSemester(semesterDraft('秋季学期'));
        await planner.saveTask(
          LearningTaskDraft(
            title: '跨学期保留的学习任务',
            dueDate: today.add(const Duration(days: 7)),
          ),
        );
        await planner.saveEvent(
          CountdownEventDraft(
            title: '期中考试',
            targetDate: today.add(const Duration(days: 14)),
            isPinned: true,
          ),
        );
        await planner.saveEvent(
          CountdownEventDraft(
            title: '社团展示日',
            targetDate: today.add(const Duration(days: 7)),
            kind: EventKind.custom,
          ),
        );
        await planner.saveEvent(
          CountdownEventDraft(
            title: '课程展示',
            targetDate: today,
            kind: EventKind.custom,
          ),
        );
      } else {
        expect(state.events.first.title, '期中考试');
        expect(state.events.first.reminderMinutes, 630);
      }
      await planner.refreshReminders();
      expect(planner.notificationAccess, NotificationAccess.enabled);
      await tester.pumpWidget(UniPocketApp(planner: planner));
      await waitFor(tester, find.text('UniPocket'));
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('查看全部倒计时'));
      await waitFor(tester, find.text('期中考试'));
      await capture('09-android-events-$phase');
      await tapVisible(tester, find.text('期中考试'));
      await tapVisible(
        tester,
        find.byKey(const ValueKey('event-reminder-time')),
      );
      if (phase == 'create') {
        await tapVisible(tester, find.byIcon(Icons.keyboard_outlined));
        final dialog = find.byType(TimePickerDialog);
        final fields = find.descendant(
          of: dialog,
          matching: find.byType(TextField),
        );
        await tester.enterText(fields.at(0), '10');
        await tester.enterText(fields.at(1), '30');
      }
      await tapVisible(tester, find.text('确定'));
      expect(find.text('当天 10:30'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const ValueKey('event-reminder-enabled')),
      );
      await capture('09-android-editor-$phase');
      await tapVisible(tester, find.text('保存事件'));
      await waitFor(tester, find.textContaining('事件已保存到本机'));
      expect((await planner.load()).events.first.reminderMinutes, 630);
      await tapVisible(tester, find.byTooltip('返回'));
      if (phase == 'restore') {
        // Use the real campus clock for a near-future system delivery.
        state = await planner.load();
        final sendAt = state.campusTime(
          DateTime.now().toUtc().add(const Duration(minutes: 3)),
        );
        final event = state.events.first;
        await planner.saveEvent(
          CountdownEventDraft(
            title: '考试提醒已更新',
            targetDate: sendAt,
            reminderMinutes: sendAt.hour * 60 + sendAt.minute,
            isPinned: true,
          ),
          id: event.id,
        );
        final deleted = await planner.saveEvent(
          CountdownEventDraft(
            title: '已删除事件不应送达',
            targetDate: sendAt,
            reminderMinutes: sendAt.hour * 60 + sendAt.minute,
          ),
        );
        await planner.deleteEvent(deleted);
        final next = await planner.saveSemester(
          semesterDraft('下学期'),
          makeCurrent: true,
        );
        expect((await planner.load()).currentSemesterId, next);
        debugPrint(
          'EVENT_DELIVERY=${sendAt.toIso8601String()} EVENT_ID=${event.id}',
        );
      } else {
        // Capture and exercise the new plain-language task reminder shortcuts.
        await tapVisible(tester, find.text('查看全部任务'));
        await tapVisible(tester, find.byTooltip('创建任务'));
        await tester.enterText(
          find.byKey(const ValueKey('task-title')),
          '高数习题 第五章',
        );
        await tapVisible(tester, find.text('提前 1 小时'));
        expect(
          tester
              .widget<TextField>(
                find.byKey(const ValueKey('task-reminder-lead')),
              )
              .controller!
              .text,
          '60',
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('task-reminder-enabled')),
        );
        await capture('09-android-task-friendly');
        await tapVisible(tester, find.byTooltip('返回'));
        await tapVisible(tester, find.byTooltip('返回'));
      }
      await tapVisible(tester, find.text('设置'));
      await tester.ensureVisible(find.text('通知权限'));
      await capture('09-android-settings-$phase');
      expect(planner.reminderSyncFailed, isFalse);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await store.close();
    }
  });
}
