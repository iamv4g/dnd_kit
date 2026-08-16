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
          'overflow-hidden rounded-[2rem] squircle bg-[#0C1420] '
          'dark:bg-surface shadow-lift',
      [
        div(classes: 'flex flex-wrap items-center gap-2 px-5 pt-5', [
          div(
            classes: 'flex items-center gap-1',
            attributes: const {'role': 'tablist'},
            [
              for (var i = 0; i < tabs.length; i++)
                button(
                  classes:
                      'rounded-full px-4 py-1.5 font-mono text-xs font-bold '
                      'transition-colors duration-200 '
                      '${i == _tab ? 'bg-white/10 text-white' : 'text-[#8FA3BC] hover:text-white'}',
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
          span(classes: 'ml-auto font-mono text-xs text-[#5A6B84]', [
            .text(file),
          ]),
        ]),
        Component.element(
          tag: 'pre',
          classes:
              'overflow-x-auto px-6 pb-6 pt-3 font-mono text-sm leading-relaxed '
              'text-[#D9E2EF]',
          children: [.text(code)],
        ),
      ],
    );
  }
}
