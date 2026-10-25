import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/semesters/model.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/timetable/model.dart';
import 'package:unipocket/timetable/course_change.dart';
import 'package:unipocket/tasks/model.dart';
import 'package:unipocket/reminders/notifications.dart';

import 'course_reminders_test.dart' show courseDraft;
import 'support/recording_notifications.dart';
import 'support/semester_fixture.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);
  late PlannerStore store;
  late SemesterPlanner planner;
  late RecordingNotifications notifications;
  late int semester;
  late int course;
  setUp(() async {
    store = PlannerStore(NativeDatabase.memory());
    notifications = RecordingNotifications();
    planner = SemesterPlanner(
      store,
      notifications: notifications,
      clock: () => DateTime.utc(2026, 8, 30),
    );
    semester = await planner.saveSemester(
      semesterDraft('秋季'),
      makeCurrent: true,
    );
    course = await planner.saveCourse(courseDraft(semester));
  });
  tearDown(() => store.close());

  test('跨周调课保留同日原课次，停课撤销，失去关联后独立补课可修改与取消', () async {
    var state = await planner.load();
    final schedule = state.courses.single.schedules.single as ClassSchedule;
    final originalKey = notifications.scopes['course']!.first.key;
    await planner.saveClassException(
      ClassExceptionDraft(
        scheduleId: schedule.id,
        originalDate: DateTime.utc(2026, 8, 31),
        targetDate: DateTime.utc(2026, 9, 7),
        startMinutes: 600,
        endMinutes: 660,
        location: '跨周补课 B202',
      ),
    );
    expect(notifications.scopes['course'], hasLength(2));
    expect(
      notifications.pending.singleWhere((r) => r.key == originalKey).at,
      DateTime.utc(2026, 9, 7, 1, 50),
    );
    expect(notifications.pending.map((r) => r.at), [
      DateTime.utc(2026, 9, 6, 23, 50),
      DateTime.utc(2026, 9, 7, 1, 50),
    ]);
    await planner.saveClassException(
      ClassExceptionDraft(
        scheduleId: schedule.id,
        originalDate: DateTime.utc(2026, 9, 7),
        targetDate: DateTime.utc(2026, 9, 7),
        startMinutes: 480,
        endMinutes: 580,
        location: 'A101',
        isCancelled: true,
      ),
    );
    expect(notifications.pending.single.key, originalKey);
    final preview = await planner.previewCourseChange(
      course,
      CourseDraft(
        semesterId: semester,
        name: '数学分析',
        reminderMinutesBefore: 30,
        schedules: [
          ClassSchedule(
            id: schedule.id,
            weekday: 2,
            startPeriod: 1,
            endPeriod: 1,
            location: '新教室',
            weeks: {3},
          ),
        ],
      ),
    );
    await planner.applyCourseChange(
      preview,
      choices: {
        for (final e in preview.orphaned)
          e.key: e.isCancelled
              ? OrphanChoice.delete
              : OrphanChoice.keepIndependent,
      },
    );
    expect(notifications.pending.any((r) => r.key == originalKey), isFalse);
    expect(notifications.pending.map((r) => r.at).toSet(), {
      DateTime.utc(2026, 9, 7, 1, 30),
      DateTime.utc(2026, 9, 14, 23, 30),
    });
    state = await planner.load();
    final independent = state.independentLessons.single;
    await planner.saveIndependentLesson(
      IndependentLesson(
        id: independent.id,
        courseId: course,
        date: DateTime.utc(2027, 2, 1),
        startMinutes: 720,
        endMinutes: 780,
        location: '学期外补课',
      ),
    );
    expect(
      notifications.pending
          .singleWhere((r) => r.key.startsWith('independent:'))
          .at,
      DateTime.utc(2027, 2, 1, 3, 30),
    );
    await planner.deleteIndependentLesson(independent.id);
    expect(notifications.pending, hasLength(1));
    await planner.deleteCourse(await planner.previewCourseDeletion(course));
    expect(notifications.pending, isEmpty);
  });

  test('切换或保存当前学期清除旧课程提醒，独立与关联 DDL 不丢失，改节次和校园时区重算', () async {
    await planner.saveTask(
      LearningTaskDraft(title: '独立任务', dueDate: DateTime.utc(2026, 10, 1)),
    );
    await planner.saveTask(
      LearningTaskDraft(
        title: '课程作业',
        courseId: course,
        dueDate: DateTime.utc(2026, 10, 2),
      ),
    );
    final ddl = notifications.scopes['ddl']!.map((r) => (r.key, r.at)).toList();
    final spring = await planner.saveSemester(
      semesterDraft('春季'),
      makeCurrent: true,
    );
    expect(notifications.scopes['course'], isEmpty);
    await planner.saveCourse(courseDraft(spring, name: '大学物理'));
    expect(
      notifications.scopes['course']!.every((r) => r.title == '大学物理'),
      isTrue,
    );
    await planner.setCurrentSemester(semester);
    expect(
      notifications.scopes['course']!.every((r) => r.title == '高等数学'),
      isTrue,
    );
    expect(notifications.scopes['ddl']!.map((r) => (r.key, r.at)), ddl);
    final draft = semesterDraft('改作息');
    await planner.saveSemester(
      SemesterDraft(
        name: draft.name,
        firstMonday: draft.firstMonday,
        totalWeeks: draft.totalWeeks,
        periods: {
          for (var day = 1; day <= 7; day++)
            day: [
              const PeriodTime(600, 645),
              const PeriodTime(660, 705),
              const PeriodTime(720, 765),
            ],
        },
      ),
      id: semester,
    );
    expect(
      notifications.scopes['course']!.first.at,
      DateTime.utc(2026, 8, 31, 1, 50),
    );
    await planner.setCampusTimeZone('Asia/Tokyo');
    expect(
      notifications.scopes['course']!.first.at,
      DateTime.utc(2026, 8, 31, 0, 50),
    );
    await planner.deleteCourse(await planner.previewCourseDeletion(course));
    expect(notifications.scopes['course'], isEmpty);
    expect(notifications.scopes['ddl'], hasLength(2));
    expect(
      (await planner.load()).tasks.every((t) => t.courseId == null),
      isTrue,
    );
  });

  test('通知禁用或更新失败仍保存课程；重试仅重建真实有效提醒，非法配置不改变数据', () async {
    notifications.access = NotificationAccess.blocked;
    await planner.updateCourseDetails(
      course,
      name: '仍然保存',
      teacher: '',
      colorIndex: 0,
      reminderMinutesBefore: 0,
    );
    expect(notifications.scopes['course'], isEmpty);
    var state = await planner.load();
    expect(
      planner.courseReminderStatus(state.courses.single, state),
      contains('设备通知已关闭'),
    );
    notifications.access = NotificationAccess.enabled;
    notifications.fail = true;
    await planner.updateCourseDetails(
      course,
      name: '系统失败仍保存',
      teacher: '',
      colorIndex: 0,
      reminderMinutesBefore: 5,
    );
    expect((await planner.load()).courses.single.name, '系统失败仍保存');
    expect(planner.reminderSyncFailed, isTrue);
    notifications.fail = false;
    await planner.refreshReminders();
    expect(
      notifications.scopes['course']!.first.at,
      DateTime.utc(2026, 8, 30, 23, 55),
    );
    for (final invalid in [-1, 525601]) {
      await expectLater(
        planner.updateCourseDetails(
          course,
          name: '无效',
          teacher: '',
          colorIndex: 0,
          reminderMinutesBefore: invalid,
        ),
        throwsA(isA<InputProblem>()),
      );
    }
    state = await planner.load();
    expect(state.courses.single.reminderMinutesBefore, 5);
    expect(notifications.scopes['course'], hasLength(2));
  });

  test('DDL 更新失败仍尝试撤销课程提醒，关闭时的系统失败如实反馈', () async {
    notifications.failScope = 'ddl';
    await planner.updateCourseDetails(
      course,
      name: '高等数学',
      teacher: '',
      colorIndex: 0,
      reminderMinutesBefore: null,
    );
    expect(notifications.scopes['course'], isEmpty);
    final state = await planner.load();
    expect(state.courses.single.reminderMinutesBefore, isNull);
    expect(
      planner.courseReminderStatus(state.courses.single, state),
      contains('失败'),
    );
  });
}
