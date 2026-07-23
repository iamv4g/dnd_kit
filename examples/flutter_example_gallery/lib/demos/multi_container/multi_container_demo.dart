import 'dart:math' as math;

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
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xff090d16),
                Color(0xff111827),
                Color(0xff1f2937),
              ],
            ),
          ),
          child: Stack(
            children: [
              SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                    colors: [
                                      Color(0xff8b5cf6),
                                      Color(0xff06b6d4)
                                    ],
                                  ).createShader(bounds),
                                  child: const Text(
                                    'Interactive Board',
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Experimental Multi-Container Sortable Showcase (Web Only)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xff8b5cf6)
                                  .withValues(alpha: 0.15),
                              border: Border.all(
                                color: const Color(0xff8b5cf6)
                                    .withValues(alpha: 0.35),
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.bolt,
                                    size: 16, color: Color(0xffa78bfa)),
                                SizedBox(width: 4),
                                Text(
                                  'v1.0-dev',
                                  style: TextStyle(
                                    color: Color(0xffa78bfa),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Column Layout
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final container in _containers)
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  child: BoardColumnWidget(
                                    container: container,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Floating Drag Overlay
              DndDragOverlay(
                builder: (context, details) {
                  final taskId = details.activeId.value;
                  final task = tasks[taskId];
                  if (task == null) return const SizedBox.shrink();

                  return Transform.rotate(
                    angle: math.pi / 60,
                    child: TaskCardContent(
                      task: task,
                      isDraggingOverlay: true,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
