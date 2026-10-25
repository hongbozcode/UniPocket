import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:unipocket/app.dart';
import 'package:unipocket/semesters/planner.dart';
import 'package:unipocket/storage/planner_store.dart';

import '../test/support/widget_actions.dart';
import '../test/support/candidate_random.dart';

const databaseName = String.fromEnvironment(
  'ACCEPTANCE_DATABASE',
  defaultValue: 'unipocket_dice_coin_acceptance',
);

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();

  testWidgets('Android 工具入口、投掷结果、返回取消与源图对照', (tester) async {
    final store = PlannerStore.open(name: databaseName);
    final planner = SemesterPlanner(store);
    Future<void> capture(String name) async {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 10000));
      await tester.pumpAndSettle();
      await binding.takeScreenshot(name);
    }

    try {
      await tester.pumpWidget(
        UniPocketApp(
          planner: planner,
          random: CandidateRandom([0, 1, 2, 3, 4, 5], 6),
        ),
      );
      await waitFor(tester, find.text('UniPocket'));
      await binding.convertFlutterSurfaceToImage();
      await tapVisible(tester, find.text('工具'));
      await capture('10-android-tools');
      await tapVisible(tester, find.text('掷骰子'));
      expect(find.text('等待投掷'), findsOneWidget);
      await capture('10-android-die-ready');
      for (final point in [1, 2, 3, 4, 5, 6]) {
        await tapVisible(tester, find.byKey(const ValueKey('random-action')));
        expect(find.text('$point'), findsOneWidget);
        await capture('10-android-die-$point');
      }
      await tapVisible(tester, find.byTooltip('返回'));
      await tapVisible(tester, find.text('掷骰子'));
      expect(find.text('等待投掷'), findsOneWidget);

      // Recreate the application over the same real SQLite store to select the
      // two coin candidates at the external randomness boundary only.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        UniPocketApp(planner: planner, random: CandidateRandom([0, 1, 0], 2)),
      );
      await waitFor(tester, find.text('UniPocket'));
      await tapVisible(tester, find.text('工具'));
      await tapVisible(tester, find.text('抛硬币'));
      await capture('10-android-coin-ready');
      await tapVisible(tester, find.byKey(const ValueKey('random-action')));
      expect(find.text('正面'), findsOneWidget);
      await capture('10-android-coin-heads');
      await tapVisible(tester, find.byKey(const ValueKey('random-action')));
      expect(find.text('反面'), findsOneWidget);
      await capture('10-android-coin-tails');
      final action = find.byKey(const ValueKey('random-action'));
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await tester.tap(action);
      await tester.pump();
      expect(find.text('投掷中…'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tapVisible(tester, find.text('抛硬币'));
      expect(find.text('等待投掷'), findsOneWidget);
      await capture('10-android-coin-cancelled');
      expect((await planner.load()).semesters, isEmpty);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await store.close();
    }
  });
}
