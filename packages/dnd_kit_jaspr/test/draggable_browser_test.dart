@TestOn('browser')
library;

import 'dart:async';

import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/client_test.dart';
import 'package:universal_web/web.dart' as web;

void main() {
  group('DndDraggable browser input', () {
    testClient('starts from a handle and ignores the body when a handle exists', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      DndDragStartEvent? startEvent;
      DndDragEndEvent? endEvent;

      tester.pumpComponent(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            onDragStart: (event) => startEvent = event,
            onDragEnd: (event) => endEvent = event,
            child: div([
              DndDragHandle(
                child: button([Component.text('handle')]),
              ),
              section([Component.text('body')]),
            ]),
          ),
        ),
      );

      await tester.dispatchEvent(
        find.tag('button'),
        _pointerEvent('pointerdown', x: 10, y: 10, pointerType: 'mouse', pointerId: 1),
      );
      await tester.dispatchEvent(
        find.tag('button'),
        _pointerEvent('pointermove', x: 40, y: 10, pointerType: 'mouse', pointerId: 1),
      );
      await tester.dispatchEvent(
        find.tag('button'),
        _pointerEvent('pointerup', x: 40, y: 10, pointerType: 'mouse', pointerId: 1),
      );

      expect(startEvent?.activeId, const DndId('task-1'));
      expect(startEvent?.inputKind, DndInputKind.mouse);
      expect(endEvent?.activeId, const DndId('task-1'));
      expect(controller.state, const DndIdle());

      startEvent = null;
      endEvent = null;

      await tester.dispatchEvent(
        find.tag('section'),
        _pointerEvent('pointerdown', x: 80, y: 80, pointerType: 'mouse', pointerId: 2),
      );
      await tester.dispatchEvent(
        find.tag('section'),
        _pointerEvent('pointermove', x: 120, y: 80, pointerType: 'mouse', pointerId: 2),
      );
      await tester.dispatchEvent(
        find.tag('section'),
        _pointerEvent('pointerup', x: 120, y: 80, pointerType: 'mouse', pointerId: 2),
      );

      expect(startEvent, isNull);
      expect(endEvent, isNull);
      expect(controller.state, const DndIdle());
    });

    testClient('touch waits for the default hold while mouse starts immediately', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      DndDragStartEvent? startEvent;
      DndDragCancelEvent? cancelEvent;

      tester.pumpComponent(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            onDragStart: (event) => startEvent = event,
            onDragCancel: (event) => cancelEvent = event,
            child: section([Component.text('body')]),
          ),
        ),
      );

      await tester.dispatchEvent(
        find.tag('section'),
        _pointerEvent('pointerdown', x: 10, y: 10, pointerType: 'touch', pointerId: 3),
      );
      await tester.dispatchEvent(
        find.tag('section'),
        _pointerEvent('pointermove', x: 30, y: 10, pointerType: 'touch', pointerId: 3),
      );
      await tester.dispatchEvent(
        find.tag('section'),
        _pointerEvent('pointerup', x: 30, y: 10, pointerType: 'touch', pointerId: 3),
      );

      expect(startEvent, isNull);
      expect(cancelEvent?.activeId, const DndId('task-1'));
      expect(cancelEvent?.reason, DndCancelReason.sensor);
      expect(controller.state, const DndIdle());

      startEvent = null;
      cancelEvent = null;

      await tester.dispatchEvent(
        find.tag('section'),
        _pointerEvent('pointerdown', x: 10, y: 10, pointerType: 'touch', pointerId: 4),
      );
      await Future<void>.delayed(const Duration(milliseconds: 550));
      await tester.dispatchEvent(
        find.tag('section'),
        _pointerEvent('pointerup', x: 10, y: 10, pointerType: 'touch', pointerId: 4),
      );

      expect(startEvent?.activeId, const DndId('task-1'));
      expect(startEvent?.inputKind, DndInputKind.touch);
      expect(controller.state, const DndIdle());
    });

    testClient('supports keyboard pickup, movement, and drop from a handle', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      DndDragStartEvent? startEvent;
      final moveEvents = <DndDragMoveEvent>[];
      DndDragEndEvent? endEvent;

      tester.pumpComponent(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            keyboardDragStep: 10,
            onDragStart: (event) => startEvent = event,
            onDragMove: moveEvents.add,
            onDragEnd: (event) => endEvent = event,
            child: div([
              DndDragHandle(
                child: button([Component.text('handle')]),
              ),
            ]),
          ),
        ),
      );

      await tester.dispatchEvent(
        find.tag('button'),
        _keyboardEvent('keydown', 'Enter'),
      );
      await tester.dispatchEvent(
        find.tag('button'),
        _keyboardEvent('keydown', 'ArrowRight'),
      );
      await tester.dispatchEvent(
        find.tag('button'),
        _keyboardEvent('keydown', 'ArrowDown'),
      );
      await tester.dispatchEvent(
        find.tag('button'),
        _keyboardEvent('keydown', 'Enter'),
      );

      expect(startEvent?.activeId, const DndId('task-1'));
      expect(startEvent?.inputKind, DndInputKind.keyboard);
      expect(moveEvents, hasLength(2));
      expect(moveEvents.last.session.delta, const DndPoint(10, 10));
      expect(endEvent?.activeId, const DndId('task-1'));
      expect(endEvent?.inputKind, DndInputKind.keyboard);
      expect(controller.state, const DndIdle());
    });
  });
}

web.PointerEvent _pointerEvent(
  String type, {
  required int x,
  required int y,
  required String pointerType,
  required int pointerId,
}) {
  return web.PointerEvent(
    type,
    web.PointerEventInit(
      bubbles: true,
      cancelable: true,
      composed: true,
      clientX: x,
      clientY: y,
      pointerType: pointerType,
      pointerId: pointerId,
    ),
  );
}

web.KeyboardEvent _keyboardEvent(String type, String key) {
  return web.KeyboardEvent(
    type,
    web.KeyboardEventInit(
      bubbles: true,
      cancelable: true,
      composed: true,
      key: key,
    ),
  );
}
