/// Pure Dart core primitives and algorithms for dnd_kit.
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
export 'src/geometry.dart';
export 'src/id.dart';
export 'src/collision.dart';
export 'src/diagnostics.dart';
export 'src/events.dart';
export 'src/measuring.dart';
export 'src/modifier.dart';
export 'src/registry.dart';
export 'src/runtime.dart';
export 'src/sensor.dart';
export 'src/sortable.dart';
export 'src/state.dart';
