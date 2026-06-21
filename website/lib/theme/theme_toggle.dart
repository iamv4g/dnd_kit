import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

/// Sun/moon button that flips the `dark` class on `<html>` and remembers the
/// choice in `localStorage`. The initial class is set by a no-flash script in
/// the document head, so this island just reads and toggles it.
@client
class ThemeToggle extends StatefulComponent {
  const ThemeToggle({super.key});

  @override
  State<ThemeToggle> createState() => _ThemeToggleState();
}

class _ThemeToggleState extends State<ThemeToggle> {
  bool _isDark = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _isDark =
          web.document.documentElement?.classList.contains('dark') ?? false;
    }
  }

  void _toggle() {
    setState(() => _isDark = !_isDark);
    if (kIsWeb) {
      web.document.documentElement?.classList.toggle('dark', _isDark);
      web.window.localStorage.setItem('theme', _isDark ? 'dark' : 'light');
    }
  }

  @override
  Component build(BuildContext context) {
    return button(
      classes:
          'inline-grid h-10 w-10 place-items-center rounded-full border '
          'border-line bg-surface text-ink transition-colors hover:border-accent '
          'hover:text-accent',
      attributes: {
        'type': 'button',
        'aria-label': _isDark
            ? 'Switch to light theme'
            : 'Switch to dark theme',
      },
      onClick: _toggle,
      [
        span(classes: 'text-lg leading-none', [.text(_isDark ? '☀' : '☾')]),
      ],
    );
  }
}
