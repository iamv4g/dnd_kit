import 'package:dnd_kit_flutter/dnd_kit_flutter.dart';
import 'package:flutter/material.dart';

void main() => runApp(const BasicDragDropApp());

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

const _items = <_Item>[
  _Item(id: 'red', label: 'Red', color: Color(0xffe57373)),
  _Item(id: 'blue', label: 'Blue', color: Color(0xff64b5f6)),
  _Item(id: 'green', label: 'Green', color: Color(0xff81c784)),
  _Item(id: 'yellow', label: 'Yellow', color: Color(0xffffd54f)),
];

const _zoneIds = <String>['unassigned', 'zone_a', 'zone_b'];

class BasicDragDropApp extends StatelessWidget {
  const BasicDragDropApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Basic Drag & Drop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const BasicDragDropExample(),
    );
  }
}

class BasicDragDropExample extends StatefulWidget {
  const BasicDragDropExample({super.key});

  @override
  State<BasicDragDropExample> createState() => _BasicDragDropExampleState();
}

class _BasicDragDropExampleState extends State<BasicDragDropExample> {
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
                return _CardContent(item: item);
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
    final colorScheme = Theme.of(context).colorScheme;
    return DndDroppable(
      id: DndId(zoneId),
      builder: (context, details, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: details.isOver
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.4),
              width: details.isOver ? 2 : 1,
            ),
            color: details.isOver
                ? colorScheme.primaryContainer.withValues(alpha: 0.25)
                : colorScheme.surface,
          ),
          child: child,
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 8),
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
          opacity: details.isDragging ? 0.4 : 1.0,
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
    return Container(
      width: 80,
      height: 56,
      decoration: BoxDecoration(
        color: item.color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: item.color.withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        item.label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
