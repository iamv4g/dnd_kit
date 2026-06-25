import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// A code block with a Flutter / Jaspr toggle, so one snippet shows the same
/// API on both adapters. Server-rendered with the Flutter tab active, then
/// hydrated to switch tabs on the client.
@client
class CodeTabs extends StatefulComponent {
  const CodeTabs({
    required this.flutter,
    required this.jaspr,
    this.flutterFile = 'main.dart',
    this.jasprFile = 'main.dart',
    super.key,
  });

  final String flutter;
  final String jaspr;
  final String flutterFile;
  final String jasprFile;

  @override
  State<CodeTabs> createState() => _CodeTabsState();
}

class _CodeTabsState extends State<CodeTabs> {
  int _tab = 0; // 0 = Flutter, 1 = Jaspr

  @override
  Component build(BuildContext context) {
    final tabs = ['Flutter', 'Jaspr'];
    final code = _tab == 0 ? component.flutter : component.jaspr;
    final file = _tab == 0 ? component.flutterFile : component.jasprFile;
    return div(
      classes:
          'overflow-hidden rounded-2xl border border-line bg-surface shadow-lift',
      [
        div(
          classes:
              'flex items-center gap-3 border-b border-line bg-raised px-4 py-2.5',
          [
            div(
              classes: 'flex items-center gap-1',
              attributes: const {'role': 'tablist'},
              [
                for (var i = 0; i < tabs.length; i++)
                  button(
                    classes:
                        'rounded-full px-3 py-1 font-mono text-xs transition-colors '
                        '${i == _tab ? 'bg-accent text-white' : 'text-muted hover:text-ink'}',
                    attributes: {
                      'type': 'button',
                      'role': 'tab',
                      'aria-selected': (i == _tab).toString(),
                    },
                    onClick: () => setState(() => _tab = i),
                    [.text(tabs[i])],
                  ),
              ],
            ),
            span(classes: 'ml-auto font-mono text-xs text-muted', [
              .text(file),
            ]),
          ],
        ),
        Component.element(
          tag: 'pre',
          classes:
              'overflow-x-auto p-5 font-mono text-sm leading-relaxed text-ink',
          children: [.text(code)],
        ),
      ],
    );
  }
}
