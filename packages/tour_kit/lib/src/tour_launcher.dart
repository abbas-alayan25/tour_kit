import 'dart:async';

import 'package:flutter/widgets.dart';

import 'tour.dart';
import 'tour_card.dart';
import 'tour_controller.dart';
import 'tour_options.dart';
import 'tour_result.dart';
import 'tour_step.dart';
import 'tour_storage.dart';
import 'tour_strings.dart';
import 'tour_theme.dart';

/// Shows a tour once, shortly after its [child] first appears.
///
/// With a [storage], the tour is skipped when it was already completed and
/// recorded afterwards. Without one, control [enabled] and listen to [onShown]
/// to keep track yourself.
class TourLauncher extends StatefulWidget {
  /// Creates a launcher around [child].
  const TourLauncher({
    super.key,
    required this.tourId,
    required this.steps,
    required this.child,
    this.storage,
    this.enabled = true,
    this.delay = const Duration(milliseconds: 650),
    this.theme = const TourTheme(),
    this.strings = const TourStrings(),
    this.options = const TourOptions(),
    this.cardBuilder,
    this.markCompletedOnSkip = true,
    this.onShown,
    this.onFinished,
    this.onStepChanged,
  });

  /// A unique name for this tour, used with [storage].
  final String tourId;

  /// The steps to show.
  final List<TourStep> steps;

  /// The screen the tour explains.
  final Widget child;

  /// Where "already seen" is remembered.
  final TourStorage? storage;

  /// Set to false to hold the tour back, for example until data has loaded.
  final bool enabled;

  /// How long to wait after the first frame before showing the tour.
  final Duration delay;

  /// The theme of the tour.
  final TourTheme theme;

  /// The texts of the tour.
  final TourStrings strings;

  /// The behaviour options of the tour.
  final TourOptions options;

  /// A custom card, replacing the default one.
  final TourCardBuilder? cardBuilder;

  /// Whether skipping also counts as seen. Defaults to true.
  final bool markCompletedOnSkip;

  /// Called after the tour was shown, with how it ended.
  final ValueChanged<TourOutcome>? onShown;

  /// Called whenever a step is presented.
  /// Called after the tour was shown, with the full [TourResult].
  final ValueChanged<TourResult>? onFinished;

  /// Called whenever a step is presented.
  final TourStepChanged? onStepChanged;

  @override
  State<TourLauncher> createState() => _TourLauncherState();
}

class _TourLauncherState extends State<TourLauncher> {
  static final Set<String> _scheduled = {};

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(TourLauncher old) {
    super.didUpdateWidget(old);
    if (old.tourId != widget.tourId || (!old.enabled && widget.enabled)) {
      _schedule();
    }
  }

  void _schedule() {
    if (!widget.enabled || !_scheduled.add(widget.tourId)) return;
    final id = widget.tourId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _run(id));
  }

  Future<void> _run(String id) async {
    try {
      final storage = widget.storage;
      if (storage != null && await storage.isCompleted(id)) return;
      await Future<void>.delayed(widget.delay);
      if (!mounted || !widget.enabled) return;
      final result = await Tour.show(
        context,
        steps: widget.steps,
        theme: widget.theme,
        strings: widget.strings,
        options: widget.options,
        cardBuilder: widget.cardBuilder,
        onStepChanged: widget.onStepChanged,
      );
      if (result.outcome == TourOutcome.unavailable) return;
      final counts = result.outcome == TourOutcome.completed ||
          widget.markCompletedOnSkip ||
          result.dontShowAgain;
      if (counts) await storage?.markCompleted(id);
      widget.onShown?.call(result.outcome);
      widget.onFinished?.call(result);
    } finally {
      _scheduled.remove(id);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
