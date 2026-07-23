import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_example_gallery/demos/planner/planner_demo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Drives the two nested sortable surfaces of the planner: section reorder
  // within a day, and item moves across sections.
  group('PlannerDemo', () {
    Future<void> pumpPlanner(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(520, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const MaterialApp(home: PlannerDemo()));
      await tester.pump();
    }

    Future<void> dragHandleOnto(
      WidgetTester tester,
      Key handle,
      Offset target,
    ) async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(handle)),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.moveTo(target);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets('reorders a section within its day', (tester) async {
      await pumpPlanner(tester);

      // Monday: Morning above Afternoon.
      expect(
        tester.getTopLeft(find.text('Morning')).dy,
        lessThan(tester.getTopLeft(find.text('Afternoon')).dy),
      );

      // Drag the Afternoon section handle up onto the Morning section.
      await dragHandleOnto(
        tester,
        const ValueKey('section-handle:s-afternoon'),
        tester.getCenter(find.text('Morning')),
      );

      // They swap: Afternoon now sits above Morning.
      expect(
        tester.getTopLeft(find.text('Afternoon')).dy,
        lessThan(tester.getTopLeft(find.text('Morning')).dy),
        reason: 'the section should have reordered within its day',
      );
    });

    testWidgets('moves an item into another section', (tester) async {
      await pumpPlanner(tester);

      // 'Write the brief' starts in Morning, far above 'Team standup' in
      // Afternoon (a different section).
      final standup = find.text('Team standup');
      final briefBefore = tester.getTopLeft(find.text('Write the brief')).dy;
      final standupBefore = tester.getTopLeft(standup).dy;
      expect(standupBefore - briefBefore, greaterThan(120));

      // Drop the brief onto the standup item (Afternoon section).
      await dragHandleOnto(
        tester,
        const ValueKey('item-handle:i-brief'),
        tester.getCenter(standup),
      );

      // The brief now sits next to standup — they share the Afternoon section.
      final briefAfter = tester.getTopLeft(find.text('Write the brief')).dy;
      final standupAfter = tester.getTopLeft(standup).dy;
      expect(
        (briefAfter - standupAfter).abs(),
        lessThan(120),
        reason: 'the item should have moved into the standup section',
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('picking an item up and dropping in place keeps the order',
        (tester) async {
      await pumpPlanner(tester);

      final brief = find.text('Write the brief');
      final wireframe = find.text('Wireframe the flow');
      // Morning: brief above wireframe.
      expect(tester.getTopLeft(brief).dy,
          lessThan(tester.getTopLeft(wireframe).dy));

      // Press to enter drag, then release without moving.
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('item-handle:i-brief'))),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      await gesture.up();
      await tester.pumpAndSettle();

      // Nothing moved: the two items keep their original order.
      expect(
        tester.getTopLeft(brief).dy,
        lessThan(tester.getTopLeft(wireframe).dy),
        reason: 'a pick-up with no movement must not reorder',
      );
    });

    testWidgets('the target section grows to hold an incoming item',
        (tester) async {
      await pumpPlanner(tester);

      final afternoon = find.byKey(const ValueKey('section-card:s-afternoon'));
      final restingHeight = tester.getSize(afternoon).height;

      // Start dragging the brief (from Morning) over the Afternoon section.
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('item-handle:i-brief'))),
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.moveTo(tester.getCenter(find.text('Team standup')));
      await tester.pumpAndSettle();

      // While hovering, the section reserves layout for the incoming item so the
      // shifted items stay inside the card.
      expect(
        tester.getSize(afternoon).height,
        greaterThan(restingHeight + 20),
        reason: 'the section should reserve room for the incoming item',
      );

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('an item note survives a move', (tester) async {
      await pumpPlanner(tester);

      // Type a note into the brief, then move it to another section.
      await tester.enterText(
        find.descendant(
          of: find
              .ancestor(
                of: find.text('Write the brief'),
                matching: find.byType(Column),
              )
              .first,
          matching: find.byType(TextField),
        ),
        'keep me',
      );
      await tester.pump();

      await dragHandleOnto(
        tester,
        const ValueKey('item-handle:i-brief'),
        tester.getCenter(find.text('Team standup')),
      );

      expect(find.text('keep me'), findsOneWidget);
    });
  });
}
