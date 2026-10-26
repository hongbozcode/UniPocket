/// Entries keep their order and identity by position, including equal text.
class WheelList {
  WheelList({required this.id, required this.name, required List<String> items})
    : items = List.unmodifiable(items);
  final int id;
  final String name;
  final List<String> items;
}
