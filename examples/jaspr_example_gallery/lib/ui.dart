import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Shared visual language for the dnd_kit_jaspr feature gallery.
///
/// Styling uses Jaspr's type-safe CSS-in-Dart [Styles] API. This is a
/// client-mode example, so static styles are expressed as inline [Styles]
/// (matching the dnd_kit_jaspr package components) rather than `@css`, which
/// targets server/static rendering.

/// The gallery font stack.
const FontFamily kFontFamily = FontFamily.list([
  FontFamily('IBM Plex Sans'),
  FontFamily('Avenir Next'),
  FontFamily('Segoe UI'),
  FontFamilies.sansSerif,
]);

// Palette.
const Color cPageBg = Color('#f4efe7');
const Color cPanelBg = Color('#fffaf2');
const Color cPanelAlt = Color('#f8efe2');
const Color cCardBg = Color('#fffdf8');
const Color cBorder = Color('#d7c7af');
const Color cBorderSoft = Color('#dbc9b1');
const Color cCardBorder = Color('#d9c4a2');
const Color cAccent = Color('#9a3412');
const Color cAccentBright = Color('#c2410c');
const Color cAccentSoft = Color('#fff1df');
const Color cText = Color('#1f2937');
const Color cMuted = Color('#5b6470');
const Color cLabel = Color('#8a5a24');
const Color cPillBg = Color('#fbf4ea');
const Color cTagBg = Color('#eadac4');
const Color cTagText = Color('#6b4f32');
const Color cEmptyBg = Color('#fcf7ef');
const Color cEmptyText = Color('#8c7658');
const Color cHandleBg = Color('#f1e3cc');
const Color cActiveRow = Color('#fdeede');
const Color cWhiteWarm = Color('#fff7ed');
const Color cHint = Color('#7a8391');
const Color cTabBg = Color('#efe5d4');
const Color cTabText = Color('#6b5a40');

/// Formats a [DndPoint] as rounded `x, y` for status panels.
String formatPoint(DndPoint point) =>
    '${point.x.toStringAsFixed(0)}, ${point.y.toStringAsFixed(0)}';

/// A rounded panel that frames one demo's content.
class DemoPanel extends StatelessComponent {
  const DemoPanel({required this.children, super.key});

  final List<Component> children;

  @override
  Component build(BuildContext context) {
    return div(
      styles: Styles(
        display: .flex,
        maxWidth: 1080.px,
        padding: .all(28.px),
        margin: .symmetric(horizontal: .auto),
        border: .all(color: cBorder, width: 1.px),
        radius: .circular(28.px),
        flexDirection: .column,
        gap: .all(24.px),
        backgroundColor: cPanelBg,
      ),
      children,
    );
  }
}

/// A demo title plus a short explanatory paragraph.
class DemoIntro extends StatelessComponent {
  const DemoIntro({required this.title, required this.description, super.key});

  final String title;
  final String description;

  @override
  Component build(BuildContext context) {
    return div(
      styles: Styles(
        display: .flex,
        flexDirection: .column,
        gap: .all(10.px),
      ),
      [
        h2(
          styles: Styles(
            margin: .zero,
            fontSize: 30.px,
            lineHeight: 1.15.em,
          ),
          [.text(title)],
        ),
        p(
          styles: Styles(
            margin: .zero,
            fontSize: 17.px,
            lineHeight: 1.5.em,
            color: cMuted,
          ),
          [.text(description)],
        ),
      ],
    );
  }
}

/// A labelled key/value chip used across status panels.
class Pill extends StatelessComponent {
  const Pill({required this.label, required this.value, this.id, super.key});

  final String label;
  final String value;
  final String? id;

  @override
  Component build(BuildContext context) {
    return div(
      id: id,
      styles: Styles(
        display: .flex,
        padding: .symmetric(vertical: 10.px, horizontal: 14.px),
        border: .all(color: cBorder, width: 1.px),
        radius: .circular(999.px),
        alignItems: .center,
        gap: .all(8.px),
        backgroundColor: cPillBg,
      ),
      [
        span(
          styles: Styles(
            fontSize: 12.px,
            textTransform: .upperCase,
            letterSpacing: 1.1.px,
            color: cLabel,
          ),
          [.text(label)],
        ),
        strong([.text(value)]),
      ],
    );
  }
}

/// A horizontal row of [Pill]s describing live drag state.
class StatusBar extends StatelessComponent {
  const StatusBar({required this.children, super.key});

  final List<Component> children;

  @override
  Component build(BuildContext context) {
    return div(
      styles: Styles(
        display: .flex,
        flexWrap: .wrap,
        gap: .all(12.px),
      ),
      children,
    );
  }
}

/// A small uppercase tag/chip, optionally highlighted.
class Tag extends StatelessComponent {
  const Tag({required this.label, this.active = false, super.key});

  final String label;
  final bool active;

  @override
  Component build(BuildContext context) {
    return span(
      styles: Styles(
        padding: .symmetric(vertical: 6.px, horizontal: 10.px),
        radius: .circular(999.px),
        fontSize: 12.px,
        textTransform: .upperCase,
        letterSpacing: 1.1.px,
        color: active ? cWhiteWarm : cTagText,
        backgroundColor: active ? cAccentBright : cTagBg,
      ),
      [.text(label)],
    );
  }
}
