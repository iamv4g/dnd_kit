import 'package:flutter/material.dart';

import '../../theme.dart';

@immutable
class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.owner,
    required this.color,
  });

  final String id;
  final String title;
  final String description;
  final String priority;
  final String owner;
  final Color color;
}

final Map<String, TaskItem> tasks = {
  'task-1': const TaskItem(
    id: 'task-1',
    title: 'Design Dark Mode UI',
    description:
        'Create premium dark-themed wireframes with nice glassmorphism gradients.',
    priority: 'High',
    owner: 'Mina',
    color: GalleryTokens.accentDeep,
  ),
  'task-2': const TaskItem(
    id: 'task-2',
    title: 'Implement Multi-Container API',
    description:
        'Integrate the new SortableContainer model and compute move details.',
    priority: 'Medium',
    owner: 'Kai',
    color: GalleryTokens.apricot,
  ),
  'task-3': const TaskItem(
    id: 'task-3',
    title: 'Write Widget Tests',
    description: 'Cover cross-container sorting scenarios in automated tests.',
    priority: 'Medium',
    owner: 'Sora',
    color: GalleryTokens.accent,
  ),
  'task-4': const TaskItem(
    id: 'task-4',
    title: 'Release dnd_kit v1.0.0',
    description:
        'Ship stable version with all benchmarks and telemetry checks.',
    priority: 'Low',
    owner: 'An',
    color: GalleryTokens.sky,
  ),
  'task-5': const TaskItem(
    id: 'task-5',
    title: 'Analyze Performance',
    description: 'Ensure drag operations take less than 16ms per frame on web.',
    priority: 'High',
    owner: 'Tuan',
    color: GalleryTokens.mint,
  ),
};
