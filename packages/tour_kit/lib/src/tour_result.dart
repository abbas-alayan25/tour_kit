import 'package:flutter/foundation.dart';

/// How a tour ended.
enum TourOutcome {
  /// The user reached the end of the last step.
  completed,

  /// The user skipped the tour, pressed back, or the overlay was disposed.
  skipped,

  /// The tour never started: it had no steps, or another tour was active.
  unavailable,
}

/// The full result of a tour, passed to [TourLauncher.onFinished] and returned
/// by [Tour.show].
@immutable
class TourResult {
  /// Creates a result.
  const TourResult({
    required this.outcome,
    this.lastIndex = -1,
    this.dontShowAgain = false,
  });

  /// The result of a tour that could not start.
  static const unavailable = TourResult(outcome: TourOutcome.unavailable);

  /// How the tour ended.
  final TourOutcome outcome;

  /// The zero-based index of the last step that was shown, or -1 if none.
  final int lastIndex;

  /// Whether the user ticked the "don't show again" box.
  final bool dontShowAgain;

  @override
  String toString() =>
      'TourResult($outcome, lastIndex: $lastIndex, dontShowAgain: $dontShowAgain)';
}
