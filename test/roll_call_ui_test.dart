import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/random_tools/roll_call.dart';
import 'package:unipocket/random_tools/roll_call_page.dart';
import 'package:unipocket/ui/design.dart';

import 'support/roll_call_random.dart';
import 'support/widget_actions.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);
  for (final width in [320.0, 393.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$width 宽 $scale 倍字：空名单、长文本、模式确认、编辑取消和主动重置', (tester) async {
        tester.view.physicalSize = Size(width, 740);
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
          const longName = '非常长的同学姓名包含中文与 English words 需要完整换行显示';
          const detail = '学号 202600000000112，备注：这是一段很长的区分信息';
          const title = '非常长的点名名单名称应该完整换行';
          try {
            await planner.saveRollCallList(name: '空名单', members: []);
            await planner.saveRollCallList(
              name: title,
              members: [
                const RollCallMember(id: 1, name: longName, detail: detail),
              ],
            );
            await tester.pumpWidget(
              MaterialApp(
                theme: appTheme(),
                home: RollCallPage(
                  planner: planner,
                  random: RollCallRandom([(1, 0), (1, 0)]),
                ),
              ),
            );
            await waitFor(tester, find.text('空名单 · 0人'));
            await tester.pumpAndSettle();
            final draw = find.byKey(const ValueKey('roll-call-draw'));
            await tester.scrollUntilVisible(
              draw,
              180,
              scrollable: verticalScroll(),
            );
            expect(tester.widget<FilledButton>(draw).onPressed, isNull);
            await tapVisible(tester, find.text('空名单 · 0人'));
            await tapVisible(tester, find.text(title));
            await tapVisible(tester, draw);
            await waitFor(tester, find.text('本次抽中'));
            expect(
              tester
                  .widget<SelectableText>(
                    find.byKey(const ValueKey('roll-call-result')),
                  )
                  .data,
              longName,
            );
            expect(
              tester
                  .widget<SelectableText>(
                    find.byKey(const ValueKey('roll-call-identification')),
                  )
                  .data,
              detail,
            );
            await tester.scrollUntilVisible(
              draw,
              180,
              scrollable: verticalScroll(),
            );
            expect(tester.widget<FilledButton>(draw).onPressed, isNull);
            await tapVisible(tester, find.text('管理名单'));
            await tapVisible(tester, find.text('保留进度'));
            expect((await planner.loadRollCallLists()).last.drawn, [1]);
            await tapVisible(tester, find.text('管理名单'));
            await tapVisible(tester, find.text('继续编辑'));
            await tester.enterText(
              find.widgetWithText(TextFormField, '名单名称'),
              '放弃修改',
            );
            await tapVisible(tester, find.byTooltip('取消编辑'));
            expect((await planner.loadRollCallLists()).last.name, title);
            expect((await planner.loadRollCallLists()).last.drawn, [1]);
            await tapVisible(tester, find.text('可重复'));
            await tapVisible(
              tester,
              find.widgetWithText(FilledButton, '开始新一轮'),
            );
            expect((await planner.loadRollCallLists()).last.repeat, isTrue);
            await tapVisible(tester, draw);
            await waitFor(tester, find.text('本次抽中'));
            expect((await planner.loadRollCallLists()).last.drawn, [1]);
            await tapVisible(
              tester,
              find.widgetWithText(OutlinedButton, '开始新一轮'),
            );
            await tapVisible(
              tester,
              find.widgetWithText(FilledButton, '开始新一轮'),
            );
            expect((await planner.loadRollCallLists()).last.drawn, isEmpty);
            await tapVisible(tester, find.text('管理名单'));
            await tapVisible(tester, find.text('继续编辑'));
            await tester.enterText(
              find.widgetWithText(TextFormField, '名单名称'),
              '修改后',
            );
            await tapVisible(tester, find.text('保存到本机'));
            await waitFor(tester, find.text('修改后 · 1人'));
            expect(
              (await planner.loadRollCallLists()).last.members.single.detail,
              detail,
            );
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await store.close();
          }
        });
      });
    }
  }

  testWidgets('显式取消和进入后台不消耗轮次，播放期间锁定编辑与模式', (tester) async {
    tester.view.physicalSize = const Size(393, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.runAsync(() async {
      final store = PlannerStore(NativeDatabase.memory());
      final planner = SemesterPlanner(store);
      try {
        await planner.saveRollCallList(
          name: '名单',
          members: [const RollCallMember(id: 1, name: '甲')],
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: appTheme(),
            home: RollCallPage(
              planner: planner,
              random: RollCallRandom([(1, 0), (1, 0)]),
            ),
          ),
        );
        await waitFor(tester, find.text('名单 · 1人'));
        final draw = find.byKey(const ValueKey('roll-call-draw'));
        for (final background in [false, true]) {
          await tester.scrollUntilVisible(
            draw,
            180,
            scrollable: verticalScroll(),
          );
          await tester.pumpAndSettle();
          await tester.tap(draw);
          await waitForRolling(tester);
          expect(
            tester
                .widget<OutlinedButton>(
                  find.widgetWithText(OutlinedButton, '管理名单'),
                )
                .onPressed,
            isNull,
          );
          expect(
            tester
                .widget<TextButton>(find.widgetWithText(TextButton, '可重复'))
                .onPressed,
            isNull,
          );
          if (background) {
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.paused,
            );
            tester.binding.handleAppLifecycleStateChanged(
              AppLifecycleState.resumed,
            );
          } else {
            await tester.ensureVisible(find.text('取消点名'));
            await tester.tap(find.text('取消点名'));
          }
          await tester.pumpAndSettle();
          expect((await planner.loadRollCallLists()).single.drawn, isEmpty);
          expect(find.text('已取消点名，未消耗本轮名额'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
      }
    });
  });
  testWidgets('工具入口新建同名名单，滚动结束才入轮，返回取消后重开续接', (tester) async {
    await tester.runAsync(() async {
      final dir = Directory.systemTemp.createTempSync('roll-ui-');
      final file = File('${dir.path}/planner.sqlite');
      var store = PlannerStore(NativeDatabase(file));
      var planner = SemesterPlanner(store);
      try {
        await tester.pumpWidget(
          UniPocketApp(
            planner: planner,
            random: RollCallRandom([(2, 1), (1, 0)]),
          ),
        );
        await waitFor(tester, find.text('UniPocket'));
        await tapVisible(tester, find.text('工具'));
        await tapVisible(tester, find.text('随机点名'));
        await tapVisible(tester, find.text('新建名单'));
        await tester.enterText(
          find.widgetWithText(TextFormField, '名单名称'),
          '高数学习小组',
        );
        await tester.enterText(
          find.byKey(const ValueKey('member-name-1')),
          '林晓',
        );
        await tester.enterText(
          find.byKey(const ValueKey('member-detail-1')),
          '0112',
        );
        await tapVisible(tester, find.text('添加成员'));
        await tester.enterText(
          find.byKey(const ValueKey('member-name-2')),
          '林晓',
        );
        await tester.enterText(
          find.byKey(const ValueKey('member-detail-2')),
          '组长',
        );
        await tapVisible(tester, find.text('保存到本机'));
        await waitFor(tester, find.text('高数学习小组 · 2人'));
        await tester.pumpAndSettle();
        final draw = find.byKey(const ValueKey('roll-call-draw'));
        await tester.scrollUntilVisible(
          draw,
          200,
          scrollable: find
              .byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              )
              .last,
        );
        await tester.pumpAndSettle();
        await tester.tap(draw);
        await waitForRolling(tester);
        expect((await planner.loadRollCallLists()).single.drawn, isEmpty);
        expect(tester.widget<FilledButton>(draw).onPressed, isNull);
        await tester.tap(draw);
        await tester.pump(const Duration(milliseconds: 1399));
        expect((await planner.loadRollCallLists()).single.drawn, isEmpty);
        await tester.pump(const Duration(milliseconds: 2));
        await waitFor(tester, find.text('本次抽中'));
        expect((await planner.loadRollCallLists()).single.drawn, [2]);
        expect(find.text('组长'), findsOneWidget);
        await tester.ensureVisible(draw);
        await tester.tap(draw);
        await waitForRolling(tester);
        await tester.pump(const Duration(milliseconds: 1300));
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
        store = PlannerStore(NativeDatabase(file));
        planner = SemesterPlanner(store);
        expect((await planner.loadRollCallLists()).single.drawn, [2]);
        await tester.pumpWidget(UniPocketApp(planner: planner));
        await waitFor(tester, find.text('UniPocket'));
        await tapVisible(tester, find.text('工具'));
        await tapVisible(tester, find.text('随机点名'));
        await waitFor(tester, find.text('高数学习小组 · 2人'));
        expect(find.text('剩余 1 人'), findsOneWidget);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await store.close();
        dir.deleteSync(recursive: true);
      }
    });
  });
}

Future<void> waitForRolling(WidgetTester tester) async {
  for (var i = 0; i < 100 && find.text('名字滚动中…').evaluate().isEmpty; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await tester.pump();
  }
  expect(find.text('名字滚动中…'), findsOneWidget);
  await tester.pump();
}

Finder verticalScroll() => find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .first;
