import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'demos/accessibility_demo.dart';
import 'demos/auto_scroll_demo.dart';
import 'demos/basic_demo.dart';
import 'demos/modifiers_demo.dart';
import 'demos/sortable_demo.dart';
import 'ui.dart';

/// The runnable dnd_kit_jaspr feature gallery.
///
/// A tabbed shell that renders one self-contained demo per supported surface,
/// each driving the real shared `dnd_kit` runtime.
class GalleryApp extends StatefulComponent {
  const GalleryApp({super.key});

  @override
  State<GalleryApp> createState() => _GalleryAppState();
}

class _GalleryAppState extends State<GalleryApp> {
  int _selected = 0;

  static final List<_Demo> _demos = <_Demo>[
    _Demo('Basic', 'Drag, drop, handle, overlay', () => const BasicDemo()),
    _Demo('Sortable', 'Reorderable list preset', () => const SortableDemo()),
    _Demo('Auto-scroll', 'Edge-driven scrolling', () => const AutoScrollDemo()),
    _Demo(
      'Accessibility',
      'Keyboard + live region',
      () => const AccessibilityDemo(),
    ),
    _Demo('Modifiers', 'Constrained movement', () => const ModifiersDemo()),
  ];

  void _select(int index) {
    if (index != _selected) {
      setState(() => _selected = index);
    }
  }

  @override
  Component build(BuildContext context) {
    final demo = _demos[_selected];
    return div(
      styles: Styles(
        minHeight: 100.vh,
        padding: .all(32.px),
        color: cText,
        fontFamily: kFontFamily,
        backgroundColor: cPageBg,
      ),
      [
        div(
          styles: Styles(
            display: .flex,
            maxWidth: 1080.px,
            margin:
                .only(left: .auto, right: .auto, bottom: 24.px),
            flexDirection: .column,
            gap: .all(18.px),
          ),
          [
            _Masthead(),
            _TabBar(demos: _demos, selected: _selected, onSelect: _select),
          ],
        ),
        // Re-key the demo subtree per tab so each demo's controller and
        // registrations are created fresh and disposed on switch.
        div(
          key: Key('demo-${demo.label}'),
          [demo.build()],
        ),
      ],
    );
  }
}

class _Masthead extends StatelessComponent {
  @override
  Component build(BuildContext context) {
    return div(
      styles: Styles(
        display: .flex,
        flexDirection: .column,
        gap: .all(8.px),
      ),
      [
        h1(
          styles:
              Styles(margin: .zero, fontSize: 38.px, lineHeight: 1.1.em),
          const [.text('dnd_kit_jaspr feature gallery')],
        ),
        p(
          styles: Styles(
            margin: .zero,
            maxWidth: 720.px,
            color: cMuted,
            fontSize: 17.px,
            lineHeight: 1.5.em,
          ),
          const [
            .text(
              'Every tab drives the same shared dnd_kit runtime that powers the '
              'Flutter adapter. Drag with a pointer or the keyboard; the library '
              'reports intent and the app owns its data.',
            ),
          ],
        ),
      ],
    );
  }
}

class _TabBar extends StatelessComponent {
  const _TabBar({
    required this.demos,
    required this.selected,
    required this.onSelect,
  });

  final List<_Demo> demos;
  final int selected;
  final void Function(int index) onSelect;

  @override
  Component build(BuildContext context) {
    return div(
      styles: Styles(
        display: .flex,
        flexWrap: .wrap,
        gap: .all(10.px),
      ),
      attributes: const <String, String>{
        'role': 'tablist',
        'aria-label': 'Feature demos',
      },
      [
        for (var index = 0; index < demos.length; index++)
          _tab(demos[index], index == selected, () => onSelect(index)),
      ],
    );
  }

  Component _tab(_Demo demo, bool active, void Function() onTap) {
    return button(
      styles: Styles(
        display: .flex,
        padding: .symmetric(vertical: 10.px, horizontal: 16.px),
        border: .all(color: active ? cAccent : cBorder, width: 1.px),
        radius: .circular(16.px),
        cursor: .pointer,
        flexDirection: .column,
        gap: .all(2.px),
        color: active ? cText : cTabText,
        textAlign: .left,
        fontFamily: kFontFamily,
        backgroundColor: active ? cPanelBg : cTabBg,
      ),
      attributes: <String, String>{
        'role': 'tab',
        'aria-selected': active.toString(),
      },
      onClick: onTap,
      [
        strong(
          styles: Styles(fontSize: 15.px),
          [.text(demo.label)],
        ),
        span(
          styles: Styles(fontSize: 12.px, color: cMuted),
          [.text(demo.hint)],
        ),
      ],
    );
  }
}

class _Demo {
  _Demo(this.label, this.hint, this.build);

  final String label;
  final String hint;
  final Component Function() build;
}
