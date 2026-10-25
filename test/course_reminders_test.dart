import 'package:drift/native.dart';

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/timetable/model.dart';
import 'package:timezone/timezone.dart' as tz;

import 'support/recording_notifications.dart';
import 'support/semester_fixture.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('当前学期每次有效上课默认提前十分钟提醒，刷新不重复', () async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final notifications = RecordingNotifications();
    final planner = SemesterPlanner(
      store,
      notifications: notifications,
      clock: () => DateTime.utc(2026, 8, 30),
    );
    final semesterId = await planner.saveSemester(
      semesterDraft('秋季'),
      makeCurrent: true,
    );
    await planner.saveCourse(
      CourseDraft(
        semesterId: semesterId,
        name: '高等数学',
        schedules: [
          ScheduleDraft(
            weekday: 1,
            startPeriod: 1,
            endPeriod: 2,
            location: '教学楼 A101',
            weeks: {1, 2},
          ),
        ],
      ),
    );
    expect(notifications.pending.map((r) => r.at), [
      DateTime.utc(2026, 8, 30, 23, 50),
      DateTime.utc(2026, 9, 6, 23, 50),
    ]);
    expect(notifications.pending.first.body, contains('08:00'));
    expect(notifications.pending.first.body, contains('教学楼 A101'));
    expect(notifications.pending.first.body, '8月31日 08:00 上课，地点：教学楼 A101。');
    await planner.refreshReminders();
    expect(notifications.pending.map((r) => r.key).toSet(), hasLength(2));
  });

  test('schema 7 升级保留调停课、独立补课和 DDL 配置；课程获得默认提醒', () async {
    final store = PlannerStore(
      NativeDatabase.memory(
        setup: (db) {
          db.execute(File('test/fixtures/planner_v5.sql').readAsStringSync());
          db.execute('''
CREATE TABLE independent_lesson_records (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
  course_id INTEGER NOT NULL REFERENCES course_records(id) ON DELETE CASCADE,
  date TEXT NOT NULL, start_minutes INTEGER NOT NULL, end_minutes INTEGER NOT NULL, location TEXT NOT NULL);
INSERT INTO independent_lesson_records VALUES (1, 1, '2026-09-16T00:00:00.000Z', 600, 660, '独立补课');
ALTER TABLE learning_task_records ADD COLUMN reminder_minutes_before INTEGER NULL DEFAULT 1440;
UPDATE learning_task_records SET reminder_minutes_before = 30;
PRAGMA user_version = 7;
''');
        },
      ),
    );
    addTearDown(store.close);
    final notifications = RecordingNotifications();
    final planner = SemesterPlanner(
      store,
      notifications: notifications,
      clock: () => DateTime.utc(2026, 8, 30),
    );
    final state = await planner.load();
    expect(state.courses.single.reminderMinutesBefore, 10);
    expect(state.tasks.single.reminderMinutesBefore, 30);
    expect(state.tasks.single.isCompleted, isTrue);
    expect(state.classExceptions, hasLength(2));
    expect(state.independentLessons.single.location, '独立补课');
    await planner.refreshReminders();
    expect(notifications.scopes['course']!.map((r) => r.at).toSet(), {
      DateTime.utc(2026, 9, 15, 1, 50),
      DateTime.utc(2026, 9, 16, 0, 50),
      DateTime.utc(2026, 9, 27, 22, 50),
    });
  });

  test('手机本地时区改变不改变纽约校园夏令时结束日课程提醒', () async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final notifications = RecordingNotifications();
    final planner = SemesterPlanner(
      store,
      notifications: notifications,
      clock: () => DateTime.utc(2026, 10, 25),
    );
    final semester = await planner.saveSemester(
      semesterDraft('秋季'),
      makeCurrent: true,
    );
    await planner.setCampusTimeZone('America/New_York');
    await planner.saveCourse(
      CourseDraft(
        semesterId: semester,
        name: '夏令时结束日',
        schedules: [
          ScheduleDraft(
            weekday: 7,
            startPeriod: 3,
            endPeriod: 3,
            location: 'A101',
            weeks: {9},
          ),
        ],
      ),
    );
    expect(notifications.pending.single.at, DateTime.utc(2026, 11, 1, 14, 50));
    final previous = tz.local;
    addTearDown(() => tz.setLocalLocation(previous));
    tz.setLocalLocation(tz.getLocation('Pacific/Honolulu'));
    await planner.refreshReminders();
    expect(notifications.pending.single.at, DateTime.utc(2026, 11, 1, 14, 50));
  });

  test('修改或关闭课程提醒持久化；提醒时间已过明确反馈且不补发', () async {
    final directory = await Directory.systemTemp.createTemp(
      'course_reminders_',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/planner.sqlite');
    final notifications = RecordingNotifications();
    var now = DateTime.utc(2026, 8, 30);
    var store = PlannerStore(NativeDatabase(file));
    var planner = SemesterPlanner(
      store,
      notifications: notifications,
      clock: () => now,
    );
    final semester = await planner.saveSemester(
      semesterDraft('秋季'),
      makeCurrent: true,
    );
    final id = await planner.saveCourse(courseDraft(semester));
    await planner.updateCourseDetails(
      id,
      name: '数学分析',
      teacher: '李老师',
      colorIndex: 1,
      reminderMinutesBefore: 30,
    );
    expect(notifications.pending.first.at, DateTime.utc(2026, 8, 30, 23, 30));
    await store.close();
    store = PlannerStore(NativeDatabase(file));
    addTearDown(store.close);
    planner = SemesterPlanner(
      store,
      notifications: notifications,
      clock: () => now,
    );
    await planner.refreshReminders();
    var state = await planner.load();
    expect(state.courses.single.reminderMinutesBefore, 30);
    expect(notifications.pending.first.title, '数学分析');
    now = DateTime.utc(2026, 8, 30, 23, 30);
    await planner.refreshReminders();
    expect(notifications.pending, hasLength(1));
    expect(
      planner.courseReminderStatus(state.courses.single, state),
      contains('已过'),
    );
    await planner.updateCourseDetails(
      id,
      name: '数学分析',
      teacher: '李老师',
      colorIndex: 1,
      reminderMinutesBefore: null,
    );
    state = await planner.load();
    expect(state.courses.single.reminderMinutesBefore, isNull);
    expect(notifications.pending, isEmpty);
    expect(
      planner.courseReminderStatus(state.courses.single, state),
      contains('已关闭'),
    );
  });
}

CourseDraft courseDraft(int semester, {String name = '高等数学', int? lead = 10}) =>
    CourseDraft(
      semesterId: semester,
      name: name,
      reminderMinutesBefore: lead,
      schedules: [
        ScheduleDraft(
          weekday: 1,
          startPeriod: 1,
          endPeriod: 2,
          location: 'A101',
          weeks: {1, 2},
        ),
      ],
    );
