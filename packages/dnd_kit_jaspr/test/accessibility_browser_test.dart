@TestOn('browser')
library;

import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/client_test.dart';
import 'package:universal_web/web.dart' as web;

void main() {
  group('DndLiveRegion browser', () {
    testClient('announces drag start, over, and drop across the lifecycle', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);

      tester.pumpComponent(
        DndScope(
          controller: controller,
          child: div([
            div(
              styles: Styles(position: Position.fixed(left: 240.px, top: 0.px)),
              [
                DndDroppable(
                  id: const DndId('column-2'),
                  child: article(
                    styles: Styles(width: 120.px, height: 120.px),
                    const [Component.text('drop zone')],
                  ),
                ),
              ],
            ),
            div(
              styles: Styles(position: Position.fixed(left: 0.px, top: 0.px)),
              [
                DndDraggable(
                  id: const DndId('task-1'),
                  label: 'Task one',
                  description: 'Press space to lift, arrow keys to move, space to drop.',
                  child: button([Component.text('handle')]),
                ),
              ],
            ),
            const DndLiveRegion(),
          ]),
        ),
      );

      expect(_liveRegionText(), '');

      await tester.dispatchEvent(
        find.tag('button'),
        _pointerEvent('pointerdown', x: 20, y: 20, pointerId: 1),
      );
      expect(_liveRegionText(), 'Picked up draggable item task-1.');

      await tester.dispatchEvent(
        find.tag('article'),
        _pointerEvent('pointermove', x: 280, y: 20, pointerId: 1),
      );
      expect(controller.overId, const DndId('column-2'));
      expect(_liveRegionText(), 'Draggable item task-1 moved over droppable column-2.');

      await tester.dispatchEvent(
        find.tag('article'),
        _pointerEvent('pointerup', x: 280, y: 20, pointerId: 1),
      );
      expect(_liveRegionText(), 'Draggable item task-1 was dropped over droppable column-2.');
      expect(controller.state, const DndIdle());
    });

    testClient('exposes a configurable label and keyboard description', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);

      tester.pumpComponent(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            label: 'Task one',
            description: 'Keyboard drag instructions.',
            child: button([Component.text('handle')]),
          ),
        ),
      );

      final draggable =
          web.document.querySelector('[aria-roledescription="draggable"]')! as web.HTMLElement;
      expect(draggable.getAttribute('aria-label'), 'Task one');

      final describedBy = draggable.getAttribute('aria-describedby');
      expect(describedBy, isNotNull);

      final description = web.document.getElementById(describedBy!);
      expect(description, isNotNull);
      expect(description!.textContent, 'Keyboard drag instructions.');
    });

    testClient('keyboard drag keeps focus on the activator', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);

      tester.pumpComponent(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            keyboardDragStep: 10,
            child: div([
              DndDragHandle(
                label: 'Drag task one',
                child: button([Component.text('handle')]),
              ),
            ]),
          ),
        ),
      );

      final handle = web.document.querySelector('button')! as web.HTMLElement;
      handle.focus();
      expect(web.document.activeElement, handle);

      await tester.dispatchEvent(find.tag('button'), _keyboardEvent('keydown', 'Enter'));
      expect(controller.isDragging, isTrue);
      expect(web.document.activeElement, handle);

      await tester.dispatchEvent(find.tag('button'), _keyboardEvent('keydown', 'ArrowDown'));
      expect(web.document.activeElement, handle);

      await tester.dispatchEvent(find.tag('button'), _keyboardEvent('keydown', 'Enter'));
      expect(controller.state, const DndIdle());
      expect(web.document.activeElement, handle);
    });
  });
}

String _liveRegionText() {
  return web.document.querySelector('[data-dnd-live-region]')?.textContent ?? '';
}

web.PointerEvent _pointerEvent(
  String type, {
  required int x,
  required int y,
  required int pointerId,
  String pointerType = 'mouse',
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
