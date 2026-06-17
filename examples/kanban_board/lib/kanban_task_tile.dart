import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/material.dart';

import 'kanban_board_utils.dart';
import 'models.dart';

class KanbanTaskTile extends StatelessWidget {
  const KanbanTaskTile({
    super.key,
    required this.columnId,
    required this.task,
    required this.onDragEnd,
  });

  final String columnId;
  final KanbanTask task;
  final DndDragEndCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final id = taskDndId(task.id);
    return DndDroppable(
      key: ValueKey<String>('task-drop:${task.id}'),
      id: id,
      data: KanbanDropData(
        columnId: columnId,
        taskId: task.id,
      ),
      child: DndDraggable(
        key: ValueKey<String>('drag:${task.id}'),
        id: id,
        data: KanbanTaskDragData(
          columnId: columnId,
          taskId: task.id,
        ),
        // Default platform-adaptive activation: drag immediately with a mouse,
        // but require a short hold on touch so a quick swipe scrolls the column
        // instead of starting a drag.
        onDragEnd: onDragEnd,
        builder: (context, details, child) {
          return AnimatedOpacity(
            duration: const Duration(milliseconds: 100),
            opacity: details.isDragging ? 0.36 : 1,
            child: child,
          );
        },
        child: KanbanTaskCard(
          key: ValueKey<String>('task:${task.id}'),
          task: task,
        ),
      ),
    );
  }
}

class KanbanTaskCard extends StatelessWidget {
  const KanbanTaskCard({
    super.key,
    required this.task,
    this.elevated = false,
  });

  final KanbanTask task;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xffffffff),
      elevation: elevated ? 8 : 1,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: task.accent,
              width: 4,
            ),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              task.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    task.owner,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
