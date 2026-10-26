class LotteryPool {
  LotteryPool({
    required this.id,
    required this.name,
    required List<String> items,
    this.repeat = false,
    this.round = 1,
    this.revision = 0,
    List<int> drawn = const [],
  }) : items = List.unmodifiable(items),
       drawn = List.unmodifiable(drawn);
  final int id;
  final String name;
  final List<String> items;
  final bool repeat;
  final int round;
  final int revision;

  /// Positions identify separate tickets even when their text is identical.
  final List<int> drawn;
  List<int> get candidates => [
    for (var i = 0; i < items.length; i++)
      if (repeat || !drawn.contains(i)) i,
  ];
  String? get last => drawn.isEmpty ? null : items[drawn.last];
}

/// Feedback owns a provisional selection; only completion consumes a ticket.
class LotteryDraw {
  LotteryDraw(this.text, this._commit);
  final String text;
  final Future<LotteryPool> Function() _commit;
  bool _cancelled = false;
  Future<LotteryPool>? _completion;
  void cancel() {
    if (_completion == null) _cancelled = true;
  }

  Future<LotteryPool> complete() {
    if (_cancelled) return Future.error(StateError('抽签已取消，未消耗轮次'));
    return _completion ??= _commit();
  }
}
