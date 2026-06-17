import 'package:dnd_kit/dnd_kit.dart';
import 'package:test/test.dart';

void main() {
  group('DndId', () {
    test('compares by stable string value', () {
      expect(const DndId('task-1'), equals(const DndId('task-1')));
      expect(const DndId('task-1'), isNot(equals(const DndId('task-2'))));
      expect(const DndId('task-1').hashCode, equals(const DndId('task-1').hashCode));
    });

    test('has readable debug output', () {
      expect(const DndId('column-todo').toString(), 'DndId(column-todo)');
    });

    test('rejects empty values in debug mode', () {
      expect(() => DndId(''), throwsA(isA<AssertionError>()));
    });
  });
}
