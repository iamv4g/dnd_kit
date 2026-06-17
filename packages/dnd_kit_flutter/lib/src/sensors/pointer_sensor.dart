// The pointer sensor activation state machine is framework-neutral and now
// lives in `dnd_kit`, driven against a `DndRuntime`. It is re-exported here
// so existing `package:dnd_kit_flutter/dnd_kit_flutter.dart` imports keep
// working. Construct it with `runtime: controller.runtime`.
export 'package:dnd_kit/dnd_kit.dart'
    show
        DndPointerSensor,
        DndDragStartCallback,
        DndDragMoveCallback,
        DndDragEndCallback,
        DndDragCancelCallback;
