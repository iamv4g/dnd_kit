import 'dart:collection';

import 'diagnostics.dart';
import 'id.dart';

/// Pure Dart metadata for a registered draggable.
final class DndDraggableRegistration {
  /// Creates draggable registration metadata.
  const DndDraggableRegistration({
    required this.id,
    this.disabled = false,
    this.data,
  });

  /// The stable draggable id.
  final DndId id;

  /// Whether dragging is disabled for this entry.
  final bool disabled;

  /// Optional application-owned data associated with this draggable.
  final Object? data;

  @override
  bool operator ==(Object other) {
    return other is DndDraggableRegistration &&
        other.id == id &&
        other.disabled == disabled &&
        other.data == data;
  }

  @override
  int get hashCode => Object.hash(id, disabled, data);

  @override
  String toString() {
    return 'DndDraggableRegistration(id: $id, disabled: $disabled, data: $data)';
  }
}

/// Pure Dart metadata for a registered droppable.
final class DndDroppableRegistration {
  /// Creates droppable registration metadata.
  const DndDroppableRegistration({
    required this.id,
    this.disabled = false,
    this.data,
  });

  /// The stable droppable id.
  final DndId id;

  /// Whether dropping is disabled for this entry.
  final bool disabled;

  /// Optional application-owned data associated with this droppable.
  final Object? data;

  @override
  bool operator ==(Object other) {
    return other is DndDroppableRegistration &&
        other.id == id &&
        other.disabled == disabled &&
        other.data == data;
  }

  @override
  int get hashCode => Object.hash(id, disabled, data);

  @override
  String toString() {
    return 'DndDroppableRegistration(id: $id, disabled: $disabled, data: $data)';
  }
}

/// Immutable view of the currently registered draggable and droppable entries.
final class DndRegistrySnapshot {
  /// Creates a registry snapshot.
  factory DndRegistrySnapshot({
    Map<DndId, DndDraggableRegistration> draggables = const <DndId, DndDraggableRegistration>{},
    Map<DndId, DndDroppableRegistration> droppables = const <DndId, DndDroppableRegistration>{},
  }) {
    return DndRegistrySnapshot._(
      UnmodifiableMapView(Map<DndId, DndDraggableRegistration>.of(draggables)),
      UnmodifiableMapView(Map<DndId, DndDroppableRegistration>.of(droppables)),
    );
  }

  const DndRegistrySnapshot._(this.draggables, this.droppables);

  /// Registered draggables keyed by stable id.
  final Map<DndId, DndDraggableRegistration> draggables;

  /// Registered droppables keyed by stable id.
  final Map<DndId, DndDroppableRegistration> droppables;

  /// An empty registry snapshot.
  static final empty = DndRegistrySnapshot();

  @override
  bool operator ==(Object other) {
    return other is DndRegistrySnapshot &&
        _mapEquals(other.draggables, draggables) &&
        _mapEquals(other.droppables, droppables);
  }

  @override
  int get hashCode => Object.hash(_mapHash(draggables), _mapHash(droppables));

  @override
  String toString() {
    return 'DndRegistrySnapshot(draggables: $draggables, droppables: $droppables)';
  }
}

/// Schedules a deferred registry task after transient reconciliation settles.
typedef DndDeferredTaskScheduler = void Function(void Function() task);

/// Pure Dart registry for draggable and droppable entries.
final class DndRegistry {
  /// Creates a registry.
  DndRegistry({
    DndDiagnosticsConfig diagnosticsConfig = const DndDiagnosticsConfig(),
    DndDeferredTaskScheduler? scheduleDeferredTask,
  })  : _diagnosticsConfig = diagnosticsConfig,
        _scheduleDeferredTask = scheduleDeferredTask;

  final DndDiagnosticsConfig _diagnosticsConfig;
  DndDeferredTaskScheduler? _scheduleDeferredTask;
  final Map<DndId, DndDraggableRegistration> _draggables = <DndId, DndDraggableRegistration>{};
  final Map<DndId, DndDroppableRegistration> _droppables = <DndId, DndDroppableRegistration>{};

  // Identity of the widget/state that currently owns each id. Owner-aware
  // registration lets a lazy list rebuild a keyed entry (new owner mounts
  // before the old owner is disposed) without tripping duplicate detection or
  // letting the departing owner remove the live registration.
  final Map<DndId, Object> _draggableOwners = <DndId, Object>{};
  final Map<DndId, Object> _droppableOwners = <DndId, Object>{};
  final Map<DndId, LinkedHashMap<Object, DndDraggableRegistration>> _draggableClaims =
      <DndId, LinkedHashMap<Object, DndDraggableRegistration>>{};
  final Map<DndId, LinkedHashMap<Object, DndDroppableRegistration>> _droppableClaims =
      <DndId, LinkedHashMap<Object, DndDroppableRegistration>>{};
  final Set<DndId> _warnedDraggableDuplicates = <DndId>{};
  final Set<DndId> _warnedDroppableDuplicates = <DndId>{};
  bool _deferredDuplicateCheckScheduled = false;

  /// Registered draggables keyed by stable id.
  Map<DndId, DndDraggableRegistration> get draggables {
    return UnmodifiableMapView(_draggables);
  }

  /// Registered droppables keyed by stable id.
  Map<DndId, DndDroppableRegistration> get droppables {
    return UnmodifiableMapView(_droppables);
  }

  /// The current immutable registry snapshot.
  DndRegistrySnapshot get snapshot {
    return DndRegistrySnapshot(
      draggables: _draggables,
      droppables: _droppables,
    );
  }

  /// Returns whether a draggable with [id] is registered.
  bool hasDraggable(DndId id) => _draggables.containsKey(id);

  /// Returns whether a droppable with [id] is registered.
  bool hasDroppable(DndId id) => _droppables.containsKey(id);

  /// Returns the registered draggable with [id], when one exists.
  DndDraggableRegistration? draggable(DndId id) => _draggables[id];

  /// Returns the registered droppable with [id], when one exists.
  DndDroppableRegistration? droppable(DndId id) => _droppables[id];

  /// Reconfigures how owner-aware duplicate checks are deferred.
  ///
  /// Adapters use this to align duplicate warnings with their own frame
  /// boundary. Any already-scheduled callback keeps the scheduler it was
  /// created with.
  set scheduleDeferredTask(DndDeferredTaskScheduler? value) {
    _scheduleDeferredTask = value;
  }

  /// Registers [registration] as a draggable entry.
  ///
  /// When [owner] is provided, registration is owner-aware and last-wins: a new
  /// owner can take over an id (e.g. a lazy list rebuilding a keyed entry)
  /// without tripping duplicate detection. When [owner] is omitted, duplicate
  /// ids are rejected in debug mode, preserving strict diagnostics for direct
  /// registry usage.
  void registerDraggable(DndDraggableRegistration registration, {Object? owner}) {
    if (owner == null) {
      if (_draggables.containsKey(registration.id)) {
        _warnDuplicate(
          code: 'duplicate-draggable-id',
          id: registration.id,
          label: 'draggable',
        );
      }
      assert(
        !_draggables.containsKey(registration.id),
        'Duplicate draggable id registered: ${registration.id}.',
      );
      _draggables[registration.id] = registration;
      return;
    }

    final claims = _draggableClaims.putIfAbsent(
      registration.id,
      LinkedHashMap<Object, DndDraggableRegistration>.new,
    );
    claims.remove(owner);
    claims[owner] = registration;
    _syncCurrentDraggable(registration.id);
    _scheduleDeferredDuplicateCheck();
  }

  /// Registers [registration] as a droppable entry.
  ///
  /// See [registerDraggable] for the [owner] semantics.
  void registerDroppable(DndDroppableRegistration registration, {Object? owner}) {
    if (owner == null) {
      if (_droppables.containsKey(registration.id)) {
        _warnDuplicate(
          code: 'duplicate-droppable-id',
          id: registration.id,
          label: 'droppable',
        );
      }
      assert(
        !_droppables.containsKey(registration.id),
        'Duplicate droppable id registered: ${registration.id}.',
      );
      _droppables[registration.id] = registration;
      return;
    }

    final claims = _droppableClaims.putIfAbsent(
      registration.id,
      LinkedHashMap<Object, DndDroppableRegistration>.new,
    );
    claims.remove(owner);
    claims[owner] = registration;
    _syncCurrentDroppable(registration.id);
    _scheduleDeferredDuplicateCheck();
  }

  /// Updates or inserts [registration] as a draggable entry.
  void updateDraggable(DndDraggableRegistration registration, {Object? owner}) {
    if (owner != null) {
      final claims = _draggableClaims[registration.id];
      if (claims != null && claims.containsKey(owner)) {
        claims.remove(owner);
        claims[owner] = registration;
        _syncCurrentDraggable(registration.id);
        _scheduleDeferredDuplicateCheck();
        return;
      }
    }

    _draggables[registration.id] = registration;
  }

  /// Updates or inserts [registration] as a droppable entry.
  void updateDroppable(DndDroppableRegistration registration, {Object? owner}) {
    if (owner != null) {
      final claims = _droppableClaims[registration.id];
      if (claims != null && claims.containsKey(owner)) {
        claims.remove(owner);
        claims[owner] = registration;
        _syncCurrentDroppable(registration.id);
        _scheduleDeferredDuplicateCheck();
        return;
      }
    }

    _droppables[registration.id] = registration;
  }

  /// Removes the draggable with [id].
  ///
  /// When [owner] is provided and a different owner currently holds [id]
  /// (a newer owner took over), the removal is skipped and `null` is returned so
  /// a departing owner cannot drop the live registration.
  DndDraggableRegistration? unregisterDraggable(DndId id, {Object? owner}) {
    if (owner != null) {
      final claims = _draggableClaims[id];
      if (claims == null || !claims.containsKey(owner)) {
        return null;
      }

      claims.remove(owner);
      _warnedDraggableDuplicates.remove(id);
      if (claims.isEmpty) {
        _draggableClaims.remove(id);
        _draggableOwners.remove(id);
        return _draggables.remove(id);
      }

      _syncCurrentDraggable(id);
      _scheduleDeferredDuplicateCheck();
      return null;
    }
    _draggableOwners.remove(id);
    _draggableClaims.remove(id);
    _warnedDraggableDuplicates.remove(id);
    return _draggables.remove(id);
  }

  /// Removes the droppable with [id].
  ///
  /// See [unregisterDraggable] for the [owner] semantics.
  DndDroppableRegistration? unregisterDroppable(DndId id, {Object? owner}) {
    if (owner != null) {
      final claims = _droppableClaims[id];
      if (claims == null || !claims.containsKey(owner)) {
        return null;
      }

      claims.remove(owner);
      _warnedDroppableDuplicates.remove(id);
      if (claims.isEmpty) {
        _droppableClaims.remove(id);
        _droppableOwners.remove(id);
        return _droppables.remove(id);
      }

      _syncCurrentDroppable(id);
      _scheduleDeferredDuplicateCheck();
      return null;
    }
    _droppableOwners.remove(id);
    _droppableClaims.remove(id);
    _warnedDroppableDuplicates.remove(id);
    return _droppables.remove(id);
  }

  /// Removes all registered entries.
  void clear() {
    _draggables.clear();
    _droppables.clear();
    _draggableOwners.clear();
    _droppableOwners.clear();
    _draggableClaims.clear();
    _droppableClaims.clear();
    _warnedDraggableDuplicates.clear();
    _warnedDroppableDuplicates.clear();
  }

  void _syncCurrentDraggable(DndId id) {
    final claims = _draggableClaims[id];
    if (claims == null || claims.isEmpty) {
      _draggableOwners.remove(id);
      _draggables.remove(id);
      return;
    }

    final currentClaim = claims.entries.last;
    _draggableOwners[id] = currentClaim.key;
    _draggables[id] = currentClaim.value;
  }

  void _syncCurrentDroppable(DndId id) {
    final claims = _droppableClaims[id];
    if (claims == null || claims.isEmpty) {
      _droppableOwners.remove(id);
      _droppables.remove(id);
      return;
    }

    final currentClaim = claims.entries.last;
    _droppableOwners[id] = currentClaim.key;
    _droppables[id] = currentClaim.value;
  }

  void _scheduleDeferredDuplicateCheck() {
    final scheduler = _scheduleDeferredTask;
    if (scheduler == null || _deferredDuplicateCheckScheduled) {
      return;
    }

    _deferredDuplicateCheckScheduled = true;
    scheduler(() {
      _deferredDuplicateCheckScheduled = false;
      _flushDeferredDuplicateWarnings();
    });
  }

  void _flushDeferredDuplicateWarnings() {
    _flushDeferredWarningsForDraggables();
    _flushDeferredWarningsForDroppables();
  }

  void _flushDeferredWarningsForDraggables() {
    final duplicateIds = <DndId>{};
    for (final entry in _draggableClaims.entries) {
      if (entry.value.length > 1) {
        duplicateIds.add(entry.key);
        if (_warnedDraggableDuplicates.add(entry.key)) {
          _diagnosticsConfig.warn(
            DndWarning(
              code: 'duplicate-draggable-id',
              id: entry.key,
              message: 'Duplicate draggable id remained registered across multiple widgets after '
                  'reconciliation: ${entry.key}. Each active draggable in the same DndRegistry '
                  'must use a unique DndId.',
            ),
          );
        }
      }
    }

    _warnedDraggableDuplicates.removeWhere((id) => !duplicateIds.contains(id));
  }

  void _flushDeferredWarningsForDroppables() {
    final duplicateIds = <DndId>{};
    for (final entry in _droppableClaims.entries) {
      if (entry.value.length > 1) {
        duplicateIds.add(entry.key);
        if (_warnedDroppableDuplicates.add(entry.key)) {
          _diagnosticsConfig.warn(
            DndWarning(
              code: 'duplicate-droppable-id',
              id: entry.key,
              message: 'Duplicate droppable id remained registered across multiple widgets after '
                  'reconciliation: ${entry.key}. Each active droppable in the same DndRegistry '
                  'must use a unique DndId.',
            ),
          );
        }
      }
    }

    _warnedDroppableDuplicates.removeWhere((id) => !duplicateIds.contains(id));
  }

  void _warnDuplicate({
    required String code,
    required DndId id,
    required String label,
  }) {
    _diagnosticsConfig.warn(
      DndWarning(
        code: code,
        id: id,
        message: 'Duplicate $label id registered: $id. '
            'Each active $label in the same DndRegistry must use a unique DndId.',
      ),
    );
  }
}

bool _mapEquals<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }

  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }

  return true;
}

int _mapHash<V>(Map<DndId, V> map) {
  final entries = map.entries.toList()..sort((a, b) => a.key.value.compareTo(b.key.value));
  return Object.hashAll(entries.map((entry) => Object.hash(entry.key, entry.value)));
}
