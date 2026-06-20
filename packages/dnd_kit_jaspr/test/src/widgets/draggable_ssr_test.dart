import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr_test/server_test.dart';

void main() {
  group('DndDraggable server pre-render', () {
    testServer('renders a draggable with a handle without a deferred setState', (tester) async {
      final controller = DndController();
      addTearDown(controller.dispose);

      tester.pumpComponent(
        DndScope(
          controller: controller,
          child: DndDraggable(
            id: const DndId('task-1'),
            child: DndDragHandle(
              label: 'Reorder task',
              child: div([]),
            ),
          ),
        ),
      );

      // Before the kIsWeb guard in _scheduleHandleStateSync, registering the
      // handle scheduled a microtask setState during pre-render, which tripped
      // a framework assertion (surfacing as an unhandled async error and
      // failing this request).
      final response = await tester.request('/');

      expect(response.statusCode, 200);
      expect(response.body, contains('aria-roledescription="draggable"'));
    });
  });
}
