import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/material.dart';

import 'collision_detector.dart';
import 'horizontal_board_auto_scroll.dart';
import 'kanban_board_utils.dart';
import 'kanban_column_view.dart';
import 'kanban_task_tile.dart';
import 'models.dart';

void main() {
  runApp(const KanbanBoardApp());
}

class KanbanBoardApp extends StatelessWidget {
  const KanbanBoardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'dnd_kit Kanban',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff2f6f73),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfff4f1ea),
        useMaterial3: true,
      ),
      home: const KanbanBoardExample(),
    );
  }
}

class KanbanBoardExample extends StatefulWidget {
  const KanbanBoardExample({
    super.key,
    this.initialColumns = defaultKanbanColumns,
    this.onChanged,
  });

  final List<KanbanColumn> initialColumns;
  final KanbanBoardChanged? onChanged;

  @override
  State<KanbanBoardExample> createState() => _KanbanBoardExampleState();
}

class _KanbanBoardExampleState extends State<KanbanBoardExample> {
  late List<KanbanColumn> _columns;
  late DndController _controller;
  late ScrollController _boardScrollController;
  String? _indicatorColumnId;
  int? _indicatorIndex;

  @override
  void initState() {
    super.initState();
    _columns = cloneColumns(widget.initialColumns);
    _controller =
        DndController(collisionDetector: kanbanBoardCollisionDetector);
    _boardScrollController = ScrollController();
    _controller.addListener(_syncDropIndicator);
  }

  @override
  void didUpdateWidget(KanbanBoardExample oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialColumns != widget.initialColumns) {
      _columns = cloneColumns(widget.initialColumns);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_syncDropIndicator);
    _boardScrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _syncDropIndicator() {
    if (!_controller.isDragging) {
      _clearIndicator();
      return;
    }

    final session = _controller.activeSession;
    final activeId = _controller.activeId;
    if (session == null || activeId == null) return;

    final overId = _controller.overId;
    final dropData =
        overId == null ? null : _controller.registry.droppable(overId)?.data;
    final dragData = _controller.registry.draggable(activeId)?.data;
    if (dropData is! KanbanDropData || dragData is! KanbanTaskDragData) {
      _clearIndicator();
      return;
    }

    final colIdx = _columns.indexWhere((c) => c.id == dropData.columnId);
    if (colIdx == -1) return;
    final column = _columns[colIdx];

    final tasksWithoutDragged = dropData.columnId == dragData.columnId
        ? column.tasks.where((t) => t.id != dragData.taskId).toList()
        : column.tasks.toList();

    final insertionIndex = _computeInsertionIndex(
      columnTasks: tasksWithoutDragged,
      pointer: session.currentPointer,
      droppableRects: _controller.measuring.droppableRects,
      targetTaskId: dropData.taskId,
    );

    // Convert "index in list without dragged" → "visual index in full list"
    // because the dragged task is still rendered (at 36% opacity) at its
    // original slot, shifting the visual positions after it.
    int visualIndex;
    if (dropData.columnId == dragData.columnId) {
      final draggedOrigIdx =
          column.tasks.indexWhere((t) => t.id == dragData.taskId);
      visualIndex = (draggedOrigIdx != -1 && draggedOrigIdx < insertionIndex)
          ? insertionIndex + 1
          : insertionIndex;
    } else {
      visualIndex = insertionIndex;
    }

    if (_indicatorColumnId != dropData.columnId ||
        _indicatorIndex != visualIndex) {
      setState(() {
        _indicatorColumnId = dropData.columnId;
        _indicatorIndex = visualIndex;
      });
    }
  }

  void _clearIndicator() {
    if (_indicatorColumnId != null) {
      setState(() {
        _indicatorColumnId = null;
        _indicatorIndex = null;
      });
    }
  }

  void _handleDragEnd(DndDragEndEvent event) {
    final dragData = _controller.registry.draggable(event.activeId)?.data;
    final overId = event.overId;
    final dropData =
        overId == null ? null : _controller.registry.droppable(overId)?.data;
    if (dragData is! KanbanTaskDragData || dropData is! KanbanDropData) {
      _controller.reset();
      return;
    }

    final pointer = event.currentPointer;
    final droppableRects =
        Map<DndId, DndRect>.from(_controller.measuring.droppableRects);

    _moveTask(
      taskId: dragData.taskId,
      fromColumnId: dragData.columnId,
      toColumnId: dropData.columnId,
      targetTaskId: dropData.taskId,
      pointer: pointer,
      droppableRects: droppableRects,
    );
    _controller.reset();
  }

  void _moveTask({
    required String taskId,
    required String fromColumnId,
    required String toColumnId,
    required String? targetTaskId,
    required DndPoint pointer,
    required Map<DndId, DndRect> droppableRects,
  }) {
    if (fromColumnId == toColumnId && taskId == targetTaskId) {
      return;
    }

    final nextColumns = _columns.map((column) => column.copyWith()).toList();
    final fromIndex =
        nextColumns.indexWhere((column) => column.id == fromColumnId);
    final toIndex = nextColumns.indexWhere((column) => column.id == toColumnId);
    if (fromIndex == -1 || toIndex == -1) {
      return;
    }

    final fromTasks = nextColumns[fromIndex].tasks.toList();
    final taskIndex = fromTasks.indexWhere((task) => task.id == taskId);
    if (taskIndex == -1) {
      return;
    }

    final task = fromTasks.removeAt(taskIndex);
    nextColumns[fromIndex] = nextColumns[fromIndex].copyWith(tasks: fromTasks);

    if (fromColumnId != toColumnId) {
      setState(() {
        _columns = List<KanbanColumn>.unmodifiable(nextColumns);
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _insertTask(
          task: task,
          toColumnId: toColumnId,
          targetTaskId: targetTaskId,
          pointer: pointer,
          droppableRects: droppableRects,
        );
      });
      return;
    }

    final insertionIndex = _computeInsertionIndex(
      columnTasks: nextColumns[toIndex].tasks,
      pointer: pointer,
      droppableRects: droppableRects,
      targetTaskId: targetTaskId,
    );
    final targetTasks = nextColumns[toIndex].tasks.toList()
      ..insert(insertionIndex, task);
    nextColumns[toIndex] = nextColumns[toIndex].copyWith(tasks: targetTasks);

    setState(() {
      _columns = List<KanbanColumn>.unmodifiable(nextColumns);
    });
    widget.onChanged?.call(_columns);
  }

  void _insertTask({
    required KanbanTask task,
    required String toColumnId,
    required String? targetTaskId,
    required DndPoint pointer,
    required Map<DndId, DndRect> droppableRects,
  }) {
    final nextColumns = _columns.map((column) => column.copyWith()).toList();
    final toIndex = nextColumns.indexWhere((column) => column.id == toColumnId);
    if (toIndex == -1) {
      return;
    }

    final insertionIndex = _computeInsertionIndex(
      columnTasks: nextColumns[toIndex].tasks,
      pointer: pointer,
      droppableRects: droppableRects,
      targetTaskId: targetTaskId,
    );
    final targetTasks = nextColumns[toIndex].tasks.toList()
      ..insert(insertionIndex, task);
    nextColumns[toIndex] = nextColumns[toIndex].copyWith(tasks: targetTasks);

    setState(() {
      _columns = List<KanbanColumn>.unmodifiable(nextColumns);
    });
    widget.onChanged?.call(_columns);
  }

  int _computeInsertionIndex({
    required List<KanbanTask> columnTasks,
    required DndPoint pointer,
    required Map<DndId, DndRect> droppableRects,
    String? targetTaskId,
  }) {
    if (targetTaskId != null) {
      final idx = columnTasks.indexWhere((t) => t.id == targetTaskId);
      if (idx != -1) {
        final rect = droppableRects[taskDndId(targetTaskId)];
        if (rect != null) {
          return pointer.y > rect.center.y ? idx + 1 : idx;
        }
        return idx;
      }
    }

    // Gap/column drop: compare pointer against sorted task centers.
    final measured = <(KanbanTask, DndRect)>[];
    for (final task in columnTasks) {
      final rect = droppableRects[taskDndId(task.id)];
      if (rect != null) {
        measured.add((task, rect));
      }
    }
    if (measured.isEmpty) {
      return 0;
    }
    measured.sort((a, b) => a.$2.center.y.compareTo(b.$2.center.y));
    var index = 0;
    for (final (_, rect) in measured) {
      if (pointer.y > rect.center.y) {
        index += 1;
      } else {
        break;
      }
    }
    return index;
  }

  KanbanTask? _taskFor(DndId id) {
    final taskId = taskIdFromDndId(id);
    if (taskId == null) {
      return null;
    }
    for (final column in _columns) {
      for (final task in column.tasks) {
        if (task.id == taskId) {
          return task;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return DndScope(
      controller: _controller,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('dnd_kit Kanban'),
          actions: const <Widget>[
            Padding(
              padding: EdgeInsets.only(right: 20),
              child: Icon(Icons.view_kanban_outlined),
            ),
          ],
        ),
        body: Stack(
          children: <Widget>[
            HorizontalBoardAutoScroll(
              controller: _controller,
              scrollController: _boardScrollController,
              child: ListView.builder(
                key: const ValueKey<String>('kanban-board-scroll'),
                controller: _boardScrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(20),
                itemCount: _columns.length,
                findChildIndexCallback: (key) {
                  final value = (key as ValueKey<String>).value;
                  final id = value.replaceFirst('column-view:', '');
                  final index = _columns.indexWhere((c) => c.id == id);
                  return index < 0 ? null : index;
                },
                itemBuilder: (context, index) {
                  final column = _columns[index];
                  return Padding(
                    key: ValueKey<String>('column-view:${column.id}'),
                    padding: EdgeInsets.only(
                      right: index == _columns.length - 1 ? 0 : 16,
                    ),
                    child: KanbanColumnView(
                      column: column,
                      onDragEnd: _handleDragEnd,
                      dropIndicatorIndex: _indicatorColumnId == column.id
                          ? _indicatorIndex
                          : null,
                    ),
                  );
                },
              ),
            ),
            DndDragOverlay(
              controller: _controller,
              builder: (context, details) {
                final task = _taskFor(details.activeId);
                if (task == null) {
                  return const SizedBox.shrink();
                }
                return KanbanTaskCard(
                  task: task,
                  elevated: true,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
