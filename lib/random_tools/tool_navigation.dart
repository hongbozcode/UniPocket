import 'dart:math';

import 'package:flutter/material.dart';

import '../semesters/planner.dart';
import 'groups_page.dart';
import 'lottery_page.dart';
import 'roll_call_page.dart';
import 'tool_library.dart';
import 'toss_page.dart';
import 'wheel_page.dart';

Future<void> openRandomTool(
  BuildContext context,
  SemesterPlanner planner,
  RandomTool tool, {
  Random? random,
}) async {
  try {
    await planner.recordToolUse(tool);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('最近使用记录保存失败，工具仍可使用。')));
    }
  }
  if (!context.mounted) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => switch (tool) {
        RandomTool.wheel => WheelPage(planner: planner, random: random),
        RandomTool.rollCall => RollCallPage(planner: planner, random: random),
        RandomTool.groups => GroupsPage(planner: planner, random: random),
        RandomTool.lottery => LotteryPage(planner: planner, random: random),
        RandomTool.die => TossPage(tool: TossTool.die, random: random),
        RandomTool.coin => TossPage(tool: TossTool.coin, random: random),
      },
    ),
  );
}
