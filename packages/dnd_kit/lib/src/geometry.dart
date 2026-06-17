/// A point in a two-dimensional coordinate space.
final class DndPoint {
  /// Creates a point at [x], [y].
  const DndPoint(this.x, this.y);

  /// The horizontal coordinate.
  final double x;

  /// The vertical coordinate.
  final double y;

  /// The origin point.
  static const zero = DndPoint(0, 0);

  /// Returns a point offset by [delta].
  DndPoint translate(DndPoint delta) => DndPoint(x + delta.x, y + delta.y);

  /// Returns the vector from [other] to this point.
  DndPoint difference(DndPoint other) => DndPoint(x - other.x, y - other.y);

  @override
  bool operator ==(Object other) => other is DndPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'DndPoint($x, $y)';
}

/// A two-dimensional size.
final class DndSize {
  /// Creates a size with [width] and [height].
  const DndSize(this.width, this.height)
      : assert(width >= 0, 'DndSize width must be non-negative.'),
        assert(height >= 0, 'DndSize height must be non-negative.');

  /// The horizontal extent.
  final double width;

  /// The vertical extent.
  final double height;

  /// The empty size.
  static const zero = DndSize(0, 0);

  /// Whether either extent is zero.
  bool get isEmpty => width == 0 || height == 0;

  @override
  bool operator ==(Object other) =>
      other is DndSize && other.width == width && other.height == height;

  @override
  int get hashCode => Object.hash(width, height);

  @override
  String toString() => 'DndSize($width, $height)';
}

/// An axis-aligned rectangle represented by its top-left point and size.
final class DndRect {
  /// Creates a rectangle from [left], [top], [width], and [height].
  const DndRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  })  : assert(width >= 0, 'DndRect width must be non-negative.'),
        assert(height >= 0, 'DndRect height must be non-negative.');

  /// Creates a rectangle from [origin] and [size].
  factory DndRect.fromPointAndSize(DndPoint origin, DndSize size) {
    return DndRect(left: origin.x, top: origin.y, width: size.width, height: size.height);
  }

  /// The left edge.
  final double left;

  /// The top edge.
  final double top;

  /// The horizontal extent.
  final double width;

  /// The vertical extent.
  final double height;

  /// The right edge.
  double get right => left + width;

  /// The bottom edge.
  double get bottom => top + height;

  /// The top-left point.
  DndPoint get topLeft => DndPoint(left, top);

  /// The center point.
  DndPoint get center => DndPoint(left + width / 2, top + height / 2);

  /// The rectangle size.
  DndSize get size => DndSize(width, height);

  /// Whether the rectangle has no area.
  bool get isEmpty => width == 0 || height == 0;

  /// Returns whether [point] is inside this rectangle, including the edges.
  bool containsPoint(DndPoint point) {
    return point.x >= left && point.x <= right && point.y >= top && point.y <= bottom;
  }

  /// Returns whether this rectangle overlaps [other] with positive area.
  bool overlaps(DndRect other) {
    return left < other.right && right > other.left && top < other.bottom && bottom > other.top;
  }

  /// Returns this rectangle translated by [delta].
  DndRect translate(DndPoint delta) {
    return DndRect(left: left + delta.x, top: top + delta.y, width: width, height: height);
  }

  /// Returns this rectangle expanded outward by [delta] on each side.
  DndRect inflate(double delta) {
    final inflatedWidth = width + delta * 2;
    final inflatedHeight = height + delta * 2;
    assert(inflatedWidth >= 0, 'Inflated DndRect width must be non-negative.');
    assert(inflatedHeight >= 0, 'Inflated DndRect height must be non-negative.');

    return DndRect(
      left: left - delta,
      top: top - delta,
      width: inflatedWidth,
      height: inflatedHeight,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DndRect &&
        other.left == left &&
        other.top == top &&
        other.width == width &&
        other.height == height;
  }

  @override
  int get hashCode => Object.hash(left, top, width, height);

  @override
  String toString() {
    return 'DndRect(left: $left, top: $top, width: $width, height: $height)';
  }
}

/// A pure Dart transform used to describe drag translation and scale.
final class DndTransform {
  /// Creates a transform.
  const DndTransform({
    this.x = 0,
    this.y = 0,
    this.scaleX = 1,
    this.scaleY = 1,
  })  : assert(scaleX >= 0, 'DndTransform scaleX must be non-negative.'),
        assert(scaleY >= 0, 'DndTransform scaleY must be non-negative.');

  /// No translation or scaling.
  static const identity = DndTransform();

  /// Horizontal translation.
  final double x;

  /// Vertical translation.
  final double y;

  /// Horizontal scale.
  final double scaleX;

  /// Vertical scale.
  final double scaleY;

  /// Whether this transform has no visible effect.
  bool get isIdentity => this == identity;

  /// The translation component as a point.
  DndPoint get offset => DndPoint(x, y);

  /// Returns a transform with additional translation.
  DndTransform translate(DndPoint delta) {
    return DndTransform(x: x + delta.x, y: y + delta.y, scaleX: scaleX, scaleY: scaleY);
  }

  @override
  bool operator ==(Object other) {
    return other is DndTransform &&
        other.x == x &&
        other.y == y &&
        other.scaleX == scaleX &&
        other.scaleY == scaleY;
  }

  @override
  int get hashCode => Object.hash(x, y, scaleX, scaleY);

  @override
  String toString() {
    return 'DndTransform(x: $x, y: $y, scaleX: $scaleX, scaleY: $scaleY)';
  }
}
