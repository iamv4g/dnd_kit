// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/server.dart';
import 'package:dnd_kit_website/docs/code_tabs.dart' as _code_tabs;
import 'package:dnd_kit_website/drag/telemetry_hud.dart' as _telemetry_hud;
import 'package:dnd_kit_website/layout/mobile_nav.dart' as _mobile_nav;
import 'package:dnd_kit_website/layout/nav_bar.dart' as _nav_bar;
import 'package:dnd_kit_website/sections/code_sample.dart' as _code_sample;
import 'package:dnd_kit_website/sections/features.dart' as _features;
import 'package:dnd_kit_website/sections/hero.dart' as _hero;
import 'package:dnd_kit_website/sections/kanban_showcase.dart'
    as _kanban_showcase;
import 'package:dnd_kit_website/sections/playground.dart' as _playground;
import 'package:dnd_kit_website/theme/theme_toggle.dart' as _theme_toggle;

/// Default [ServerOptions] for use with your Jaspr project.
///
/// Use this to initialize Jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'main.server.options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultServerOptions,
///   );
///
///   runApp(...);
/// }
/// ```
ServerOptions get defaultServerOptions => ServerOptions(
  clientId: 'main.client.dart.js',
  clients: {
    _code_tabs.CodeTabs: ClientTarget<_code_tabs.CodeTabs>(
      'code_tabs',
      params: __code_tabsCodeTabs,
    ),
    _telemetry_hud.TelemetryHud: ClientTarget<_telemetry_hud.TelemetryHud>(
      'telemetry_hud',
    ),
    _mobile_nav.MobileNav: ClientTarget<_mobile_nav.MobileNav>('mobile_nav'),
    _nav_bar.ReorderableNav: ClientTarget<_nav_bar.ReorderableNav>('nav_bar'),
    _code_sample.CodeSample: ClientTarget<_code_sample.CodeSample>(
      'code_sample',
    ),
    _features.Features: ClientTarget<_features.Features>('features'),
    _hero.HeroStack: ClientTarget<_hero.HeroStack>('hero'),
    _kanban_showcase.KanbanShowcase:
        ClientTarget<_kanban_showcase.KanbanShowcase>('kanban_showcase'),
    _playground.Playground: ClientTarget<_playground.Playground>('playground'),
    _theme_toggle.ThemeToggle: ClientTarget<_theme_toggle.ThemeToggle>(
      'theme_toggle',
    ),
  },
);

Map<String, Object?> __code_tabsCodeTabs(_code_tabs.CodeTabs c) => {
  'flutter': c.flutter,
  'jaspr': c.jaspr,
  'flutterFile': c.flutterFile,
  'jasprFile': c.jasprFile,
};
