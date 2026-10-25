import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/timetable/model.dart';
import 'package:unipocket/reminders/notifications.dart';

import 'support/recording_notifications.dart';
import 'support/semester_fixture.dart';
import 'support/widget_actions.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);
  testWidgets('同页刷新通知权限或失败后，课程提醒预览随真实状态更新', (tester) async {
    await tester.runAsync(() async {
      final store = PlannerStore(NativeDatabase.memory());
      final notifications = RecordingNotifications()
        ..access = NotificationAccess.blocked;
      final now = DateTime.utc(2026, 8, 30);
      final planner = SemesterPlanner(
        store,
        notifications: notifications,
        clock: () => now,
      );
      try {
        final semester = await planner.saveSemester(
          semesterDraft('秋季'),
          makeCurrent: true,
        );
        await planner.saveCourse(
          CourseDraft(
            semesterId: semester,
            name: '高等数学',
            schedules: [
              ScheduleDraft(
                weekday: 1,
                startPeriod: 1,
                endPeriod: 1,
                location: 'A101',
                weeks: {1, 2},
              ),
            ],
          ),
        );
        await tester.pumpWidget(
          UniPocketApp(planner: planner, clock: () => now),
        );
        await waitFor(tester, find.textContaining('校园时间'));
        await tapVisible(tester, find.text('课表'));
        await tapVisible(tester, find.text('高等数学'));
        await waitFor(tester, find.textContaining('保存后：'));
        String preview() =>
            tester.widget<Text>(find.textContaining('保存后：')).data!;
        expect(preview(), contains('设备通知已关闭'));
        notifications.access = NotificationAccess.enabled;
        await tapVisible(tester, find.text('刷新提醒状态'));
        await waitFor(tester, find.text('通知已开启'));
        expect(preview(), contains('未来提醒已安排'));
        notifications.fail = true;
        await tapVisible(tester, find.text('刷新提醒状态'));
        await waitFor(tester, find.text('通知状态暂不可用'));
        expect(preview(), contains('失败'));
        notifications.fail = false;
        await tapVisible(tester, find.text('刷新提醒状态'));
        await waitFor(tester, find.text('通知已开启'));
        expect(preview(), contains('未来提醒已安排'));
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
      }
    });
  });
  for (final width in [320.0, 393.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$width 宽 $scale 倍文字，课程提醒可调整或关闭，过期反馈与保存可达', (tester) async {
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
          final notifications = RecordingNotifications();
          final now = DateTime.utc(2026, 8, 31, 0, 1);
          final planner = SemesterPlanner(
            store,
            notifications: notifications,
            clock: () => now,
          );
          try {
            final semester = await planner.saveSemester(
              semesterDraft('秋季'),
              makeCurrent: true,
            );
            await planner.saveCourse(
              CourseDraft(
                semesterId: semester,
                name: '高等数学与空间解析几何的长课程名称',
                schedules: [
                  ScheduleDraft(
                    weekday: 1,
                    startPeriod: 1,
                    endPeriod: 2,
                    location: '很长的教学楼名称 A101',
                    weeks: {1, 2},
                  ),
                ],
              ),
            );
            await tester.pumpWidget(
              UniPocketApp(planner: planner, clock: () => now),
            );
            await waitFor(tester, find.text('高等数学与空间解析几何的长课程名称'));
            await tapVisible(tester, find.text('高等数学与空间解析几何的长课程名称'));
            await tapVisible(
              tester,
              find.byKey(const ValueKey('course-reminder-lead')),
            );
            await tester.enterText(
              find.byKey(const ValueKey('course-reminder-lead')),
              '30',
            );
            FocusManager.instance.primaryFocus?.unfocus();
            await tester.pumpAndSettle();
            expect(find.textContaining('已过，不会补发'), findsOneWidget);
            await tapVisible(tester, find.byKey(const ValueKey('save-course')));
            await waitFor(tester, find.textContaining('课程已保存到本机'));
            expect(
              (await planner.load()).courses.single.reminderMinutesBefore,
              30,
            );
            await tapVisible(tester, find.text('高等数学与空间解析几何的长课程名称'));
            await tapVisible(
              tester,
              find.byKey(const ValueKey('course-reminder-enabled')),
            );
            await tapVisible(tester, find.byKey(const ValueKey('save-course')));
            await waitFor(tester, find.textContaining('课程已保存到本机'));
            expect(
              (await planner.load()).courses.single.reminderMinutesBefore,
              isNull,
            );
            expect(notifications.pending, isEmpty);
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
