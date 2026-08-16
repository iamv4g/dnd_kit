import 'package:dnd_kit_jaspr/dnd_kit_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Shared visual language for the dnd_kit_jaspr feature gallery.
///
/// Ported from the website's visual system, so the gallery and the site it
/// demonstrates speak one language: the same sampled palette, real superellipse
/// corners, layered blue-tinted shadows instead of hairline outlines, and warm
/// off-white ground instead of cream.
///
/// Styling uses Jaspr's type-safe CSS-in-Dart [Styles] API. This is a
/// client-mode example, so static styles are expressed as inline [Styles]
/// (matching the dnd_kit_jaspr package components) rather than `@css`, which
/// targets server/static rendering.
///
/// Note there are deliberately **no border tokens**. A surface in this
/// direction is separated by weight, not by a 1px line; if a new component
/// seems to need an outline, it wants [kLift] or [dropZoneStyles] instead.

/// The gallery font stack. Hanken Grotesk is loaded by `web/index.html`.
const FontFamily kFontFamily = FontFamily.list([
  FontFamily('Hanken Grotesk'),
  FontFamily('Avenir Next'),
  FontFamily('Segoe UI'),
  FontFamilies.sansSerif,
]);

// Palette — sampled, not invented: Dart #0175C2 and Flutter #02569B, warmed
// with apricot. The previous warm-editorial cream/terracotta set is retired.
const Color cPageBg = Color('#fbfaf7'); // warm off-white, never #fff
const Color cPanelBg = Color('#ffffff'); // raised card
const Color cPanelAlt = Color('#f1f2f6'); // the recess / wash
const Color cCardBg = Color('#ffffff');
const Color cAccent = Color('#02569b'); // Flutter
const Color cAccentBright = Color('#0175c2'); // Dart
const Color cSky = Color('#38bdf8');
const Color cApricot = Color('#ffae7e');
const Color cMint = Color('#5fd6b0');
const Color cAccentSoft = Color.rgba(1, 117, 194, 0.1);
const Color cText = Color('#16181d'); // never #000
const Color cMuted = Color('#565c6b');
const Color cLabel = Color('#02569b');
const Color cPillBg = Color('#ffffff');
const Color cTagBg = Color('#f1f2f6');
const Color cTagText = Color('#565c6b');
const Color cEmptyBg = Color('#f1f2f6');
const Color cEmptyText = Color('#8a90a0');
const Color cHandleBg = Color('#f1f2f6');
const Color cActiveRow = Color.rgba(1, 117, 194, 0.08);
const Color cWhiteWarm = Color('#ffffff');
const Color cHint = Color('#8a90a0');
const Color cTabBg = Color('#f1f2f6');
const Color cTabText = Color('#565c6b');

/// The lift pair: layered and blue-tinted, so a raised surface reads as resting
/// on the page rather than cut out of it.
const BoxShadow kLift = BoxShadow.combine(<BoxShadow>[
  BoxShadow(
    offsetX: Unit.zero,
    offsetY: Unit.pixels(1),
    blur: Unit.pixels(2),
    color: Color.rgba(22, 24, 29, 0.04),
  ),
  BoxShadow(
    offsetX: Unit.zero,
    offsetY: Unit.pixels(8),
    blur: Unit.pixels(20),
    spread: Unit.pixels(-8),
    color: Color.rgba(22, 24, 29, 0.1),
  ),
  BoxShadow(
    offsetX: Unit.zero,
    offsetY: Unit.pixels(28),
    blur: Unit.pixels(56),
    spread: Unit.pixels(-24),
    color: Color.rgba(2, 86, 155, 0.16),
  ),
]);

/// The lifted state: what a picked-up object gets.
const BoxShadow kLiftHigh = BoxShadow.combine(<BoxShadow>[
  BoxShadow(
    offsetX: Unit.zero,
    offsetY: Unit.pixels(2),
    blur: Unit.pixels(4),
    color: Color.rgba(22, 24, 29, 0.05),
  ),
  BoxShadow(
    offsetX: Unit.zero,
    offsetY: Unit.pixels(16),
    blur: Unit.pixels(32),
    spread: Unit.pixels(-10),
    color: Color.rgba(22, 24, 29, 0.14),
  ),
  BoxShadow(
    offsetX: Unit.zero,
    offsetY: Unit.pixels(48),
    blur: Unit.pixels(80),
    spread: Unit.pixels(-32),
    color: Color.rgba(2, 86, 155, 0.24),
  ),
]);

/// A drop target lit by an incoming drag: a glow lifted out of the recess.
const BoxShadow kOverGlow = BoxShadow(
  offsetX: Unit.zero,
  offsetY: Unit.pixels(18),
  blur: Unit.pixels(40),
  spread: Unit.pixels(-16),
  color: Color.rgba(1, 117, 194, 0.4),
);

/// Applied alongside `radius:` to get real continuous-curvature corners.
///
/// `corner-shape` has no typed Jaspr property, so it lives in the stylesheet in
/// `web/index.html` and is opted into by class. It is progressive — browsers
/// without it fall back to the plain radius, which is still round.
const String kSquircle = 'sq';

/// Formats a [DndPoint] as rounded `x, y` for status panels.
String formatPoint(DndPoint point) =>
    '${point.x.toStringAsFixed(0)}, ${point.y.toStringAsFixed(0)}';

/// A surface that rests on the page: superellipse corners and a layered shadow,
/// never an outline.
Styles cardStyles({double radius = 20, Color background = cCardBg}) {
  return Styles(
    radius: .circular(radius.px),
    shadow: kLift,
    backgroundColor: background,
  );
}

/// Settling motion: a released or highlighted surface eases, never snaps.
const Transition kSettle = Transition.combine(<Transition>[
  Transition('background-color', duration: Duration(milliseconds: 260)),
  Transition('box-shadow', duration: Duration(milliseconds: 260)),
  Transition('transform', duration: Duration(milliseconds: 260)),
]);

/// A drop target reads as a recess in the surface, not a dashed rectangle.
Styles dropZoneStyles({required bool isOver, double radius = 22}) {
  return Styles(
    radius: .circular(radius.px),
    shadow: isOver ? kOverGlow : BoxShadow.none,
    backgroundColor: isOver ? Color.rgba(56, 189, 248, 0.14) : cEmptyBg,
    transition: kSettle,
  );
}

/// A rounded panel that frames one demo's content.
class DemoPanel extends StatelessComponent {
  const DemoPanel({required this.children, super.key});

  final List<Component> children;

  @override
  Component build(BuildContext context) {
    return div(
      classes: kSquircle,
      styles: Styles(
        display: .flex,
        maxWidth: 1080.px,
        padding: .all(28.px),
        margin: .symmetric(horizontal: .auto),
        radius: .circular(32.px),
        shadow: kLift,
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
      styles: Styles(display: .flex, flexDirection: .column, gap: .all(10.px)),
      [
        h2(
          styles: Styles(
            margin: .zero,
            fontSize: 30.px,
            fontWeight: .w800,
            letterSpacing: (-0.9).px,
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
        padding: .symmetric(vertical: 10.px, horizontal: 16.px),
        radius: .circular(999.px),
        shadow: kLift,
        alignItems: .center,
        gap: .all(8.px),
        backgroundColor: cPillBg,
      ),
      [
        span(
          styles: Styles(
            fontSize: 12.px,
            fontWeight: .w600,
            textTransform: .upperCase,
            letterSpacing: 1.1.px,
            color: cLabel,
          ),
          [.text(label)],
        ),
        strong(styles: Styles(color: cText), [.text(value)]),
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
      styles: Styles(display: .flex, flexWrap: .wrap, gap: .all(12.px)),
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
        // A chip hugs its label. Without this it inherits `align-items:
        // stretch` from any flex-column parent and renders as a full-width bar.
        alignSelf: .start,
        padding: .symmetric(vertical: 6.px, horizontal: 11.px),
        radius: .circular(999.px),
        fontSize: 11.px,
        fontWeight: .w800,
        textTransform: .upperCase,
        letterSpacing: 1.1.px,
        color: active ? cWhiteWarm : cTagText,
        backgroundColor: active ? cAccentBright : cTagBg,
      ),
      [.text(label)],
    );
  }
}
