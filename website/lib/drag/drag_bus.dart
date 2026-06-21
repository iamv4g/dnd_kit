import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr/jaspr.dart';

/// An immutable snapshot of the page's most recent drag activity.
class DragSnapshot {
  const DragSnapshot({
    this.active = false,
    this.source = '—',
    this.activeId,
    this.overId,
    this.state = 'idle',
    this.dx = 0,
    this.dy = 0,
    this.inputKind = '—',
  });

  final bool active;
  final String source;
  final String? activeId;
  final String? overId;
  final String state;
  final double dx;
  final double dy;
  final String inputKind;
}

/// A single shared drag "bus" the whole page reports into.
///
/// Every interactive island feeds its controller state here so the
/// [TelemetryHud] can read one live view of the engine, no matter which
/// surface the visitor grabs.
class DragBus extends ChangeNotifier {
  DragSnapshot snapshot = const DragSnapshot();

  /// Pushes the current state of [controller] onto the bus.
  void report(DndController controller, {required String source}) {
    final session = controller.activeSession;
    snapshot = DragSnapshot(
      active: !controller.isIdle,
      source: source,
      activeId: controller.activeId?.value,
      overId: controller.overId?.value,
      state: _stateName(controller.state),
      dx: session?.delta.x ?? 0,
      dy: session?.delta.y ?? 0,
      inputKind: session?.inputKind.name ?? '—',
    );
    notifyListeners();
  }

  static String _stateName(DndState state) {
    final raw = state.runtimeType.toString();
    return raw.startsWith('Dnd') ? raw.substring(3).toLowerCase() : raw;
  }
}

/// Process-wide bus shared by every hydrated island in the client bundle.
final dragBus = DragBus();
