import 'package:dnd_kit_core/dnd_kit_core.dart';
import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DndDroppable', () {
    testWidgets('registers and unregisters droppable metadata', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: const DndDroppable(
            id: DndId('column-1'),
            data: 'payload',
            child: SizedBox(width: 80, height: 80),
          ),
        ),
      );

      expect(
        controller.registry.droppable(const DndId('column-1')),
        const DndDroppableRegistration(
          id: DndId('column-1'),
          data: 'payload',
        ),
      );

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: const SizedBox(),
        ),
      );

      expect(controller.registry.hasDroppable(const DndId('column-1')), isFalse);
    });

    testWidgets('updates registry metadata when widget inputs change', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: const DndDroppable(
            id: DndId('column-1'),
            data: 'first',
            child: SizedBox(width: 80, height: 80),
          ),
        ),
      );

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: const DndDroppable(
            id: DndId('column-2'),
            disabled: true,
            data: 'second',
            child: SizedBox(width: 80, height: 80),
          ),
        ),
      );

      expect(controller.registry.hasDroppable(const DndId('column-1')), isFalse);
      expect(
        controller.registry.droppable(const DndId('column-2')),
        const DndDroppableRegistration(
          id: DndId('column-2'),
          disabled: true,
          data: 'second',
        ),
      );
    });

    testWidgets('moves registration when the nearest controller changes', (tester) async {
      final firstController = DndController();
      final secondController = DndController();
      addTearDown(firstController.dispose);
      addTearDown(secondController.dispose);

      await tester.pumpWidget(
        DndScope(
          controller: firstController,
          child: const DndDroppable(
            id: DndId('column-1'),
            child: SizedBox(width: 80, height: 80),
          ),
        ),
      );

      await tester.pumpWidget(
        DndScope(
          controller: secondController,
          child: const DndDroppable(
            id: DndId('column-1'),
            child: SizedBox(width: 80, height: 80),
          ),
        ),
      );

      expect(firstController.registry.hasDroppable(const DndId('column-1')), isFalse);
      expect(secondController.registry.hasDroppable(const DndId('column-1')), isTrue);
    });

    testWidgets('keeps disabled droppables registered as disabled metadata', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: const DndDroppable(
            id: DndId('column-1'),
            disabled: true,
            child: SizedBox(width: 80, height: 80),
          ),
        ),
      );

      expect(
        controller.registry.droppable(const DndId('column-1'))?.disabled,
        isTrue,
      );
    });

    testWidgets('measures global droppable bounds while mounted', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: const Stack(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              Positioned(
                left: 10,
                top: 20,
                child: DndDroppable(
                  id: DndId('column-1'),
                  child: SizedBox(width: 80, height: 60),
                ),
              ),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(
        controller.measuring.droppableRect(const DndId('column-1')),
        const DndRect(left: 10, top: 20, width: 80, height: 60),
      );

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: const SizedBox(),
        ),
      );

      expect(controller.measuring.droppableRect(const DndId('column-1')), isNull);
    });
  });
}
