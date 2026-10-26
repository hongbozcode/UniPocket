import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

import '../test/support/candidate_random.dart';
import '../test/support/widget_actions.dart';

const databaseName = String.fromEnvironment(
  'ACCEPTANCE_DATABASE',
  defaultValue: 'unipocket_wheel_acceptance',
);
const restore = bool.fromEnvironment('ACCEPTANCE_RESTORE');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  testWidgets('Android 命名保存、全部候选落位、编辑与进程重启恢复', (tester) async {
    final store = PlannerStore.open(name: databaseName);
    final planner = SemesterPlanner(store);
    const options = ['食堂一楼', '食堂二楼', '面馆', '盖饭', '轻食', '饺子'];
    Future<void> capture(String name) async {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 10000));
      await tester.pumpAndSettle();
      await binding.takeScreenshot(name);
    }

    try {
      await tester.pumpWidget(
        UniPocketApp(
          planner: planner,
          random: CandidateRandom(restore ? [2] : [0, 1, 2, 3, 4, 5], 6),
        ),
      );
      await waitFor(tester, find.text('UniPocket'));
      await binding.convertFlutterSurfaceToImage();
      await tapVisible(tester, find.text('工具'));
      await capture(restore ? '11-android-tools-restored' : '11-android-tools');
      await tapVisible(tester, find.text('转盘'));
      if (!restore) {
        await waitFor(tester, find.text('新建转盘'));
        await capture('11-android-empty');
        await tapVisible(tester, find.text('新建转盘'));
        await tester.enterText(
          find.widgetWithText(TextFormField, '列表名称'),
          '午餐怎么选',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, '选项（每行一项）'),
          options.join('\n'),
        );
        await tapVisible(tester, find.text('保存到本机'));
        await waitFor(tester, find.text('午餐怎么选 · 6项'));
        await capture('11-android-ready');
        for (var i = 0; i < options.length; i++) {
          await tapVisible(tester, find.byKey(const ValueKey('wheel-spin')));
          expect(
            tester
                .widget<Text>(find.byKey(const ValueKey('wheel-result')))
                .data,
            options[i],
          );
          await capture('11-android-result-${i + 1}');
        }
        await tapVisible(tester, find.text('午餐怎么选 · 6项'));
        await tapVisible(tester, find.text('新建转盘'));
        await tester.enterText(
          find.widgetWithText(TextFormField, '列表名称'),
          '周末',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, '选项（每行一项）'),
          '散步\n散步',
        );
        await tester.pump();
        expect(find.textContaining('有重复文字'), findsOneWidget);
        await capture('11-android-duplicates');
        await tapVisible(tester, find.text('保存到本机'));
        await waitFor(tester, find.text('周末 · 2项'));
        await tapVisible(tester, find.text('编辑选项'));
        await tester.enterText(
          find.widgetWithText(TextFormField, '列表名称'),
          '周末计划',
        );
        await tapVisible(tester, find.text('保存到本机'));
        await waitFor(tester, find.text('周末计划 · 2项'));
      } else {
        await waitFor(tester, find.text('午餐怎么选 · 6项'));
        expect(find.text('等待转动'), findsOneWidget);
        final lists = await planner.loadWheelLists();
        expect(lists.map((l) => l.name), ['午餐怎么选', '周末计划']);
        expect(lists.last.items, ['散步', '散步']);
        await tapVisible(tester, find.byKey(const ValueKey('wheel-spin')));
        expect(find.text('面馆'), findsOneWidget);
        await capture('11-android-process-restored');
        await tapVisible(tester, find.text('午餐怎么选 · 6项'));
        await tapVisible(tester, find.text('周末计划'));
        await capture('11-android-list-restored');
      }
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await store.close();
    }
  });
}
