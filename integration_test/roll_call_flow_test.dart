import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

import '../test/support/roll_call_random.dart';
import '../test/support/widget_actions.dart';

const databaseName = String.fromEnvironment(
  'ACCEPTANCE_DATABASE',
  defaultValue: 'unipocket_roll_call_acceptance',
);
const restore = bool.fromEnvironment('ACCEPTANCE_RESTORE');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  testWidgets('Android 点名名单、结果和轮次跨进程恢复，返回取消不消耗', (tester) async {
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
        UniPocketApp(
          planner: planner,
          random: RollCallRandom(restore ? [(2, 1)] : [(3, 0), (2, 1)]),
        ),
      );
      await waitFor(tester, find.text('UniPocket'));
      await binding.convertFlutterSurfaceToImage();
      await tapVisible(tester, find.text('工具'));
      await capture(restore ? '12-android-tools-restored' : '12-android-tools');
      await tapVisible(tester, find.text('随机点名'));
      if (!restore) {
        await waitFor(tester, find.text('新建名单'));
        await capture('12-android-empty');
        await tapVisible(tester, find.text('新建名单'));
        await tester.enterText(
          find.widgetWithText(TextFormField, '名单名称'),
          '高数学习小组',
        );
        final names = ['林晓', '林晓', '许诺'];
        final details = ['学号 20260112', '学号 20260113 · 组长', '学号 20260004'];
        for (var i = 1; i <= names.length; i++) {
          if (i > 1) await tapVisible(tester, find.text('添加成员'));
          await tester.enterText(
            find.byKey(ValueKey('member-name-$i')),
            names[i - 1],
          );
          await tester.enterText(
            find.byKey(ValueKey('member-detail-$i')),
            details[i - 1],
          );
        }
        await tapVisible(tester, find.text('保存到本机'));
        await waitFor(tester, find.text('高数学习小组 · 3人'));
        await capture('12-android-ready');
        await tapVisible(tester, find.byKey(const ValueKey('roll-call-draw')));
        await waitFor(tester, find.text('本次抽中'));
        expect((await planner.loadRollCallLists()).single.drawn, [1]);
        await capture('12-android-result');
        await tester.drag(
          find
              .byWidgetPredicate(
                (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
              )
              .first,
          const Offset(0, -500),
        );
        await tester.pumpAndSettle();
        await binding.takeScreenshot('12-android-history');
        await tapVisible(tester, find.text('管理名单'));
        await binding.takeScreenshot('12-android-edit-confirm');
        await tapVisible(tester, find.text('继续编辑'));
        await tester.enterText(
          find.widgetWithText(TextFormField, '名单名称'),
          '不保存',
        );
        await tapVisible(tester, find.byTooltip('取消编辑'));
        expect((await planner.loadRollCallLists()).single.drawn, [1]);
        final draw = find.byKey(const ValueKey('roll-call-draw'));
        await tester.ensureVisible(draw);
        await tester.pumpAndSettle();
        await tester.tap(draw);
        for (var i = 0; i < 30 && find.text('名字滚动中…').evaluate().isEmpty; i++) {
          await tester.pump(const Duration(milliseconds: 10));
        }
        expect(find.text('名字滚动中…'), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 1200));
        expect(find.text('名字滚动中…'), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect((await planner.loadRollCallLists()).single.drawn, [1]);
        await tapVisible(tester, find.text('随机点名'));
        await waitFor(tester, find.text('高数学习小组 · 3人'));
        await tapVisible(tester, find.text('高数学习小组 · 3人'));
        await tapVisible(tester, find.text('新建名单'));
        await tester.enterText(
          find.widgetWithText(TextFormField, '名单名称'),
          '活动点名',
        );
        await tapVisible(tester, find.byTooltip('移除成员 1'));
        await tapVisible(tester, find.text('保存到本机'));
        await waitFor(tester, find.text('活动点名 · 0人'));
        await capture('12-android-empty-list');
      } else {
        await waitFor(tester, find.text('高数学习小组 · 3人'));
        final lists = await planner.loadRollCallLists();
        expect(lists.map((l) => l.name), ['高数学习小组', '活动点名']);
        expect(lists.first.drawn, [1]);
        expect(lists.first.members.map((m) => m.id), [1, 2, 3]);
        expect(lists.first.members[1].detail, '学号 20260113 · 组长');
        await capture('12-android-process-restored');
        await tapVisible(tester, find.byKey(const ValueKey('roll-call-draw')));
        await waitFor(tester, find.text('本次抽中'));
        expect((await planner.loadRollCallLists()).first.drawn, [1, 3]);
        await capture('12-android-resumed-result');
        await tapVisible(tester, find.text('高数学习小组 · 3人'));
        await binding.takeScreenshot('12-android-picker');
        await tapVisible(tester, find.text('活动点名'));
        await waitFor(tester, find.text('活动点名 · 0人'));
      }
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await store.close();
    }
  });
}
