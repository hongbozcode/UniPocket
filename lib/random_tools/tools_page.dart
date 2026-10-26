import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../semesters/planner.dart';
import '../ui/design.dart';
import 'toss_page.dart';
import 'wheel_page.dart';
import 'roll_call_page.dart';
import 'lottery_page.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({required this.planner, this.random, super.key});
  final SemesterPlanner planner;
  final Random? random;

  @override
  Widget build(BuildContext context) => PageContent(
    children: [
      const Row(
        children: [
          DesignIcon('badge', color: primaryBlue),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'UniPocket',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      const PageHeading('随机工具箱', '给纠结一点灵感', art: 'badge'),
      LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - 12) / 2;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ToolCard(
                width: width,
                title: '转盘',
                subtitle: '自定义你的选择',
                art: 'wheel',
                surface: const Color(0xffeee8fc),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => WheelPage(planner: planner, random: random),
                  ),
                ),
              ),
              _ToolCard(
                width: width,
                title: '随机点名',
                subtitle: '下一位是谁',
                art: 'badge',
                surface: const Color(0xffeee8fc),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) =>
                        RollCallPage(planner: planner, random: random),
                  ),
                ),
              ),
              _ToolCard(
                width: width,
                title: '抽签',
                subtitle: '抽一份小期待',
                art: 'lottery-bag',
                surface: const Color(0xffffe7d7),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) =>
                        LotteryPage(planner: planner, random: random),
                  ),
                ),
              ),
              for (final tool in TossTool.values)
                _ToolCard(
                  width: width,
                  title: tool.title,
                  subtitle: tool == TossTool.die ? '一颗六面骰' : '正面还是反面',
                  art: tool.name,
                  surface: tool.surface,
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => TossPage(tool: tool, random: random),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.art,
    required this.surface,
    required this.onTap,
  });
  final double width;
  final String title;
  final String subtitle;
  final String art;
  final Color surface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Material(
      color: surface,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: art == 'lottery-bag'
                    ? Image.asset(
                        'docs/design/resources/illustrations/lottery-bag.png',
                        width: 100,
                        height: 100,
                        excludeFromSemantics: true,
                      )
                    : SvgPicture.asset(
                        'docs/design/resources/illustrations/$art.svg',
                        width: 100,
                        height: 100,
                        excludeFromSemantics: true,
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(subtitle, style: const TextStyle(color: Color(0xff73819a))),
            ],
          ),
        ),
      ),
    ),
  );
}
