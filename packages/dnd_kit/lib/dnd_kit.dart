/// Pure Dart core engine for the dnd_kit drag-and-drop family.
///
/// This is the `dnd_kit` package: the framework-neutral engine that the
/// `dnd_kit_flutter` and `dnd_kit_jaspr` adapters build on. Flutter apps import
/// `package:dnd_kit_flutter/dnd_kit_flutter.dart`; Jaspr apps import
/// `package:dnd_kit_jaspr/dnd_kit_jaspr.dart`.
///
/// This library has no Flutter dependency. It exposes stable identifiers,
/// geometry primitives, drag state, events, collision detectors, modifiers,
/// sensor contracts, registry contracts, the measuring-cache contract, the
/// framework-neutral drag runtime ([DndRuntime]), sortable move/strategy math,
/// auto-scroll edge/velocity math, and diagnostics shared by every framework
/// adapter.
///
library;

export 'src/auto_scroll.dart';
export 'src/a11y/announcements.dart';
export 'src/geometry.dart';
export 'src/id.dart';
export 'src/collision.dart';
export 'src/diagnostics.dart';
export 'src/events.dart';
export 'src/measuring.dart';
export 'src/modifier.dart';
export 'src/pointer_sensor.dart';
export 'src/registry.dart';
export 'src/runtime.dart';
export 'src/sensor.dart';
export 'src/sortable.dart';
export 'src/state.dart';
