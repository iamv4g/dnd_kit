@TestOn('browser')
library;

import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/client_test.dart';
import 'package:universal_web/web.dart' as web;

void main() {
  group('Sortable offsets browser', () {
    testClient(
      'applying an offset in the builder leaves measured rects unshifted',
      (tester) async {
        const itemIds = <DndId>[DndId('item-0'), DndId('item-1'), DndId('item-2')];
        final controller = DndController();
        final offsets = <DndId, DndPoint>{};

        tester.pumpComponent(
          SortableScope(
            controller: controller,
            itemIds: itemIds,
            strategy: SortableStrategies.dropOnOver,
            offsetResolver: SortableOffsets.verticalList,
            child: div(
              styles: Styles(position: Position.fixed(left: 0.px, top: 0.px)),
              [
                for (final id in itemIds)
                  SortableItem(
                    id: id,
                    builder: (context, details, child) {
                      offsets[details.id] = details.offset;
                      // Applied inside the builder, so the transform lands on a
                      // child of the measured element rather than on it.
                      return div(
                        styles: Styles(
                          transform: details.offset == DndPoint.zero
                              ? Transform.none
                              : Transform.translate(
                                  x: details.offset.x.px,
                                  y: details.offset.y.px,
                                ),
                        ),
                        [child],
                      );
                    },
                    child: button(
                      attributes: {'data-item': id.value},
                      styles: Styles(display: Display.block, width: 100.px, height: 40.px),
                      [Component.text(id.value)],
                    ),
                  ),
              ],
            ),
          ),
        );

        double? measuredTopOf(DndId id) {
          return controller.measuring.droppableRect(id)?.top;
        }

        // Materialize the resting layout before any drag, so the baseline is
        // taken with every offset still zero.
        await Future<void>.delayed(Duration.zero);
        controller.measuring.refreshDirty();
        final restingTop = measuredTopOf(const DndId('item-1'));
        expect(restingTop, isNotNull);
        expect(offsets[const DndId('item-1')] ?? DndPoint.zero, DndPoint.zero);

        await tester.dispatchEvent(
          find.tag('button').first,
          _pointerEvent('pointerdown', x: 20, y: 20, pointerId: 1),
        );
        await tester.dispatchEvent(
          find.tag('button').first,
          _pointerEvent('pointermove', x: 20, y: 100, pointerId: 1),
        );

        expect(controller.overId, const DndId('item-2'));
        expect(
          offsets[const DndId('item-1')],
          isNot(DndPoint.zero),
          reason: 'item-1 is displaced by the previewed move',
        );

        expect(
          measuredTopOf(const DndId('item-1')),
          restingTop,
          reason: 'a CSS transform below the measured element must not move its rect',
        );

        await tester.dispatchEvent(
          find.tag('button').first,
          _pointerEvent('pointerup', x: 20, y: 100, pointerId: 1),
        );
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
