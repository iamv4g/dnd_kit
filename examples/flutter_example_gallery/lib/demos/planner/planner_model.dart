import 'package:flutter/foundation.dart';

/// A leaf item: a titled row with an editable note.
class PlannerItem {
  PlannerItem({required this.id, required this.title, this.note = ''});

  final String id;
  final String title;
  String note;
}

/// A section groups items and can be reordered within its day.
class PlannerSection {
  PlannerSection(
      {required this.id, required this.title, required this.itemIds});

  final String id;
  final String title;
  List<String> itemIds;
}

/// A day groups sections under a sticky header.
class PlannerDay {
  PlannerDay({required this.id, required this.title, required this.sectionIds});

  final String id;
  final String title;
  List<String> sectionIds;
}

/// Mutable board state owned by the demo.
class PlannerBoard {
  PlannerBoard({
    required this.days,
    required this.sections,
    required this.items,
  });

  final List<PlannerDay> days;
  final Map<String, PlannerSection> sections;
  final Map<String, PlannerItem> items;

  /// Moves a section within its day.
  void reorderSection({
    required String dayId,
    required int fromIndex,
    required int toIndex,
  }) {
    final day = days.firstWhere((d) => d.id == dayId);
    if (fromIndex < 0 || fromIndex >= day.sectionIds.length) {
      return;
    }
    final sectionId = day.sectionIds.removeAt(fromIndex);
    day.sectionIds.insert(toIndex.clamp(0, day.sectionIds.length), sectionId);
  }

  /// Moves an item from one section to another (or within a section).
  void moveItem({
    required String fromSectionId,
    required int fromIndex,
    required String toSectionId,
    required int toIndex,
  }) {
    final from = sections[fromSectionId];
    final to = sections[toSectionId];
    if (from == null || to == null) {
      return;
    }
    if (fromIndex < 0 || fromIndex >= from.itemIds.length) {
      return;
    }
    final itemId = from.itemIds.removeAt(fromIndex);
    to.itemIds.insert(toIndex.clamp(0, to.itemIds.length), itemId);
  }

  static PlannerBoard demo() {
    final items = <String, PlannerItem>{};
    void addItem(String id, String title, [String note = '']) {
      items[id] = PlannerItem(id: id, title: title, note: note);
    }

    addItem('i-brief', 'Write the brief', 'Two paragraphs, ship by noon.');
    addItem('i-wireframe', 'Wireframe the flow');
    addItem('i-standup', 'Team standup', '9:30, 15 min.');
    addItem('i-review', 'Review the PR');
    addItem('i-deploy', 'Deploy to staging');
    addItem('i-retro', 'Sprint retro', 'Bring three notes.');
    addItem('i-demo', 'Record the demo');

    final sections = <String, PlannerSection>{
      's-morning': PlannerSection(
        id: 's-morning',
        title: 'Morning',
        itemIds: ['i-brief', 'i-wireframe'],
      ),
      's-afternoon': PlannerSection(
        id: 's-afternoon',
        title: 'Afternoon',
        itemIds: ['i-standup', 'i-review'],
      ),
      's-tue-focus': PlannerSection(
        id: 's-tue-focus',
        title: 'Focus',
        itemIds: ['i-deploy'],
      ),
      's-tue-wrap': PlannerSection(
        id: 's-tue-wrap',
        title: 'Wrap up',
        itemIds: ['i-retro', 'i-demo'],
      ),
    };

    final days = <PlannerDay>[
      PlannerDay(
          id: 'd-mon',
          title: 'Monday',
          sectionIds: ['s-morning', 's-afternoon']),
      PlannerDay(
          id: 'd-tue',
          title: 'Tuesday',
          sectionIds: ['s-tue-focus', 's-tue-wrap']),
    ];

    return PlannerBoard(days: days, sections: sections, items: items);
  }
}

/// Encodes/decodes the namespaced ids the nested sortables use.
@immutable
class PlannerIds {
  const PlannerIds._();

  static String section(String id) => 'section:$id';
  static String sectionContainer(String id) => 'sec:$id';
  static String item(String id) => 'item:$id';

  static bool isSection(String value) => value.startsWith('section:');
  static bool isSectionContainer(String value) => value.startsWith('sec:');
  static bool isItem(String value) => value.startsWith('item:');

  static String decode(String value) => value.substring(value.indexOf(':') + 1);
}
