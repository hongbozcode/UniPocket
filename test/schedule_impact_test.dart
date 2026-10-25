import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/semesters/model.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/timetable/model.dart';
import 'package:unipocket/timetable/course_change.dart';
import 'package:unipocket/tasks/model.dart';

import 'support/semester_fixture.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('重复安排预览不写入，保留有效例外并逐项处理失联例外，文件重开后补课独立存在', () async {
    final directory = await Directory.systemTemp.createTemp('schedule_impact_');
    final file = File('${directory.path}/planner.sqlite');
    var store = PlannerStore(NativeDatabase(file));
    var planner = SemesterPlanner(store);
    addTearDown(() async {
      await store.close();
      await directory.delete(recursive: true);
    });
    final semester = await planner.saveSemester(semesterDraft('秋季'));
    final id = await planner.saveCourse(
      CourseDraft(
        semesterId: semester,
        name: '数学',
        schedules: [
          ScheduleDraft(
            weekday: 1,
            startPeriod: 1,
            endPeriod: 2,
            location: 'A201',
            weeks: {1, 2, 3},
          ),
        ],
      ),
    );
    final course = (await planner.load()).courses.single;
    final schedule = course.schedules.single as ClassSchedule;
    for (final day in [31, 7, 14]) {
      await planner.saveClassException(
        ClassExceptionDraft(
          scheduleId: schedule.id,
          originalDate: day == 31
              ? DateTime.utc(2026, 8, 31)
              : DateTime.utc(2026, 9, day),
          targetDate: DateTime.utc(2026, 9, day == 31 ? 1 : day + 1),
          startMinutes: 660,
          endMinutes: 720,
          location: '补课教室',
          isCancelled: day == 14,
        ),
      );
    }
    final impact = await planner.previewCourseChange(
      id,
      CourseDraft(
        semesterId: semester,
        name: '数学',
        schedules: [
          ClassSchedule(
            id: schedule.id,
            weekday: 1,
            startPeriod: 2,
            endPeriod: 2,
            location: '新教室',
            weeks: {1},
          ),
        ],
      ),
    );
    expect(impact.retained.length, 1);
    expect(impact.orphaned.length, 2);
    expect((await planner.load()).classExceptions.length, 3);
    expect((await planner.load()).courses.single.schedules.single.weeks, {
      1,
      2,
      3,
    });
    await expectLater(
      planner.applyCourseChange(impact, choices: {}),
      throwsA(isA<InputProblem>()),
    );
    expect((await planner.load()).classExceptions.length, 3);
    await planner.applyCourseChange(
      impact,
      choices: {
        impact.orphaned[0].key: OrphanChoice.keepIndependent,
        impact.orphaned[1].key: OrphanChoice.delete,
      },
    );
    await store.close();
    store = PlannerStore(NativeDatabase(file));
    planner = SemesterPlanner(store);
    final state = await planner.load();
    expect(
      state.classExceptions.single.originalDate,
      DateTime.utc(2026, 8, 31),
    );
    expect(
      (state.courses.single.schedules.single as ClassSchedule).id,
      schedule.id,
    );
    expect(state.today(DateTime.utc(2026, 9, 1)).single.location, '补课教室');
    final makeup = state.today(DateTime.utc(2026, 9, 8)).single;
    expect(makeup.isIndependent, isTrue);
    expect(makeup.startMinutes, 660);
    expect(state.today(DateTime.utc(2026, 9, 7)), isEmpty);
    expect(state.today(DateTime.utc(2026, 9, 15)), isEmpty);
  });

  test('删除和新增安排仍保留其他安排身份，停课可明确转独立补课，后续重复变更不移动补课', () async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    final semester = await planner.saveSemester(semesterDraft('秋季'));
    final id = await planner.saveCourse(
      CourseDraft(
        semesterId: semester,
        name: '数学',
        schedules: [
          _schedule(1, {1, 2}),
          _schedule(3, {1, 2}),
        ],
      ),
    );
    final schedules = (await planner.load()).courses.single.schedules
        .cast<ClassSchedule>()
        .toList();
    await planner.saveClassException(
      ClassExceptionDraft(
        scheduleId: schedules.first.id,
        originalDate: DateTime.utc(2026, 8, 31),
        targetDate: DateTime.utc(2026, 8, 31),
        startMinutes: 660,
        endMinutes: 720,
        location: '停课后补回',
        isCancelled: true,
      ),
    );
    await planner.saveClassException(
      ClassExceptionDraft(
        scheduleId: schedules.last.id,
        originalDate: DateTime.utc(2026, 9, 2),
        targetDate: DateTime.utc(2026, 9, 2),
        startMinutes: 480,
        endMinutes: 580,
        location: 'A201',
        isCancelled: true,
      ),
    );
    final impact = await planner.previewCourseChange(
      id,
      CourseDraft(
        semesterId: semester,
        name: '数学',
        schedules: [
          schedules.last,
          _schedule(5, {1, 2}),
        ],
      ),
    );
    expect(impact.retained.single.scheduleId, schedules.last.id);
    await planner.applyCourseChange(
      impact,
      choices: {impact.orphaned.single.key: OrphanChoice.keepIndependent},
    );
    var state = await planner.load();
    expect(state.today(DateTime.utc(2026, 8, 31)).single.isIndependent, isTrue);
    expect(state.today(DateTime.utc(2026, 9, 2)), isEmpty);
    expect(state.today(DateTime.utc(2026, 9, 4)).single.course.id, id);
    expect(
      (state.courses.single.schedules.first as ClassSchedule).id,
      schedules.last.id,
    );
    final next = await planner.previewCourseChange(
      id,
      CourseDraft(
        semesterId: semester,
        name: '数学改名',
        schedules: [
          _schedule(2, {1}),
        ],
      ),
    );
    await planner.applyCourseChange(
      next,
      choices: {next.orphaned.single.key: OrphanChoice.delete},
    );
    state = await planner.load();
    expect(state.today(DateTime.utc(2026, 8, 31)).single.location, '停课后补回');
    expect(state.today(DateTime.utc(2026, 8, 31)).single.course.name, '数学改名');
    expect(state.classExceptions, isEmpty);
  });

  test('最终有效课次检查补课冲突；拒绝确认无写入，确认可保留，独立补课能编辑和删除', () async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    final semester = await planner.saveSemester(semesterDraft('秋季'));
    final id = await planner.saveCourse(
      CourseDraft(
        semesterId: semester,
        name: '数学',
        schedules: [
          _schedule(1, {1, 2}),
        ],
      ),
    );
    final original =
        (await planner.load()).courses.single.schedules.single as ClassSchedule;
    await planner.saveClassException(
      ClassExceptionDraft(
        scheduleId: original.id,
        originalDate: DateTime.utc(2026, 8, 31),
        targetDate: DateTime.utc(2026, 9, 1),
        startMinutes: 480,
        endMinutes: 580,
        location: '补课',
      ),
    );
    final impact = await planner.previewCourseChange(
      id,
      CourseDraft(
        semesterId: semester,
        name: '数学',
        schedules: [
          _schedule(2, {1, 2}),
        ],
      ),
    );
    final choices = {impact.orphaned.single.key: OrphanChoice.keepIndependent};
    await expectLater(
      planner.applyCourseChange(impact, choices: choices),
      throwsA(isA<CourseConflict>()),
    );
    expect((await planner.load()).independentLessons, isEmpty);
    expect((await planner.load()).classExceptions.length, 1);
    await planner.applyCourseChange(
      impact,
      choices: choices,
      allowConflicts: true,
    );
    var state = await planner.load();
    expect(state.today(DateTime.utc(2026, 9, 1)).length, 2);
    final makeup = state.independentLessons.single;
    IndependentLesson moved(int start, {int day = 1}) => IndependentLesson(
      id: makeup.id,
      courseId: id,
      date: DateTime.utc(2026, 9, day),
      startMinutes: start,
      endMinutes: start + 45,
      location: '修改后的独立教室',
    );
    await expectLater(
      planner.saveIndependentLesson(moved(500)),
      throwsA(isA<CourseConflict>()),
    );
    expect((await planner.load()).independentLessons.single.location, '补课');
    await planner.saveIndependentLesson(moved(660, day: 13));
    state = await planner.load();
    expect(state.today(DateTime.utc(2026, 9, 13)).single.isIndependent, isTrue);
    expect(state.today(DateTime.utc(2026, 9, 13)).single.location, '修改后的独立教室');
    await planner.deleteIndependentLesson(makeup.id);
    expect((await planner.load()).today(DateTime.utc(2026, 9, 13)), isEmpty);
    expect((await planner.load()).today(DateTime.utc(2026, 9, 1)).length, 1);
  });

  test('预览后新增例外或关联任务会要求重新确认，不覆盖新数据，安排身份不能串到其他课程', () async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    final semester = await planner.saveSemester(semesterDraft('秋季'));
    final id = await planner.saveCourse(
      CourseDraft(
        semesterId: semester,
        name: '数学',
        schedules: [
          _schedule(1, {1, 2}),
        ],
      ),
    );
    final other = await planner.saveCourse(
      CourseDraft(
        semesterId: semester,
        name: '英语',
        schedules: [
          _schedule(3, {1, 2}),
        ],
      ),
    );
    var state = await planner.load();
    final schedule = state.courses.first.schedules.single as ClassSchedule;
    final draft = CourseDraft(
      semesterId: semester,
      name: '新名称',
      schedules: [schedule],
    );
    final preview = await planner.previewCourseChange(id, draft);
    await planner.saveClassException(
      ClassExceptionDraft(
        scheduleId: schedule.id,
        originalDate: DateTime.utc(2026, 8, 31),
        targetDate: DateTime.utc(2026, 9, 1),
        startMinutes: 660,
        endMinutes: 720,
        location: '新补课',
      ),
    );
    await expectLater(
      planner.applyCourseChange(preview, choices: {}),
      throwsA(isA<InputProblem>()),
    );
    expect((await planner.load()).courses.first.name, '数学');
    expect((await planner.load()).classExceptions.single.location, '新补课');
    final deletion = await planner.previewCourseDeletion(id);
    await planner.saveTask(
      LearningTaskDraft(
        title: '新增作业',
        dueDate: DateTime.utc(2026, 9, 10),
        courseId: id,
      ),
    );
    await expectLater(
      planner.deleteCourse(deletion),
      throwsA(isA<InputProblem>()),
    );
    state = await planner.load();
    expect(state.tasks.single.courseId, id);
    await expectLater(
      planner.previewCourseChange(
        id,
        CourseDraft(
          semesterId: semester,
          name: '非法身份',
          schedules: state.courses.singleWhere((c) => c.id == other).schedules,
        ),
      ),
      throwsA(isA<InputProblem>()),
    );
    await expectLater(
      planner.previewCourseChange(
        id,
        CourseDraft(
          semesterId: semester,
          name: '重复身份',
          schedules: [schedule, schedule],
        ),
      ),
      throwsA(isA<InputProblem>()),
    );
  });

  test('真实 SQLite 写入失败时，安排修改及删除事务都回滚，原例外和任务关联不受损', () async {
    final store = PlannerStore(
      NativeDatabase.memory(
        setup: (db) {
          db.execute(File('test/fixtures/planner_v5.sql').readAsStringSync());
          db.execute(
            "CREATE TRIGGER fail_schedule BEFORE UPDATE ON schedule_records BEGIN SELECT RAISE(ABORT, 'storage failure'); END;",
          );
          db.execute(
            "CREATE TRIGGER fail_course_delete BEFORE DELETE ON course_records BEGIN SELECT RAISE(ABORT, 'storage failure'); END;",
          );
        },
      ),
    );
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    final course = (await planner.load()).courses.single;
    final schedule = course.schedules.single as ClassSchedule;
    final impact = await planner.previewCourseChange(
      course.id,
      CourseDraft(
        semesterId: course.semesterId,
        name: '不应保存的名称',
        schedules: [
          ClassSchedule(
            id: schedule.id,
            weekday: 1,
            startPeriod: 1,
            endPeriod: 1,
            location: '不应保存的地点',
            weeks: {1},
          ),
        ],
      ),
    );
    await expectLater(
      planner.applyCourseChange(
        impact,
        choices: {impact.orphaned.single.key: OrphanChoice.keepIndependent},
      ),
      throwsA(isA<Exception>()),
    );
    var state = await planner.load();
    expect(state.courses.single.name, '大学物理');
    expect(state.courses.single.schedules.single.weeks, {1, 3, 5});
    expect(state.independentLessons, isEmpty);
    expect(state.classExceptions.length, 2);
    await expectLater(
      planner.deleteCourse(await planner.previewCourseDeletion(course.id)),
      throwsA(isA<Exception>()),
    );
    state = await planner.load();
    expect(state.classExceptions.length, 2);
    expect(state.courses.single.schedules.length, 1);
    expect(state.tasks.single.courseId, course.id);
    expect(state.today(DateTime.utc(2026, 9, 15)).single.location, '升级前补课');
  });

  test('schema 5 升级保留调停课和所有数据，删除课程仅清理其关系，完成与未完成 DDL 都保留', () async {
    final directory = await Directory.systemTemp.createTemp(
      'impact_migration_',
    );
    final file = File('${directory.path}/planner.sqlite');
    var store = PlannerStore(
      NativeDatabase(
        file,
        setup: (db) {
          db.execute(File('test/fixtures/planner_v5.sql').readAsStringSync());
        },
      ),
    );
    var planner = SemesterPlanner(store);
    addTearDown(() async {
      await store.close();
      await directory.delete(recursive: true);
    });
    var state = await planner.load();
    expect(state.campusTimeZone, 'Asia/Tokyo');
    expect(state.classExceptions.length, 2);
    expect(state.today(DateTime.utc(2026, 9, 15)).single.location, '升级前补课');
    final course = state.courses.single;
    final other = await planner.saveCourse(
      CourseDraft(
        semesterId: course.semesterId,
        name: '保留的英语',
        schedules: [
          _schedule(1, {2}),
        ],
      ),
    );
    await planner.saveTask(
      LearningTaskDraft(
        title: '未完成的物理作业',
        dueDate: DateTime.utc(2026, 9, 10),
        courseId: course.id,
      ),
    );
    await planner.saveTask(
      LearningTaskDraft(
        title: '英语作业',
        dueDate: DateTime.utc(2026, 9, 10),
        courseId: other,
      ),
    );
    final preview = await planner.previewCourseDeletion(course.id);
    expect(preview.exceptionCount, 2);
    expect(preview.taskCount, 2);
    await planner.deleteCourse(preview);
    await store.close();
    store = PlannerStore(NativeDatabase(file));
    planner = SemesterPlanner(store);
    state = await planner.load();
    expect(state.courses.single.id, other);
    expect(state.classExceptions, isEmpty);
    expect(state.tasks.where((t) => t.courseId == null).length, 2);
    expect(state.tasks.first.isCompleted, isTrue);
    expect(state.tasks.first.notes, '保留实验数据');
    expect(state.tasks.first.dueMinutes, 1439);
    expect(state.tasks.singleWhere((t) => t.title == '英语作业').courseId, other);
    expect(state.events.single.isPinned, isTrue);
    expect(state.today(DateTime.utc(2026, 9, 7)).single.course.name, '保留的英语');
    expect(state.currentSemesterId, course.semesterId);
  });
}

ScheduleDraft _schedule(int day, Set<int> weeks) => ScheduleDraft(
  weekday: day,
  startPeriod: 1,
  endPeriod: 1,
  location: 'A201',
  weeks: weeks,
);
