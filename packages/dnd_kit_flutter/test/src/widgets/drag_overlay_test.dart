import 'package:dnd_kit_core/dnd_kit_core.dart';
import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DndDragOverlay', () {
    testWidgets('renders nothing when no active session exists', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: Stack(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              DndDragOverlay(
                builder: (context, details) {
                  return const Text('overlay');
                },
              ),
            ],
          ),
        ),
      );

      expect(find.text('overlay'), findsNothing);

      controller.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('task-1'),
          position: DndPoint(10, 10),
        ),
        activeRect: const DndRect(left: 20, top: 30, width: 40, height: 50),
      );
      await tester.pump();

      expect(find.text('overlay'), findsNothing);
    });

    testWidgets('renders active details while dragging', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      DndDragOverlayDetails? latestDetails;

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(
              children: <Widget>[
                DndDragOverlay(
                  builder: (context, details) {
                    latestDetails = details;
                    return Text('overlay:${details.activeId.value}:${details.transform.x}');
                  },
                ),
              ],
            ),
          ),
        ),
      );

      controller.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('task-1'),
          position: DndPoint(10, 10),
        ),
        activeRect: const DndRect(left: 20, top: 30, width: 40, height: 50),
      );
      controller.startDrag();
      await tester.pump();

      expect(find.text('overlay:task-1:0.0'), findsOneWidget);
      expect(latestDetails?.activeId, const DndId('task-1'));
      expect(
        latestDetails?.activeRect,
        const DndRect(left: 20, top: 30, width: 40, height: 50),
      );

      controller.moveDrag(const DndPoint(25, 35));
      await tester.pump();

      expect(find.text('overlay:task-1:15.0'), findsOneWidget);
      expect(latestDetails?.transform, const DndTransform(x: 15, y: 25));
    });

    testWidgets('positions overlay from active rect and transform', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: Stack(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              DndDragOverlay(
                builder: (context, details) {
                  return const SizedBox(
                    key: ValueKey<String>('overlay-child'),
                    width: 40,
                    height: 50,
                  );
                },
              ),
            ],
          ),
        ),
      );

      controller.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('task-1'),
          position: DndPoint(10, 10),
        ),
        activeRect: const DndRect(left: 20, top: 30, width: 40, height: 50),
      );
      controller.startDrag();
      controller.moveDrag(const DndPoint(35, 45));
      await tester.pump();

      expect(tester.getTopLeft(find.byKey(const ValueKey<String>('overlay-child'))),
          const Offset(45, 65));
      expect(
          tester.getSize(find.byKey(const ValueKey<String>('overlay-child'))), const Size(40, 50));
    });

    testWidgets('ignores pointer events by default', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);
      var tapCount = 0;

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: Stack(
            textDirection: TextDirection.ltr,
            children: <Widget>[
              Positioned(
                left: 20,
                top: 30,
                width: 40,
                height: 50,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    tapCount += 1;
                  },
                  child: const SizedBox(),
                ),
              ),
              DndDragOverlay(
                builder: (context, details) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      tapCount += 100;
                    },
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ],
          ),
        ),
      );

      controller.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('task-1'),
          position: DndPoint(10, 10),
        ),
        activeRect: const DndRect(left: 20, top: 30, width: 40, height: 50),
      );
      controller.startDrag();
      await tester.pump();

      await tester.tapAt(const Offset(30, 40));
      await tester.pump();

      expect(tapCount, 1);
    });
  });
}
