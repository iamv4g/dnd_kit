import 'package:dnd_kit/dnd_kit.dart';

/// Builds the screen-reader text announced when a drag starts.
typedef DndDragStartAnnouncement = String Function(DndId active);

/// Builds the text announced when the drag-over target changes.
typedef DndDragOverAnnouncement = String Function(DndId active, DndId? over);

/// Builds the text announced when a drag drops.
typedef DndDragEndAnnouncement = String Function(DndId active, DndId? over);

/// Builds the text announced when a drag is cancelled.
typedef DndDragCancelAnnouncement = String Function(DndId active);

/// Configurable screen-reader announcements for the Jaspr drag lifecycle.
///
/// `DndLiveRegion` derives announcements from the shared controller's state
/// transitions and renders them into an ARIA live region. Provide a custom
/// instance through `DndScope(announcements: ...)` or per `DndLiveRegion` to
/// localize or reword the defaults.
final class DndAnnouncements {
  /// Creates announcement builders, defaulting to English messages.
  const DndAnnouncements({
    this.onDragStart = _defaultDragStart,
    this.onDragOver = _defaultDragOver,
    this.onDragEnd = _defaultDragEnd,
    this.onDragCancel = _defaultDragCancel,
  });

  /// Builds the text announced when a drag starts.
  final DndDragStartAnnouncement onDragStart;

  /// Builds the text announced when the drag-over target changes.
  final DndDragOverAnnouncement onDragOver;

  /// Builds the text announced when a drag drops.
  final DndDragEndAnnouncement onDragEnd;

  /// Builds the text announced when a drag is cancelled.
  final DndDragCancelAnnouncement onDragCancel;

  static String _defaultDragStart(DndId active) {
    return 'Picked up draggable item ${active.value}.';
  }

  static String _defaultDragOver(DndId active, DndId? over) {
    return over == null
        ? 'Draggable item ${active.value} is no longer over a drop target.'
        : 'Draggable item ${active.value} moved over droppable ${over.value}.';
  }

  static String _defaultDragEnd(DndId active, DndId? over) {
    return over == null
        ? 'Draggable item ${active.value} was dropped.'
        : 'Draggable item ${active.value} was dropped over droppable ${over.value}.';
  }

  static String _defaultDragCancel(DndId active) {
    return 'Dragging draggable item ${active.value} was cancelled.';
  }
}
