import 'package:dnd_kit/dnd_kit.dart' show DndAnnouncements;
import 'package:jaspr/jaspr.dart';

import 'controller.dart';

/// Provides a [DndController] to a Jaspr subtree.
///
/// `DndScope` mirrors the Flutter adapter's scope: it owns a controller's
/// lifecycle (creating one when none is injected, disposing what it created)
/// and exposes it to descendants through an [InheritedComponent], looked up via
/// [DndScope.of]. It also provides the [DndAnnouncements] used by
/// `DndLiveRegion`, read via [DndScope.announcementsOf].
class DndScope extends StatefulComponent {
  /// Creates a drag scope around [child].
  const DndScope({
    this.controller,
    this.announcements = const DndAnnouncements(),
    required this.child,
    super.key,
  });

  /// An optional externally-owned controller.
  ///
  /// When null, the scope creates and disposes its own [DndController].
  final DndController? controller;

  /// Screen-reader announcements provided to descendant `DndLiveRegion`s.
  final DndAnnouncements announcements;

  /// The subtree that can access the controller via [DndScope.of].
  final Component child;

  /// Returns the nearest [DndController] provided by an enclosing [DndScope].
  static DndController of(BuildContext context) {
    final provider = context.dependOnInheritedComponentOfExactType<_DndScopeProvider>();
    assert(provider != null, 'DndScope.of() called without an enclosing DndScope.');
    return provider!.controller;
  }

  /// Returns the nearest [DndAnnouncements], or sensible defaults when no scope
  /// is found.
  static DndAnnouncements announcementsOf(BuildContext context) {
    final provider = context.dependOnInheritedComponentOfExactType<_DndScopeProvider>();
    return provider?.announcements ?? const DndAnnouncements();
  }

  @override
  State<DndScope> createState() => _DndScopeState();
}

class _DndScopeState extends State<DndScope> {
  DndController? _ownController;

  DndController get _controller {
    final injected = component.controller;
    if (injected != null) {
      return injected;
    }
    return _ownController ??= DndController();
  }

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final controller = _controller;
    controller.runtime.registry.scheduleDeferredTask = context.binding.addPostFrameCallback;
    return _DndScopeProvider(
      controller: controller,
      announcements: component.announcements,
      child: component.child,
    );
  }
}

class _DndScopeProvider extends InheritedComponent {
  const _DndScopeProvider({
    required this.controller,
    required this.announcements,
    required super.child,
  });

  final DndController controller;
  final DndAnnouncements announcements;

  @override
  bool updateShouldNotify(_DndScopeProvider oldComponent) {
    return controller != oldComponent.controller || announcements != oldComponent.announcements;
  }
}
