import 'package:dnd_kit_core/dnd_kit_core.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

/// The framework-neutral measuring cache now lives in `dnd_kit_core`.
///
/// `DndMeasuringRegistry` and `DndMeasurementStatus` are re-exported here so
/// existing `package:dnd_kit_flutter/dnd_kit_flutter.dart` imports keep working.
/// Only the Flutter-specific act of measuring a render box stays in this file.
export 'package:dnd_kit_core/dnd_kit_core.dart' show DndMeasuringRegistry, DndMeasurementStatus;

/// Measures [context]'s render box in global coordinates.
DndRect? measureDndRect(BuildContext context) {
  final renderObject = context.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) {
    return null;
  }

  final topLeft = renderObject.localToGlobal(Offset.zero);
  final size = renderObject.size;
  return DndRect(
    left: topLeft.dx,
    top: topLeft.dy,
    width: size.width,
    height: size.height,
  );
}

@internal
class DndMeasuredBox extends SingleChildRenderObjectWidget {
  const DndMeasuredBox({
    super.key,
    required this.onLayout,
    required super.child,
  });

  final VoidCallback onLayout;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderDndMeasuredBox(onLayout);
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderDndMeasuredBox).onLayout = onLayout;
  }
}

class _RenderDndMeasuredBox extends RenderProxyBox {
  _RenderDndMeasuredBox(this.onLayout);

  VoidCallback onLayout;

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
    } else {
      child.layout(constraints, parentUsesSize: true);
      size = constraints.constrain(child.size);
    }

    onLayout();
  }
}
