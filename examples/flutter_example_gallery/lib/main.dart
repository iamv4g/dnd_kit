import 'package:flutter/material.dart';

import 'demos/accessibility_demo.dart';
import 'demos/auto_scroll_demo.dart';
import 'demos/basic_demo.dart';
import 'demos/collision_demo.dart';
import 'demos/modifiers_demo.dart';
import 'demos/multi_container/multi_container_demo.dart';
import 'demos/planner/planner_demo.dart';
import 'demos/sensors_demo.dart';
import 'demos/sortable_demo.dart';
import 'theme.dart';

void main() => runApp(const ExampleGalleryApp());

@immutable
final class _DemoEntry {
  const _DemoEntry({
    required this.slug,
    required this.label,
    required this.hint,
    required this.icon,
    required this.builder,
  });

  /// Catalog slug; matches the docs concept and the Jaspr gallery.
  final String slug;
  final String label;
  final String hint;
  final IconData icon;
  final WidgetBuilder builder;
}

// Catalog order (see docs/product/examples-standard.md). Flutter now ships the
// full catalog.
final _demos = <_DemoEntry>[
  _DemoEntry(
    slug: 'basic',
    label: 'Basic',
    hint: 'Drag, drop, handle, overlay',
    icon: Icons.drag_indicator,
    builder: (_) => const BasicDemo(),
  ),
  _DemoEntry(
    slug: 'collision',
    label: 'Collision',
    hint: 'Detector picks the target',
    icon: Icons.adjust,
    builder: (_) => const CollisionDemo(),
  ),
  _DemoEntry(
    slug: 'sensors',
    label: 'Sensors',
    hint: 'Activation constraints',
    icon: Icons.touch_app_outlined,
    builder: (_) => const SensorsDemo(),
  ),
  _DemoEntry(
    slug: 'modifiers',
    label: 'Modifiers',
    hint: 'Constrained movement',
    icon: Icons.tune,
    builder: (_) => const ModifiersDemo(),
  ),
  _DemoEntry(
    slug: 'auto-scroll',
    label: 'Auto-scroll',
    hint: 'Edge-driven scrolling',
    icon: Icons.swap_vert,
    builder: (_) => const AutoScrollDemo(),
  ),
  _DemoEntry(
    slug: 'sortable',
    label: 'Sortable',
    hint: 'Reorderable list preset',
    icon: Icons.reorder,
    builder: (_) => const SortableDemo(),
  ),
  _DemoEntry(
    slug: 'multi-container',
    label: 'Multi-container',
    hint: 'Move cards across columns',
    icon: Icons.dashboard_customize_outlined,
    builder: (_) => const MultiContainerDemo(),
  ),
  _DemoEntry(
    slug: 'accessibility',
    label: 'Accessibility',
    hint: 'Keyboard + announcements',
    icon: Icons.accessibility_new,
    builder: (_) => const AccessibilityDemo(),
  ),
  // Flutter-only advanced demo (no catalog/Jaspr peer): nested sortables in a
  // CustomScrollView with sticky day headers.
  _DemoEntry(
    slug: 'planner',
    label: 'Planner',
    hint: 'Nested sortables in slivers',
    icon: Icons.calendar_view_day_outlined,
    builder: (_) => const PlannerDemo(),
  ),
];

class ExampleGalleryApp extends StatelessWidget {
  const ExampleGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'dnd_kit Examples',
      theme: galleryTheme(),
      home: const ExampleGalleryShell(),
    );
  }
}

class ExampleGalleryShell extends StatefulWidget {
  const ExampleGalleryShell({super.key});

  @override
  State<ExampleGalleryShell> createState() => _ExampleGalleryShellState();
}

class _ExampleGalleryShellState extends State<ExampleGalleryShell> {
  var _selectedIndex = 0;

  void _selectDemo(int index) {
    if (_selectedIndex == index) {
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useWideLayout = constraints.maxWidth >= 900;
        final selectedDemo = _demos[_selectedIndex];
        final demo = KeyedSubtree(
          key: ValueKey<String>(selectedDemo.label),
          child: selectedDemo.builder(context),
        );

        if (useWideLayout) {
          // No rule between rail and stage: the demo sits on a raised surface
          // and the paper ground behind the rail is what separates them.
          return Scaffold(
            body: Row(
              children: <Widget>[
                _GalleryRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _selectDemo,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                    child: DecoratedBox(
                      decoration: cardDecoration(radius: 28),
                      child: ClipPath(
                        clipper: ShapeBorderClipper(shape: squircle(28)),
                        child: demo,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          body: demo,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _selectDemo,
            destinations: [
              for (final demo in _demos)
                NavigationDestination(
                  icon: Icon(demo.icon),
                  label: demo.label,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _GalleryRail extends StatelessWidget {
  const _GalleryRail({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 232,
      child: NavigationRail(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        extended: true,
        leading: const Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 20, 28),
          child: Row(
            children: <Widget>[
              _GalleryMark(size: 30),
              SizedBox(width: 10),
              Flexible(
                child: Text(
                  'dnd_kit',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: GalleryTokens.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
        destinations: <NavigationRailDestination>[
          for (final demo in _demos)
            NavigationRailDestination(
              icon: Icon(demo.icon, size: 20),
              label: Text(demo.label),
            ),
        ],
      ),
    );
  }
}

/// The dnd_kit mark: the grip lattice with one dot dragged out of it, and the
/// slot it left behind. The same drawing as `website/web/favicon.svg` — the
/// gallery is embedded a few hundred pixels from the site's own nav, so a
/// second, different mark would read as a different product.
class _GalleryMark extends StatelessWidget {
  const _GalleryMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _MarkPainter()),
    );
  }
}

class _MarkPainter extends CustomPainter {
  // Laid out on the favicon's 32x32 grid, then scaled.
  static const _lattice = <Offset>[
    Offset(11.5, 10.5),
    Offset(11.5, 16.5),
    Offset(19.5, 16.5),
    Offset(11.5, 22.5),
    Offset(19.5, 22.5),
  ];
  static const _vacated = Offset(19.5, 10.5);
  static const _loose = Offset(25.4, 6.6);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 32;
    final rect = Offset.zero & size;

    // The tile runs Dart → Flutter so the corner holding the apricot dot is the
    // deepest blue available to carry it.
    final tile = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: <Color>[GalleryTokens.accent, GalleryTokens.accentDeep],
      ).createShader(rect);
    canvas.drawPath(
      squircle(size.width * 0.28).getOuterPath(rect),
      tile,
    );

    final dot = Paint()..color = GalleryTokens.paper.withValues(alpha: 0.94);
    for (final p in _lattice) {
      canvas.drawCircle(p * s, 2 * s, dot);
    }

    // The vacated slot, drawn hollow: below ~28px the trace stops resolving and
    // this ring is what keeps "one of these moved" readable.
    canvas.drawCircle(
      _vacated * s,
      1.9 * s,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3 * s
        ..color = GalleryTokens.paper.withValues(alpha: 0.34),
    );

    canvas.drawPath(
      Path()
        ..moveTo(21 * s, 9.4 * s)
        ..cubicTo(22 * s, 9 * s, 22.7 * s, 8.5 * s, 23.4 * s, 7.7 * s),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * s
        ..strokeCap = StrokeCap.round
        ..color = GalleryTokens.apricot.withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      _loose * s,
      2.4 * s,
      Paint()..color = GalleryTokens.apricot,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => false;
}
