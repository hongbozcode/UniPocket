class GroupMember {
  const GroupMember({required this.id, required this.name, this.detail = ''});
  final int id;
  final String name;
  final String detail;
  String get identification =>
      detail.isEmpty ? '成员 ${id.toString().padLeft(4, '0')}' : detail;
}

class GroupList {
  GroupList({
    required this.id,
    required this.name,
    required List<GroupMember> members,
  }) : members = List.unmodifiable(members);
  final int id;
  final String name;
  final List<GroupMember> members;
}

enum GroupMode { count, limit }
