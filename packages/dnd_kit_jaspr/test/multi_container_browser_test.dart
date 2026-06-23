@TestOn('browser')
library;

// ignore_for_file: experimental_member_use

import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/client_test.dart';
import 'package:universal_web/web.dart' as web;

void main() {
  group('SortableMultiContainer browser', () {
    testClient(
      'computes cross-container move intent from a Jaspr drag flow',
      (tester) async {
        final controller = DndController();
        addTearDown(controller.dispose);
        final containers = <SortableContainer>[
          SortableContainer(
            id: const DndId('todo'),
            itemIds: const <DndId>[DndId('task-1')],
          ),
          SortableContainer(
            id: const DndId('done'),
            itemIds: const <DndId>[],
          ),
        ];
        SortableMoveDetails? move;

        tester.pumpComponent(
          DndScope(
            controller: controller,
            child: div([
              div(
                styles: Styles(position: Position.fixed(left: 0.px, top: 0.px)),
                [
                  DndDraggable(
                    id: const DndId('task-1'),
                    onDragEnd: (event) {
                      move = SortableMultiContainer.moveDetailsFor(
                        event,
                        containers: containers,
                      );
                    },
                    child: button([Component.text('task')]),
                  ),
                ],
              ),
              div(
                styles: Styles(position: Position.fixed(left: 240.px, top: 0.px)),
                [
                  DndDroppable(
                    id: const DndId('done'),
                    child: article(
                      styles: Styles(width: 120.px, height: 120.px),
                      const [Component.text('done')],
                    ),
                  ),
                ],
              ),
            ]),
          ),
        );

        await tester.dispatchEvent(
          find.tag('button'),
          _pointerEvent('pointerdown', x: 20, y: 20, pointerId: 1),
        );
        await tester.dispatchEvent(
          find.tag('article'),
          _pointerEvent('pointermove', x: 280, y: 20, pointerId: 1),
        );

        expect(controller.overId, const DndId('done'));

        await tester.dispatchEvent(
          find.tag('article'),
          _pointerEvent('pointerup', x: 280, y: 20, pointerId: 1),
        );

        expect(move, isNotNull);
        expect(move!.activeId, const DndId('task-1'));
        expect(move!.overId, const DndId('done'));
        expect(move!.fromContainerId, const DndId('todo'));
        expect(move!.toContainerId, const DndId('done'));
        expect(move!.fromIndex, 0);
        expect(move!.toIndex, 0);
        expect(controller.state, const DndIdle());
      },
    );
  });
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
