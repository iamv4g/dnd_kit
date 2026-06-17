import 'id.dart';

/// Receives non-fatal diagnostics emitted by dnd_kit.
typedef DndWarningCallback = void Function(DndWarning warning);

/// A non-fatal warning emitted when dnd_kit detects likely misconfiguration.
final class DndWarning {
  /// Creates a warning.
  const DndWarning({
    required this.code,
    required this.message,
    this.id,
  });

  /// Stable machine-readable warning code.
  final String code;

  /// Clear, actionable warning message.
  final String message;

  /// The related drag-and-drop id, when the warning is id-specific.
  final DndId? id;

  @override
  bool operator ==(Object other) {
    return other is DndWarning && other.code == code && other.message == message && other.id == id;
  }

  @override
  int get hashCode => Object.hash(code, message, id);

  @override
  String toString() {
    return 'DndWarning(code: $code, message: $message, id: $id)';
  }
}

/// Configures non-fatal diagnostics for dnd_kit runtime components.
final class DndDiagnosticsConfig {
  /// Creates diagnostics configuration.
  const DndDiagnosticsConfig({
    this.onWarning,
  });

  /// Receives warnings for recoverable library misconfiguration.
  final DndWarningCallback? onWarning;

  /// Emits [warning] when a warning callback is configured.
  void warn(DndWarning warning) {
    onWarning?.call(warning);
  }
}
