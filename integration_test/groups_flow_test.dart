import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

import '../test/support/widget_actions.dart';

const databaseName = String.fromEnvironment(
  'ACCEPTANCE_DATABASE',
  defaultValue: 'unipocket_groups_acceptance',
);
const restore = bool.fromEnvironment('ACCEPTANCE_RESTORE');
const names = ['陈安', '苏禾', '周屿', '许诺', '沈念', '唐棠', '顾言', '林晓', '林晓', '陆晨'];

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  testWidgets('Android 从工具页建名单、分组、取消、编辑与进程重启保留', (tester) async {
    final store = PlannerStore.open(name: databaseName);
    final planner = SemesterPlanner(store);
    Future<void> capture(String name) async {
      await tester.drag(
        find
            .byWidgetPredicate(
              (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
            )
            .first,
        const Offset(0, 10000),
      );
      await tester.pumpAndSettle();
      await binding.takeScreenshot(name);
    }

    try {
      await tester.pumpWidget(
        UniPocketApp(planner: planner, random: Random(14)),
      );
      await waitFor(tester, find.text('UniPocket'));
      await binding.convertFlutterSurfaceToImage();
      await tapVisible(tester, find.text('工具'));
      await capture(restore ? '14-android-tools-restored' : '14-android-tools');
      await tapVisible(tester, find.text('随机分组'));
      if (!restore) {
        await waitFor(tester, find.text('新建名单'));
        await capture('14-android-empty');
        await tapVisible(tester, find.text('新建名单'));
        await tapVisible(tester, find.text('保存到本机'));
        expect(find.text('请为名单命名'), findsOneWidget);
        await tester.enterText(
          find.widgetWithText(TextFormField, '名单名称'),
          '学习伙伴',
        );
        for (var i = 1; i <= names.length; i++) {
          if (i > 1) await tapVisible(tester, find.text('添加成员'));
          await tester.ensureVisible(find.byKey(ValueKey('member-name-$i')));
          await tester.enterText(
            find.byKey(ValueKey('member-name-$i')),
            names[i - 1],
          );
          if (i == 8 || i == 9) {
            await tester.enterText(
              find.byKey(ValueKey('member-detail-$i')),
              '20260$i',
            );
          }
        }
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await binding.takeScreenshot('14-android-editor');
        await tapVisible(tester, find.text('保存到本机'));
        await waitFor(tester, find.text('学习伙伴 · 10人'));
        await capture('14-android-ready');
      } else {
        await waitFor(tester, find.text('学习伙伴 · 10人'));
        expect(
          (await planner.loadGroupLists()).first.members.map((m) => m.name),
          names,
        );
        expect(
          (await planner.loadGroupLists()).first.members[8].detail,
          '202609',
        );
        await capture('14-android-process-restored');
      }
      final start = find.byKey(const ValueKey('group-start'));
      await tapVisible(tester, start);
      await waitFor(tester, find.byKey(const ValueKey('group-result')));
      expect(find.text('4 人'), findsOneWidget);
      expect(find.text('3 人'), findsNWidgets(2));
      expect(find.text('林晓'), findsNWidgets(2));
      await capture(
        restore ? '14-android-result-restored' : '14-android-result',
      );
      await tapVisible(tester, find.text('编辑名单'));
      await tester.enterText(
        find.widgetWithText(TextFormField, '名单名称'),
        '取消编辑的草稿',
      );
      await tapVisible(tester, find.byTooltip('取消编辑'));
      expect((await planner.loadGroupLists()).first.name, '学习伙伴');
      await tapVisible(tester, find.text('按组数'));
      await tester.enterText(find.byKey(const ValueKey('group-amount')), '11');
      await tapVisible(tester, start);
      await waitFor(tester, find.text('组数不能超过名单人数'));
      await binding.takeScreenshot('14-android-invalid');
      for (var i = 0; i < 7; i++) {
        await tapVisible(tester, find.byTooltip('减少数量'));
      }
      await tapVisible(tester, start);
      await waitFor(tester, find.byKey(const ValueKey('group-result')));
      expect(find.text('第4组'), findsOneWidget);
      await capture('14-android-count-result');
      if (!restore) {
        await tapVisible(tester, find.text('学习伙伴 · 10人'));
        await binding.takeScreenshot('14-android-picker');
        await tapVisible(tester, find.text('新建名单'));
        await tester.enterText(
          find.widgetWithText(TextFormField, '名单名称'),
          '第二份空名单',
        );
        await tapVisible(tester, find.byTooltip('移除成员 1'));
        await tapVisible(tester, find.text('保存到本机'));
        await waitFor(tester, find.text('名单为空，请编辑名单添加成员后再分组。'));
        await capture('14-android-empty-list');
      } else {
        await tapVisible(tester, find.text('学习伙伴 · 10人'));
        expect(find.text('第二份空名单'), findsOneWidget);
        await binding.takeScreenshot('14-android-picker-restored');
      }
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await store.close();
    }
  });
}
