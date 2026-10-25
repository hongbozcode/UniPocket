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
import 'support/class_exception_flow.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);
  for (final width in [320.0, 393.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$width 宽 $scale 倍字：长文本、时间错误、节次外调课及停课均可达', (tester) async {
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
          final semester = await planner.saveSemester(semesterDraft('秋季'));
          const name = '高等数学与数学分析的长课程名称需要完整显示';
          const location = '新校区数学楼 C401 长地点与集合说明应完整保留并可滚动阅读';
          await planner.saveCourse(
            CourseDraft(
              semesterId: semester,
              name: name,
              schedules: [
                ScheduleDraft(
                  weekday: 1,
                  startPeriod: 1,
                  endPeriod: 2,
                  location: 'A201',
                  weeks: {1, 2},
                ),
              ],
            ),
          );
          try {
            await tester.pumpWidget(
              UniPocketApp(
                planner: planner,
                clock: () => DateTime.utc(2026, 8, 31),
              ),
            );
            await waitFor(tester, find.text(name));
            await tapVisible(tester, find.text(name));
            await tapVisible(tester, find.text('单次调课'));
            await tester.ensureVisible(
              find.byKey(const ValueKey('exception-location')),
            );
            await tester.enterText(
              find.byKey(const ValueKey('exception-location')),
              location,
            );
            await pickExceptionTime(tester, 'exception-start', '11', '00');
            await tapVisible(tester, find.text('保存调课'));
            await waitFor(tester, find.text('结束时间须晚于开始时间，且须在同一天内。'));
            expect((await planner.load()).classExceptions, isEmpty);
            await pickExceptionTime(tester, 'exception-end', '12', '15');
            await tapVisible(tester, find.text('保存调课'));
            await waitFor(
              tester,
              find.byKey(const ValueKey('main-navigation')),
            );
            expect(
              (await planner.load())
                  .today(DateTime.utc(2026, 8, 31))
                  .single
                  .location,
              location,
            );
            await tapVisible(tester, find.text('课表'));
            await tapVisible(tester, find.text('节次外调课'));
            await tapVisible(tester, find.text(name).first);
            await tapVisible(tester, find.text('单次停课'));
            await tapVisible(tester, find.text('确认停课'));
            await waitFor(
              tester,
              find.byKey(const ValueKey('main-navigation')),
            );
            await tapVisible(tester, find.text('今日'));
            expect(find.text('今天没有课程，可以从容安排时间。'), findsOneWidget);
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await store.close();
          }
        });
      });
    }
  }
  testWidgets('真实表单跨周、冲突确认、调课再改时间和停课经文件数据库重开保留', (tester) async {
    await tester.runAsync(() async {
      final directory = await Directory.systemTemp.createTemp('exceptions_ui_');
      final file = File('${directory.path}/planner.sqlite');
      var store = PlannerStore(NativeDatabase(file));
      var planner = SemesterPlanner(store);
      Future<void> launch() async {
        await tester.pumpWidget(
          UniPocketApp(
            planner: planner,
            clock: () => DateTime.utc(2026, 10, 23),
          ),
        );
        await waitFor(tester, find.byKey(const ValueKey('main-navigation')));
      }

      try {
        await seedExceptionCourses(planner);
        await launch();
        await runExceptionCreation(tester, planner);
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
        store = PlannerStore(NativeDatabase(file));
        planner = SemesterPlanner(store);
        await launch();
        await verifyExceptionRestoration(tester, planner);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
        await directory.delete(recursive: true);
      }
    });
  });
  testWidgets('首页课次可单次停课，取消编辑不写入，课表及首页立即同步', (tester) async {
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
              weeks: {1, 2},
            ),
          ],
        ),
      );
      try {
        await tester.pumpWidget(
          UniPocketApp(
            planner: planner,
            clock: () => DateTime.utc(2026, 8, 31),
          ),
        );
        await waitFor(tester, find.text('数学'));
        await tapVisible(tester, find.text('数学'));
        await tapVisible(tester, find.text('单次调课'));
        await tester.enterText(
          find.byKey(const ValueKey('exception-location')),
          '未保存地点',
        );
        await tapVisible(tester, find.text('取消编辑'));
        expect((await planner.load()).classExceptions, isEmpty);
        await tapVisible(tester, find.text('单次停课'));
        await tapVisible(tester, find.text('确认停课'));
        await waitFor(tester, find.byKey(const ValueKey('main-navigation')));
        expect(
          (await planner.load()).today(DateTime.utc(2026, 8, 31)),
          isEmpty,
        );
        await tapVisible(tester, find.text('课表'));
        await tapVisible(tester, find.text('今日'));
        expect(find.text('今天没有课程，可以从容安排时间。'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
      }
    });
  });
}
