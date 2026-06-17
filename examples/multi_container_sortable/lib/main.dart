import 'dart:math' as math;

import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/material.dart';

import 'board_column_widget.dart';
import 'collision_detector.dart';
import 'task_card_content.dart';
import 'task_item.dart';

void main() => runApp(const MultiContainerSortableApp());

class MultiContainerSortableApp extends StatelessWidget {
  const MultiContainerSortableApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'dnd_kit Multi-Container Sortable',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff8b5cf6),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const MultiContainerSortableExample(),
    );
  }
}

class MultiContainerSortableExample extends StatefulWidget {
  const MultiContainerSortableExample({super.key});

  @override
  State<MultiContainerSortableExample> createState() =>
      _MultiContainerSortableExampleState();
}

class _MultiContainerSortableExampleState
    extends State<MultiContainerSortableExample> {
  late final DndController _controller;

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

  @override
  void initState() {
    super.initState();
    _controller = DndController(
      collisionDetector: multiContainerCollisionDetector,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDragEnd(DndDragEndEvent event) {
    final move = SortableMultiContainer.moveDetailsFor(
      event,
      containers: _containers,
    );

    if (move == null) {
      _controller.reset();
      return;
    }

    final fromId = move.fromContainerId;
    final toId = move.toContainerId;

    if (fromId == null || toId == null) {
      _controller.reset();
      return;
    }

    if (fromId == toId) {
      // Same-container sorting
      setState(() {
        _containers = _containers.map((container) {
          if (container.id == fromId) {
            final items = List<DndId>.from(container.itemIds);
            final removed = items.removeAt(move.fromIndex);
            items.insert(move.toIndex, removed);
            return SortableContainer(id: container.id, itemIds: items);
          }
          return container;
        }).toList();
      });
      _controller.reset();
    } else {
      // Cross-container move
      final activeItem = move.activeId;

      // Phase 1: Remove item from original container to avoid duplicate registration
      setState(() {
        _containers = _containers.map((container) {
          if (container.id == fromId) {
            final items = List<DndId>.from(container.itemIds);
            items.removeAt(move.fromIndex);
            return SortableContainer(id: container.id, itemIds: items);
          }
          return container;
        }).toList();
      });

      // Phase 2: Add item to target container in the next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _containers = _containers.map((container) {
            if (container.id == toId) {
              final items = List<DndId>.from(container.itemIds);
              final targetIndex = move.toIndex.clamp(0, items.length);
              items.insert(targetIndex, activeItem);
              return SortableContainer(id: container.id, itemIds: items);
            }
            return container;
          }).toList();
        });
      });
      _controller.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return DndScope(
      controller: _controller,
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
                                    onDragEnd: _handleDragEnd,
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
                controller: _controller,
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
