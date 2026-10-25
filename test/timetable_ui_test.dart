import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/timetable/model.dart';

import 'support/semester_fixture.dart';
import 'support/widget_actions.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  for (final width in [320.0, 393.0]) {
    testWidgets('$width 窄屏双倍字号下多安排与教学周选择可保存，周网格、详情和滚动可达', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 28, bottom: 24);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetPadding();
        tester.platformDispatcher.clearTextScaleFactorTestValue();
      });
      await tester.runAsync(() async {
        final store = PlannerStore(NativeDatabase.memory());
        final planner = SemesterPlanner(store);
        await planner.saveSemester(
          semesterDraft('很长的秋季学期名称用于检查大字号下的页面布局与完整阅读'),
        );
        Future<void> tap(Finder finder) => tapVisible(tester, finder);

        try {
          await tester.pumpWidget(
            UniPocketApp(
              planner: planner,
              clock: () => DateTime.utc(2026, 8, 31),
            ),
          );
          await tester.pumpAndSettle();
          await tap(find.text('添加课程'));
          const name = '很长的高等数学与数学分析课程名称需要完整换行显示';
          await tester.enterText(
            find.byKey(const ValueKey('course-name')),
            name,
          );
          await tester.enterText(
            find.byKey(const ValueKey('schedule-location-0')),
            '数学楼 A201 长地点名称',
          );
          await tap(find.text('双周').first);
          await tap(find.text('单周').first);
          await tap(find.byTooltip('第 3 周').first);
          await tap(find.text('添加上课安排'));
          await tap(find.byKey(const ValueKey('schedule-day-1')));
          await tap(find.text('周三').last);
          await tester.ensureVisible(
            find.byKey(const ValueKey('schedule-start-1')),
          );
          await tester.enterText(
            find.byKey(const ValueKey('schedule-start-1')),
            '3',
          );
          await tester.enterText(
            find.byKey(const ValueKey('schedule-end-1')),
            '3',
          );
          await tester.enterText(
            find.byKey(const ValueKey('schedule-location-1')),
            '实验楼 B302',
          );
          await tap(find.text('连续周').last);
          await tester.enterText(find.widgetWithText(TextField, '起始周'), '2');
          await tester.enterText(find.widgetWithText(TextField, '结束周'), '4');
          await tap(find.text('应用连续周'));
          await tap(find.byTooltip('第 3 周').last);
          await tap(find.byKey(const ValueKey('save-course')));
          await waitFor(tester, find.text('课程已保存到本机'));
          final course = (await planner.load()).courses.single;
          expect(course.schedules.first.weeks, {
            1,
            5,
            7,
            9,
            11,
            13,
            15,
            17,
            19,
          });
          expect(course.schedules.last.weeks, {2, 4});
          expect(course.schedules.last.weekday, 3);
          expect(course.schedules.last.location, '实验楼 B302');
          expect(tester.takeException(), isNull);
          await tap(find.text('课表'));
          await tap(find.byTooltip('下一周'));
          expect(find.text('第 2 周'), findsOneWidget);
          await tester.ensureVisible(find.text('节次'));
          await tester.pumpAndSettle();
          await tester.dragFrom(
            tester.getTopLeft(find.text('节次')) + const Offset(100, 20),
            const Offset(-450, 0),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await tap(find.text('今日'));
          await tap(find.text(name).first);
          expect(find.textContaining('已有上课安排'), findsOneWidget);
          expect(tester.takeException(), isNull);
        } finally {
          await tester.pumpWidget(const SizedBox.shrink());
          await store.close();
        }
      });
    });
  }

  testWidgets('冲突可返回修改且不写入，确认后两课可见；空周选择有明确错误', (tester) async {
    await tester.runAsync(() async {
      final store = PlannerStore(NativeDatabase.memory());
      final planner = SemesterPlanner(store);
      final semester = await planner.saveSemester(semesterDraft('秋季'));
      await planner.saveCourse(
        CourseDraft(
          semesterId: semester,
          name: '数学',
          schedules: [
            ScheduleDraft(
              weekday: 1,
              startPeriod: 1,
              endPeriod: 2,
              location: 'A201',
              weeks: {1},
            ),
          ],
        ),
      );
      Future<void> tap(Finder finder) => tapVisible(tester, finder);

      try {
        await tester.pumpWidget(
          UniPocketApp(
            planner: planner,
            clock: () => DateTime.utc(2026, 8, 31),
          ),
        );
        await tester.pumpAndSettle();
        await tap(find.text('添加课程'));
        await tester.enterText(find.byKey(const ValueKey('course-name')), '英语');
        await tap(find.byKey(const ValueKey('save-course')));
        await waitFor(tester, find.text('上课时间冲突'));
        await tap(find.text('返回修改'));
        expect((await planner.load()).courses, hasLength(1));
        await tap(find.byKey(const ValueKey('save-course')));
        await waitFor(tester, find.text('上课时间冲突'));
        await tap(find.text('仍然保存'));
        await waitFor(tester, find.text('课程已保存到本机'));
        expect((await planner.load()).courses, hasLength(2));
        await tap(find.text('添加课程'));
        await tester.enterText(
          find.byKey(const ValueKey('course-name')),
          '无效课程',
        );
        for (var week = 1; week <= 20; week++) {
          await tap(find.byTooltip('第 $week 周'));
        }
        await tap(find.byKey(const ValueKey('save-course')));
        await waitFor(tester, find.textContaining('请至少选择一个教学周'));
        expect((await planner.load()).courses, hasLength(2));
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
      }
    });
  });

  testWidgets('从首页录入课程，今日与周课表可见，重开数据库后仍保留并可编辑基本信息', (tester) async {
    await tester.runAsync(() async {
      final directory = Directory.systemTemp.createTempSync('timetable-ui-');
      final file = File('${directory.path}/planner.sqlite');
      var store = PlannerStore(NativeDatabase(file));
      try {
        var planner = SemesterPlanner(store);
        await planner.saveSemester(semesterDraft('秋季'));
        Widget app() => UniPocketApp(
          planner: planner,
          clock: () => DateTime.utc(2026, 8, 31),
        );
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        await tester.tap(find.text('添加课程'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('course-name')),
          '高等数学',
        );
        await tester.enterText(
          find.byKey(const ValueKey('course-teacher')),
          '李老师',
        );
        await tester.enterText(
          find.byKey(const ValueKey('schedule-location-0')),
          '数学楼 A201',
        );
        final save = find.byKey(const ValueKey('save-course'));
        await tester.scrollUntilVisible(
          save,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(save);
        await tester.pumpAndSettle();
        await waitFor(tester, find.text('课程已保存到本机'));
        expect(find.text('高等数学'), findsOneWidget);
        expect(find.textContaining('08:00–09:40'), findsWidgets);
        expect(find.textContaining('数学楼 A201'), findsWidgets);
        await tester.tap(find.text('课表'));
        await tester.pumpAndSettle();
        expect(find.text('第 1 周'), findsOneWidget);
        await tester.tap(find.byTooltip('下一周'));
        await tester.pumpAndSettle();
        expect(find.text('第 2 周'), findsOneWidget);
        await tester.tap(find.text('回到本周'));
        await tester.pumpAndSettle();
        expect(find.text('第 1 周'), findsOneWidget);
        await tester.tap(find.text('今日'));
        await tester.pumpAndSettle();
        expect(find.text('高等数学'), findsWidgets);
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
        store = PlannerStore(NativeDatabase(file));
        planner = SemesterPlanner(store);
        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        await tester.tap(find.text('高等数学'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('course-name')),
          '数学分析',
        );
        await tester.scrollUntilVisible(
          save,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(save);
        await tester.pumpAndSettle();
        await waitFor(tester, find.text('课程已保存到本机'));
        expect(find.text('数学分析'), findsOneWidget);
        expect((await planner.load()).courses.single.teacher, '李老师');
        expect(
          (await planner.load()).courses.single.schedules.single.location,
          '数学楼 A201',
        );
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
        directory.deleteSync(recursive: true);
      }
    });
  });
}
