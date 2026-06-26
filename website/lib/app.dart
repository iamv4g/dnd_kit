import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'docs/pages/accessibility_page.dart';
import 'docs/pages/autoscroll_page.dart';
import 'docs/pages/collision_page.dart';
import 'docs/pages/draggable_page.dart';
import 'docs/pages/droppable_page.dart';
import 'docs/pages/install_page.dart';
import 'docs/pages/modifiers_page.dart';
import 'docs/pages/multi_container_page.dart';
import 'docs/pages/overlay_page.dart';
import 'docs/pages/overview_page.dart';
import 'docs/pages/quickstart_page.dart';
import 'docs/pages/reference_page.dart';
import 'docs/pages/sensors_page.dart';
import 'docs/pages/sortable_page.dart';
import 'showcase/showcase_page.dart';
import 'site.dart';

/// Top-level routing. In static (SSG) mode jaspr generates one HTML file per
/// route, so this emits `index.html` (the marketing home) plus a page under
/// `docs/` for each documentation route.
class App extends StatelessComponent {
  const App({super.key});

  @override
  Component build(BuildContext context) {
    return Router(
      routes: [
        Route(path: '/', builder: (context, state) => const Site()),
        Route(
          path: '/showcase',
          title: 'Showcase · dnd_kit',
          builder: (context, state) => const ShowcasePage(),
        ),
        Route(
          path: '/docs',
          title: 'Documentation · dnd_kit',
          builder: (context, state) => const OverviewPage(),
        ),
        Route(
          path: '/docs/install',
          title: 'Installation · dnd_kit',
          builder: (context, state) => const InstallPage(),
        ),
        Route(
          path: '/docs/quickstart',
          title: 'Quickstart · dnd_kit',
          builder: (context, state) => const QuickstartPage(),
        ),
        Route(
          path: '/docs/draggable',
          title: 'Draggable · dnd_kit',
          builder: (context, state) => const DraggablePage(),
        ),
        Route(
          path: '/docs/droppable',
          title: 'Droppable · dnd_kit',
          builder: (context, state) => const DroppablePage(),
        ),
        Route(
          path: '/docs/overlay',
          title: 'Drag overlay · dnd_kit',
          builder: (context, state) => const OverlayPage(),
        ),
        Route(
          path: '/docs/collision',
          title: 'Collision detection · dnd_kit',
          builder: (context, state) => const CollisionPage(),
        ),
        Route(
          path: '/docs/sensors',
          title: 'Sensors & activation · dnd_kit',
          builder: (context, state) => const SensorsPage(),
        ),
        Route(
          path: '/docs/modifiers',
          title: 'Modifiers · dnd_kit',
          builder: (context, state) => const ModifiersPage(),
        ),
        Route(
          path: '/docs/auto-scroll',
          title: 'Auto-scroll · dnd_kit',
          builder: (context, state) => const AutoscrollPage(),
        ),
        Route(
          path: '/docs/sortable',
          title: 'Sortable lists · dnd_kit',
          builder: (context, state) => const SortablePage(),
        ),
        Route(
          path: '/docs/multi-container',
          title: 'Multi-container sortable · dnd_kit',
          builder: (context, state) => const MultiContainerPage(),
        ),
        Route(
          path: '/docs/accessibility',
          title: 'Accessibility · dnd_kit',
          builder: (context, state) => const AccessibilityPage(),
        ),
        Route(
          path: '/docs/reference',
          title: 'API reference · dnd_kit',
          builder: (context, state) => const ReferencePage(),
        ),
      ],
    );
  }
}
