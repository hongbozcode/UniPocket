import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../semesters/planner.dart';
import '../ui/design.dart';
import 'tool_library.dart';
import 'tool_navigation.dart';

class ToolsPage extends StatefulWidget {
  const ToolsPage({required this.planner, this.random, super.key});
  final SemesterPlanner planner;
  final Random? random;

  @override
  State<ToolsPage> createState() => _ToolsPageState();
}

class _ToolsPageState extends State<ToolsPage> {
  final _search = TextEditingController();
  ToolLibrary? _library;
  ToolFilter _filter = ToolFilter.all;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
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
      if (mounted) setState(() => _error = '工具记录读取失败，请重试。');
    }
  }

  Future<void> _favorite(RandomTool tool) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.planner.setToolFavorite(tool, !_library!.isFavorite(tool));
      await _load();
    } catch (_) {
      if (mounted) setState(() => _error = '收藏保存失败，请重试。');
    } finally {
      if (mounted) setState(() => _busy = false);
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
  Widget build(BuildContext context) {
    final tools = _library?.tools(filter: _filter, query: _search.text) ?? [];
    return PageContent(
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
        const SizedBox(height: 16),
        const PageHeading('随机工具箱', '给纠结一点灵感', art: 'badge', bottomSpacing: 16),
        TextField(
          key: const ValueKey('tool-search'),
          controller: _search,
          style: const TextStyle(fontSize: 14),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            hintText: '搜索工具',
            prefixIcon: const Padding(
              padding: EdgeInsets.all(12),
              child: DesignIcon('search'),
            ),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: '清空搜索',
                    onPressed: () => setState(_search.clear),
                    icon: const DesignIcon('close'),
                  ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xffe8edf5)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xffeaf0f7),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: Row(
              children: [
                for (final entry in [
                  (ToolFilter.all, '全部'),
                  (ToolFilter.favorites, '收藏'),
                  (ToolFilter.recent, '最近使用'),
                ])
                  Expanded(
                    child: Semantics(
                      selected: _filter == entry.$1,
                      child: TextButton(
                        onPressed: () => setState(() => _filter = entry.$1),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 10,
                          ),
                          backgroundColor: _filter == entry.$1
                              ? const Color(0xffd9c8fa)
                              : Colors.transparent,
                          foregroundColor: _filter == entry.$1
                              ? inkColor
                              : const Color(0xff73819a),
                        ),
                        child: Text(entry.$2, textAlign: TextAlign.center),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_error != null) ...[
          ProblemBanner(_error!),
          TextButton(onPressed: _load, child: const Text('重新读取工具记录')),
        ],
        if (_library == null && _error == null)
          const Center(child: CircularProgressIndicator()),
        if (_library != null && tools.isEmpty)
          SurfaceCard(
            child: Column(
              children: [
                const DesignIcon('search', size: 32),
                const SizedBox(height: 12),
                Text(
                  _search.text.trim().isNotEmpty
                      ? '没有找到相关工具'
                      : _filter == ToolFilter.favorites
                      ? '还没有收藏工具'
                      : '还没有使用记录',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  _search.text.trim().isNotEmpty
                      ? '试试工具名称，如「转盘」或「硬币」。'
                      : _filter == ToolFilter.favorites
                      ? '点击工具卡片上的星星，留住常用工具。'
                      : '打开一项工具后，就会出现在这里。',
                  textAlign: TextAlign.center,
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _filter = ToolFilter.all;
                    _search.clear();
                  }),
                  child: const Text('查看全部工具'),
                ),
              ],
            ),
          ),
        if (tools.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final tool in tools)
                  ToolCard(
                    tool: tool,
                    width: (constraints.maxWidth - 12) / 2,
                    favorite: _library!.isFavorite(tool),
                    onFavorite: _busy ? null : () => _favorite(tool),
                    onTap: _busy ? null : () => _open(tool),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class ToolArt extends StatelessWidget {
  const ToolArt(this.tool, {this.size = 80, super.key});
  final RandomTool tool;
  final double size;

  @override
  Widget build(BuildContext context) => tool.art == 'lottery-bag'
      ? Image.asset(
          'docs/design/resources/illustrations/lottery-bag.png',
          width: size,
          height: size,
          excludeFromSemantics: true,
        )
      : SvgPicture.asset(
          'docs/design/resources/illustrations/${tool.art}.svg',
          width: size,
          height: size,
          excludeFromSemantics: true,
        );
}

class ToolCard extends StatelessWidget {
  const ToolCard({
    required this.tool,
    required this.width,
    required this.favorite,
    required this.onFavorite,
    required this.onTap,
    super.key,
  });
  final RandomTool tool;
  final double width;
  final bool favorite;
  final VoidCallback? onFavorite;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Material(
      color: Color(tool.surface),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('tool-${tool.name}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 80,
                child: Stack(
                  children: [
                    Center(child: ToolArt(tool)),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: IconButton(
                        key: ValueKey('favorite-${tool.name}'),
                        tooltip: '${favorite ? '取消收藏' : '收藏'}${tool.title}',
                        isSelected: favorite,
                        onPressed: onFavorite,
                        icon: Icon(
                          favorite
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: favorite
                              ? primaryBlue
                              : const Color(0xff8d9bb0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tool.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tool.subtitle,
                style: const TextStyle(fontSize: 12, color: Color(0xff73819a)),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
