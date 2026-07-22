import 'package:dnd_kit/dnd_kit.dart';
import 'package:test/test.dart';

void main() {
  group('SortableDragContext', () {
    const strategies = <String, SortableStrategy>{
      'verticalList': SortableStrategies.verticalList,
      'horizontalList': SortableStrategies.horizontalList,
      'grid': SortableStrategies.grid,
      'dropOnOver': SortableStrategies.dropOnOver,
    };

    for (final entry in strategies.entries) {
      test('${entry.key} resolves a preview identically to the commit', () {
        SortableStrategyInput inputFor(SortableResolutionPhase phase) {
          return _input(
            activeId: const DndId('item-1'),
            overId: const DndId('item-3'),
            fromIndex: 0,
            activeTranslatedRect: _rect(top: 126),
            itemRects: <DndId, DndRect>{
              const DndId('item-1'): _rect(top: 0),
              const DndId('item-2'): _rect(top: 60),
              const DndId('item-3'): _rect(top: 120),
            },
            phase: phase,
          );
        }

        final preview = entry.value(inputFor(SortableResolutionPhase.preview));
        final commit = entry.value(inputFor(SortableResolutionPhase.commit));

        expect(preview?.activeId, commit?.activeId);
        expect(preview?.overId, commit?.overId);
        expect(preview?.fromIndex, commit?.fromIndex);
        expect(preview?.toIndex, commit?.toIndex);
        expect(preview?.fromContainerId, commit?.fromContainerId);
        expect(preview?.toContainerId, commit?.toContainerId);
      });
    }

    test('carries the end event only when committing', () {
      final session = DndDragSession.start(
        activeId: const DndId('item-1'),
        initialPointer: DndPoint.zero,
      );
      const overId = DndId('item-2');

      final preview = SortableDragContext.preview(session: session, overId: overId);
      final commit = SortableDragContext.commit(
        DndDragEndEvent(session: session, overId: overId),
      );

      expect(preview.isPreview, isTrue);
      expect(preview.endEvent, isNull);
      expect(preview.activeId, const DndId('item-1'));
      expect(preview.overId, overId);

      expect(commit.isPreview, isFalse);
      expect(commit.phase, SortableResolutionPhase.commit);
      expect(commit.endEvent?.overId, overId);
      expect(commit.activeId, const DndId('item-1'));
    });

    test('reports move details without an end event during preview', () {
      final details = SortableStrategies.dropOnOver(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-3'),
          fromIndex: 0,
          activeTranslatedRect: _rect(top: 0),
          itemRects: const <DndId, DndRect>{},
          phase: SortableResolutionPhase.preview,
        ),
      );

      expect(details?.toIndex, 2);
      expect(
        details?.event,
        isNull,
        reason: 'a preview describes an intent that has not happened yet',
      );
    });
  });

  group('SortableStrategies.dropOnOver', () {
    test('lands at the drop-over index regardless of the active center', () {
      // The active center has not crossed item-3's center, so the geometric
      // strategy reports no move while dropOnOver commits at the highlight.
      final input = _input(
        activeId: const DndId('item-1'),
        overId: const DndId('item-3'),
        fromIndex: 0,
        activeTranslatedRect: _rect(top: 30),
        itemRects: <DndId, DndRect>{
          const DndId('item-1'): _rect(top: 0),
          const DndId('item-2'): _rect(top: 60),
          const DndId('item-3'): _rect(top: 120),
        },
      );

      final details = SortableStrategies.dropOnOver(input);

      expect(details?.activeId, const DndId('item-1'));
      expect(details?.overId, const DndId('item-3'));
      expect(details?.fromIndex, 0);
      expect(details?.toIndex, 2);
      expect(SortableStrategies.verticalList(input), isNull);
    });

    test('reports moves without any measured rects', () {
      final details = SortableStrategies.dropOnOver(
        _input(
          activeId: const DndId('item-3'),
          overId: const DndId('item-1'),
          fromIndex: 2,
          activeTranslatedRect: _rect(top: 0),
          itemRects: const <DndId, DndRect>{},
        ),
      );

      expect(details?.toIndex, 0);
    });

    test('does not report same-item or targetless drops', () {
      expect(
        SortableStrategies.dropOnOver(
          _input(
            activeId: const DndId('item-1'),
            overId: const DndId('item-1'),
            fromIndex: 0,
            activeTranslatedRect: _rect(top: 0),
            itemRects: <DndId, DndRect>{const DndId('item-1'): _rect(top: 0)},
          ),
        ),
        isNull,
      );

      expect(
        SortableStrategies.dropOnOver(
          _input(
            activeId: const DndId('item-1'),
            overId: null,
            fromIndex: 0,
            activeTranslatedRect: _rect(top: 0),
            itemRects: <DndId, DndRect>{const DndId('item-1'): _rect(top: 0)},
          ),
        ),
        isNull,
      );
    });
  });

  group('SortableStrategies.verticalList', () {
    test('computes new index from the active translated center', () {
      final details = SortableStrategies.verticalList(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-3'),
          fromIndex: 0,
          activeTranslatedRect: _rect(top: 126),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(top: 0),
            const DndId('item-2'): _rect(top: 60),
            const DndId('item-3'): _rect(top: 120),
          },
        ),
      );

      expect(details?.activeId, const DndId('item-1'));
      expect(details?.overId, const DndId('item-3'));
      expect(details?.fromIndex, 0);
      expect(details?.toIndex, 2);
    });

    test('supports moving upward before earlier measured items', () {
      final details = SortableStrategies.verticalList(
        _input(
          activeId: const DndId('item-3'),
          overId: const DndId('item-1'),
          fromIndex: 2,
          activeTranslatedRect: _rect(top: -20),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(top: 0),
            const DndId('item-2'): _rect(top: 60),
            const DndId('item-3'): _rect(top: 120),
          },
        ),
      );

      expect(details?.fromIndex, 2);
      expect(details?.toIndex, 0);
    });

    test('uses measured centers for a two item vertical list', () {
      final details = SortableStrategies.verticalList(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-2'),
          fromIndex: 0,
          itemIds: const <DndId>[DndId('item-1'), DndId('item-2')],
          activeTranslatedRect: _rect(top: 80),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(top: 0),
            const DndId('item-2'): _rect(top: 60),
          },
        ),
      );

      expect(details?.toIndex, 1);
    });

    test('falls back to drop-over index when measurements are incomplete', () {
      final details = SortableStrategies.verticalList(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-3'),
          fromIndex: 0,
          activeTranslatedRect: _rect(top: 126),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(top: 0),
            const DndId('item-2'): _rect(top: 60),
          },
        ),
      );

      expect(details?.toIndex, 2);
    });

    test('falls back to drop-over index for non-vertical layouts', () {
      final details = SortableStrategies.verticalList(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-2'),
          fromIndex: 0,
          activeTranslatedRect: _rect(top: 0, left: 100),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(top: 0, left: 0),
            const DndId('item-2'): _rect(top: 0, left: 100),
            const DndId('item-3'): _rect(top: 0, left: 200),
          },
        ),
      );

      expect(details?.toIndex, 1);
    });

    test('does not report same-item moves or mutate item order', () {
      final itemIds = <DndId>[
        const DndId('item-1'),
        const DndId('item-2'),
        const DndId('item-3'),
      ];

      final details = SortableStrategies.verticalList(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-1'),
          fromIndex: 0,
          itemIds: itemIds,
          activeTranslatedRect: _rect(top: 60),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(top: 0),
            const DndId('item-2'): _rect(top: 60),
            const DndId('item-3'): _rect(top: 120),
          },
        ),
      );

      expect(details, isNull);
      expect(
        itemIds,
        const <DndId>[DndId('item-1'), DndId('item-2'), DndId('item-3')],
      );
    });
  });

  group('SortableStrategies.horizontalList', () {
    test('computes new index from the active translated center', () {
      final details = SortableStrategies.horizontalList(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-3'),
          fromIndex: 0,
          activeTranslatedRect: _rect(left: 126),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(left: 0),
            const DndId('item-2'): _rect(left: 60),
            const DndId('item-3'): _rect(left: 120),
          },
        ),
      );

      expect(details?.activeId, const DndId('item-1'));
      expect(details?.overId, const DndId('item-3'));
      expect(details?.fromIndex, 0);
      expect(details?.toIndex, 2);
    });

    test('supports moving left before earlier measured items', () {
      final details = SortableStrategies.horizontalList(
        _input(
          activeId: const DndId('item-3'),
          overId: const DndId('item-1'),
          fromIndex: 2,
          activeTranslatedRect: _rect(left: -20),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(left: 0),
            const DndId('item-2'): _rect(left: 60),
            const DndId('item-3'): _rect(left: 120),
          },
        ),
      );

      expect(details?.fromIndex, 2);
      expect(details?.toIndex, 0);
    });

    test('uses measured centers for a two item horizontal list', () {
      final details = SortableStrategies.horizontalList(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-2'),
          fromIndex: 0,
          itemIds: const <DndId>[DndId('item-1'), DndId('item-2')],
          activeTranslatedRect: _rect(left: 80),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(left: 0),
            const DndId('item-2'): _rect(left: 60),
          },
        ),
      );

      expect(details?.toIndex, 1);
    });

    test('falls back to drop-over index when measurements are incomplete', () {
      final details = SortableStrategies.horizontalList(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-3'),
          fromIndex: 0,
          activeTranslatedRect: _rect(left: 126),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(left: 0),
            const DndId('item-2'): _rect(left: 60),
          },
        ),
      );

      expect(details?.toIndex, 2);
    });

    test('falls back to drop-over index for non-horizontal layouts', () {
      final details = SortableStrategies.horizontalList(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-2'),
          fromIndex: 0,
          activeTranslatedRect: _rect(top: 100),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(top: 0),
            const DndId('item-2'): _rect(top: 100),
            const DndId('item-3'): _rect(top: 200),
          },
        ),
      );

      expect(details?.toIndex, 1);
    });

    test('does not report same-item moves or mutate item order', () {
      final itemIds = <DndId>[
        const DndId('item-1'),
        const DndId('item-2'),
        const DndId('item-3'),
      ];

      final details = SortableStrategies.horizontalList(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-1'),
          fromIndex: 0,
          itemIds: itemIds,
          activeTranslatedRect: _rect(left: 60),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(left: 0),
            const DndId('item-2'): _rect(left: 60),
            const DndId('item-3'): _rect(left: 120),
          },
        ),
      );

      expect(details, isNull);
      expect(
        itemIds,
        const <DndId>[DndId('item-1'), DndId('item-2'), DndId('item-3')],
      );
    });
  });

  group('SortableStrategies.grid', () {
    test('computes new index from the active translated center in row-major order', () {
      final details = SortableStrategies.grid(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-4'),
          fromIndex: 0,
          itemIds: const <DndId>[
            DndId('item-1'),
            DndId('item-2'),
            DndId('item-3'),
            DndId('item-4'),
          ],
          activeTranslatedRect: _rect(top: 81, left: 81),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(top: 0, left: 0),
            const DndId('item-2'): _rect(top: 0, left: 80),
            const DndId('item-3'): _rect(top: 80, left: 0),
            const DndId('item-4'): _rect(top: 80, left: 80),
          },
        ),
      );

      expect(details?.activeId, const DndId('item-1'));
      expect(details?.overId, const DndId('item-4'));
      expect(details?.fromIndex, 0);
      expect(details?.toIndex, 3);
    });

    test('supports moving upward before earlier measured rows', () {
      final details = SortableStrategies.grid(
        _input(
          activeId: const DndId('item-4'),
          overId: const DndId('item-1'),
          fromIndex: 3,
          itemIds: const <DndId>[
            DndId('item-1'),
            DndId('item-2'),
            DndId('item-3'),
            DndId('item-4'),
          ],
          activeTranslatedRect: _rect(top: -80, left: -80),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(top: 0, left: 0),
            const DndId('item-2'): _rect(top: 0, left: 80),
            const DndId('item-3'): _rect(top: 80, left: 0),
            const DndId('item-4'): _rect(top: 80, left: 80),
          },
        ),
      );

      expect(details?.fromIndex, 3);
      expect(details?.toIndex, 0);
    });

    test('uses measured centers within the same row', () {
      final details = SortableStrategies.grid(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-2'),
          fromIndex: 0,
          itemIds: const <DndId>[
            DndId('item-1'),
            DndId('item-2'),
            DndId('item-3'),
            DndId('item-4'),
          ],
          activeTranslatedRect: _rect(left: 81),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(top: 0, left: 0),
            const DndId('item-2'): _rect(top: 0, left: 80),
            const DndId('item-3'): _rect(top: 80, left: 0),
            const DndId('item-4'): _rect(top: 80, left: 80),
          },
        ),
      );

      expect(details?.toIndex, 1);
    });

    test('falls back to drop-over index when measurements are incomplete', () {
      final details = SortableStrategies.grid(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-4'),
          fromIndex: 0,
          itemIds: const <DndId>[
            DndId('item-1'),
            DndId('item-2'),
            DndId('item-3'),
            DndId('item-4'),
          ],
          activeTranslatedRect: _rect(top: 80, left: 80),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(top: 0, left: 0),
            const DndId('item-2'): _rect(top: 0, left: 80),
            const DndId('item-3'): _rect(top: 80, left: 0),
          },
        ),
      );

      expect(details?.toIndex, 3);
    });

    test('falls back to drop-over index for non-grid layouts', () {
      final details = SortableStrategies.grid(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-2'),
          fromIndex: 0,
          activeTranslatedRect: _rect(top: 0, left: 80),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(top: 0, left: 0),
            const DndId('item-2'): _rect(top: 0, left: 80),
            const DndId('item-3'): _rect(top: 0, left: 160),
          },
        ),
      );

      expect(details?.toIndex, 1);
    });

    test('does not report same-item moves or mutate item order', () {
      final itemIds = <DndId>[
        const DndId('item-1'),
        const DndId('item-2'),
        const DndId('item-3'),
        const DndId('item-4'),
      ];

      final details = SortableStrategies.grid(
        _input(
          activeId: const DndId('item-1'),
          overId: const DndId('item-1'),
          fromIndex: 0,
          itemIds: itemIds,
          activeTranslatedRect: _rect(top: 80, left: 80),
          itemRects: <DndId, DndRect>{
            const DndId('item-1'): _rect(top: 0, left: 0),
            const DndId('item-2'): _rect(top: 0, left: 80),
            const DndId('item-3'): _rect(top: 80, left: 0),
            const DndId('item-4'): _rect(top: 80, left: 80),
          },
        ),
      );

      expect(details, isNull);
      expect(
        itemIds,
        const <DndId>[
          DndId('item-1'),
          DndId('item-2'),
          DndId('item-3'),
          DndId('item-4'),
        ],
      );
    });
  });
}

SortableStrategyInput _input({
  required DndId activeId,
  required DndId? overId,
  required int fromIndex,
  required Map<DndId, DndRect> itemRects,
  required DndRect activeTranslatedRect,
  Iterable<DndId> itemIds = const <DndId>[
    DndId('item-1'),
    DndId('item-2'),
    DndId('item-3'),
  ],
  SortableResolutionPhase phase = SortableResolutionPhase.commit,
}) {
  final session = DndDragSession.start(
    activeId: activeId,
    initialPointer: DndPoint.zero,
  );

  return SortableStrategyInput(
    activeId: activeId,
    overId: overId,
    itemIds: itemIds,
    itemRects: itemRects,
    fromIndex: fromIndex,
    fromContainerId: const DndId('list-1'),
    toContainerId: const DndId('list-1'),
    context: switch (phase) {
      SortableResolutionPhase.commit => SortableDragContext.commit(
          DndDragEndEvent(session: session, overId: overId),
        ),
      SortableResolutionPhase.preview => SortableDragContext.preview(
          session: session,
          overId: overId,
        ),
    },
    activeRect: itemRects[activeId],
    activeTranslatedRect: activeTranslatedRect,
  );
}

DndRect _rect({
  double top = 0,
  double left = 0,
}) {
  return DndRect(left: left, top: top, width: 50, height: 50);
}
