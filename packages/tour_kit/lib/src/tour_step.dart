import 'dart:async';

import 'package:flutter/widgets.dart';

import 'tour_card.dart';
import 'tour_shape.dart';
import 'tour_theme.dart';

/// A callback run when a step is entered, left or its target is tapped.
///
/// The [context] is the one the tour was started from.
typedef TourHook = FutureOr<void> Function(BuildContext context);

/// Scrolls [target] into view in a custom way, replacing the default scrolling.
typedef TourScroller = FutureOr<void> Function(
    BuildContext context, BuildContext target);

/// Where the card sits relative to the highlighted widget.
enum TourCardPlacement {
  /// Below the target if there is room, otherwise above.
  auto,

  /// Above the target.
  above,

  /// Below the target.
  below,

  /// Centred on screen, ignoring the target.
  center,
}

@immutable

/// One step of a tour: what to highlight and what to say about it.
class TourStep {
  /// Creates a step. Use either [target] or [targetKey], or neither for a
  /// centred card with no highlight.
  const TourStep({
    this.target,
    this.targetKey,
    this.icon,
    this.title,
    this.body,
    this.content,
    this.shape,
    this.padding,
    this.placement = TourCardPlacement.auto,
    this.scroll = true,
    this.scrollAlignment = 0.3,
    this.scrollController,
    this.scrollOffset,
    this.scrollTo,
    this.onEnter,
    this.onExit,
    this.onTargetTap,
    this.tapTargetToContinue = false,
    this.interactive = false,
    this.theme,
    this.cardBuilder,
    this.waitFor = const Duration(milliseconds: 1500),
    this.hookTimeout = const Duration(seconds: 2),
    this.skipIfMissing = true,
    this.data,
  }) : assert(
          target == null || targetKey == null,
          'Use either target or targetKey, not both.',
        );

  /// The id of a [TourTarget] to highlight.
  final String? target;

  /// A [GlobalKey] of the widget to highlight, as an alternative to [target].
  final GlobalKey? targetKey;

  /// An icon shown at the start of the default card's header.
  final IconData? icon;

  /// The card's heading.
  final String? title;

  /// The card's explanation text.
  final String? body;

  /// A widget shown instead of [body], for rich content.
  final Widget? content;

  /// The cut-out shape. Falls back to [TourTheme.holeShape].
  final TourShape? shape;

  /// Space around the target inside the cut-out. Falls back to [TourTheme.holePadding].
  final EdgeInsets? padding;

  /// Where the card sits relative to the target.
  final TourCardPlacement placement;

  /// Whether to scroll the target into view with [Scrollable.ensureVisible].
  final bool scroll;

  /// Where in the viewport the target should land when scrolled (0 top, 1 bottom).
  final double scrollAlignment;

  /// A controller to move before looking for the target.
  ///
  /// Combine with [scrollOffset] to reach items of a lazy list that are not
  /// built yet.
  final ScrollController? scrollController;

  /// The offset to jump [scrollController] to before looking for the target.
  final double? scrollOffset;

  /// Replaces the default scrolling with your own logic.
  final TourScroller? scrollTo;

  /// Runs before the step looks for its target. Switch tabs or open panels here.
  ///
  /// The tour waits for it to finish, then waits up to [waitFor] for the target.
  final TourHook? onEnter;

  /// Runs when the user leaves the step, in either direction.
  final TourHook? onExit;

  /// Runs when the user taps inside the highlighted area.
  final TourHook? onTargetTap;

  /// Whether tapping the highlighted area also moves to the next step.
  final bool tapTargetToContinue;

  /// Whether taps inside the highlighted area reach the real widget underneath.
  ///
  /// The tour still reports the tap through [onTargetTap].
  final bool interactive;

  /// A theme for this step only, replacing the tour's theme.
  final TourTheme? theme;

  /// A card for this step only, replacing the tour's card builder.
  final TourCardBuilder? cardBuilder;

  /// How long to wait for the target to appear. Defaults to 1.5 seconds.
  final Duration waitFor;

  /// How long to wait for [onEnter] and [onExit] to finish before carrying on.
  ///
  /// Navigation futures such as `Navigator.push` only complete when the new
  /// screen closes, so a hook that returns one is treated as started once this
  /// time has passed. Prefer a block body, `onEnter: (c) { Navigator.push(...); }`,
  /// to continue at once.
  final Duration hookTimeout;

  /// Whether to skip the step when its target never appears.
  ///
  /// When false the step is shown as a centred card instead.
  final bool skipIfMissing;

  /// Anything you want to carry with the step, for custom cards.
  final Object? data;

  /// Whether this step highlights something.
  bool get hasTarget => target != null || targetKey != null;
}
