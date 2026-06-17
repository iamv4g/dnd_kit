import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';

import 'models.dart';

List<KanbanColumn> cloneColumns(List<KanbanColumn> columns) {
  return List<KanbanColumn>.unmodifiable(
    columns.map((column) => column.copyWith(tasks: column.tasks.toList())),
  );
}

DndId columnDndId(String id) => DndId('column:$id');

DndId taskDndId(String id) => DndId('task:$id');

String? taskIdFromDndId(DndId id) {
  const prefix = 'task:';
  return id.value.startsWith(prefix) ? id.value.substring(prefix.length) : null;
}
