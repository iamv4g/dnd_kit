import 'package:dnd_kit_core/dnd_kit_core.dart';
import 'package:test/test.dart';

void main() {
  group('DndSensorActivationEvent', () {
    test('compares by value', () {
      const first = DndSensorActivationEvent(
        activeId: DndId('drag'),
        position: DndPoint(1, 2),
        inputKind: DndInputKind.mouse,
        data: 'data',
      );
      const second = DndSensorActivationEvent(
        activeId: DndId('drag'),
        position: DndPoint(1, 2),
        inputKind: DndInputKind.mouse,
        data: 'data',
      );

      expect(first, equals(second));
      expect(first.hashCode, equals(second.hashCode));
      expect(first.toString(), contains('DndSensorActivationEvent'));
    });
  });

  group('DndSensorActivationConstraint', () {
    test('compares by value', () {
      const first = DndSensorActivationConstraint(
        distance: 4,
        delay: Duration(milliseconds: 120),
        tolerance: 8,
      );
      const second = DndSensorActivationConstraint(
        distance: 4,
        delay: Duration(milliseconds: 120),
        tolerance: 8,
      );

      expect(first, equals(second));
      expect(first.hashCode, equals(second.hashCode));
      expect(first.toString(), contains('DndSensorActivationConstraint'));
    });

    test('requires distance and delay before activation is satisfied', () {
      const constraint = DndSensorActivationConstraint(
        distance: 5,
        delay: Duration(milliseconds: 100),
      );

      expect(
        constraint.isSatisfied(
          initialPointer: DndPoint.zero,
          currentPointer: const DndPoint(3, 4),
          elapsed: const Duration(milliseconds: 99),
        ),
        isFalse,
      );
      expect(
        constraint.isSatisfied(
          initialPointer: DndPoint.zero,
          currentPointer: const DndPoint(2, 2),
          elapsed: const Duration(milliseconds: 100),
        ),
        isFalse,
      );
      expect(
        constraint.isSatisfied(
          initialPointer: DndPoint.zero,
          currentPointer: const DndPoint(3, 4),
          elapsed: const Duration(milliseconds: 100),
        ),
        isTrue,
      );
    });

    test('limits pending movement only while waiting for delay', () {
      const constraint = DndSensorActivationConstraint(
        delay: Duration(milliseconds: 100),
        tolerance: 4,
      );

      expect(
        constraint.allowsPendingMovement(
          initialPointer: DndPoint.zero,
          currentPointer: const DndPoint(3, 3),
          elapsed: const Duration(milliseconds: 50),
        ),
        isFalse,
      );
      expect(
        constraint.allowsPendingMovement(
          initialPointer: DndPoint.zero,
          currentPointer: const DndPoint(30, 30),
          elapsed: const Duration(milliseconds: 100),
        ),
        isTrue,
      );
    });

    test('has a none constraint that activates immediately', () {
      expect(
        DndSensorActivationConstraint.none.isSatisfied(
          initialPointer: DndPoint.zero,
          currentPointer: DndPoint.zero,
        ),
        isTrue,
      );
    });
  });

  group('DndSensorDescriptor', () {
    test('uses activator to decide whether an event can activate', () {
      final descriptor = DndSensorDescriptor(
        kind: DndSensorKind.pointer,
        inputKind: DndInputKind.pointer,
        activator: (event) => event.activeId == const DndId('enabled'),
      );

      expect(
        descriptor.canActivate(
          const DndSensorActivationEvent(
            activeId: DndId('enabled'),
            position: DndPoint.zero,
          ),
        ),
        isTrue,
      );
      expect(
        descriptor.canActivate(
          const DndSensorActivationEvent(
            activeId: DndId('disabled'),
            position: DndPoint.zero,
          ),
        ),
        isFalse,
      );
      expect(descriptor.toString(), contains('DndSensorDescriptor'));
    });
  });

  group('DndSensor', () {
    test('defines the adapter sensor lifecycle contract', () {
      final sensor = _RecordingSensor();

      sensor
        ..start(
          const DndSensorActivationEvent(
            activeId: DndId('drag'),
            position: DndPoint(1, 2),
          ),
        )
        ..move(const DndPoint(3, 4))
        ..end()
        ..cancel();

      expect(sensor.events, [
        'start:DndId(drag)',
        'move:DndPoint(3.0, 4.0)',
        'end',
        'cancel:DndCancelReason.sensor',
      ]);
    });
  });
}

final class _RecordingSensor implements DndSensor {
  final List<String> events = [];

  @override
  DndSensorDescriptor get descriptor {
    return DndSensorDescriptor(
      kind: DndSensorKind.custom,
      activator: (_) => true,
    );
  }

  @override
  void start(DndSensorActivationEvent event) {
    events.add('start:${event.activeId}');
  }

  @override
  void move(DndPoint position) {
    events.add('move:$position');
  }

  @override
  void end() {
    events.add('end');
  }

  @override
  void cancel({DndCancelReason reason = DndCancelReason.sensor}) {
    events.add('cancel:$reason');
  }
}
