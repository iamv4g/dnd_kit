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

    expect(find.text('Interactive Board'), findsOneWidget);
    expect(find.text('Design Dark Mode UI'), findsOneWidget);
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

    await gesture.moveTo(tester.getCenter(thirdRow));
    await tester.pumpAndSettle();

    // The third row has slid up to make room for the row being dragged onto it.
    expect(
      tester.getTopLeft(thirdRow).dy,
      lessThan(restingTop),
      reason: 'the live gap should shift the displaced row upward',
    );

    await gesture.up();
    await tester.pumpAndSettle();

    // Dropping commits the move the gap was previewing.
    expect(tester.getTopLeft(firstRow).dy,
        greaterThan(tester.getTopLeft(thirdRow).dy));
  });
}
