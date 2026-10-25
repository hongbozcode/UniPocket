import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/tasks/model.dart';
import 'package:unipocket/semesters/model.dart';
import 'package:unipocket/timetable/model.dart';

import 'support/semester_fixture.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('截止精确边界、校园午夜和夏令时按校园日期时间判断，切换学期保留任务', () async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    final autumn = await planner.saveSemester(semesterDraft('秋季'));
    await planner.saveTask(
      LearningTaskDraft(title: '午夜作业', dueDate: DateTime(2026, 10, 25)),
    );
    var state = await planner.load();
    expect(
      state.tasks.single.groupAt(
        state.campusTime(DateTime.utc(2026, 10, 25, 15, 59)),
      ),
      TaskGroup.today,
    );
    expect(
      state.tasks.single.groupAt(
        state.campusTime(DateTime.utc(2026, 10, 25, 15, 59, 0, 1)),
      ),
      TaskGroup.overdue,
    );
    expect(
      state.tasks.single.groupAt(
        state.campusTime(DateTime.utc(2026, 10, 25, 16)),
      ),
      TaskGroup.overdue,
    );
    expect(state.tasks.single.isCompleted, isFalse);
    final spring = await planner.saveSemester(semesterDraft('春季'));
    await planner.setCurrentSemester(spring);
    expect((await planner.load()).tasks.single.title, '午夜作业');
    await planner.setCurrentSemester(autumn);
    await planner.setCampusTimeZone('America/New_York');
    await planner.saveTask(
      LearningTaskDraft(
        title: '夏令时结束日',
        dueDate: DateTime(2026, 11, 1),
        dueMinutes: 600,
      ),
    );
    state = await planner.load();
    final task = state.tasks.last;
    expect(
      task.groupAt(state.campusTime(DateTime.utc(2026, 11, 1, 15))),
      TaskGroup.today,
    );
    expect(
      task.groupAt(state.campusTime(DateTime.utc(2026, 11, 1, 15, 0, 1))),
      TaskGroup.overdue,
    );
    await planner.setTaskCompleted(task.id, true);
    expect(
      (await planner.load()).tasks.last.groupAt(
        state.campusTime(DateTime.utc(2026, 11, 2)),
      ),
      TaskGroup.completed,
    );
  });

  test('任务 2 数据库升级保留课表和设置，升级后任务可关联原课程', () async {
    final store = PlannerStore(
      NativeDatabase.memory(
        setup: (database) {
          database.execute(
            File('test/fixtures/planner_v1.sql').readAsStringSync(),
          );
          database.execute('''
        CREATE TABLE course_records (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          semester_id INTEGER NOT NULL REFERENCES semester_records(id), name TEXT NOT NULL,
          teacher TEXT NOT NULL, color_index INTEGER NOT NULL);
        CREATE TABLE schedule_records (id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
          course_id INTEGER NOT NULL REFERENCES course_records(id), weekday INTEGER NOT NULL,
          start_period INTEGER NOT NULL, end_period INTEGER NOT NULL, location TEXT NOT NULL, weeks TEXT NOT NULL);
        INSERT INTO course_records VALUES (1, 1, '升级前数学', '李老师', 2);
        INSERT INTO schedule_records VALUES (1, 1, 1, 1, 1, 'A201', '[1,3,5]');
        PRAGMA user_version = 2;
      ''');
        },
      ),
    );
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    final state = await planner.load();
    expect(state.currentSemester!.name, '升级前的秋季');
    expect(state.campusTimeZone, 'Asia/Tokyo');
    expect(state.courses.single.schedules.single.weeks, {1, 3, 5});
    expect(state.courses.single.teacher, '李老师');
    expect(state.today(DateTime.utc(2026, 8, 31)).single.location, 'A201');
    await planner.saveTask(
      LearningTaskDraft(
        title: '升级后作业',
        dueDate: DateTime(2026, 10, 25),
        courseId: 1,
      ),
    );
    expect((await planner.load()).tasks.single.courseId, 1);
  });

  test('课程关联、编辑、完成撤销与删除均经应用入口持久化，非法修改不写入', () async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    final semester = await planner.saveSemester(semesterDraft('秋季'));
    final course = await planner.saveCourse(
      CourseDraft(
        semesterId: semester,
        name: '高等数学',
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
    final id = await planner.saveTask(
      LearningTaskDraft(
        title: '习题',
        dueDate: DateTime(2026, 10, 25),
        courseId: course,
        notes: '第五章',
      ),
    );
    await planner.setTaskCompleted(id, true);
    await planner.saveTask(
      LearningTaskDraft(
        title: '订正习题',
        dueDate: DateTime(2026, 10, 26),
        dueMinutes: 600,
        courseId: course,
        notes: '补充证明',
      ),
      id: id,
    );
    var task = (await planner.load()).tasks.single;
    expect(task.isCompleted, isTrue);
    expect(task.courseId, course);
    expect(task.notes, '补充证明');
    expect(task.title, '订正习题');
    expect(task.dueMinutes, 600);
    await planner.setTaskCompleted(id, false);
    for (final draft in [
      LearningTaskDraft(title: ' ', dueDate: DateTime(2026)),
      LearningTaskDraft(title: '错误', dueDate: DateTime(2026), dueMinutes: 1440),
      LearningTaskDraft(
        title: '错误',
        dueDate: DateTime(2026),
        courseId: course + 99,
      ),
    ]) {
      await expectLater(
        planner.saveTask(draft, id: id),
        throwsA(isA<InputProblem>()),
      );
    }
    task = (await planner.load()).tasks.single;
    expect(task.isCompleted, isFalse);
    expect(task.title, '订正习题');
    await planner.saveTask(
      LearningTaskDraft(title: task.title, dueDate: task.dueDate),
      id: id,
    );
    expect((await planner.load()).tasks.single.courseId, isNull);
    await planner.deleteTask(id);
    expect((await planner.load()).tasks, isEmpty);
    await expectLater(
      planner.setTaskCompleted(id, true),
      throwsA(isA<InputProblem>()),
    );
  });

  test('独立学习任务仅选日期默认 23:59，关闭文件数据库后仍可读取', () async {
    final directory = await Directory.systemTemp.createTemp('unipocket_tasks_');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/planner.sqlite');
    var store = PlannerStore(NativeDatabase(file));
    var planner = SemesterPlanner(store);
    final id = await planner.saveTask(
      LearningTaskDraft(title: '  英语阅读笔记  ', dueDate: DateTime(2026, 10, 25)),
    );
    await store.close();
    store = PlannerStore(NativeDatabase(file));
    addTearDown(store.close);
    planner = SemesterPlanner(store);
    final task = (await planner.load()).tasks.single;
    expect(task.id, id);
    expect(task.title, '英语阅读笔记');
    expect(task.dueDate, DateTime.utc(2026, 10, 25));
    expect(task.dueMinutes, 1439);
    expect(task.courseId, isNull);
    expect(task.isCompleted, isFalse);
  });
}
