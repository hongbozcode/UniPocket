class RollCallMember {
  const RollCallMember({
    required this.id,
    required this.name,
    this.detail = '',
  });
  final int id;
  final String name;
  final String detail;
  String get identification =>
      detail.isEmpty ? '成员 ${id.toString().padLeft(4, '0')}' : detail;
}

class RollCallList {
  RollCallList({
    required this.id,
    required this.name,
    required List<RollCallMember> members,
    this.repeat = false,
    this.round = 1,
    this.revision = 0,
    List<int> drawn = const [],
  }) : members = List.unmodifiable(members),
       drawn = List.unmodifiable(drawn);
  final int id;
  final String name;
  final List<RollCallMember> members;
  final bool repeat;
  final int round;
  final int revision;
  final List<int> drawn;
  List<RollCallMember> get candidates =>
      repeat ? members : members.where((m) => !drawn.contains(m.id)).toList();
  RollCallMember? get last => drawn.isEmpty ? null : member(drawn.last);
  RollCallMember member(int id) => members.firstWhere((m) => m.id == id);
}

/// A selected result stays provisional until feedback completes. Repeated
/// completion shares the same write; a cancelled feedback can never commit.
class RollCallDraw {
  RollCallDraw(this.member, this._commit);
  final RollCallMember member;
  final Future<RollCallList> Function() _commit;
  bool _cancelled = false;
  Future<RollCallList>? _completion;
  void cancel() {
    if (_completion == null) _cancelled = true;
  }

  Future<RollCallList> complete() {
    if (_cancelled) return Future.error(StateError('点名已取消，未消耗轮次'));
    return _completion ??= _commit();
  }
}
