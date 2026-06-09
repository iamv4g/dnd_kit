import 'package:dnd_kit_core/dnd_kit_core.dart';
import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DndController', () {
    test('starts idle with an empty registry', () {
      final controller = DndController();
      addTearDown(controller.dispose);

      expect(controller.state, const DndIdle());
      expect(controller.isIdle, isTrue);
      expect(controller.isDragging, isFalse);
      expect(controller.activeId, isNull);
      expect(controller.activeSession, isNull);
      expect(controller.registry.snapshot, DndRegistrySnapshot.empty);
    });

    test('notifies listeners through drag lifecycle transitions', () {
      final controller = DndController();
      addTearDown(controller.dispose);
      var notificationCount = 0;
      controller.addListener(() {
        notificationCount += 1;
      });

      controller.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('task-1'),
          position: DndPoint(10, 20),
          inputKind: DndInputKind.mouse,
        ),
      );
      expect(controller.state, isA<DndPending>());
      expect(controller.activeId, const DndId('task-1'));

      final startEvent = controller.startDrag();
      expect(startEvent, isA<DndDragStartEvent>());
      expect(controller.isDragging, isTrue);
      expect(controller.activeSession?.currentPointer, const DndPoint(10, 20));

      final moveEvent = controller.moveDrag(const DndPoint(14, 25));
      expect(moveEvent?.delta, const DndPoint(4, 5));
      expect(controller.activeSession?.currentPointer, const DndPoint(14, 25));

      final endEvent = controller.endDrag(overId: const DndId('column-done'));
      expect(endEvent?.overId, const DndId('column-done'));
      expect(controller.state, isA<DndDropping>());

      controller.reset();
      expect(controller.state, const DndIdle());
      expect(notificationCount, 5);
    });

    test('cancels pending and active drags', () {
      final controller = DndController();
      addTearDown(controller.dispose);

      controller.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('task-1'),
          position: DndPoint.zero,
        ),
      );
      final pendingCancel = controller.cancelDrag(reason: DndCancelReason.user);
      expect(pendingCancel?.activeId, const DndId('task-1'));
      expect(pendingCancel?.session, isNull);
      expect(controller.state, isA<DndCancelled>());

      controller.reset();
      controller.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('task-2'),
          position: DndPoint.zero,
        ),
      );
      controller.startDrag();
      controller.moveDrag(const DndPoint(3, 4));

      final activeCancel = controller.cancelDrag(reason: DndCancelReason.disabled);
      expect(activeCancel?.activeId, const DndId('task-2'));
      expect(activeCancel?.session?.currentPointer, const DndPoint(3, 4));
      expect(activeCancel?.reason, DndCancelReason.disabled);
      expect(controller.state, isA<DndCancelled>());
    });
  });
}
