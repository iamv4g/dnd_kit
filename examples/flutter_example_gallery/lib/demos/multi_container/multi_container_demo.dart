import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/material.dart';

import 'board_column_widget.dart';
import 'task_card_content.dart';
import 'task_item.dart';

/// The `multi-container` catalog demo: move cards within and across columns on
/// the supported `SortableMultiScope` surface (Kanban shape).
class MultiContainerDemo extends StatefulWidget {
  const MultiContainerDemo({super.key});

  @override
  State<MultiContainerDemo> createState() => _MultiContainerDemoState();
}

class _MultiContainerDemoState extends State<MultiContainerDemo> {
  List<SortableContainer> _containers = [
    SortableContainer(
      id: const DndId('backlog'),
      itemIds: const [
        DndId('task-1'),
        DndId('task-2'),
      ],
    ),
    SortableContainer(
      id: const DndId('in_progress'),
      itemIds: const [
        DndId('task-3'),
        DndId('task-4'),
      ],
    ),
    SortableContainer(
      id: const DndId('completed'),
      itemIds: const [
        DndId('task-5'),
      ],
    ),
  ];

  void _handleMove(SortableMoveDetails move) {
    final fromId = move.fromContainerId;
    final toId = move.toContainerId;
    if (fromId == null || toId == null) {
      return;
    }

    setState(() {
      _containers = _applyMove(_containers, move);
    });
  }

  List<SortableContainer> _applyMove(
    List<SortableContainer> containers,
    SortableMoveDetails move,
  ) {
    final fromId = move.fromContainerId;
    final toId = move.toContainerId;
    if (fromId == null || toId == null) {
      return containers;
    }

    return containers.map((container) {
      final items = List<DndId>.from(container.itemIds);

      if (container.id == fromId) {
        items.removeAt(move.fromIndex);
      }

      if (container.id == toId) {
        final insertIndex = container.id == fromId
            ? move.toIndex.clamp(0, items.length)
            : move.toIndex.clamp(0, items.length);
        items.insert(insertIndex, move.activeId);
      }

      return SortableContainer(
        id: container.id,
        itemIds: items,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SortableMultiScope(
      containers: _containers,
      // Open a live gap within and across columns while dragging. The library
      // reports the per-card offset; the card builder animates it.
      offsetResolver: SortableMultiOffsets.verticalLists,
      onMove: _handleMove,
      child: Scaffold(
        appBar: AppBar(title: const Text('Multi-container board')),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Drag a card within a column or across to another. dnd_kit '
                    'reports the move; the board owns its data.',
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final container in _containers)
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: BoardColumnWidget(container: container),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // The dragged card floats here; the in-list copy is hidden.
            DndDragOverlay(
              builder: (context, details) {
                final task = tasks[details.activeId.value];
                if (task == null) return const SizedBox.shrink();

                // Leans while lifted, like every other picked-up object here.
                return Transform.rotate(
                  angle: 0.025,
                  child: Transform.scale(
                    scale: 1.03,
                    child: TaskCardContent(task: task, isDraggingOverlay: true),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
