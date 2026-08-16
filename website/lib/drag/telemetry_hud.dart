import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:universal_web/web.dart' as web;

import 'drag_bus.dart';

/// A fixed mono strip that streams live drag telemetry from the shared
/// [dragBus]. Muted while idle, highlighted while a drag is in flight.
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
    // Active state warms via border + text (no translucent fill): a near-solid
    // background avoids the iOS Safari backdrop-filter-on-fixed bug where the
    // bar only paints after a scroll.
    final shell = s.active
        ? 'text-ink shadow-lift-hi'
        : 'text-muted shadow-lift';

    // Anchored to the bottom-left on mobile: centring a fixed element resolves
    // against the initial containing block, which a device emulator can size
    // wider than the viewport and push the bar off-screen. Same reason there
    // are no vw/% widths here.
    return div(
      classes:
          'pointer-events-none fixed bottom-3 left-3 z-40 '
          'sm:left-1/2 sm:-translate-x-1/2',
      [
        div(
          classes:
              'pointer-events-auto flex min-w-0 items-center gap-3 '
              'overflow-x-auto rounded-full bg-surface/95 px-5 py-2.5 '
              'font-mono text-xs shadow-lift transition-colors $shell',
          attributes: const {'role': 'status', 'aria-live': 'off'},
          [
            span(
              classes: s.active
                  ? 'h-2 w-2 shrink-0 animate-pulse rounded-full bg-accent'
                  : 'h-2 w-2 shrink-0 rounded-full bg-muted/50',
              const [],
            ),
            // `always: false` fields are hidden on mobile to keep the bar compact.
            _field('source', s.source, always: false),
            _field('active', s.activeId ?? '—'),
            _field('over', s.overId ?? '—'),
            _field('Δ', '${s.dx.round()},${s.dy.round()}', always: false),
            _field('input', s.inputKind, always: false),
            _field('state', s.state),
          ],
        ),
      ],
    );
  }

  Component _field(String label, String value, {bool always = true}) {
    return span(
      classes: 'whitespace-nowrap ${always ? '' : 'hidden sm:inline'}',
      [
        span(classes: 'text-accent', [.text('$label ')]),
        .text(value),
      ],
    );
  }
}
