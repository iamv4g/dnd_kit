import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

import 'app.dart';
import 'main.server.options.dart';

/// Google Fonts: Hanken Grotesk carries both display and body, Geist Mono
/// carries utility and code. Weight 800 is what the display sizes are set in.
const _fontsUrl =
    'https://fonts.googleapis.com/css2?family=Geist+Mono:wght@400;500'
    '&family=Hanken+Grotesk:wght@400;500;600;700;800'
    '&display=swap';

/// Applies the saved (or system) theme before first paint to avoid a flash, and
/// marks the document as script-capable.
///
/// The `js` class is what arms the scroll-reveal animation. Keeping it here
/// means the hidden state only ever exists when scripting is actually running,
/// so a failed or blocked bundle degrades to "everything visible" instead of a
/// blank page.
const _noFlashScript = '''
(function(){try{
  document.documentElement.classList.add('js');
  var t = localStorage.getItem('theme');
  var dark = t ? (t === 'dark')
                : window.matchMedia('(prefers-color-scheme: dark)').matches;
  if (dark) document.documentElement.classList.add('dark');
}catch(e){}})();
''';

const _title = 'dnd_kit — drag-and-drop for Flutter & Web';
const _description =
    'dnd_kit is one drag-and-drop engine for Flutter and the web. Interactive '
    'Kanban, sortable lists, keyboard accessibility and modifiers — this whole '
    'page is built with it.';

void main() {
  Jaspr.initializeApp(options: defaultServerOptions);

  runApp(
    Document(
      title: _title,
      lang: 'en',
      meta: const {'description': _description, 'theme-color': '#FBFAF7'},
      head: [
        Component.element(
          tag: 'link',
          attributes: const {
            'rel': 'preconnect',
            'href': 'https://fonts.googleapis.com',
          },
        ),
        Component.element(
          tag: 'link',
          attributes: const {
            'rel': 'preconnect',
            'href': 'https://fonts.gstatic.com',
            'crossorigin': '',
          },
        ),
        Component.element(
          tag: 'link',
          attributes: const {'rel': 'stylesheet', 'href': _fontsUrl},
        ),
        Component.element(
          tag: 'link',
          attributes: const {'rel': 'stylesheet', 'href': 'styles.css'},
        ),
        Component.element(
          tag: 'link',
          attributes: const {
            'rel': 'icon',
            'type': 'image/svg+xml',
            'href': 'favicon.svg',
          },
        ),
        Component.element(
          tag: 'meta',
          attributes: const {'property': 'og:title', 'content': _title},
        ),
        Component.element(
          tag: 'meta',
          attributes: const {
            'property': 'og:description',
            'content': 'One drag engine for Flutter and the web.',
          },
        ),
        Component.element(
          tag: 'meta',
          attributes: const {'property': 'og:type', 'content': 'website'},
        ),
        Component.element(
          tag: 'script',
          children: const [RawText(_noFlashScript)],
        ),
      ],
      body: const App(),
    ),
  );
}
