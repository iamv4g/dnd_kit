import 'package:flutter/material.dart';

import '../../theme.dart';
import 'task_item.dart';

/// A Kanban card on the gallery's shared surface language: superellipse corners
/// and a layered shadow, with hover and lift expressed as weight rather than a
/// coloured outline.
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
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: ShapeDecoration(
        color: GalleryTokens.surface,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(16),
          // Hover gets a faint tinted edge; the lifted copy needs none, its
          // shadow already separates it.
          side: isHovered && !isDraggingOverlay
              ? BorderSide(
                  color: GalleryTokens.accent.withValues(alpha: 0.35),
                  width: 1.5,
                )
              : BorderSide.none,
        ),
        shadows:
            isDraggingOverlay ? GalleryTokens.liftHigh : GalleryTokens.lift,
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
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: -0.2,
              color: GalleryTokens.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            task.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: GalleryTokens.muted,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.account_circle_outlined,
                size: 15,
                color: GalleryTokens.faint,
              ),
              const SizedBox(width: 4),
              Text(
                task.owner,
                style: const TextStyle(
                  color: GalleryTokens.faint,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.drag_indicator,
                size: 16,
                color: GalleryTokens.faint,
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
    // Pulled onto the gallery ramp so the board is one palette, not Material's
    // stock red/amber/green traffic lights.
    final color = switch (priority) {
      'High' => const Color(0xFFB8501C),
      'Medium' => GalleryTokens.apricot,
      'Low' => GalleryTokens.mint,
      _ => GalleryTokens.faint,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: ShapeDecoration(
        color: color.withValues(alpha: 0.16),
        shape: const StadiumBorder(),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark
              ? color
              : GalleryTokens.ink,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
