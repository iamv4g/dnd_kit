import 'geometry.dart';
import 'id.dart';
import 'state.dart';

/// The type of sensor producing drag activation input.
enum DndSensorKind {
  /// Generic pointer sensor.
  pointer,

  /// Mouse-specific sensor.
  mouse,

  /// Touch-specific sensor.
  touch,

  /// Keyboard sensor.
  keyboard,

  /// Application or adapter-defined sensor.
  custom,
}

/// Pure Dart activation data shared by sensor implementations.
final class DndSensorActivationEvent {
  /// Creates sensor activation data.
  const DndSensorActivationEvent({
    required this.activeId,
    required this.position,
    this.inputKind = DndInputKind.unknown,
    this.data,
  });

  /// The draggable that may become active.
  final DndId activeId;

  /// The normalized activation position.
  final DndPoint position;

  /// The input source represented by this activation.
  final DndInputKind inputKind;

  /// Optional adapter-owned activation data.
  final Object? data;

  @override
  bool operator ==(Object other) {
    return other is DndSensorActivationEvent &&
        other.activeId == activeId &&
        other.position == position &&
        other.inputKind == inputKind &&
        other.data == data;
  }

  @override
  int get hashCode => Object.hash(activeId, position, inputKind, data);

  @override
  String toString() {
    return 'DndSensorActivationEvent(activeId: $activeId, position: $position, '
        'inputKind: $inputKind, data: $data)';
  }
}

/// Activation constraints used by sensors before a drag session starts.
final class DndSensorActivationConstraint {
  /// Creates sensor activation constraints.
  const DndSensorActivationConstraint({
    this.distance = 0,
    this.delay = Duration.zero,
    this.tolerance = double.infinity,
  })  : assert(distance >= 0, 'Activation distance must be non-negative.'),
        assert(tolerance >= 0, 'Activation tolerance must be non-negative.');

  /// No distance or delay is required before activation.
  static const none = DndSensorActivationConstraint();

  /// The minimum movement required before activation.
  final double distance;

  /// The minimum elapsed time required before activation.
  final Duration delay;

  /// The maximum movement allowed while waiting for [delay].
  final double tolerance;

  /// Whether [currentPointer] satisfies the distance and delay requirements.
  bool isSatisfied({
    required DndPoint initialPointer,
    required DndPoint currentPointer,
    Duration elapsed = Duration.zero,
  }) {
    return elapsed >= delay &&
        _distanceSquared(initialPointer, currentPointer) >= distance * distance;
  }

  /// Whether movement is still allowed before the delay has elapsed.
  bool allowsPendingMovement({
    required DndPoint initialPointer,
    required DndPoint currentPointer,
    Duration elapsed = Duration.zero,
  }) {
    if (elapsed >= delay) {
      return true;
    }

    return _distanceSquared(initialPointer, currentPointer) <= tolerance * tolerance;
  }

  @override
  bool operator ==(Object other) {
    return other is DndSensorActivationConstraint &&
        other.distance == distance &&
        other.delay == delay &&
        other.tolerance == tolerance;
  }

  @override
  int get hashCode => Object.hash(distance, delay, tolerance);

  @override
  String toString() {
    return 'DndSensorActivationConstraint(distance: $distance, delay: $delay, '
        'tolerance: $tolerance)';
  }
}

/// Decides whether a sensor activation event should start pending activation.
typedef DndSensorActivator = bool Function(DndSensorActivationEvent event);

/// Describes a sensor that an adapter can install.
final class DndSensorDescriptor {
  /// Creates a sensor descriptor.
  const DndSensorDescriptor({
    required this.kind,
    required this.activator,
    this.inputKind = DndInputKind.unknown,
    this.constraint = DndSensorActivationConstraint.none,
  });

  /// The sensor category.
  final DndSensorKind kind;

  /// The drag session input source this sensor produces.
  final DndInputKind inputKind;

  /// The constraint applied after activation begins.
  final DndSensorActivationConstraint constraint;

  /// Whether this descriptor should respond to an activation event.
  final DndSensorActivator activator;

  /// Returns whether [event] can activate this sensor.
  bool canActivate(DndSensorActivationEvent event) => activator(event);

  @override
  String toString() {
    return 'DndSensorDescriptor(kind: $kind, inputKind: $inputKind, '
        'constraint: $constraint)';
  }
}

/// Interface implemented by adapter-specific sensor runtimes.
abstract interface class DndSensor {
  /// The descriptor used to register this sensor.
  DndSensorDescriptor get descriptor;

  /// Starts tracking the activation event.
  void start(DndSensorActivationEvent event);

  /// Updates the latest normalized pointer position.
  void move(DndPoint position);

  /// Ends the sensor lifecycle normally.
  void end();

  /// Cancels the sensor lifecycle.
  void cancel({DndCancelReason reason = DndCancelReason.sensor});
}

double _distanceSquared(DndPoint first, DndPoint second) {
  final delta = first.difference(second);
  return delta.x * delta.x + delta.y * delta.y;
}
