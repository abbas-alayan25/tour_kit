import 'package:flutter/foundation.dart';

/// What happens when the user taps the dimmed area outside the highlight.
enum TourScrimTap {
  /// Go to the next step.
  next,

  /// End the tour.
  skip,

  /// Nothing.
  none,
}

/// How the default card shows the user's position in the tour.
enum TourProgressStyle {
  /// A row of dots at the bottom of the card.
  dots,

  /// A "1 / 5" counter next to the title.
  counter,

  /// Both the dots and the counter.
  both,

  /// No progress indicator.
  none,
}

@immutable

/// Behaviour switches for a tour.
class TourOptions {
  /// Creates options with the usual defaults.
  const TourOptions({
    this.scrimTap = TourScrimTap.next,
    this.progress = TourProgressStyle.dots,
    this.showSkip = true,
    this.showBack = true,
    this.rootNavigator = true,
    this.initialIndex = 0,
    this.keyboard = true,
    this.offerDontShowAgain = false,
  });

  /// What tapping the dimmed area does. Defaults to [TourScrimTap.next].
  final TourScrimTap scrimTap;

  /// How the default card shows progress. Defaults to dots.
  final TourProgressStyle progress;

  /// Whether the default card shows a skip button (hidden on the last step).
  final bool showSkip;

  /// Whether the default card shows a back arrow (hidden on the first step).
  final bool showBack;

  /// Whether to show the tour above all navigators. Defaults to true.
  final bool rootNavigator;

  /// The step to start from. Defaults to 0.
  final int initialIndex;

  /// Whether Escape, Enter and the arrow keys control the tour.
  final bool keyboard;

  /// Whether the default card offers a "don't show again" checkbox.
  final bool offerDontShowAgain;
}
