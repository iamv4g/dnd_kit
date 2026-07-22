import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SortableScopeData.resolveDetails', () {
    final scope = SortableScopeData(
      containerId: const DndId('list-1'),
      strategy: SortableStrategies.verticalList,
      itemIds: const <DndId>[DndId('item-1'), DndId('item-2'), DndId('item-3')],
    );
    final itemRects = <DndId, DndRect>{
      const DndId('item-1'): const DndRect(left: 0, top: 0, width: 100, height: 40),
      const DndId('item-2'): const DndRect(left: 0, top: 40, width: 100, height: 40),
      const DndId('item-3'): const DndRect(left: 0, top: 80, width: 100, height: 40),
    };
    final session = DndDragSession.start(
      activeId: const DndId('item-1'),
      initialPointer: const DndPoint(50, 20),
    ).moveTo(const DndPoint(50, 105));

    test('resolves a preview identically to the committed move', () {
      final preview = scope.resolveDetails(
        SortableDragContext.preview(session: session, overId: const DndId('item-3')),
        itemRects: itemRects,
        activeRect: itemRects[const DndId('item-1')],
      );
      final commit = scope.moveDetailsFor(
        DndDragEndEvent(session: session, overId: const DndId('item-3')),
        itemRects: itemRects,
        activeRect: itemRects[const DndId('item-1')],
      );

      expect(preview?.toIndex, commit?.toIndex);
      expect(preview?.fromIndex, commit?.fromIndex);
      expect(preview?.overId, commit?.overId);
      expect(preview?.event, isNull);
      expect(commit?.event, isNotNull);
    });

    test('reports no preview when the drag is over itself', () {
      final preview = scope.resolveDetails(
        SortableDragContext.preview(session: session, overId: const DndId('item-1')),
        itemRects: itemRects,
      );

      expect(preview, isNull);
    });
  });

  group('SortableScope', () {
    testWidgets('provides immutable item order and the underlying controller', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      SortableScopeData? capturedScope;
      DndController? capturedController;

      await tester.pumpWidget(
        SortableScope(
          controller: controller,
          containerId: const DndId('list-1'),
          itemIds: const <DndId>[DndId('item-1'), DndId('item-2')],
          child: Builder(
            builder: (context) {
              capturedScope = SortableScope.of(context);
              capturedController = DndScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedController, same(controller));
      expect(capturedScope?.containerId, const DndId('list-1'));
      expect(capturedScope?.itemIds, const <DndId>[DndId('item-1'), DndId('item-2')]);
      expect(
        () => capturedScope?.itemIds.add(const DndId('item-3')),
        throwsUnsupportedError,
      );
    });

    testWidgets('returns null from maybeOf when no scope exists', (tester) async {
      SortableScopeData? capturedScope;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            capturedScope = SortableScope.maybeOf(context);
            return const SizedBox();
          },
        ),
      );

      expect(capturedScope, isNull);
    });

    testWidgets('throws from of when no scope exists', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox();
          },
        ),
      );

      expect(
        () => SortableScope.of(capturedContext),
        throwsA(
          isA<FlutterError>().having(
            (error) => error.toString(),
            'message',
            contains('SortableScope.of() was called without a SortableScope'),
          ),
        ),
      );
    });
  });
}
