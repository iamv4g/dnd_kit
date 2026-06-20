/// Flutter drag-and-drop toolkit with sortable presets.
///
/// This is the Flutter adapter package. Applications may import it directly:
///
/// ```dart
/// import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
/// ```
///
/// or through the `dnd_kit` umbrella package, which re-exports this library:
///
/// ```dart
/// import 'package:dnd_kit/dnd_kit.dart';
/// ```
///
/// The package provides the widget layer around the pure Dart core:
/// [DndScope], [DndController], [DndDraggable], [DndDroppable],
/// [DndDragOverlay], auto-scroll helpers, and stable sortable APIs such as
/// [SortableScope] and [SortableItem].
///
/// Applications own their item, board, or document data. `dnd_kit_flutter`
/// reports drag/drop and sortable move intent so app code can update its own
/// state.
///
library;

export 'package:dnd_kit/dnd_kit.dart';

export 'src/a11y/announcements.dart';
export 'src/measuring/measuring.dart' hide DndMeasuredBox;
export 'src/scope/controller.dart';
export 'src/scope/scope.dart';
export 'src/sensors/long_press_activation.dart';
export 'src/sensors/pointer_sensor.dart';
export 'src/sortable/sortable_container.dart';
export 'src/sortable/sortable_details.dart';
export 'src/sortable/sortable_item.dart';
export 'src/sortable/sortable_scope.dart';
export 'src/sortable/sortable_strategy.dart';
export 'src/widgets/auto_scroll.dart';
export 'src/widgets/drag_handle.dart';
export 'src/widgets/drag_overlay.dart';
export 'src/widgets/draggable.dart' hide DndDraggableHandleController, DndDraggableHandleScope;
export 'src/widgets/droppable.dart';
