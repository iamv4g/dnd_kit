import 'package:flutter/material.dart';

/// The gallery's visual system, ported from the website's own.
///
/// The gallery is embedded in the showcase page as an iframe, sitting inches
/// from the site's own demos, so it has to speak the same language: the same
/// sampled palette, real superellipse corners rather than plain radii, layered
/// blue-tinted shadows instead of hairline outlines, and warm off-white ground
/// instead of pure white.
///
/// Everything here is a token. Demos should reach for [GalleryTokens] and the
/// decoration helpers below rather than hand-rolling `Border.all` — that is what
/// made the old gallery read as a wireframe.
abstract final class GalleryTokens {
  /// Sampled, not invented: Dart and Flutter's own brand blues, warmed with
  /// apricot so nothing lands in the purple "AI product" cliché.
  static const accent = Color(0xFF0175C2); // Dart
  static const accentDeep = Color(0xFF02569B); // Flutter
  static const sky = Color(0xFF38BDF8);
  static const apricot = Color(0xFFFFAE7E);
  static const mint = Color(0xFF5FD6B0);

  static const paper = Color(0xFFFBFAF7); // warm off-white, never #FFF
  static const surface = Color(0xFFFFFFFF);
  static const raised = Color(0xFFF1F2F6); // the recess / wash
  static const ink = Color(0xFF16181D); // never #000
  static const muted = Color(0xFF565C6B);
  static const faint = Color(0xFF8A90A0);

  /// Demo item colours, pulled onto the same ramp as the sweep so a scattering
  /// of draggable cards still reads as one palette.
  static const swatches = <Color>[
    accentDeep,
    accent,
    sky,
    mint,
    apricot,
    Color(0xFFB8501C),
  ];

  /// The lift pair. Layered and tinted toward the brand blue, so a raised
  /// surface reads as resting on the page rather than cut out of it.
  static const lift = <BoxShadow>[
    BoxShadow(
      color: Color(0x0A16181D),
      blurRadius: 2,
      offset: Offset(0, 1),
    ),
    BoxShadow(
      color: Color(0x1A16181D),
      blurRadius: 20,
      spreadRadius: -8,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x2902569B),
      blurRadius: 56,
      spreadRadius: -24,
      offset: Offset(0, 28),
    ),
  ];

  static const liftHigh = <BoxShadow>[
    BoxShadow(
      color: Color(0x0D16181D),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x2416181D),
      blurRadius: 32,
      spreadRadius: -10,
      offset: Offset(0, 16),
    ),
    BoxShadow(
      color: Color(0x3D02569B),
      blurRadius: 80,
      spreadRadius: -32,
      offset: Offset(0, 48),
    ),
  ];

  /// Spring easing — a released card should settle, not stop dead.
  static const spring = Cubic(0.34, 1.56, 0.64, 1);
  static const settle = Duration(milliseconds: 260);
}

/// A real superellipse corner, the Flutter counterpart of the site's
/// `corner-shape: squircle`.
///
/// This is the whole reason the gallery stops looking boxy: continuous
/// curvature actually changes the silhouette, where a larger [BorderRadius]
/// only makes the same rounded rectangle rounder.
RoundedSuperellipseBorder squircle(double radius) => RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(radius),
    );

/// A surface that rests on the page: superellipse corners and a layered shadow,
/// never a 1px outline.
ShapeDecoration cardDecoration({
  double radius = 20,
  Color color = GalleryTokens.surface,
  bool raised = true,
}) {
  return ShapeDecoration(
    color: color,
    shape: squircle(radius),
    shadows: raised ? GalleryTokens.lift : const <BoxShadow>[],
  );
}

/// A drop target reads as a recess in the surface, not a dashed rectangle.
///
/// [isOver] deepens the tint and lifts a coloured glow out of the recess, so
/// the feedback is the same "weight" language the rest of the system uses.
ShapeDecoration dropZoneDecoration({required bool isOver, double radius = 22}) {
  return ShapeDecoration(
    color: isOver
        ? GalleryTokens.sky.withValues(alpha: 0.14)
        : GalleryTokens.raised.withValues(alpha: 0.6),
    shape: RoundedSuperellipseBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(
        color: GalleryTokens.accent.withValues(alpha: isOver ? 0.45 : 0.1),
        width: isOver ? 2 : 1.5,
      ),
    ),
    shadows: isOver
        ? <BoxShadow>[
            BoxShadow(
              color: GalleryTokens.accent.withValues(alpha: 0.4),
              blurRadius: 40,
              spreadRadius: -16,
              offset: const Offset(0, 18),
            ),
          ]
        : const <BoxShadow>[],
  );
}

/// The draggable card most demos hand to the user, and the copy that follows
/// the pointer.
///
/// [lifted] is the whole difference between the two: a card under the pointer
/// grows its shadow and leans a couple of degrees. The old gallery signalled
/// this by swapping to a saturated fill, which is a different object rather
/// than the same object picked up.
Widget demoCard({
  required Widget child,
  double? width,
  bool lifted = false,
  double radius = 20,
  EdgeInsets padding = const EdgeInsets.symmetric(
    vertical: 18,
    horizontal: 22,
  ),
}) {
  final card = Container(
    width: width,
    padding: padding,
    alignment: Alignment.center,
    decoration: ShapeDecoration(
      color: GalleryTokens.surface,
      shape: squircle(radius),
      shadows: lifted ? GalleryTokens.liftHigh : GalleryTokens.lift,
    ),
    child: DefaultTextStyle.merge(
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: GalleryTokens.ink,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      child: child,
    ),
  );
  if (!lifted) return card;
  return Transform.rotate(
    angle: 0.035,
    child: Transform.scale(scale: 1.04, child: card),
  );
}

/// The eyebrow/label capsule used above groups — a filled pill, because in this
/// direction nothing sits directly on the ground without a surface under it.
Widget galleryEyebrow(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: ShapeDecoration(
      color: GalleryTokens.accent.withValues(alpha: 0.1),
      shape: const StadiumBorder(),
    ),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: GalleryTokens.accentDeep,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
      ),
    ),
  );
}

/// The gallery theme.
ThemeData galleryTheme() {
  const scheme = ColorScheme(
    brightness: Brightness.light,
    primary: GalleryTokens.accent,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFDCEEFB),
    onPrimaryContainer: GalleryTokens.accentDeep,
    secondary: GalleryTokens.apricot,
    onSecondary: GalleryTokens.ink,
    secondaryContainer: Color(0xFFFFE8D9),
    onSecondaryContainer: Color(0xFF7A3A12),
    tertiary: GalleryTokens.mint,
    onTertiary: GalleryTokens.ink,
    error: Color(0xFFB3261E),
    onError: Colors.white,
    surface: GalleryTokens.surface,
    onSurface: GalleryTokens.ink,
    onSurfaceVariant: GalleryTokens.muted,
    outline: Color(0xFFE4E7EE),
    outlineVariant: Color(0xFFEDEFF4),
    surfaceContainerLowest: GalleryTokens.surface,
    surfaceContainerLow: GalleryTokens.paper,
    surfaceContainer: GalleryTokens.raised,
    surfaceContainerHigh: Color(0xFFEAECF2),
    surfaceContainerHighest: Color(0xFFE3E6ED),
  );

  const family = 'HankenGrotesk';

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: family,
    scaffoldBackgroundColor: GalleryTokens.paper,
    canvasColor: GalleryTokens.paper,
    // Material's default hairline dividers are exactly the "ruled" language
    // this direction replaces with washes and shadows.
    dividerTheme: const DividerThemeData(
      color: Colors.transparent,
      space: 1,
      thickness: 0,
    ),
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(
      backgroundColor: GalleryTokens.paper,
      surfaceTintColor: Colors.transparent,
      foregroundColor: GalleryTokens.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: family,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: GalleryTokens.ink,
      ),
    ),
    cardTheme: CardThemeData(
      color: GalleryTokens.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: squircle(20),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: GalleryTokens.raised,
      // Selection is accent-tinted, matching the rail indicator. Material would
      // otherwise reach for secondaryContainer and make every selected chip
      // apricot while the rest of the app says "selected" in blue.
      selectedColor: GalleryTokens.accent.withValues(alpha: 0.12),
      checkmarkColor: GalleryTokens.accentDeep,
      side: BorderSide.none,
      shape: const StadiumBorder(),
      labelStyle: const TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w700,
        color: GalleryTokens.muted,
        fontSize: 12,
      ),
      secondaryLabelStyle: const TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w700,
        color: GalleryTokens.accentDeep,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(
          fontFamily: family,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      // A "ghost" button here is a soft raised capsule, never an outline.
      style: OutlinedButton.styleFrom(
        backgroundColor: GalleryTokens.surface,
        foregroundColor: GalleryTokens.ink,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(
          fontFamily: family,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(shape: const StadiumBorder()),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: GalleryTokens.raised,
        side: BorderSide.none,
        shape: const StadiumBorder(),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: const WidgetStatePropertyAll<Color>(
        Colors.transparent,
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: GalleryTokens.accent,
      inactiveTrackColor: GalleryTokens.raised,
      thumbColor: GalleryTokens.surface,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: GalleryTokens.ink,
      contentTextStyle: const TextStyle(
        fontFamily: family,
        color: GalleryTokens.paper,
      ),
      shape: squircle(18),
      behavior: SnackBarBehavior.floating,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: GalleryTokens.paper,
      indicatorColor: GalleryTokens.accent.withValues(alpha: 0.1),
      indicatorShape: const StadiumBorder(),
      selectedIconTheme: const IconThemeData(color: GalleryTokens.accentDeep),
      unselectedIconTheme: const IconThemeData(color: GalleryTokens.faint),
      selectedLabelTextStyle: const TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w700,
        color: GalleryTokens.accentDeep,
        fontSize: 14,
      ),
      unselectedLabelTextStyle: const TextStyle(
        fontFamily: family,
        fontWeight: FontWeight.w600,
        color: GalleryTokens.muted,
        fontSize: 14,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: GalleryTokens.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: GalleryTokens.accent.withValues(alpha: 0.1),
      indicatorShape: const StadiumBorder(),
      elevation: 0,
      labelTextStyle: const WidgetStatePropertyAll<TextStyle>(
        TextStyle(
          fontFamily: family,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: GalleryTokens.muted,
        ),
      ),
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: GalleryTokens.ink,
      ),
      titleMedium: TextStyle(
        fontWeight: FontWeight.w700,
        color: GalleryTokens.ink,
      ),
      titleSmall: TextStyle(
        fontWeight: FontWeight.w700,
        color: GalleryTokens.ink,
      ),
      bodyMedium: TextStyle(color: GalleryTokens.muted, height: 1.5),
      bodySmall: TextStyle(color: GalleryTokens.muted, height: 1.5),
      labelLarge: TextStyle(fontWeight: FontWeight.w700),
    ),
  );
}
