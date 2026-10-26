import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unipocket/random_tools/groups.dart';
import 'package:unipocket/random_tools/groups_page.dart';
import 'package:unipocket/random_tools/group_editor.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';
import 'package:unipocket/ui/design.dart';

import 'support/widget_actions.dart';

Finder verticalScroll() => find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .first;

void main() {
  testWidgets('长名单离屏空姓名保存时显示明确原因且原数据保留', (tester) async {
    await tester.runAsync(() async {
      final store = PlannerStore(NativeDatabase.memory());
      final planner = SemesterPlanner(store);
      try {
        final list = await planner.saveGroupList(
          name: '名单',
          members: [
            for (var i = 1; i <= 20; i++) GroupMember(id: i, name: '同学$i'),
          ],
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: appTheme(),
            home: GroupEditor(planner: planner, list: list),
          ),
        );
        await tester.enterText(
          find.byKey(const ValueKey('member-name-1')),
          ' ',
        );
        await tapVisible(tester, find.text('保存到本机'));
        await waitFor(tester, find.text('成员姓名不能为空，成员身份必须独立'));
        expect(
          (await planner.loadGroupLists()).single.members.first.name,
          '同学1',
        );
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await store.close();
      }
    });
  });
  testWidgets('大名单可到末组，减少动效、系统返回和重新进入清理结果', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.runAsync(() async {
      final store = PlannerStore(NativeDatabase.memory());
      final planner = SemesterPlanner(store);
      var reduce = true;
      try {
        await planner.saveGroupList(
          name: '40人名单',
          members: [
            for (var i = 1; i <= 40; i++) GroupMember(id: i, name: '同学$i'),
          ],
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: appTheme(),
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () => Navigator.push<void>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MediaQuery(
                          data: MediaQuery.of(context)
                              .copyWith(disableAnimations: reduce),
                          child: GroupsPage(
                            planner: planner,
                            random: Random(1),
                          ),
                        ),
                      ),
                    ),
                    child: const Text('打开分组'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tapVisible(tester, find.text('打开分组'));
        await waitFor(tester, find.text('40人名单 · 40人'));
        await tapVisible(tester, find.text('按组数'));
        await tester.enterText(
          find.byKey(const ValueKey('group-amount')),
          '20',
        );
        await tapVisible(tester, find.byKey(const ValueKey('group-start')));
        await waitFor(tester, find.byKey(const ValueKey('group-result')));
        await tester.scrollUntilVisible(
          find.text('第20组'),
          400,
          scrollable: verticalScroll(),
          maxScrolls: 50,
        );
        expect(find.text('第20组').hitTestable(), findsOneWidget);
        expect(find.text('2 人'), findsNWidgets(20));
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        reduce = false;
        await tapVisible(tester, find.text('打开分组'));
        await waitFor(tester, find.text('40人名单 · 40人'));
        expect(find.byKey(const ValueKey('group-result')), findsNothing);
        final start = find.byKey(const ValueKey('group-start'));
        await tester.ensureVisible(start);
        await tester.pumpAndSettle();
        await tester.tap(start);
        for (
          var i = 0;
          i < 100 && find.text('先洗洗牌，再认识新的伙伴').evaluate().isEmpty;
          i++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 10));
          await tester.pump();
        }
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tapVisible(tester, find.text('打开分组'));
        await waitFor(tester, find.text('40人名单 · 40人'));
        expect(find.byKey(const ValueKey('group-result')), findsNothing);
        expect(find.text('取消分组'), findsNothing);
        expect((await planner.loadGroupLists()).single.members.length, 40);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await store.close();
      }
    });
  });
  for (final width in [320.0, 393.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('$width 宽 $scale 倍字：完整横向标签、取消和非法参数', (tester) async {
        tester.view.physicalSize = Size(width, 850);
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
          const longName = '很长的姓名 English 名字完整可读';
          try {
            await planner.saveGroupList(
              name: '非常长的名单名称需要换行完整呈现',
              members: [
                for (var i = 1; i <= 10; i++)
                  GroupMember(
                    id: i,
                    name: i == 1 ? longName : '林晓',
                    detail: '学号 $i',
                  ),
              ],
            );
            await tester.pumpWidget(
              MaterialApp(
                theme: appTheme(),
                home: GroupsPage(planner: planner, random: Random(3)),
              ),
            );
            await waitFor(tester, find.text('每组最多'));
            await tester.enterText(
              find.byKey(const ValueKey('group-amount')),
              '0',
            );
            await tapVisible(tester, find.byKey(const ValueKey('group-start')));
            expect(find.text('请输入大于 0 的整数'), findsOneWidget);
            await tester.enterText(
              find.byKey(const ValueKey('group-amount')),
              '4',
            );
            await tester.ensureVisible(
              find.byKey(const ValueKey('group-start')),
            );
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const ValueKey('group-start')));
            for (
              var i = 0;
              i < 100 && find.text('先洗洗牌，再认识新的伙伴').evaluate().isEmpty;
              i++
            ) {
              await Future<void>.delayed(const Duration(milliseconds: 10));
              await tester.pump();
            }
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 200));
            expect(
              tester
                  .widget<FilledButton>(
                    find.byKey(const ValueKey('group-start')),
                  )
                  .onPressed,
              isNull,
            );
            await tester.ensureVisible(find.text('取消分组'));
            await tester.tap(find.text('取消分组'));
            await tester.pumpAndSettle();
            expect(find.text('已取消分组'), findsOneWidget);
            expect(find.byKey(const ValueKey('group-result')), findsNothing);
            await tester.ensureVisible(
              find.byKey(const ValueKey('group-start')),
            );
            await tester.tap(find.byKey(const ValueKey('group-start')));
            for (
              var i = 0;
              i < 100 && find.text('先洗洗牌，再认识新的伙伴').evaluate().isEmpty;
              i++
            ) {
              await Future<void>.delayed(const Duration(milliseconds: 10));
              await tester.pump();
            }
            for (final state in [
              AppLifecycleState.inactive,
              AppLifecycleState.hidden,
              AppLifecycleState.paused,
              AppLifecycleState.hidden,
              AppLifecycleState.inactive,
              AppLifecycleState.resumed,
            ]) {
              tester.binding.handleAppLifecycleStateChanged(state);
            }
            await tester.pumpAndSettle();
            expect(find.byKey(const ValueKey('group-result')), findsNothing);
            await tapVisible(tester, find.byKey(const ValueKey('group-start')));
            await waitFor(tester, find.byKey(const ValueKey('group-result')));
            await tester.scrollUntilVisible(
              find.text(longName),
              180,
              scrollable: verticalScroll(),
            );
            expect(find.text(longName), findsOneWidget);
            expect(find.text('学号 1'), findsOneWidget);
            expect(find.text('第1组'), findsOneWidget);
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox());
            await store.close();
          }
        });
      });
    }
  }
}
