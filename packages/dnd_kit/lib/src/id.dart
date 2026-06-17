/// Stable identifier used for draggables, droppables, containers, and sortable
/// items.
final class DndId {
  /// Creates an identifier from a stable string value.
  const DndId(this.value) : assert(value.length > 0, 'DndId value must not be empty.');

  /// The application-owned stable identifier value.
  final String value;

  @override
  bool operator ==(Object other) => other is DndId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'DndId($value)';
}
