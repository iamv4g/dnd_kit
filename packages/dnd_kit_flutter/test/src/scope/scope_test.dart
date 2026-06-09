import 'package:dnd_kit_core/dnd_kit_core.dart';
import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DndScope', () {
    testWidgets('creates an internal controller for uncontrolled usage', (tester) async {
      DndController? capturedController;

      await tester.pumpWidget(
        DndScope(
          child: Builder(
            builder: (context) {
              capturedController = DndScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedController, isNotNull);
      expect(capturedController?.state, const DndIdle());

      await tester.pumpWidget(const SizedBox());
      expect(
        () => capturedController?.addListener(() {}),
        throwsFlutterError,
      );
    });

    testWidgets('uses but does not dispose an external controller', (tester) async {
      final controller = _TrackingDndController();
      addTearDown(controller.dispose);
      DndController? capturedController;

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: Builder(
            builder: (context) {
              capturedController = DndScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedController, same(controller));

      await tester.pumpWidget(const SizedBox());
      expect(controller.disposeCount, 0);
      expect(() => controller.addListener(() {}), returnsNormally);
    });

    testWidgets('returns null from maybeOf when no scope exists', (tester) async {
      DndController? capturedController;

      await tester.pumpWidget(
        Builder(
          builder: (context) {
            capturedController = DndScope.maybeOf(context);
            return const SizedBox();
          },
        ),
      );

      expect(capturedController, isNull);
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
        () => DndScope.of(capturedContext),
        throwsA(
          isA<FlutterError>().having(
            (error) => error.toString(),
            'message',
            contains('DndScope.of() was called without a DndScope'),
          ),
        ),
      );
    });

    testWidgets('rebuilds dependents when the controller notifies', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        DndScope(
          controller: controller,
          child: Builder(
            builder: (context) {
              final state = DndScope.of(context).state;
              return Text(
                state.runtimeType.toString(),
                textDirection: TextDirection.ltr,
              );
            },
          ),
        ),
      );

      expect(find.text('DndIdle'), findsOneWidget);

      controller.beginDrag(
        const DndSensorActivationEvent(
          activeId: DndId('task-1'),
          position: DndPoint.zero,
        ),
      );
      await tester.pump();

      expect(find.text('DndPending'), findsOneWidget);
    });
  });
}

class _TrackingDndController extends DndController {
  int disposeCount = 0;

  @override
  void dispose() {
    disposeCount += 1;
    super.dispose();
  }
}
