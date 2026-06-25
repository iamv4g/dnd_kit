import 'package:jaspr/dom.dart';
import 'package:jaspr/server.dart';

import 'app.dart';
import 'main.server.options.dart';

/// Google Fonts: Newsreader (display serif), Hanken Grotesk (body),
/// Geist Mono (utility/code).
const _fontsUrl =
    'https://fonts.googleapis.com/css2?family=Geist+Mono:wght@400;500'
    '&family=Hanken+Grotesk:wght@400;500;600;700'
    '&family=Newsreader:opsz,wght@6..72,400;6..72,500;6..72,600'
    '&display=swap';

/// Applies the saved (or system) theme before first paint to avoid a flash.
const _noFlashScript = '''
(function(){try{
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
      meta: const {'description': _description, 'theme-color': '#FAF9F5'},
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
