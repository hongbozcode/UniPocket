/// Stable identifiers for the six released tools. Never persist enum indexes.
enum RandomTool {
  wheel('转盘', '今天怎么选', 'wheel', 0xffe9f2ff),
  rollCall('随机点名', '下一位是谁', 'badge', 0xfff0eaff),
  groups('随机分组', '轻松分成几组', 'groups', 0xfffff5d0),
  lottery('抽签', '抽个好签', 'lottery-bag', 0xffffebde),
  die('掷骰子', '一颗六面骰', 'die', 0xffe7f5ee),
  coin('抛硬币', '正面还是反面', 'coin', 0xfffceff5);

  const RandomTool(this.title, this.subtitle, this.art, this.surface);
  final String title;
  final String subtitle;
  final String art;
  final int surface;
}

enum ToolFilter { all, favorites, recent }

class ToolUsage {
  const ToolUsage({this.isFavorite = false, this.lastOpened = 0});
  final bool isFavorite;
  // Monotonic order, independent of clock changes and timestamp collisions.
  final int lastOpened;
}

class ToolLibrary {
  ToolLibrary(Map<RandomTool, ToolUsage> usage)
    : _usage = Map.unmodifiable(usage);
  final Map<RandomTool, ToolUsage> _usage;

  bool isFavorite(RandomTool tool) => _usage[tool]?.isFavorite ?? false;

  List<RandomTool> tools({
    ToolFilter filter = ToolFilter.all,
    String query = '',
  }) {
    final search = query.trim().toLowerCase();
    final result = RandomTool.values.where((tool) {
      final usage = _usage[tool] ?? const ToolUsage();
      final included = switch (filter) {
        ToolFilter.all => true,
        ToolFilter.favorites => usage.isFavorite,
        ToolFilter.recent => usage.lastOpened > 0,
      };
      return included &&
          '${tool.title} ${tool.subtitle}'.toLowerCase().contains(search);
    }).toList();
    if (filter == ToolFilter.recent) {
      result.sort(
        (a, b) => _usage[b]!.lastOpened.compareTo(_usage[a]!.lastOpened),
      );
    }
    return result;
  }

  /// Favorites first, then recent tools; give new users working shortcuts too.
  List<RandomTool> get homeTools => {
    ...tools(filter: ToolFilter.favorites),
    ...tools(filter: ToolFilter.recent),
    ...RandomTool.values,
  }.take(2).toList();
}
