// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/client.dart';

import 'package:dnd_kit_website/docs/code_tabs.dart' deferred as _code_tabs;
import 'package:dnd_kit_website/drag/telemetry_hud.dart'
    deferred as _telemetry_hud;
import 'package:dnd_kit_website/layout/mobile_nav.dart' deferred as _mobile_nav;
import 'package:dnd_kit_website/layout/nav_bar.dart' deferred as _nav_bar;
import 'package:dnd_kit_website/sections/code_sample.dart'
    deferred as _code_sample;
import 'package:dnd_kit_website/sections/features.dart' deferred as _features;
import 'package:dnd_kit_website/sections/hero.dart' deferred as _hero;
import 'package:dnd_kit_website/sections/kanban_showcase.dart'
    deferred as _kanban_showcase;
import 'package:dnd_kit_website/sections/playground.dart'
    deferred as _playground;
import 'package:dnd_kit_website/theme/theme_toggle.dart'
    deferred as _theme_toggle;

/// Default [ClientOptions] for use with your Jaspr project.
///
/// Use this to initialize Jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'main.client.options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultClientOptions,
///   );
///
///   runApp(...);
/// }
/// ```
ClientOptions get defaultClientOptions => ClientOptions(
  clients: {
    'code_tabs': ClientLoader(
      (p) => _code_tabs.CodeTabs(
        flutter: p['flutter'] as String,
        jaspr: p['jaspr'] as String,
        flutterFile: p['flutterFile'] as String,
        jasprFile: p['jasprFile'] as String,
      ),
      loader: _code_tabs.loadLibrary,
    ),
    'telemetry_hud': ClientLoader(
      (p) => _telemetry_hud.TelemetryHud(),
      loader: _telemetry_hud.loadLibrary,
    ),
    'mobile_nav': ClientLoader(
      (p) => _mobile_nav.MobileNav(),
      loader: _mobile_nav.loadLibrary,
    ),
    'nav_bar': ClientLoader(
      (p) => _nav_bar.ReorderableNav(),
      loader: _nav_bar.loadLibrary,
    ),
    'code_sample': ClientLoader(
      (p) => _code_sample.CodeSample(),
      loader: _code_sample.loadLibrary,
    ),
    'features': ClientLoader(
      (p) => _features.Features(),
      loader: _features.loadLibrary,
    ),
    'hero': ClientLoader((p) => _hero.HeroStack(), loader: _hero.loadLibrary),
    'kanban_showcase': ClientLoader(
      (p) => _kanban_showcase.KanbanShowcase(),
      loader: _kanban_showcase.loadLibrary,
    ),
    'playground': ClientLoader(
      (p) => _playground.Playground(),
      loader: _playground.loadLibrary,
    ),
    'theme_toggle': ClientLoader(
      (p) => _theme_toggle.ThemeToggle(),
      loader: _theme_toggle.loadLibrary,
    ),
  },
);
