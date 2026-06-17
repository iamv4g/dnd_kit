import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/material.dart';

import 'task_card_content.dart';
import 'task_item.dart';

class DraggableCard extends StatefulWidget {
  const DraggableCard({
    super.key,
    required this.task,
    required this.onDragEnd,
  });

  final TaskItem task;
  final DndDragEndCallback onDragEnd;

  @override
  State<DraggableCard> createState() => _DraggableCardState();
}

class _DraggableCardState extends State<DraggableCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final taskDndId = DndId(widget.task.id);

    return DndDroppable(
      key: ValueKey('task-drop:${widget.task.id}'),
      id: taskDndId,
      builder: (context, details, child) {
        final isOver = details.isOver;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            border: Border.all(
              color: isOver ? const Color(0xff8b5cf6) : Colors.transparent,
              width: isOver ? 2.0 : 0.0,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        );
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: DndDraggable(
          key: ValueKey('drag:${widget.task.id}'),
          id: taskDndId,
          onDragEnd: widget.onDragEnd,
          // Default platform-adaptive activation: immediate with a mouse, but a
          // short hold on touch so a quick swipe scrolls instead of dragging.
          builder: (context, details, child) {
            return AnimatedOpacity(
              duration: const Duration(milliseconds: 150),
              opacity: details.isDragging ? 0.35 : 1.0,
              child: child,
            );
          },
          child: AnimatedScale(
            scale: _isHovered ? 1.02 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: TaskCardContent(
              task: widget.task,
              isHovered: _isHovered,
            ),
          ),
        ),
      ),
    );
  }
}
