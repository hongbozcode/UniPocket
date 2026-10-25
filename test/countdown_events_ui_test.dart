import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/events/model.dart';
import 'package:unipocket/events/events_page.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/ui/design.dart';

import 'support/widget_actions.dart';
import 'support/semester_fixture.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  testWidgets('校园午夜停留时刷新天数并转入历史，返回首页也排除过去事件', (tester) async {
    final store = PlannerStore(NativeDatabase.memory());
    final planner = SemesterPlanner(store);
    var instant = DateTime.utc(2026, 10, 23, 15, 59);
    addTearDown(store.close);
    await tester.runAsync(() async {
      await planner.saveEvent(
        CountdownEventDraft(
          title: '今天的考试',
          targetDate: DateTime(2026, 10, 23),
          isPinned: true,
        ),
      );
      await planner.saveEvent(
        CountdownEventDraft(title: '明天的考试', targetDate: DateTime(2026, 10, 24)),
      );
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(),
        home: EventsPage(planner: planner, clock: () => instant),
      ),
    );
    await tester.runAsync(() => waitFor(tester, find.text('进行中  2')));
    expect(find.text('就是今天'), findsOneWidget);
    instant = DateTime.utc(2026, 10, 23, 16);
    await tester.pump(const Duration(seconds: 31));
    expect(find.text('进行中  1'), findsOneWidget);
    expect(find.text('今天的考试'), findsNothing);
    expect(find.text('明天的考试'), findsOneWidget);
    await tapVisible(tester, find.text('历史'));
    expect(find.text('今天的考试'), findsOneWidget);
    expect(find.text('已过去 1 天'), findsOneWidget);
    await tester.runAsync(() async {
      expect((await planner.load()).events, hasLength(2));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        UniPocketApp(planner: planner, clock: () => instant),
      );
      await waitFor(tester, find.text('UniPocket'));
      await tapVisible(tester, find.text('查看全部倒计时'));
      expect(find.text('进行中  1'), findsOneWidget);
      expect(find.text('今天的考试'), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  for (final width in [320.0, 393.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$width 宽度 $scale 倍文字，安全区域、长标题、历史及末项表单可达', (tester) async {
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
          await planner.saveSemester(semesterDraft('2026 秋季'));
          for (var i = 0; i < 8; i++) {
            await planner.saveEvent(
              CountdownEventDraft(
                title: '第 $i 项倒计时事件的很长标题应完整展示并能编辑',
                targetDate: DateTime(2026, 11, i + 1),
                isPinned: i == 0,
              ),
            );
          }
          await planner.saveEvent(
            CountdownEventDraft(
              title: '过去的考试',
              targetDate: DateTime(2026, 10, 1),
            ),
          );
          try {
            await tester.pumpWidget(
              UniPocketApp(
                planner: planner,
                clock: () => DateTime.utc(2026, 10, 23, 4),
              ),
            );
            await waitFor(tester, find.text('UniPocket'));
            await tapVisible(tester, find.text('课表'));
            await tapVisible(tester, find.byTooltip('倒计时'));
            await waitFor(tester, find.text('进行中  8'));
            expect(tester.takeException(), isNull);
            await tapVisible(tester, find.text('第 7 项倒计时事件的很长标题应完整展示并能编辑'));
            await tapVisible(tester, find.byType(SwitchListTile));
            await tapVisible(tester, find.text('保存事件'));
            await waitFor(tester, find.byType(EventsPage));
            expect((await planner.load()).events[7].isPinned, isTrue);
            await tapVisible(tester, find.text('历史'));
            await tapVisible(tester, find.text('过去的考试'));
            expect(find.textContaining('保存后进入历史'), findsOneWidget);
            await tapVisible(tester, find.text('保存事件'));
            await waitFor(tester, find.byType(EventsPage));
            await tapVisible(tester, find.byTooltip('更多：过去的考试'));
            await tapVisible(tester, find.text('删除'));
            await tapVisible(tester, find.text('确认删除'));
            await waitFor(tester, find.text('还没有历史事件'));
            expect((await planner.load()).events, hasLength(8));
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await store.close();
          }
        });
      });
    }
  }

  testWidgets('无学期从首页快捷创建、编辑、置顶、取消删除及确认删除，重开文件恢复', (tester) async {
    await tester.runAsync(() async {
      final directory = await Directory.systemTemp.createTemp('events_ui_');
      final file = File('${directory.path}/planner.sqlite');
      var store = PlannerStore(NativeDatabase(file));
      var planner = SemesterPlanner(store);
      Future<void> launch() async {
        await tester.pumpWidget(
          UniPocketApp(
            planner: planner,
            clock: () => DateTime.utc(2026, 10, 23, 4),
          ),
        );
        await waitFor(tester, find.text('UniPocket'));
      }

      try {
        await launch();
        await tapVisible(tester, find.byTooltip('创建倒计时'));
        await tapVisible(tester, find.text('保存事件'));
        await waitFor(tester, find.text('请输入事件标题。'));
        await tester.enterText(
          find.byKey(const ValueKey('event-title')),
          '期中考试',
        );
        await tapVisible(tester, find.text('保存事件'));
        await waitFor(tester, find.byKey(const ValueKey('main-navigation')));
        expect((await planner.load()).events.single.title, '期中考试');
        expect((await planner.load()).tasks, isEmpty);
        await tapVisible(tester, find.text('查看全部倒计时'));
        await waitFor(tester, find.text('进行中  1'));
        expect(find.text('就是今天'), findsOneWidget);
        await tapVisible(tester, find.byTooltip('更多：期中考试'));
        await tapVisible(tester, find.text('置顶'));
        await waitFor(tester, find.text('已置顶'));
        await tapVisible(tester, find.text('期中考试'));
        await tester.enterText(
          find.byKey(const ValueKey('event-title')),
          '期末考试',
        );
        await tapVisible(tester, find.byKey(const ValueKey('event-date')));
        await tapVisible(tester, find.text('24'));
        await tapVisible(tester, find.text('确定'));
        await tapVisible(tester, find.text('自定义'));
        await tapVisible(tester, find.text('保存事件'));
        await waitFor(tester, find.text('期末考试'));
        expect(
          (await planner.load()).events.single.targetDate,
          DateTime.utc(2026, 10, 24),
        );
        expect((await planner.load()).events.single.kind, EventKind.custom);

        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
        store = PlannerStore(NativeDatabase(file));
        planner = SemesterPlanner(store);
        await launch();
        await tapVisible(tester, find.text('课表'));
        await tapVisible(tester, find.text('倒计时'));
        await waitFor(tester, find.text('期末考试'));
        expect(find.text('已置顶'), findsOneWidget);
        await tapVisible(tester, find.text('期末考试'));
        await tapVisible(tester, find.text('删除事件'));
        await tapVisible(tester, find.text('取消'));
        expect((await planner.load()).events, hasLength(1));
        await tapVisible(tester, find.text('删除事件'));
        await tapVisible(tester, find.text('确认删除'));
        await waitFor(tester, find.text('还没有进行中的事件'));
        expect((await planner.load()).events, isEmpty);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
        await directory.delete(recursive: true);
      }
    });
  });
}
