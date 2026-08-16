import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/material.dart';

import '../theme.dart';

/// The `basic` catalog demo: pick up, drop on a target, drag handle, and a
/// floating drag overlay.
@immutable
final class _Item {
  const _Item({
    required this.id,
    required this.label,
    required this.color,
  });

  final String id;
  final String label;
  final Color color;
}

// Named for the palette they now sit on, not for stock Material swatches.
const _items = <_Item>[
  _Item(id: 'flutter', label: 'Flutter', color: GalleryTokens.accentDeep),
  _Item(id: 'dart', label: 'Dart', color: GalleryTokens.accent),
  _Item(id: 'sky', label: 'Sky', color: GalleryTokens.sky),
  _Item(id: 'apricot', label: 'Apricot', color: GalleryTokens.apricot),
];

const _zoneIds = <String>['unassigned', 'zone_a', 'zone_b'];

class BasicDemo extends StatefulWidget {
  const BasicDemo({super.key});

  @override
  State<BasicDemo> createState() => _BasicDemoState();
}

class _BasicDemoState extends State<BasicDemo> {
  late final _controller = DndController();

  final _itemZone = <String, String>{
    for (final item in _items) item.id: 'unassigned',
  };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Item> _itemsIn(String zoneId) =>
      _items.where((item) => _itemZone[item.id] == zoneId).toList();

  void _handleDragEnd(DndDragEndEvent event) {
    final overId = event.overId;
    if (overId == null) return;
    if (!_zoneIds.contains(overId.value)) return;
    final itemId = event.activeId.value;
    final newZoneId = overId.value;
    if (_itemZone[itemId] == newZoneId) return;

    // Phase 1: remove from current zone so the old DndDraggable unmounts first.
    // Moving an item directly between zones causes a duplicate-registration
    // assertion because Flutter mounts the new element before unmounting the old
    // one. Deferring the insertion to the next frame (same pattern used by the
    // kanban_board example for cross-column moves) avoids this.
    setState(() => _itemZone.remove(itemId));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Phase 2: mount in the new zone after the old element has unmounted.
      setState(() => _itemZone[itemId] = newZoneId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DndScope(
      controller: _controller,
      child: Scaffold(
        appBar: AppBar(title: const Text('Basic Drag & Drop')),
        body: Stack(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _ZoneWidget(
                    zoneId: 'unassigned',
                    label: 'Unassigned',
                    items: _itemsIn('unassigned'),
                    onDragEnd: _handleDragEnd,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Expanded(
                          child: _ZoneWidget(
                            zoneId: 'zone_a',
                            label: 'Zone A',
                            items: _itemsIn('zone_a'),
                            onDragEnd: _handleDragEnd,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ZoneWidget(
                            zoneId: 'zone_b',
                            label: 'Zone B',
                            items: _itemsIn('zone_b'),
                            onDragEnd: _handleDragEnd,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            DndDragOverlay(
              controller: _controller,
              builder: (context, details) {
                final itemId = details.activeId.value;
                final item = _items.firstWhere(
                  (i) => i.id == itemId,
                  orElse: () => _items.first,
                );
                // A lifted card leans and grows its shadow — weight, not an
                // outline. Same gesture language as the website's chips.
                return Transform.rotate(
                  angle: 0.035,
                  child: Transform.scale(
                    scale: 1.04,
                    child: _CardContent(item: item),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoneWidget extends StatelessWidget {
  const _ZoneWidget({
    required this.zoneId,
    required this.label,
    required this.items,
    required this.onDragEnd,
  });

  final String zoneId;
  final String label;
  final List<_Item> items;
  final DndDragEndCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    return DndDroppable(
      id: DndId(zoneId),
      builder: (context, details, child) {
        return AnimatedContainer(
          duration: GalleryTokens.settle,
          curve: Curves.easeOutCubic,
          decoration: dropZoneDecoration(isOver: details.isOver),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            galleryEyebrow(label),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final item in items)
                  _DraggableCard(
                      key: ValueKey(item.id), item: item, onDragEnd: onDragEnd),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DraggableCard extends StatelessWidget {
  const _DraggableCard({
    super.key,
    required this.item,
    required this.onDragEnd,
  });

  final _Item item;
  final DndDragEndCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    return DndDraggable(
      id: DndId(item.id),
      onDragEnd: onDragEnd,
      builder: (context, details, child) {
        return Opacity(
          opacity: details.isDragging ? 0.3 : 1.0,
          child: child,
        );
      },
      child: _CardContent(item: item),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({required this.item});

  final _Item item;

  @override
  Widget build(BuildContext context) {
    // Apricot is light enough that white text on it fails to read, so the label
    // takes ink there instead of assuming every swatch is dark.
    final onColor =
        ThemeData.estimateBrightnessForColor(item.color) == Brightness.dark
            ? Colors.white
            : GalleryTokens.ink;
    return Container(
      width: 92,
      height: 58,
      decoration: ShapeDecoration(
        color: item.color,
        shape: squircle(18),
        shadows: <BoxShadow>[
          BoxShadow(
            color: item.color.withValues(alpha: 0.38),
            blurRadius: 24,
            spreadRadius: -6,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        item.label,
        style: TextStyle(
          color: onColor,
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}
