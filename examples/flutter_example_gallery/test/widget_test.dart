import 'package:flutter_example_gallery/main.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders gallery navigation and the basic demo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ExampleGalleryApp());

    expect(find.text('dnd_kit'), findsOneWidget);
    expect(find.text('Basic'), findsOneWidget);
    expect(find.text('Multi-container'), findsOneWidget);
    expect(find.text('Basic Drag & Drop'), findsOneWidget);
  });

  testWidgets('switches between demos', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ExampleGalleryApp());
    await tester.tap(find.text('Multi-container'));
    await tester.pumpAndSettle();

    expect(find.text('Multi-container board'), findsOneWidget);
    expect(find.text('Design Dark Mode UI'), findsOneWidget);
  });

  testWidgets('the multi-container board opens a gap while dragging a card',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ExampleGalleryApp());
    await tester.tap(find.text('Multi-container'));
    await tester.pumpAndSettle();

    // Cards in the same column: dragging one over the other opens a gap, which
    // the card builder renders as a translation transform.
    final firstCard = find.text('Design Dark Mode UI');
    final secondCard = find.text('Implement Multi-Container API');

    final gesture = await tester.startGesture(
      tester.getCenter(firstCard),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await gesture.moveTo(tester.getCenter(secondCard));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // At least one card carries a non-identity translation — the live gap.
    final shifted = tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .any((c) {
      final t = c.transform;
      return t != null &&
          (t.getTranslation().y.abs() > 0.5 ||
              t.getTranslation().x.abs() > 0.5);
    });
    expect(shifted, isTrue,
        reason: 'a displaced card should carry an offset transform');

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps the basic drag overlay aligned inside the gallery shell',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ExampleGalleryApp());
    await tester.pumpAndSettle();

    final redCard = find.text('Red');
    final initialTextTopLeft = tester.getTopLeft(redCard);
    final gesture = await tester.startGesture(
      tester.getCenter(redCard),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    await gesture.moveBy(const Offset(40, 20));
    await tester.pump();

    final expectedTextTopLeft = initialTextTopLeft.translate(40, 20);
    final redTextPositions = tester
        .widgetList<Text>(redCard)
        .map((widget) => tester.getTopLeft(find.byWidget(widget)))
        .toList();

    expect(
      redTextPositions.any(
        (offset) =>
            (offset.dx - expectedTextTopLeft.dx).abs() < 1 &&
            (offset.dy - expectedTextTopLeft.dy).abs() < 1,
      ),
      isTrue,
      reason: 'overlay should follow the dragged card without sidebar offset',
    );

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('renders every catalog demo without error', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ExampleGalleryApp());

    const labels = <String>[
      'Collision',
      'Sensors',
      'Modifiers',
      'Auto-scroll',
      'Sortable',
      'Multi-container',
      'Accessibility',
      'Planner',
    ];
    for (final label in labels) {
      await tester.tap(find.text(label).first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: '$label demo threw');
    }
  });

  testWidgets('the sortable demo opens a gap while dragging', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ExampleGalleryApp());
    await tester.tap(find.text('Sortable').first);
    await tester.pumpAndSettle();

    final firstRow = find.text('Write the launch brief');
    final thirdRow = find.text('Wire the drag engine');
    final restingTop = tester.getTopLeft(thirdRow).dy;

    final gesture = await tester.startGesture(
      tester.getCenter(firstRow),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    await tester.pumpAndSettle();

    final thirdRowCenter = tester.getCenter(thirdRow);
    await gesture.moveTo(thirdRowCenter);
    await tester.pumpAndSettle();

    // The third row has slid up to make room for the row being dragged onto it.
    expect(
      tester.getTopLeft(thirdRow).dy,
      lessThan(restingTop),
      reason: 'the live gap should shift the displaced row upward',
    );

    // The dragged row is rendered twice while dragging: the in-list source and
    // the overlay copy that follows the pointer. Without the overlay the row
    // would appear frozen in place.
    final draggedLabels = tester.widgetList<Text>(firstRow).toList();
    expect(draggedLabels, hasLength(2), reason: 'source row plus drag overlay');
    final overlayFollowsPointer = draggedLabels.any((label) {
      final center = tester.getCenter(find.byWidget(label));
      return (center.dy - thirdRowCenter.dy).abs() < 30;
    });
    expect(
      overlayFollowsPointer,
      isTrue,
      reason:
          'the drag overlay should track the pointer, not stay at the source slot',
    );

    // The in-list source row is hidden while dragging, so the neighbours
    // sliding over its slot read as one clean gap instead of overlapping a
    // visible row. Exactly one item — the dragged one — is at opacity 0.
    final zeroOpacities = tester
        .widgetList<Opacity>(find.byType(Opacity))
        .where((widget) => widget.opacity == 0);
    expect(
      zeroOpacities,
      hasLength(1),
      reason: 'the dragged source row should be hidden, not dimmed',
    );

    await gesture.up();
    await tester.pumpAndSettle();

    // Dropping commits the move the gap was previewing.
    expect(tester.getTopLeft(firstRow).dy,
        greaterThan(tester.getTopLeft(thirdRow).dy));
  });
}
