import 'dart:math';

import 'package:flutter/material.dart';

import '../semesters/planner.dart';
import '../ui/design.dart';
import 'tool_library.dart';
import 'tool_navigation.dart';
import 'tools_page.dart';

class HomeTools extends StatefulWidget {
  const HomeTools({
    required this.planner,
    required this.onAll,
    this.random,
    super.key,
  });
  final SemesterPlanner planner;
  final VoidCallback onAll;
  final Random? random;

  @override
  State<HomeTools> createState() => _HomeToolsState();
}

class _HomeToolsState extends State<HomeTools> {
  ToolLibrary? _library;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final library = await widget.planner.loadToolLibrary();
      if (mounted) {
        setState(() {
          _library = library;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _error = '常用工具读取失败');
    }
  }

  Future<void> _open(RandomTool tool) async {
    if (_busy) return;
    setState(() => _busy = true);
    await openRandomTool(context, widget.planner, tool, random: widget.random);
    if (mounted) {
      await _load();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const DesignIcon('grid'),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                '常用工具',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(onPressed: widget.onAll, child: const Text('全部工具')),
          ],
        ),
        const SizedBox(height: 12),
        if (_error != null) ...[
          Text(_error!),
          TextButton(onPressed: _load, child: const Text('重试')),
        ] else if (_library == null)
          const Center(child: CircularProgressIndicator())
        else
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tool in _library!.homeTools)
                  SizedBox(
                    width: (constraints.maxWidth - 8) / 2,
                    child: Material(
                      color: Color(tool.surface),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        key: ValueKey('home-tool-${tool.name}'),
                        borderRadius: BorderRadius.circular(16),
                        onTap: _busy ? null : () => _open(tool),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: LayoutBuilder(
                            builder: (context, box) {
                              final compact =
                                  box.maxWidth < 115 ||
                                  MediaQuery.textScalerOf(context).scale(14) >
                                      20;
                              final label = Text(
                                tool.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              );
                              return compact
                                  ? Column(
                                      children: [
                                        ToolArt(tool, size: 40),
                                        const SizedBox(height: 6),
                                        label,
                                      ],
                                    )
                                  : Row(
                                      children: [
                                        ToolArt(tool, size: 36),
                                        const SizedBox(width: 8),
                                        Expanded(child: label),
                                        const Icon(
                                          Icons.chevron_right,
                                          size: 16,
                                        ),
                                      ],
                                    );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    ),
  );
}
