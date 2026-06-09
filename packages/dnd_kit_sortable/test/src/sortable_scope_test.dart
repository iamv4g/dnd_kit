import 'package:dnd_kit_core/dnd_kit_core.dart';
import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:dnd_kit_sortable/dnd_kit_sortable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
