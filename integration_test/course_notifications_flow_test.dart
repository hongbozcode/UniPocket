import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/reminders/android_notifications.dart';
import 'package:unipocket/reminders/course_reminders.dart';
import 'package:unipocket/semesters/model.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/tasks/model.dart';
import 'package:unipocket/timetable/model.dart';

import '../test/support/widget_actions.dart';

const databaseName = String.fromEnvironment(
  'ACCEPTANCE_DATABASE',
  defaultValue: 'unipocket_course_acceptance',
);
const phase = String.fromEnvironment(
  'ACCEPTANCE_PHASE',
  defaultValue: 'create',
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  testWidgets('Android 课程提醒配置、变更撤销、进程恢复与实际调度', (tester) async {
    const notifications = AndroidNotifications(namespace: databaseName);
    if (phase == 'cleanup') {
      const extra = String.fromEnvironment('ACCEPTANCE_EXTRA_CLEANUP');
      for (final namespace in [
        databaseName,
        if (extra.isNotEmpty && extra != databaseName) extra,
      ]) {
        final boundary = AndroidNotifications(namespace: namespace);
        await boundary.replace('course', []);
        await boundary.replace('ddl', []);
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
        expect(state.courses, isEmpty, reason: '每轮创建使用新的专用数据库');
        final semester = await planner.saveSemester(
          SemesterDraft(
            name: '课程提醒验收学期',
            firstMonday: today.subtract(Duration(days: today.weekday - 1)),
            totalWeeks: 3,
            periods: {
              for (var day = 1; day <= 7; day++)
                day: [const PeriodTime(480, 525)],
            },
          ),
          makeCurrent: true,
        );
        await planner.saveCourse(
          CourseDraft(
            semesterId: semester,
            name: '高等数学',
            schedules: [
              ScheduleDraft(
                weekday: today.weekday,
                startPeriod: 1,
                endPeriod: 1,
                location: '教学楼 A101',
                weeks: {1, 2, 3},
              ),
            ],
          ),
        );
        await planner.saveTask(
          LearningTaskDraft(
            title: '跨学期保留的实验报告',
            dueDate: today.add(const Duration(days: 7)),
          ),
        );
      }
      state = await planner.load();
      final course = state.courses.single;
      if (phase != 'create') {
        expect(course.reminderMinutesBefore, phase == 'restore' ? 30 : 0);
      }
      if (phase == 'switch') {
        // Re-enable a future lesson so this phase actually exercises cancellation.
        final schedule = course.schedules.single as ClassSchedule;
        final semester = state.semesters.singleWhere(
          (s) => s.id == course.semesterId,
        );
        final original = semester.firstMonday.add(
          Duration(days: schedule.weekday - 1 + 14),
        );
        await planner.saveClassException(
          ClassExceptionDraft(
            scheduleId: schedule.id,
            originalDate: original,
            targetDate: original,
            startMinutes: 480,
            endMinutes: 525,
            location: '切换前待撤销',
          ),
        );
        expect(
          futureCourseReminders(await planner.load(), DateTime.now()),
          hasLength(1),
        );
        final other = await planner.saveSemester(
          SemesterDraft(
            name: '无课程的新学期',
            firstMonday: today.subtract(Duration(days: today.weekday - 1)),
            totalWeeks: 3,
            periods: {
              1: [const PeriodTime(480, 525)],
            },
          ),
          makeCurrent: true,
        );
        expect((await planner.load()).currentSemesterId, other);
      }
      if (phase == 'delivery') {
        await planner.setCurrentSemester(course.semesterId);
      }
      if (phase == 'restore' || phase == 'delivery') {
        await planner.updateCourseDetails(
          course.id,
          name: course.name,
          teacher: course.teacher,
          colorIndex: course.colorIndex,
          reminderMinutesBefore: 0,
        );
        final schedule = course.schedules.single as ClassSchedule;
        final target = now.add(Duration(minutes: phase == 'delivery' ? 2 : 4));
        final start = target.hour * 60 + target.minute;
        if (start > 1400) throw StateError('送达验收请避开校园午夜前半小时');
        final semester = state.semesters.singleWhere(
          (s) => s.id == course.semesterId,
        );
        final original = semester.firstMonday.add(
          Duration(days: schedule.weekday - 1 + 7),
        );
        await planner.saveClassException(
          ClassExceptionDraft(
            scheduleId: schedule.id,
            originalDate: original,
            targetDate: today,
            startMinutes: start,
            endMinutes: start + 30,
            location: '调课后 B202',
          ),
        );
        await planner.saveClassException(
          ClassExceptionDraft(
            scheduleId: schedule.id,
            originalDate: original.add(const Duration(days: 7)),
            targetDate: original.add(const Duration(days: 7)),
            startMinutes: 480,
            endMinutes: 525,
            location: '教学楼 A101',
            isCancelled: true,
          ),
        );
        final reminders = futureCourseReminders(
          await planner.load(),
          DateTime.now(),
        );
        expect(reminders, hasLength(1));
        debugPrint(
          'COURSE_DELIVERY_AT=${reminders.single.at.toIso8601String()}',
        );
        debugPrint('COURSE_DELIVERY_KEY=${reminders.single.key}');
      }
      await tester.pumpWidget(UniPocketApp(planner: planner));
      await waitFor(tester, find.textContaining('校园时间'));
      await binding.convertFlutterSurfaceToImage();
      if (phase == 'create' || phase == 'restore') {
        await tapVisible(tester, find.text('课表'));
        await tapVisible(tester, find.text('高等数学').first);
        await tester.ensureVisible(
          find.byKey(const ValueKey('course-reminder-lead')),
        );
        await tester.pumpAndSettle();
        if (phase == 'create') {
          await tester.enterText(
            find.byKey(const ValueKey('course-reminder-lead')),
            '30',
          );
          await tester.pumpAndSettle();
        }
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextField>(
                find.byKey(const ValueKey('course-reminder-lead')),
              )
              .controller!
              .text,
          phase == 'create' ? '30' : '0',
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('course-reminder-enabled')),
        );
        await capture(
          phase == 'create'
              ? '08-android-course-editor'
              : '08-android-course-restored',
        );
        if (phase == 'create') {
          await tapVisible(tester, find.byKey(const ValueKey('save-course')));
          await waitFor(tester, find.textContaining('课程已保存到本机'));
          expect(
            (await planner.load()).courses.single.reminderMinutesBefore,
            30,
          );
        } else {
          await tapVisible(tester, find.byTooltip('返回'));
        }
      }
      await tapVisible(tester, find.text('设置'));
      await tester.ensureVisible(find.text('通知权限'));
      await capture('08-android-settings-$phase');
      expect(planner.reminderSyncFailed, isFalse);
      debugPrint(
        'COURSE_PHASE=$phase CURRENT=${(await planner.load()).currentSemesterId}',
      );
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await store.close();
    }
  });
}
