import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/material.dart';

import 'draggable_card.dart';
import 'task_item.dart';

/// A Kanban column in plain Material style: a surface panel with a header and
/// its own scrollable card list.
class BoardColumnWidget extends StatelessWidget {
  const BoardColumnWidget({
    super.key,
    required this.container,
  });

  final SortableContainer container;

  String get _title {
    switch (container.id.value) {
      case 'backlog':
        return 'Backlog';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      default:
        return container.id.value;
    }
  }

  IconData get _icon {
    switch (container.id.value) {
      case 'backlog':
        return Icons.folder_open_outlined;
      case 'in_progress':
        return Icons.incomplete_circle_outlined;
      case 'completed':
        return Icons.task_alt_outlined;
      default:
        return Icons.list_alt_outlined;
    }
  }

  Color get _accent {
    switch (container.id.value) {
      case 'backlog':
        return Colors.orange;
      case 'in_progress':
        return Colors.cyan;
      case 'completed':
        return Colors.green;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SortableMultiContainerArea(
      id: container.id,
      itemIds: container.itemIds,
      builder: (context, details, child) {
        final isOver = details.isOver;
        return AnimatedContainer(
          key: ValueKey('column-drop:${container.id.value}'),
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isOver ? scheme.primary : scheme.outlineVariant,
              width: isOver ? 1.5 : 1,
            ),
          ),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(_icon, color: _accent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _title,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${container.itemIds.length}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // The column has a fixed height (its parent stretches it), so this
            // list scrolls its own cards.
            Expanded(
              child: Builder(
                builder: (context) {
                  final visibleIds = <DndId>[
                    for (final itemId in container.itemIds)
                      if (tasks[itemId.value] != null) itemId,
                  ];
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: visibleIds.length,
                    // Relocate keyed cards when the order changes instead of
                    // rebuilding them, so dnd_kit registrations stay stable
                    // across reorders in a lazy list.
                    findChildIndexCallback: (key) {
                      final value = (key as ValueKey<String>).value;
                      final id = value.replaceFirst('task-padding:', '');
                      final index = visibleIds.indexWhere((e) => e.value == id);
                      return index < 0 ? null : index;
                    },
                    itemBuilder: (context, index) {
                      final itemId = visibleIds[index];
                      return Padding(
                        key: ValueKey('task-padding:${itemId.value}'),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DraggableCard(
                          key: ValueKey('task-card:${itemId.value}'),
                          task: tasks[itemId.value]!,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
