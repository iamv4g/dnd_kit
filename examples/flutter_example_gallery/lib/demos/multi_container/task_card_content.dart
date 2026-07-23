import 'package:flutter/material.dart';

import 'task_item.dart';

/// A Kanban card rendered in plain Material style, matching the other demos.
class TaskCardContent extends StatelessWidget {
  const TaskCardContent({
    super.key,
    required this.task,
    this.isDraggingOverlay = false,
    this.isHovered = false,
  });

  final TaskItem task;
  final bool isDraggingOverlay;
  final bool isHovered;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHovered || isDraggingOverlay
              ? scheme.primary
              : scheme.outlineVariant,
        ),
        boxShadow: isDraggingOverlay
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _PriorityChip(priority: task.priority),
              const Spacer(),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: task.color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            task.title,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            task.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.account_circle_outlined,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                task.owner,
                style: textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.drag_indicator,
                size: 16,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});

  final String priority;

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      'High' => Colors.red.shade600,
      'Medium' => Colors.amber.shade700,
      'Low' => Colors.green.shade600,
      _ => Theme.of(context).colorScheme.outline,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
