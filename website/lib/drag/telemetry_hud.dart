import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'drag_bus.dart';

/// The page's signature element: a quiet fixed mono strip that reads live drag
/// telemetry from the shared [dragBus]. Idle it sits muted; the moment the
/// visitor grabs anything on the page it warms to coral and streams the
/// engine's state.
@client
class TelemetryHud extends StatefulComponent {
  const TelemetryHud({super.key});

  @override
  State<TelemetryHud> createState() => _TelemetryHudState();
}

class _TelemetryHudState extends State<TelemetryHud> {
  @override
  void initState() {
    super.initState();
    dragBus.addListener(_onBus);
  }

  void _onBus() {
    // Reflect drag state on the root element so the grabbing cursor applies
    // page-wide while a drag is in flight (see styles.tw.css).
    if (kIsWeb) {
      final root = web.document.documentElement;
      if (dragBus.snapshot.active) {
        root?.setAttribute('data-dragging', 'true');
      } else {
        root?.removeAttribute('data-dragging');
      }
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    dragBus.removeListener(_onBus);
    super.dispose();
  }

  @override
  Component build(BuildContext context) {
    final s = dragBus.snapshot;
    final shell = s.active
        ? 'border-accent bg-accent/10 text-ink'
        : 'border-line bg-surface/90 text-muted';

    return div(
      classes:
          'pointer-events-none fixed inset-x-0 bottom-0 z-40 flex justify-center '
          'px-4 pb-4',
      [
        div(
          classes:
              'pointer-events-auto flex max-w-full items-center gap-3 '
              'overflow-x-auto rounded-full border px-4 py-2 font-mono text-xs '
              'shadow-lift backdrop-blur transition-colors $shell',
          attributes: const {'role': 'status', 'aria-live': 'off'},
          [
            span(
              classes: s.active
                  ? 'h-2 w-2 shrink-0 animate-pulse rounded-full bg-accent'
                  : 'h-2 w-2 shrink-0 rounded-full bg-muted/50',
              const [],
            ),
            _field('source', s.source),
            _field('active', s.activeId ?? '—'),
            _field('over', s.overId ?? '—'),
            _field('Δ', '${s.dx.round()},${s.dy.round()}'),
            _field('input', s.inputKind),
            _field('state', s.state),
          ],
        ),
      ],
    );
  }

  Component _field(String label, String value) {
    return span(classes: 'whitespace-nowrap', [
      span(classes: 'text-accent', [.text('$label ')]),
      .text(value),
    ]);
  }
}
