import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:unipocket/events/model.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/semesters/model.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/tasks/model.dart';

import 'support/semester_fixture.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('任务 3 数据库升级保留已完成任务、课程关联、课表和校园时区', () async {
    final store = PlannerStore(
      NativeDatabase.memory(
        setup: (database) {
          database.execute(
            File('test/fixtures/planner_v3.sql').readAsStringSync(),
          );
        },
      ),
    );
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    var state = await planner.load();
    expect(state.events, isEmpty);
    expect(state.campusTimeZone, 'Asia/Tokyo');
    expect(state.currentSemester!.name, '升级前的秋季');
    expect(state.courses.single.schedules.single.weeks, {1, 3, 5});
    expect(state.tasks.single.title, '物理实验报告');
    expect(state.tasks.single.isCompleted, isTrue);
    expect(state.tasks.single.courseId, state.courses.single.id);
    expect(state.tasks.single.notes, '保留实验数据');
    await planner.saveEvent(
      CountdownEventDraft(
        title: '升级后的考试',
        targetDate: DateTime(2026, 11, 6),
        isPinned: true,
      ),
    );
    state = await planner.load();
    expect(state.events.single.title, '升级后的考试');
    expect(state.tasks.single.isCompleted, isTrue);
    expect(state.today(DateTime.utc(2026, 8, 31)).single.location, 'A201');
  });

  test('编辑、置顶排序、历史、删除与学期切换经真实文件数据库重启保留，DDL 独立', () async {
    final directory = await Directory.systemTemp.createTemp(
      'unipocket_events_',
    );
    final file = File('${directory.path}/planner.sqlite');
    var store = PlannerStore(NativeDatabase(file));
    addTearDown(() async {
      await store.close();
      await directory.delete(recursive: true);
    });
    var planner = SemesterPlanner(store);
    final exam = await planner.saveEvent(
      CountdownEventDraft(
        title: ' 期中考试 ',
        targetDate: DateTime(2026, 11, 6),
        isPinned: true,
      ),
    );
    final show = await planner.saveEvent(
      CountdownEventDraft(
        title: '课程展示',
        targetDate: DateTime(2026, 10, 23),
        kind: EventKind.custom,
      ),
    );
    await planner.saveEvent(
      CountdownEventDraft(
        title: '社团展示日',
        targetDate: DateTime(2026, 10, 30),
        kind: EventKind.custom,
      ),
    );
    await planner.saveEvent(
      CountdownEventDraft(
        title: '历史考试',
        targetDate: DateTime(2026, 10, 1),
        isPinned: true,
      ),
    );
    final now = DateTime.utc(2026, 10, 23, 12);
    var state = await planner.load();
    expect(selectEvents(state.events, now).map((e) => e.title), [
      '期中考试',
      '课程展示',
      '社团展示日',
    ]);
    expect(selectEvents(state.events, now, history: true).single.title, '历史考试');
    expect(state.tasks, isEmpty);
    await planner.saveTask(LearningTaskDraft(title: '独立作业', dueDate: now));
    expect((await planner.load()).events, hasLength(4));

    await planner.setEventPinned(exam, false);
    await planner.setEventPinned(show, true);
    await planner.saveEvent(
      CountdownEventDraft(
        title: '已修改的展示',
        targetDate: DateTime(2026, 10, 24),
        kind: EventKind.custom,
        isPinned: true,
      ),
      id: show,
    );
    final first = await planner.saveSemester(semesterDraft('秋季'));
    final second = await planner.saveSemester(semesterDraft('春季'));
    await planner.setCurrentSemester(second);
    await planner.setCurrentSemester(first);
    await store.close();
    store = PlannerStore(NativeDatabase(file));
    planner = SemesterPlanner(store);
    state = await planner.load();
    final selected = selectEvents(state.events, now);
    expect(selected.first.title, '已修改的展示');
    expect(selected.first.kind, EventKind.custom);
    expect(selected.first.isPinned, isTrue);
    expect(selected.first.targetDate, DateTime.utc(2026, 10, 24));
    expect(state.tasks.single.title, '独立作业');
    for (final draft in [
      CountdownEventDraft(title: ' ', targetDate: now),
      CountdownEventDraft(title: '超出日期范围', targetDate: DateTime(2201)),
    ]) {
      await expectLater(
        planner.saveEvent(draft, id: exam),
        throwsA(isA<InputProblem>()),
      );
    }
    expect((await planner.load()).events.first.title, '期中考试');
    await planner.deleteEvent(show);
    await expectLater(
      planner.setEventPinned(show, false),
      throwsA(isA<InputProblem>()),
    );
    await expectLater(planner.deleteEvent(show), throwsA(isA<InputProblem>()));
    await store.close();
    store = PlannerStore(NativeDatabase(file));
    state = await SemesterPlanner(store).load();
    expect(state.events, hasLength(3));
    expect(state.events.any((e) => e.id == show), isFalse);
    expect(state.tasks.single.title, '独立作业');
  });

  test('倒计时按校园日历跨午夜、跨年与夏令时变化，手机时区不改变日期含义', () async {
    final store = PlannerStore(NativeDatabase.memory());
    addTearDown(store.close);
    final planner = SemesterPlanner(store);
    await planner.saveEvent(
      CountdownEventDraft(title: '新年考试', targetDate: DateTime(2027, 1, 1)),
    );
    var state = await planner.load();
    final event = state.events.single;
    expect(
      event.daysRemaining(state.campusTime(DateTime.utc(2026, 12, 31, 15, 59))),
      1,
    );
    expect(
      event.countdownText(state.campusTime(DateTime.utc(2026, 12, 31, 16))),
      '就是今天',
    );
    expect(
      event.daysRemaining(state.campusTime(DateTime.utc(2027, 1, 1, 16))),
      -1,
    );

    final previous = tz.local;
    addTearDown(() => tz.setLocalLocation(previous));
    tz.setLocalLocation(tz.getLocation('Pacific/Honolulu'));
    final instant = DateTime.utc(2026, 12, 31, 16);
    final phoneTime = tz.TZDateTime.from(instant, tz.local);
    expect(event.daysRemaining(state.campusTime(phoneTime)), 0);
    expect(phoneTime.day, 31);

    await planner.setCampusTimeZone('America/New_York');
    await planner.saveEvent(
      CountdownEventDraft(title: '春季活动', targetDate: DateTime(2026, 3, 9)),
    );
    state = await planner.load();
    final spring = state.events.last;
    // Only 23 hours separate these midnights; they are still one calendar day apart.
    expect(
      spring.daysRemaining(state.campusTime(DateTime.utc(2026, 3, 8, 5))),
      1,
    );
    expect(
      spring.countdownText(state.campusTime(DateTime.utc(2026, 3, 9, 4))),
      '就是今天',
    );
    await planner.saveEvent(
      CountdownEventDraft(title: '秋季活动', targetDate: DateTime(2026, 11, 2)),
    );
    state = await planner.load();
    expect(
      state.events.last.daysRemaining(
        state.campusTime(DateTime.utc(2026, 11, 1, 4)),
      ),
      1,
    );
    expect(state.tasks, isEmpty);
  });
}
