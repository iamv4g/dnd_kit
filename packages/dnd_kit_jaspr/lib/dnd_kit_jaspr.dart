/// Jaspr (web) adapter for the dnd_kit drag-and-drop family.
///
/// `dnd_kit_jaspr` is built on the shared `dnd_kit` engine, so Jaspr and
/// Flutter behave as peer adapters over one drag runtime. Applications import
/// this library directly:
///
/// ```dart
/// import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
/// ```
///
/// It re-exports the pure Dart core (geometry, state, events, collision,
/// modifiers, sortable math, the drag runtime, and diagnostics) and adds the
/// Jaspr component layer: [DndScope], [DndController], [DndDraggable],
/// [DndDroppable], [DndDragHandle], [DndDragOverlay], and [DndAutoScroll].
///
/// Applications own their item, board, or document data. `dnd_kit_jaspr`
/// reports drag/drop intent so app code can update its own state.
///
library;

export 'package:dnd_kit/dnd_kit.dart';

export 'src/a11y/announcements.dart';
export 'src/a11y/live_region.dart' show DndLiveRegion;
export 'src/scope/controller.dart';
export 'src/scope/scope.dart';
export 'src/widgets/auto_scroll.dart';
export 'src/widgets/drag_handle.dart';
export 'src/widgets/drag_overlay.dart';
export 'src/widgets/draggable.dart';
export 'src/widgets/droppable.dart';
