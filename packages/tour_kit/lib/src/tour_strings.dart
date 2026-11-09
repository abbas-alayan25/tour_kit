import 'package:flutter/foundation.dart';

@immutable

/// The texts used by the default card. Replace them to localise the tour.
class TourStrings {
  /// Creates the texts, defaulting to English.
  const TourStrings({
    this.next = 'Next',
    this.back = 'Back',
    this.skip = 'Skip',
    this.done = 'Done',
    this.dontShowAgain = "Don't show again",
    this.counter,
  });

  /// Label of the button that goes to the next step.
  final String next;

  /// Tooltip of the back arrow.
  final String back;

  /// Label of the button that ends the tour early.
  final String skip;

  /// Label of the button on the last step.
  final String done;

  /// Label of the "don't show again" checkbox.
  final String dontShowAgain;

  /// Builds the position counter text, for example "2 / 5".
  final String Function(int current, int total)? counter;

  /// The counter text for step [current] of [total] (both starting at 1).
  String counterFor(int current, int total) =>
      counter?.call(current, total) ?? '$current / $total';
}
