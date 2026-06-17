import 'dart:ui';

import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/material.dart';

import 'draggable_card.dart';
import 'task_item.dart';

class BoardColumnWidget extends StatelessWidget {
  const BoardColumnWidget({
    super.key,
    required this.container,
    required this.onDragEnd,
  });

  final SortableContainer container;
  final DndDragEndCallback onDragEnd;

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

  Color get _color {
    switch (container.id.value) {
      case 'backlog':
        return const Color(0xfff3a683);
      case 'in_progress':
        return const Color(0xff06b6d4);
      case 'completed':
        return const Color(0xff10b981);
      default:
        return const Color(0xff8b5cf6);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DndDroppable(
      key: ValueKey('column-drop:${container.id.value}'),
      id: container.id,
      builder: (context, details, child) {
        final isOver = details.isOver;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: isOver ? 0.06 : 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isOver
                  ? _color.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.06),
              width: isOver ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (isOver)
                BoxShadow(
                  color: _color.withValues(alpha: 0.1),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Column Header
                Row(
                  children: [
                    Icon(_icon, color: _color, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${container.itemIds.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
                const SizedBox(height: 16),
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
                          final index =
                              visibleIds.indexWhere((e) => e.value == id);
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
                              onDragEnd: onDragEnd,
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
        ),
      ),
    );
  }
}
