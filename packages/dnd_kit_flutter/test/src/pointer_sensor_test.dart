import 'package:dnd_kit_core/dnd_kit_core.dart';
import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DndPointerSensor', () {
    test('implements the core sensor runtime contract', () {
      final controller = DndController();
      addTearDown(controller.dispose);

      final sensor = DndPointerSensor(controller: controller);

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
    });

    test('drives controller start, move, and end lifecycle', () {
      final controller = DndController();
      addTearDown(controller.dispose);
      DndDragStartEvent? startEvent;
      DndDragMoveEvent? moveEvent;
      DndDragEndEvent? endEvent;

      final sensor = DndPointerSensor(
        controller: controller,
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
      expect(moveEvent?.currentPointer, const DndPoint(20, 30));
      expect(endEvent?.currentPointer, const DndPoint(20, 30));
      expect(controller.state, const DndIdle());
    });

    test('cancels pending activation through the controller', () {
      final controller = DndController();
      addTearDown(controller.dispose);
      DndDragCancelEvent? cancelEvent;

      final sensor = DndPointerSensor(
        controller: controller,
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
      expect(controller.state, const DndIdle());
    });
  });
}
