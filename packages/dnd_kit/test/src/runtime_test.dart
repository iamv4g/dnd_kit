import 'package:dnd_kit/dnd_kit.dart';
import 'package:test/test.dart';

void main() {
  group('DndRuntime', () {
    test('starts idle with an empty registry', () {
      final runtime = DndRuntime();

      expect(runtime.state, const DndIdle());
      expect(runtime.isIdle, isTrue);
      expect(runtime.isDragging, isFalse);
      expect(runtime.activeId, isNull);
      expect(runtime.activeSession, isNull);
      expect(runtime.registry.snapshot, DndRegistrySnapshot.empty);
    });

    test('reports diagnostics through its registry', () {
      final warnings = <DndWarning>[];
      final runtime = DndRuntime(
        diagnosticsConfig: DndDiagnosticsConfig(onWarning: warnings.add),
      );

      runtime.registry.registerDraggable(
        const DndDraggableRegistration(id: DndId('task-1')),
      );
      expect(
        () => runtime.registry.registerDraggable(
          const DndDraggableRegistration(id: DndId('task-1')),
        ),
        throwsA(isA<AssertionError>()),
      );
      runtime.registry.registerDroppable(
        const DndDroppableRegistration(id: DndId('column-1')),
      );
      expect(
        () => runtime.registry.registerDroppable(
          const DndDroppableRegistration(id: DndId('column-1')),
        ),
        throwsA(isA<AssertionError>()),
      );

      expect(
        warnings,
        contains(
          isA<DndWarning>()
              .having((warning) => warning.code, 'code', 'duplicate-draggable-id')
              .having((warning) => warning.id, 'id', const DndId('task-1')),
        ),
      );
      expect(
        warnings,
        contains(
          isA<DndWarning>()
              .having((warning) => warning.code, 'code', 'duplicate-droppable-id')
              .having((warning) => warning.id, 'id', const DndId('column-1')),
        ),
      );
    });

    test('notifies through drag lifecycle transitions', () {
      var notificationCount = 0;
      final runtime = DndRuntime(onNotify: () => notificationCount += 1);

      runtime.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('task-1'),
          position: DndPoint(10, 20),
          inputKind: DndInputKind.mouse,
        ),
      );
      expect(runtime.state, isA<DndPending>());
      expect(runtime.activeId, const DndId('task-1'));

      final startEvent = runtime.startDrag();
      expect(startEvent, isA<DndDragStartEvent>());
      expect(runtime.isDragging, isTrue);
      expect(runtime.activeSession?.currentPointer, const DndPoint(10, 20));

      final moveEvent = runtime.moveDrag(const DndPoint(14, 25));
      expect(moveEvent?.delta, const DndPoint(4, 5));
      expect(runtime.activeSession?.currentPointer, const DndPoint(14, 25));

      final endEvent = runtime.endDrag(overId: const DndId('column-done'));
      expect(endEvent?.overId, const DndId('column-done'));
      expect(runtime.state, isA<DndDropping>());

      runtime.reset();
      expect(runtime.state, const DndIdle());
      expect(notificationCount, 5);
    });

    test('cancels pending and active drags', () {
      final runtime = DndRuntime();

      runtime.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('task-1'),
          position: DndPoint.zero,
        ),
      );
      final pendingCancel = runtime.cancelDrag(reason: DndCancelReason.user);
      expect(pendingCancel?.activeId, const DndId('task-1'));
      expect(pendingCancel?.session, isNull);
      expect(runtime.state, isA<DndCancelled>());

      runtime.reset();
      runtime.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('task-2'),
          position: DndPoint.zero,
        ),
      );
      runtime.startDrag();
      runtime.moveDrag(const DndPoint(3, 4));

      final activeCancel = runtime.cancelDrag(reason: DndCancelReason.disabled);
      expect(activeCancel?.activeId, const DndId('task-2'));
      expect(activeCancel?.session?.currentPointer, const DndPoint(3, 4));
      expect(activeCancel?.reason, DndCancelReason.disabled);
      expect(runtime.state, isA<DndCancelled>());
    });

    test('applies modifiers to drag movement and collision detection', () {
      final runtime = DndRuntime(
        modifiers: const <DndModifier>[
          DndModifiers.restrictToHorizontalAxis,
        ],
      );

      runtime.registry.registerDroppable(const DndDroppableRegistration(id: DndId('column-1')));
      runtime.measuring.updateDroppableRect(
        const DndId('column-1'),
        const DndRect(left: 100, top: 0, width: 80, height: 80),
      );

      runtime.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('task-1'),
          position: DndPoint(20, 20),
        ),
        activeRect: const DndRect(left: 0, top: 0, width: 40, height: 40),
      );
      runtime.startDrag();

      final moveEvent = runtime.moveDrag(const DndPoint(120, 120));

      expect(moveEvent?.currentPointer, const DndPoint(120, 20));
      expect(moveEvent?.delta, const DndPoint(100, 0));
      expect(runtime.activeSession?.transform, const DndTransform(x: 100));
      expect(runtime.overId, const DndId('column-1'));
    });

    test('passes the active draggable id to the collision detector', () {
      DndCollisionInput? captured;
      final runtime = DndRuntime(
        collisionDetector: (input) {
          captured = input;
          return DndCollisionDetectors.closestCenter(input);
        },
      );

      runtime.registry.registerDroppable(
        const DndDroppableRegistration(id: DndId('column-1')),
      );
      runtime.measuring.updateDroppableRect(
        const DndId('column-1'),
        const DndRect(left: 100, top: 0, width: 80, height: 80),
      );

      runtime.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('task-1'),
          position: DndPoint(20, 20),
        ),
        activeRect: const DndRect(left: 0, top: 0, width: 40, height: 40),
      );
      runtime.startDrag();
      runtime.moveDrag(const DndPoint(120, 20));

      expect(captured?.activeId, const DndId('task-1'));
    });

    test('excludes the active draggable from collision candidates', () {
      DndCollisionInput? captured;
      final runtime = DndRuntime(
        collisionDetector: (input) {
          captured = input;
          return DndCollisionDetectors.compose(
            const <DndCollisionDetector>[
              DndCollisionDetectors.pointerWithin,
              DndCollisionDetectors.rectIntersection,
            ],
          )(input);
        },
      );

      // Sortable-style setup: the active item registers the same id as
      // draggable and droppable, sitting directly above a neighbouring item.
      runtime.registry.registerDroppable(const DndDroppableRegistration(id: DndId('task-1')));
      runtime.registry.registerDroppable(const DndDroppableRegistration(id: DndId('task-2')));
      runtime.measuring.updateDroppableRect(
        const DndId('task-1'),
        const DndRect(left: 0, top: 0, width: 100, height: 40),
      );
      runtime.measuring.updateDroppableRect(
        const DndId('task-2'),
        const DndRect(left: 0, top: 40, width: 100, height: 40),
      );

      runtime.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('task-1'),
          position: DndPoint(50, 20),
        ),
        activeRect: const DndRect(left: 0, top: 0, width: 100, height: 40),
      );
      runtime.startDrag();

      // The pointer is still inside the active item's own slot; without the
      // exclusion the active would win its own pointer test and become overId.
      runtime.moveDrag(const DndPoint(50, 30));

      expect(captured?.droppableRects.containsKey(const DndId('task-1')), isFalse);
      expect(captured?.droppableRects.containsKey(const DndId('task-2')), isTrue);
      expect(runtime.overId, const DndId('task-2'));
    });

    test('resolves the neighbouring target without overshooting the source slot', () {
      final runtime = DndRuntime();

      runtime.registry.registerDroppable(const DndDroppableRegistration(id: DndId('task-1')));
      runtime.registry.registerDroppable(const DndDroppableRegistration(id: DndId('task-2')));
      runtime.measuring.updateDroppableRect(
        const DndId('task-1'),
        const DndRect(left: 0, top: 0, width: 100, height: 40),
      );
      runtime.measuring.updateDroppableRect(
        const DndId('task-2'),
        const DndRect(left: 0, top: 40, width: 100, height: 40),
      );

      runtime.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('task-1'),
          position: DndPoint(50, 20),
        ),
        activeRect: const DndRect(left: 0, top: 0, width: 100, height: 40),
      );
      runtime.startDrag();

      // Pointer enters the neighbour: it must win immediately.
      runtime.moveDrag(const DndPoint(50, 45));
      expect(runtime.overId, const DndId('task-2'));

      final endEvent = runtime.endDrag();
      expect(endEvent?.overId, const DndId('task-2'));
    });

    test('remeasures stale droppables at drag start', () {
      final runtime = DndRuntime();

      // The droppable was measured before an ancestor scrolled: the cache is
      // clean but the stored rect no longer matches the widget's position.
      var measuredRect = const DndRect(left: 0, top: 200, width: 100, height: 40);
      runtime.registry.registerDroppable(const DndDroppableRegistration(id: DndId('column-1')));
      runtime.measuring.markDroppableDirty(
        const DndId('column-1'),
        measure: () => measuredRect,
      );
      runtime.measuring.refreshDirty();
      measuredRect = const DndRect(left: 0, top: 40, width: 100, height: 40);

      runtime.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('task-1'),
          position: DndPoint(50, 20),
        ),
        activeRect: const DndRect(left: 0, top: 0, width: 100, height: 40),
      );
      runtime.startDrag();
      runtime.moveDrag(const DndPoint(50, 60));

      expect(
        runtime.overId,
        const DndId('column-1'),
        reason: 'collision must use the post-scroll rect, not the stale cache',
      );
    });

    test('remeasures a stale active rect at drag start when none is provided', () {
      final runtime = DndRuntime();

      var measuredRect = const DndRect(left: 0, top: 200, width: 100, height: 40);
      runtime.measuring.markDraggableDirty(
        const DndId('task-1'),
        measure: () => measuredRect,
      );
      runtime.measuring.refreshDirty();
      measuredRect = const DndRect(left: 0, top: 40, width: 100, height: 40);

      runtime.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('task-1'),
          position: DndPoint(50, 60),
        ),
      );

      expect(runtime.activeRect, const DndRect(left: 0, top: 40, width: 100, height: 40));
    });

    test('keeps the drag-start rect stable while the source collapses', () {
      final runtime = DndRuntime();

      const activeId = DndId('task-1');
      runtime.beginDrag(
        const DndSensorActivationEvent(
          activeId: activeId,
          position: DndPoint(20, 20),
        ),
        activeRect: const DndRect(left: 0, top: 0, width: 100, height: 40),
      );
      runtime.startDrag();

      // The application collapses the source slot to open a placeholder gap.
      runtime.measuring.updateDraggableRect(
        activeId,
        const DndRect(left: 0, top: 0, width: 100, height: 0),
      );
      runtime.moveDrag(const DndPoint(20, 60));

      expect(runtime.activeRect?.height, 0, reason: 'live rect follows the source');
      expect(
        runtime.initialActiveRect,
        const DndRect(left: 0, top: 0, width: 100, height: 40),
      );

      runtime.endDrag();
      runtime.reset();
      expect(runtime.initialActiveRect, isNull);
    });

    test('refreshes dirty measurements before collision detection', () {
      final runtime = DndRuntime();

      runtime.registry.registerDroppable(const DndDroppableRegistration(id: DndId('column-1')));
      runtime.measuring.updateDroppableRect(
        const DndId('column-1'),
        const DndRect(left: 300, top: 0, width: 80, height: 80),
      );
      runtime.measuring.markDroppableDirty(
        const DndId('column-1'),
        measure: () => const DndRect(left: 100, top: 0, width: 80, height: 80),
      );

      runtime.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('task-1'),
          position: DndPoint(20, 20),
        ),
        activeRect: const DndRect(left: 0, top: 0, width: 40, height: 40),
      );
      runtime.startDrag();
      runtime.moveDrag(const DndPoint(120, 20));

      expect(
          runtime.measuring.droppableStatus(const DndId('column-1')), DndMeasurementStatus.clean);
      expect(runtime.overId, const DndId('column-1'));
    });

    test('refreshes dirty active measurements before modifier input', () {
      final runtime = DndRuntime(
        modifiers: <DndModifier>[
          DndModifiers.restrictToBoundary(
            const DndRect(left: 0, top: 0, width: 100, height: 100),
          ),
        ],
      );

      runtime.measuring.updateDraggableRect(
        const DndId('task-1'),
        const DndRect(left: 0, top: 0, width: 40, height: 40),
      );
      runtime.measuring.markDraggableDirty(
        const DndId('task-1'),
        measure: () => const DndRect(left: 0, top: 0, width: 80, height: 80),
      );

      runtime.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('task-1'),
          position: DndPoint.zero,
          inputKind: DndInputKind.keyboard,
        ),
        activeRect: const DndRect(left: 0, top: 0, width: 40, height: 40),
      );
      runtime.startDrag();
      final moveEvent = runtime.moveDrag(const DndPoint(100, 100));

      expect(runtime.measuring.draggableStatus(const DndId('task-1')), DndMeasurementStatus.clean);
      expect(moveEvent?.currentPointer, const DndPoint(20, 20));
    });

    test('keeps active rect origin stable when source measurement shifts during drag', () {
      DndCollisionInput? latestInput;
      final runtime = DndRuntime(
        collisionDetector: (input) {
          latestInput = input;
          return DndCollisionResult.empty;
        },
      );

      runtime.registry.registerDroppable(const DndDroppableRegistration(id: DndId('column-1')));
      runtime.measuring.updateDroppableRect(
        const DndId('column-1'),
        const DndRect(left: 0, top: 0, width: 400, height: 400),
      );

      const activeId = DndId('task-1');
      runtime.beginDrag(
        const DndSensorActivationEvent(
          activeId: activeId,
          position: DndPoint(110, 110),
        ),
        activeRect: const DndRect(left: 100, top: 100, width: 40, height: 50),
      );
      runtime.startDrag();
      runtime.moveDrag(const DndPoint(130, 140));

      expect(
        latestInput?.activeRect,
        const DndRect(left: 120, top: 130, width: 40, height: 50),
      );

      runtime.measuring.updateDraggableRect(
        activeId,
        const DndRect(left: 40, top: 20, width: 60, height: 70),
      );
      runtime.moveDrag(const DndPoint(132, 142));

      expect(
        latestInput?.activeRect,
        const DndRect(left: 122, top: 132, width: 60, height: 70),
        reason:
            'scroll-driven source remeasurement should update size without moving the drag origin',
      );
    });
  });
}
