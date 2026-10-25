import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// File SQLite work continues outside the widget test's fake clock. Use this
/// inside runAsync to wait for its user-visible result instead of a fixed sleep.
Future<void> waitFor(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await tester.pumpAndSettle();
  }
  expect(finder, findsWidgets);
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  FocusManager.instance.primaryFocus?.unfocus();
  if (tester.testTextInput.isRegistered) tester.testTextInput.hide();
  await tester.pumpAndSettle();
  if (finder.evaluate().isEmpty) {
    final vertical = find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .first;
    await tester.drag(vertical, const Offset(0, 10000));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      finder,
      250,
      scrollable: vertical,
      maxScrolls: 60,
    );
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
