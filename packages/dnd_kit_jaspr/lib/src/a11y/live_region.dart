import 'package:dnd_kit/dnd_kit.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../scope/controller.dart';
import '../scope/scope.dart';

/// Inline style for a visually-hidden but screen-reader-available element.
const String kDndVisuallyHiddenStyle = 'position:absolute; width:1px; height:1px; '
    'padding:0; margin:-1px; overflow:hidden; clip:rect(0 0 0 0); '
    'white-space:nowrap; border:0;';

/// A visually-hidden ARIA live region that announces drag lifecycle changes.
///
/// `DndLiveRegion` listens to the enclosing [DndScope] controller and, on each
/// drag state transition (start, drag-over target change, drop, cancel),
/// announces text built by the scope's [DndAnnouncements]. It works for pointer,
/// mouse, and keyboard drags alike because the announcements are derived from
/// the shared runtime state, not from input-specific code.
///
/// Mount it once inside a [DndScope], e.g. alongside the draggable UI.
class DndLiveRegion extends StatefulComponent {
  /// Creates a live region.
  const DndLiveRegion({
    this.controller,
    this.announcements,
    this.assertive = true,
    super.key,
  });

  /// Optional controller to announce for; defaults to the [DndScope] controller.
  final DndController? controller;

  /// Optional announcement overrides; defaults to the [DndScope] announcements.
  final DndAnnouncements? announcements;

  /// Whether the live region is `assertive` (interrupts) or `polite`.
  final bool assertive;

  @override
  State<DndLiveRegion> createState() => _DndLiveRegionState();
}

class _DndLiveRegionState extends State<DndLiveRegion> {
  DndController? _controller;
  DndAnnouncements _announcements = const DndAnnouncements();

  String _message = '';
  String? _lastStateLabel;
  DndId? _lastOverId;
  DndId? _activeId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _announcements = component.announcements ?? DndScope.announcementsOf(context);

    final next = component.controller ?? DndScope.of(context);
    if (!identical(_controller, next)) {
      _controller?.removeListener(_handleControllerChanged);
      _controller = next;
      _controller?.addListener(_handleControllerChanged);
      _sync(next);
    }
  }

  @override
  void didUpdateComponent(DndLiveRegion oldComponent) {
    super.didUpdateComponent(oldComponent);
    _announcements = component.announcements ?? DndScope.announcementsOf(context);
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    final controller = _controller;
    if (controller == null || !mounted) {
      return;
    }
    _sync(controller);
  }

  void _sync(DndController controller) {
    final state = controller.state;
    final label = state.runtimeType.toString();
    String? message;

    if (state is DndDragging) {
      _activeId = state.session.activeId;
      if (_lastStateLabel != 'DndDragging') {
        message = _announcements.onDragStart(state.session.activeId);
        _lastOverId = controller.overId;
      } else if (controller.overId != _lastOverId) {
        message = _announcements.onDragOver(state.session.activeId, controller.overId);
        _lastOverId = controller.overId;
      }
    } else if (state is DndDropping && _lastStateLabel != 'DndDropping') {
      final active = controller.activeId ?? _activeId;
      if (active != null) {
        message = _announcements.onDragEnd(active, controller.overId);
      }
    } else if (state is DndCancelled && _lastStateLabel != 'DndCancelled') {
      final active = controller.activeId ?? _activeId;
      if (active != null) {
        message = _announcements.onDragCancel(active);
      }
    } else if (state is DndIdle) {
      _activeId = null;
      _lastOverId = null;
    }

    _lastStateLabel = label;
    if (message != null && message != _message) {
      setState(() => _message = message!);
    }
  }

  @override
  Component build(BuildContext context) {
    return div(
      attributes: <String, String>{
        'role': 'status',
        'aria-live': component.assertive ? 'assertive' : 'polite',
        'aria-atomic': 'true',
        'data-dnd-live-region': 'true',
        'style': kDndVisuallyHiddenStyle,
      },
      [Component.text(_message)],
    );
  }
}
