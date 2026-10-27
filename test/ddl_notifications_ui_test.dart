import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

import 'support/recording_notifications.dart';
import 'support/widget_actions.dart';

import 'package:unipocket/reminders/notifications.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);
  for (final width in [320.0, 393.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$width 宽 $scale 倍文字，禁用通知仍能保存和修改单项提醒，设置入口可达', (tester) async {
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
          final notifications = RecordingNotifications()
            ..access = NotificationAccess.blocked;
          final planner = SemesterPlanner(
            store,
            notifications: notifications,
            clock: () => DateTime.utc(2026, 10, 25),
          );
          try {
            await tester.pumpWidget(
              UniPocketApp(
                planner: planner,
                clock: () => DateTime.utc(2026, 10, 25),
              ),
            );
            await waitFor(tester, find.textContaining('校园时间'));
            await tapVisible(tester, find.text('查看全部任务'));
            await tapVisible(tester, find.byTooltip('创建任务'));
            await tester.enterText(
              find.byKey(const ValueKey('task-title')),
              '通知关闭也要保留的很长学习任务标题',
            );
            await tapVisible(
              tester,
              find.byKey(const ValueKey('task-reminder-lead')),
            );
            await tester.enterText(
              find.byKey(const ValueKey('task-reminder-lead')),
              '30',
            );
            await tapVisible(tester, find.text('保存任务'));
            await waitFor(tester, find.textContaining('任务已保存到本机'));
            expect(
              (await planner.load()).tasks.single.reminderMinutesBefore,
              30,
            );
            expect(notifications.pending, isEmpty);
            await tapVisible(tester, find.text('通知关闭也要保留的很长学习任务标题'));
            await tapVisible(
              tester,
              find.byKey(const ValueKey('task-reminder-enabled')),
            );
            await tapVisible(tester, find.text('保存任务'));
            await waitFor(tester, find.text('每一个小目标，\n都值得完成'));
            expect(
              (await planner.load()).tasks.single.reminderMinutesBefore,
              isNull,
            );
            await tapVisible(tester, find.byTooltip('返回'));
            await waitFor(
              tester,
              find.byKey(const ValueKey('main-navigation')),
            );
            await tapVisible(tester, find.text('设置'));
            await tapVisible(tester, find.text('系统通知设置'));
            await waitFor(tester, find.text('设备通知已关闭'));
            expect(notifications.settingsOpened, isTrue);
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await store.close();
          }
        });
      });
    }
  }
}
