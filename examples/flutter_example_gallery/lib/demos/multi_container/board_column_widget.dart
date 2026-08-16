import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/material.dart';

import '../../theme.dart';

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

  /// On the gallery ramp, not Material's stock swatches — three columns of
  /// unrelated primaries is what made the old board read as a wireframe.
  Color get _accent {
    switch (container.id.value) {
      case 'backlog':
        return GalleryTokens.apricot;
      case 'in_progress':
        return GalleryTokens.accent;
      case 'completed':
        return GalleryTokens.mint;
      default:
        return GalleryTokens.faint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SortableMultiContainerArea(
      id: container.id,
      itemIds: container.itemIds,
      builder: (context, details, child) {
        // A column is a recess the cards rest in, not an outlined box.
        return AnimatedContainer(
          key: ValueKey('column-drop:${container.id.value}'),
          duration: GalleryTokens.settle,
          curve: Curves.easeOutCubic,
          decoration: dropZoneDecoration(isOver: details.isOver),
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
                    _title.toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 1.2,
                      color: GalleryTokens.muted,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                  decoration: ShapeDecoration(
                    color: GalleryTokens.accent.withValues(alpha: 0.1),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    '${container.itemIds.length}',
                    style: const TextStyle(
                      color: GalleryTokens.accentDeep,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
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
