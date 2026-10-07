import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'data/site_data.dart';
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
import 'docs/pages/recipes_page.dart';
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
        _page('/', page: const Site()),
        _page(
          '/showcase',
          title: 'Showcase · dnd_kit',
          page: const ShowcasePage(),
        ),
        _page(
          '/docs',
          title: 'Documentation · dnd_kit',
          page: const OverviewPage(),
        ),
        _page(
          '/docs/install',
          title: 'Installation · dnd_kit',
          page: const InstallPage(),
        ),
        _page(
          '/docs/quickstart',
          title: 'Quickstart · dnd_kit',
          page: const QuickstartPage(),
        ),
        _page(
          '/docs/draggable',
          title: 'Draggable · dnd_kit',
          page: const DraggablePage(),
        ),
        _page(
          '/docs/droppable',
          title: 'Droppable · dnd_kit',
          page: const DroppablePage(),
        ),
        _page(
          '/docs/overlay',
          title: 'Drag overlay · dnd_kit',
          page: const OverlayPage(),
        ),
        _page(
          '/docs/collision',
          title: 'Collision detection · dnd_kit',
          page: const CollisionPage(),
        ),
        _page(
          '/docs/sensors',
          title: 'Sensors & activation · dnd_kit',
          page: const SensorsPage(),
        ),
        _page(
          '/docs/modifiers',
          title: 'Modifiers · dnd_kit',
          page: const ModifiersPage(),
        ),
        _page(
          '/docs/auto-scroll',
          title: 'Auto-scroll · dnd_kit',
          page: const AutoscrollPage(),
        ),
        _page(
          '/docs/sortable',
          title: 'Sortable lists · dnd_kit',
          page: const SortablePage(),
        ),
        _page(
          '/docs/multi-container',
          title: 'Multi-container sortable · dnd_kit',
          page: const MultiContainerPage(),
        ),
        _page(
          '/docs/recipes',
          title: 'Recipes · dnd_kit',
          page: const RecipesPage(),
        ),
        _page(
          '/docs/accessibility',
          title: 'Accessibility · dnd_kit',
          page: const AccessibilityPage(),
        ),
        _page(
          '/docs/reference',
          title: 'API reference · dnd_kit',
          page: const ReferencePage(),
        ),
      ],
    );
  }
}

/// A route whose page declares its own absolute `og:url`, so a shared docs link
/// previews as that page rather than collapsing to the home page. Static pages
/// are emitted as `<path>/index.html`, so the URL keeps the trailing slash that
/// Pages would otherwise redirect to.
Route _page(String path, {String? title, required Component page}) {
  final url = path == '/'
      ? SiteLinks.site
      : '${SiteLinks.site}${path.substring(1)}/';
  return Route(
    path: path,
    title: title,
    builder: (context, state) => Component.fragment([
      Document.head(
        children: [
          Component.element(
            tag: 'meta',
            attributes: {'property': 'og:url', 'content': url},
          ),
        ],
      ),
      page,
    ]),
  );
}
