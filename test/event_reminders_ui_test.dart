import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/events/model.dart';
import 'package:unipocket/reminders/notifications.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

import 'support/recording_notifications.dart';
import 'support/widget_actions.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);
  for (final width in [320.0, 393.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$width 宽 $scale 倍文字，事件提醒可修改关闭且权限反馈同步', (tester) async {
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
            await planner.saveEvent(
              CountdownEventDraft(
                title: '跨学期的重要考试与准备事项',
                targetDate: DateTime(2026, 11, 6),
              ),
            );
            await tester.pumpWidget(
              UniPocketApp(
                planner: planner,
                clock: () => DateTime.utc(2026, 10, 25),
              ),
            );
            await waitFor(tester, find.text('UniPocket'));
            await tapVisible(tester, find.text('查看全部倒计时'));
            await tapVisible(tester, find.text('跨学期的重要考试与准备事项'));
            await tapVisible(
              tester,
              find.byKey(const ValueKey('event-reminder-time')),
            );
            await tapVisible(tester, find.text('确定'));
            notifications.access = NotificationAccess.enabled;
            await tapVisible(tester, find.text('刷新提醒状态'));
            await tester.drag(
              find.byType(Scrollable).first,
              const Offset(0, 10000),
            );
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              find.text('通知已开启，保存后将按此时间提醒你。'),
              200,
              scrollable: find.byType(Scrollable).first,
            );
            expect(find.text('通知已开启，保存后将按此时间提醒你。'), findsOneWidget);
            await tapVisible(
              tester,
              find.byKey(const ValueKey('event-reminder-enabled')),
            );
            await tapVisible(tester, find.text('保存事件'));
            await waitFor(tester, find.textContaining('事件已保存到本机'));
            expect(
              (await planner.load()).events.single.reminderMinutes,
              isNull,
            );
            expect(notifications.pending, isEmpty);
            expect(find.textContaining('事件已保存到本机'), findsOneWidget);
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
