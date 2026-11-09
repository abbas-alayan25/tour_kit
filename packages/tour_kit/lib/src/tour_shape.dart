import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The kind of cut-out a [TourShape] draws around the highlighted widget.
enum TourShapeKind {
  /// A sharp rectangle.
  rect,

  /// A rectangle with rounded corners.
  rounded,

  /// A circle that covers the target's longest side.
  circle,

  /// An oval that fits the target.
  oval,
}

@immutable

/// The cut-out drawn around a highlighted widget.
class TourShape {
  /// A sharp rectangle around the target.
  const TourShape.rect()
      : kind = TourShapeKind.rect,
        radius = 0;

  /// A rounded rectangle around the target, with corner [radius].
  const TourShape.rounded([this.radius = 16]) : kind = TourShapeKind.rounded;

  /// A circle centred on the target and sized to its longest side.
  const TourShape.circle()
      : kind = TourShapeKind.circle,
        radius = 0;

  /// An oval that fits the target's bounds.
  const TourShape.oval()
      : kind = TourShapeKind.oval,
        radius = 0;

  /// Which kind of cut-out this is.
  final TourShapeKind kind;

  /// Corner radius, used by [TourShapeKind.rounded].
  final double radius;

  /// The outline of this shape for a target occupying [hole].
  Path pathFor(Rect hole) {
    switch (kind) {
      case TourShapeKind.rect:
        return Path()..addRect(hole);
      case TourShapeKind.rounded:
        return Path()
          ..addRRect(
            RRect.fromRectAndRadius(
              hole,
              Radius.circular(math.min(radius, hole.shortestSide / 2)),
            ),
          );
      case TourShapeKind.circle:
        return Path()
          ..addOval(
            Rect.fromCircle(center: hole.center, radius: hole.longestSide / 2),
          );
      case TourShapeKind.oval:
        return Path()..addOval(hole);
    }
  }

  @override
  bool operator ==(Object other) =>
      other is TourShape && other.kind == kind && other.radius == radius;

  @override
  int get hashCode => Object.hash(kind, radius);
}
