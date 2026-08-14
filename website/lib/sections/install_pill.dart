import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The hero's install command, with the adapter as a choice rather than an
/// assumption.
///
/// Server-renders with Flutter selected, so the command is correct and readable
/// before (or without) hydration.
@client
class InstallPill extends StatefulComponent {
  const InstallPill({super.key});

  @override
  State<InstallPill> createState() => _InstallPillState();
}

class _InstallPillState extends State<InstallPill> {
  int _adapter = 0; // 0 = Flutter, 1 = Jaspr

  static const _adapters = ['Flutter', 'Jaspr'];
  static const _packages = ['dnd_kit_flutter', 'dnd_kit_jaspr'];

  @override
  Component build(BuildContext context) {
    return div(
      classes:
          'inline-flex max-w-full flex-wrap items-center gap-x-3 gap-y-2 '
          'rounded-3xl squircle bg-surface p-1.5 shadow-lift sm:rounded-full',
      [
        div(
          classes: 'flex items-center gap-0.5 rounded-full bg-raised/70 p-0.5',
          attributes: const {
            'role': 'group',
            'aria-label': 'Choose an adapter',
          },
          [
            for (var i = 0; i < _adapters.length; i++)
              button(
                classes:
                    'rounded-full px-3 py-1.5 text-xs font-semibold '
                    'transition-colors duration-200 '
                    '${i == _adapter ? 'bg-surface text-accent-deep shadow-lift dark:text-accent' : 'text-muted hover:text-ink'}',
                attributes: {
                  'type': 'button',
                  'aria-pressed': (i == _adapter).toString(),
                },
                onClick: () => setState(() => _adapter = i),
                [.text(_adapters[i])],
              ),
          ],
        ),
        span(classes: 'px-2 pr-3 font-mono text-sm text-muted', [
          .text('dart pub add ${_packages[_adapter]}'),
        ]),
      ],
    );
  }
}
