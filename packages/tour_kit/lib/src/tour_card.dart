import 'package:flutter/material.dart';

import 'tour_options.dart';
import 'tour_step.dart';
import 'tour_strings.dart';
import 'tour_theme.dart';

/// Everything a custom card needs to render one step and drive the tour.
class TourCardData {
  /// Creates the data. Built by the tour, not by apps.
  const TourCardData({
    required this.step,
    required this.index,
    required this.count,
    required this.theme,
    required this.strings,
    required this.options,
    required this.next,
    required this.back,
    required this.skip,
    required this.dontShowAgain,
    required this.setDontShowAgain,
  });

  /// The step being shown.
  final TourStep step;

  /// The zero-based position of [step].
  final int index;

  /// The number of steps in the tour.
  final int count;

  /// The theme in use.
  final TourTheme theme;

  /// The texts in use.
  final TourStrings strings;

  /// The options in use.
  final TourOptions options;

  /// Goes to the next step, or ends the tour on the last one.
  final VoidCallback next;

  /// Goes back one step.
  final VoidCallback back;

  /// Ends the tour.
  final VoidCallback skip;

  /// Whether the user ticked "don't show again".
  final bool dontShowAgain;

  /// Sets the "don't show again" choice.
  final ValueChanged<bool> setDontShowAgain;

  /// Whether [step] is the first one.
  bool get isFirst => index == 0;

  /// Whether [step] is the last one.
  bool get isLast => index == count - 1;
}

/// Builds a custom card for a step, replacing the default one.
typedef TourCardBuilder = Widget Function(
    BuildContext context, TourCardData data);

/// The card used when no custom builder is given.
class DefaultTourCard extends StatelessWidget {
  /// Creates the card for [data].
  const DefaultTourCard({super.key, required this.data});

  /// What to show.
  final TourCardData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tour = data.theme;
    final step = data.step;
    final accent = tour.effectiveAccent(scheme);
    final muted = tour.effectiveMuted(scheme);
    final progress = data.options.progress;
    final showCounter = progress == TourProgressStyle.counter ||
        progress == TourProgressStyle.both;
    final showDots = progress == TourProgressStyle.dots ||
        progress == TourProgressStyle.both;
    final icon = step.icon;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tour.effectiveCard(scheme),
        borderRadius: BorderRadius.circular(tour.cardRadius),
        border: Border.all(color: tour.effectiveBorder(scheme)),
        boxShadow: tour.effectiveShadow(scheme),
      ),
      child: SingleChildScrollView(
        padding: tour.cardPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (icon != null || step.title != null || showCounter)
              Row(
                children: [
                  if (icon != null) ...[
                    tour.iconBuilder?.call(context, icon) ??
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: accent),
                        ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: step.title == null
                        ? const SizedBox.shrink()
                        : Text(step.title!, style: tour.effectiveTitle(theme)),
                  ),
                  if (showCounter)
                    Text(
                      data.strings.counterFor(data.index + 1, data.count),
                      textDirection: TextDirection.ltr,
                      style: tour.effectiveCounter(theme),
                    ),
                ],
              ),
            if (step.content != null || step.body != null) ...[
              const SizedBox(height: 12),
              step.content ??
                  Text(step.body!, style: tour.effectiveBody(theme)),
            ],
            if (data.options.offerDontShowAgain) ...[
              const SizedBox(height: 8),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => data.setDontShowAgain(!data.dontShowAgain),
                child: Row(
                  children: [
                    Checkbox(
                      value: data.dontShowAgain,
                      visualDensity: VisualDensity.compact,
                      onChanged: (v) => data.setDontShowAgain(v ?? false),
                    ),
                    Expanded(
                      child: Text(
                        data.strings.dontShowAgain,
                        style: tour.effectiveCounter(theme),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: showDots
                      ? Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (var d = 0; d < data.count; d++)
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsetsDirectional.only(
                                      end: 4,
                                    ),
                                    width: d == data.index ? 16 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: d == data.index
                                          ? accent
                                          : tour.effectiveBorder(scheme),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
                if (data.options.showSkip && !data.isLast)
                  TextButton(
                    onPressed: data.skip,
                    style: TextButton.styleFrom(
                      foregroundColor: muted,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(data.strings.skip),
                  ),
                if (data.options.showBack && !data.isFirst)
                  IconButton(
                    tooltip: data.strings.back,
                    visualDensity: VisualDensity.compact,
                    onPressed: data.back,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                const SizedBox(width: 4),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: tour.effectiveOnAccent(scheme),
                    shape: const StadiumBorder(),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                  ),
                  onPressed: data.next,
                  child: Text(
                    data.isLast ? data.strings.done : data.strings.next,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
