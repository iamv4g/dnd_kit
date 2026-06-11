import 'package:example_gallery/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders gallery navigation and the basic demo', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ExampleGalleryApp());

    expect(find.text('dnd_kit'), findsOneWidget);
    expect(find.text('Basic'), findsOneWidget);
    expect(find.text('Kanban'), findsOneWidget);
    expect(find.text('Multi-container'), findsOneWidget);
    expect(find.text('Basic Drag & Drop'), findsOneWidget);
  });

  testWidgets('switches between demos', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const ExampleGalleryApp());
    await tester.tap(find.text('Kanban'));
    await tester.pumpAndSettle();

    expect(find.text('dnd_kit Kanban'), findsOneWidget);
    expect(find.text('Write adoption brief'), findsOneWidget);

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
    final gesture = await tester.startGesture(tester.getCenter(redCard));
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
}
