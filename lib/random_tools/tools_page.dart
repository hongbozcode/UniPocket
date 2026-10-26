import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../ui/design.dart';
import 'toss_page.dart';
import '../semesters/planner.dart';
import 'wheel_page.dart';

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
        builder: (context, constraints) => Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: (constraints.maxWidth - 12) / 2,
              child: Material(
                color: const Color(0xffeee8fc),
                borderRadius: BorderRadius.circular(24),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) =>
                          WheelPage(planner: planner, random: random),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: SvgPicture.asset(
                            'docs/design/resources/illustrations/wheel.svg',
                            width: 100,
                            height: 100,
                            excludeFromSemantics: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '转盘',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '自定义你的选择',
                          style: TextStyle(color: Color(0xff73819a)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            for (final tool in TossTool.values)
              SizedBox(
                width: (constraints.maxWidth - 12) / 2,
                child: Material(
                  color: tool.surface,
                  borderRadius: BorderRadius.circular(24),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => TossPage(tool: tool, random: random),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: SvgPicture.asset(
                              'docs/design/resources/illustrations/${tool.name}.svg',
                              width: 100,
                              height: 100,
                              excludeFromSemantics: true,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            tool.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            tool == TossTool.die ? '一颗六面骰' : '正面还是反面',
                            style: const TextStyle(color: Color(0xff73819a)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}
