import 'package:dnd_kit/dnd_kit.dart';
import 'package:test/test.dart';

void main() {
  group('DndPointerSensor', () {
    test('implements the core sensor runtime contract', () {
      final runtime = DndRuntime();
      final sensor = DndPointerSensor(runtime: runtime);

      expect(sensor, isA<DndSensor>());
      expect(sensor.descriptor.kind, DndSensorKind.pointer);
      expect(sensor.descriptor.inputKind, DndInputKind.pointer);
      expect(sensor.descriptor.constraint, DndSensorActivationConstraint.none);
      expect(
        sensor.descriptor.canActivate(
          const DndSensorActivationEvent(
            activeId: DndId('task-1'),
            position: DndPoint(0, 0),
            inputKind: DndInputKind.pointer,
          ),
        ),
        isTrue,
      );
      expect(
        sensor.descriptor.canActivate(
          const DndSensorActivationEvent(
            activeId: DndId('task-1'),
            position: DndPoint(0, 0),
            inputKind: DndInputKind.mouse,
          ),
        ),
        isTrue,
      );
      expect(
        sensor.descriptor.canActivate(
          const DndSensorActivationEvent(
            activeId: DndId('task-1'),
            position: DndPoint(0, 0),
            inputKind: DndInputKind.touch,
          ),
        ),
        isTrue,
      );
      expect(
        sensor.descriptor.canActivate(
          const DndSensorActivationEvent(
            activeId: DndId('task-1'),
            position: DndPoint(0, 0),
            inputKind: DndInputKind.keyboard,
          ),
        ),
        isFalse,
      );
    });

    test('drives runtime start, move, and end lifecycle', () {
      final runtime = DndRuntime();
      DndDragStartEvent? startEvent;
      DndDragMoveEvent? moveEvent;
      DndDragEndEvent? endEvent;

      final sensor = DndPointerSensor(
        runtime: runtime,
        onDragStart: (event) {
          startEvent = event;
        },
        onDragMove: (event) {
          moveEvent = event;
        },
        onDragEnd: (event) {
          endEvent = event;
        },
      );

      sensor.start(
        const DndSensorActivationEvent(
          activeId: DndId('task-1'),
          position: DndPoint(10, 10),
          inputKind: DndInputKind.pointer,
        ),
      );
      sensor.move(const DndPoint(20, 30));
      sensor.end();

      expect(startEvent?.activeId, const DndId('task-1'));
      expect(startEvent?.inputKind, DndInputKind.pointer);
      expect(moveEvent?.currentPointer, const DndPoint(20, 30));
      expect(endEvent?.currentPointer, const DndPoint(20, 30));
      expect(runtime.state, const DndIdle());
    });

    test('preserves specialized input kind in lifecycle events', () {
      final runtime = DndRuntime();
      DndDragStartEvent? startEvent;

      final sensor = DndPointerSensor(
        runtime: runtime,
        onDragStart: (event) {
          startEvent = event;
        },
      );

      sensor.start(
        const DndSensorActivationEvent(
          activeId: DndId('task-1'),
          position: DndPoint(10, 10),
          inputKind: DndInputKind.mouse,
        ),
      );

      expect(startEvent?.inputKind, DndInputKind.mouse);

      sensor.cancel();
    });

    test('cancels pending activation through the runtime', () {
      final runtime = DndRuntime();
      DndDragCancelEvent? cancelEvent;

      final sensor = DndPointerSensor(
        runtime: runtime,
        constraint: const DndSensorActivationConstraint(distance: 100),
        onDragCancel: (event) {
          cancelEvent = event;
        },
      );

      sensor.start(
        const DndSensorActivationEvent(
          activeId: DndId('task-1'),
          position: DndPoint(10, 10),
          inputKind: DndInputKind.pointer,
        ),
      );
      sensor.cancel();

      expect(cancelEvent?.activeId, const DndId('task-1'));
      expect(cancelEvent?.reason, DndCancelReason.sensor);
      expect(runtime.state, const DndIdle());
    });
  });
}
