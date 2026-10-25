import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/timetable/model.dart';
import 'package:unipocket/tasks/model.dart';

import 'support/semester_fixture.dart';
import 'support/widget_actions.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);
  for (final width in [320.0, 393.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$width 宽 $scale 倍文字：长名称地点、失联停课选择与删除确认可滚动操作', (tester) async {
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
          final planner = SemesterPlanner(store);
          try {
            final semester = await planner.saveSemester(
              semesterDraft('长学期名称用于窄屏与双倍文字验证'),
            );
            const name = '高等数学与数学分析的完整长课程名称';
            final id = await planner.saveCourse(
              CourseDraft(
                semesterId: semester,
                name: name,
                schedules: [
                  ScheduleDraft(
                    weekday: 1,
                    startPeriod: 1,
                    endPeriod: 2,
                    location: '新校区数学楼 A201 长地点需完整显示并且可以滚动阅读',
                    weeks: {1, 2},
                  ),
                ],
              ),
            );
            final schedule =
                (await planner.load()).courses.single.schedules.single
                    as ClassSchedule;
            await planner.saveClassException(
              ClassExceptionDraft(
                scheduleId: schedule.id,
                originalDate: DateTime.utc(2026, 9, 7),
                targetDate: DateTime.utc(2026, 9, 7),
                startMinutes: 480,
                endMinutes: 580,
                location: '原停课地点完整说明',
                isCancelled: true,
              ),
            );
            await tester.pumpWidget(
              UniPocketApp(
                planner: planner,
                clock: () => DateTime.utc(2026, 8, 31),
              ),
            );
            await waitFor(tester, find.text(name));
            await tapVisible(tester, find.text(name));
            await tapVisible(tester, find.text('修改重复安排'));
            await tapVisible(tester, find.byTooltip('第 2 周'));
            await tapVisible(tester, find.byKey(const ValueKey('save-course')));
            await waitFor(tester, find.text('确认安排变更'));
            await tapVisible(tester, find.text('确认变更'));
            await waitFor(tester, find.text('请为每一项失去关联的例外选择保留为独立补课或删除。'));
            expect((await planner.load()).classExceptions.length, 1);
            await tapVisible(
              tester,
              find.byKey(const ValueKey('orphan-choice-0')),
            );
            await tapVisible(tester, find.text('保留为独立补课').last);
            await tapVisible(tester, find.text('确认变更'));
            await waitFor(
              tester,
              find.byKey(const ValueKey('main-navigation')),
            );
            expect(
              (await planner.load()).independentLessons.single.courseId,
              id,
            );
            await tapVisible(tester, find.text(name));
            await tapVisible(tester, find.text('编辑独立补课'));
            await tester.enterText(
              find.byKey(const ValueKey('exception-location')),
              '独立补课的新地点',
            );
            await tapVisible(tester, find.text('保存补课'));
            await waitFor(
              tester,
              find.byKey(const ValueKey('main-navigation')),
            );
            expect(
              (await planner.load()).independentLessons.single.location,
              '独立补课的新地点',
            );
            await tapVisible(tester, find.text(name));
            await tapVisible(tester, find.text('取消独立补课'));
            await tapVisible(tester, find.text('确认取消补课'));
            await waitFor(
              tester,
              find.byKey(const ValueKey('main-navigation')),
            );
            expect((await planner.load()).independentLessons, isEmpty);
            await tapVisible(tester, find.text(name));
            await tapVisible(tester, find.text('删除课程'));
            await tapVisible(tester, find.text('确认删除'));
            await waitFor(
              tester,
              find.byKey(const ValueKey('main-navigation')),
            );
            expect((await planner.load()).courses, isEmpty);
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await store.close();
          }
        });
      });
    }
  }
  testWidgets('修改安排先预览并可取消，逐项选择独立补课后保存，删除课程保留 DDL 并经重开验证', (tester) async {
    await tester.runAsync(() async {
      final directory = await Directory.systemTemp.createTemp('impact_ui_');
      final file = File('${directory.path}/planner.sqlite');
      var store = PlannerStore(NativeDatabase(file));
      var planner = SemesterPlanner(store);
      try {
        final semester = await planner.saveSemester(semesterDraft('秋季'));
        final id = await planner.saveCourse(
          CourseDraft(
            semesterId: semester,
            name: '高等数学',
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
        await planner.saveClassException(
          ClassExceptionDraft(
            scheduleId: (course.schedules.single as ClassSchedule).id,
            originalDate: DateTime.utc(2026, 9, 7),
            targetDate: DateTime.utc(2026, 9, 8),
            startMinutes: 660,
            endMinutes: 720,
            location: '补课教室',
          ),
        );
        await planner.saveTask(
          LearningTaskDraft(
            title: '数学作业',
            dueDate: DateTime.utc(2026, 9, 9),
            courseId: id,
            notes: '保留题目和完成状态',
          ),
        );
        await tester.pumpWidget(
          UniPocketApp(
            planner: planner,
            clock: () => DateTime.utc(2026, 8, 31),
          ),
        );
        await waitFor(tester, find.text('高等数学'));
        await tapVisible(tester, find.text('高等数学').first);
        await tapVisible(tester, find.text('修改重复安排'));
        await tapVisible(tester, find.byTooltip('第 2 周'));
        await tapVisible(tester, find.byKey(const ValueKey('save-course')));
        await waitFor(tester, find.text('确认安排变更'));
        expect((await planner.load()).independentLessons, isEmpty);
        await tapVisible(tester, find.text('返回修改'));
        expect((await planner.load()).classExceptions.length, 1);
        await tapVisible(tester, find.byKey(const ValueKey('save-course')));
        await waitFor(tester, find.text('确认安排变更'));
        await tapVisible(tester, find.byKey(const ValueKey('orphan-choice-0')));
        await tapVisible(tester, find.text('保留为独立补课').last);
        await tapVisible(tester, find.text('确认变更'));
        await waitFor(tester, find.byKey(const ValueKey('main-navigation')));
        expect((await planner.load()).classExceptions, isEmpty);
        expect((await planner.load()).independentLessons.length, 1);
        await tapVisible(tester, find.text('高等数学').first);
        await tapVisible(tester, find.text('删除课程'));
        await waitFor(tester, find.text('确认删除课程'));
        expect(find.textContaining('1 项学习任务'), findsOneWidget);
        await tapVisible(tester, find.text('取消'));
        expect((await planner.load()).courses.length, 1);
        await tapVisible(tester, find.text('删除课程'));
        await tapVisible(tester, find.text('确认删除'));
        await waitFor(tester, find.byKey(const ValueKey('main-navigation')));
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
        store = PlannerStore(NativeDatabase(file));
        planner = SemesterPlanner(store);
        final state = await planner.load();
        expect(state.courses, isEmpty);
        expect(state.independentLessons, isEmpty);
        expect(state.classExceptions, isEmpty);
        expect(state.tasks.single.title, '数学作业');
        expect(state.tasks.single.courseId, isNull);
        expect(state.tasks.single.notes, '保留题目和完成状态');
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
        await directory.delete(recursive: true);
      }
    });
  });
}
