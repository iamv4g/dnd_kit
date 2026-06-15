import 'package:dnd_kit/dnd_kit.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind, kLongPressTimeout;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for US-040: a `DndDraggable` must be able to drag while
/// nested in a vertical lazy `ListView.builder`, winning the gesture arena over
/// the scrollable's vertical drag recognizer.
void main() {
  const itemExtent = 60.0;

  Widget harness({
    required DndController controller,
    required ScrollController scrollController,
    required void Function(int moveCount) onMoves,
  }) {
    final ids = List<DndId>.generate(40, (i) => DndId('item-$i'));

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox(
          width: 200,
          height: 300,
          child: DndScope(
            controller: controller,
            child: ListView.builder(
              controller: scrollController,
              itemExtent: itemExtent,
              itemCount: ids.length,
              itemBuilder: (context, index) {
                final id = ids[index];
                return DndDroppable(
                  id: id,
                  child: DndDraggable(
                    id: id,
                    onDragMove: (_) => onMoves(1),
                    child: SizedBox(
                      key: ValueKey(id),
                      height: itemExtent,
                      child: Text('$id'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('mouse drag starts and tracks inside a lazy ListView.builder', (tester) async {
    final controller = DndController();
    final scrollController = ScrollController();
    addTearDown(controller.dispose);
    addTearDown(scrollController.dispose);

    var moves = 0;
    await tester.pumpWidget(
      harness(
        controller: controller,
        scrollController: scrollController,
        onMoves: (n) => moves += n,
      ),
    );
    await tester.pump();

    final start = tester.getCenter(find.byKey(const ValueKey(DndId('item-0'))));
    final gesture = await tester.startGesture(start, kind: PointerDeviceKind.mouse);
    for (var i = 0; i < 4; i++) {
      await gesture.moveBy(const Offset(0, 24));
      await tester.pump();
    }

    expect(controller.isDragging, isTrue);
    expect(moves, greaterThan(0));
    expect(scrollController.offset, 0, reason: 'the list must not scroll mid-drag');
    // The drag tracked the pointer past its origin item.
    expect((controller.activeSession?.transform.offset.y ?? 0), greaterThan(0));

    await gesture.up();
    await tester.pump();
  });

  testWidgets('touch drag waits for the hold delay inside a lazy ListView.builder', (tester) async {
    final controller = DndController();
    final scrollController = ScrollController();
    addTearDown(controller.dispose);
    addTearDown(scrollController.dispose);

    var moves = 0;
    await tester.pumpWidget(
      harness(
        controller: controller,
        scrollController: scrollController,
        onMoves: (n) => moves += n,
      ),
    );
    await tester.pump();

    final start = tester.getCenter(find.byKey(const ValueKey(DndId('item-0'))));

    // A quick touch drag does not start a drag (it stays available to scroll).
    final quick = await tester.startGesture(start, kind: PointerDeviceKind.touch);
    await quick.moveBy(const Offset(0, 40));
    await tester.pump();
    expect(controller.isDragging, isFalse);
    await quick.up();
    await tester.pump();

    // Holding past the delay then moving starts and tracks a touch drag.
    final held = await tester.startGesture(start, kind: PointerDeviceKind.touch);
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 10));
    for (var i = 0; i < 4; i++) {
      await held.moveBy(const Offset(0, 24));
      await tester.pump();
    }

    expect(controller.isDragging, isTrue);
    expect(moves, greaterThan(0));

    await held.up();
    await tester.pump();
  });

  testWidgets('active drag survives the source element being recycled', (tester) async {
    final controller = DndController();
    final scrollController = ScrollController();
    addTearDown(controller.dispose);
    addTearDown(scrollController.dispose);

    var moves = 0;
    await tester.pumpWidget(
      harness(
        controller: controller,
        scrollController: scrollController,
        onMoves: (n) => moves += n,
      ),
    );
    await tester.pump();

    final start = tester.getCenter(find.byKey(const ValueKey(DndId('item-0'))));
    final gesture = await tester.startGesture(start, kind: PointerDeviceKind.mouse);
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    expect(controller.isDragging, isTrue);

    // Scroll far enough that the source item's element is recycled mid-drag.
    scrollController.jumpTo(25 * itemExtent);
    await tester.pump();
    expect(
      find.byKey(const ValueKey(DndId('item-0'))),
      findsNothing,
      reason: 'the source element must be recycled by the lazy list',
    );

    // The drag is not cancelled, and its registration + measured rect persist.
    expect(controller.isDragging, isTrue);
    expect(controller.registry.hasDraggable(const DndId('item-0')), isTrue);
    expect(controller.measuring.draggableRect(const DndId('item-0')), isNotNull);

    // The gesture keeps tracking and can still be released cleanly.
    final movesBefore = moves;
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    expect(moves, greaterThan(movesBefore));

    await gesture.up();
    await tester.pump();
    expect(controller.isDragging, isFalse);
  });

  testWidgets('lazy list rebuild that re-registers an id does not crash', (tester) async {
    // Reproduces the duplicate-registration crash: in a lazy list a keyed item
    // can be re-mounted (new owner registers) before the old element is
    // disposed (old owner unregisters). Owner-aware registration must tolerate
    // this instead of asserting a duplicate id.
    final warnings = <DndWarning>[];
    final controller = DndController(
      diagnosticsConfig: DndDiagnosticsConfig(onWarning: warnings.add),
    );
    addTearDown(controller.dispose);
    final ids = List<DndId>.generate(6, (i) => DndId('item-$i'));

    late StateSetter rebuild;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 200,
            height: 120, // small viewport so the list is lazy
            child: DndScope(
              controller: controller,
              child: StatefulBuilder(
                builder: (context, setState) {
                  rebuild = setState;
                  return ListView.builder(
                    itemExtent: 60,
                    itemCount: ids.length,
                    // Intentionally NO findChildIndexCallback: a moved keyed
                    // item is rebuilt fresh, exercising the new-before-old path.
                    itemBuilder: (context, index) {
                      final id = ids[index];
                      return DndDroppable(
                        key: ValueKey(id),
                        id: id,
                        child: DndDraggable(
                          id: id,
                          child: SizedBox(height: 60, child: Text('$id')),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Remove the first item so the still-visible item-1 shifts up to index 0 and
    // is rebuilt fresh (new owner registers before the old element disposes).
    rebuild(() => ids.removeAt(0));
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      warnings,
      isEmpty,
      reason: 'same-frame owner handoff in a lazy list should not emit duplicate warnings',
    );
    // The shifted item is registered exactly once and remains queryable.
    expect(controller.registry.hasDraggable(const DndId('item-1')), isTrue);
    expect(controller.registry.hasDroppable(const DndId('item-1')), isTrue);
  });
}
