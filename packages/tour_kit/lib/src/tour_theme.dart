import 'package:flutter/material.dart';

import 'tour_shape.dart';

/// Builds the icon badge of the default card from a [TourStep.icon].
typedef TourIconBuilder = Widget Function(BuildContext context, IconData icon);

@immutable

/// Colours, shapes, text styles and timings of a tour.
///
/// Every colour and text style that is null falls back to the app's
/// [ThemeData], so a tour matches the app without any setup.
class TourTheme {
  /// Creates a theme. Everything is optional.
  const TourTheme({
    this.scrimColor,
    this.ringColor,
    this.ringWidth = 1.6,
    this.glow = true,
    this.holeShape = const TourShape.rounded(16),
    this.holePadding = const EdgeInsets.all(8),
    this.holeDuration = const Duration(milliseconds: 320),
    this.cardDuration = const Duration(milliseconds: 220),
    this.curve = Curves.easeOutCubic,
    this.cardColor,
    this.cardBorderColor,
    this.cardRadius = 24,
    this.cardShadow,
    this.cardMaxWidth = 400,
    this.cardPadding = const EdgeInsets.fromLTRB(18, 18, 18, 14),
    this.cardMargin = 16,
    this.titleStyle,
    this.bodyStyle,
    this.counterStyle,
    this.accentColor,
    this.onAccentColor,
    this.mutedColor,
    this.iconBuilder,
    this.pointer = false,
    this.pointerSize = const Size(22, 11),
    this.pulse = false,
    this.fadeDuration = const Duration(milliseconds: 260),
  });

  /// The colour of the dimmed area. Defaults to the scheme's scrim at 72%.
  final Color? scrimColor;

  /// The colour of the outline around the highlight. Defaults to the primary colour.
  final Color? ringColor;

  /// Width of the outline. Zero hides it.
  final double ringWidth;

  /// Whether to paint a soft glow around the outline.
  final bool glow;

  /// The default cut-out shape.
  final TourShape holeShape;

  /// The default space between the target and the cut-out edge.
  final EdgeInsets holePadding;

  /// How long the highlight takes to move between steps.
  final Duration holeDuration;

  /// How long the card takes to cross-fade between steps.
  final Duration cardDuration;

  /// The curve of the highlight animation.
  final Curve curve;

  /// The card's background. Defaults to the scheme's surface.
  final Color? cardColor;

  /// The card's border. Defaults to the scheme's outline variant.
  final Color? cardBorderColor;

  /// The card's corner radius.
  final double cardRadius;

  /// The card's shadow.
  final List<BoxShadow>? cardShadow;

  /// The card's maximum width.
  final double cardMaxWidth;

  /// Padding inside the card.
  final EdgeInsets cardPadding;

  /// Space kept between the card, the target and the screen edges.
  final double cardMargin;

  /// Style merged onto the title.
  final TextStyle? titleStyle;

  /// Style merged onto the body text.
  final TextStyle? bodyStyle;

  /// Style merged onto the position counter.
  final TextStyle? counterStyle;

  /// Colour of the next button, icon and active dot. Defaults to primary.
  final Color? accentColor;

  /// Text colour on the next button. Defaults to on-primary.
  final Color? onAccentColor;

  /// Colour of secondary text such as the skip button.
  final Color? mutedColor;

  /// Replaces the default round icon badge.
  final TourIconBuilder? iconBuilder;

  /// Whether to draw a small arrow from the card towards the highlight.
  final bool pointer;

  /// The size of the pointer arrow.
  final Size pointerSize;

  /// Whether the outline gently pulses. Ignored when the system asks to
  /// reduce motion.
  final bool pulse;

  /// How long the tour takes to fade in and out.
  final Duration fadeDuration;

  /// The scrim colour after applying defaults.
  Color effectiveScrim(ColorScheme scheme) =>
      scrimColor ?? scheme.scrim.withValues(alpha: 0.72);

  /// The outline colour after applying defaults.
  Color effectiveRing(ColorScheme scheme) => ringColor ?? scheme.primary;

  /// The card colour after applying defaults.
  Color effectiveCard(ColorScheme scheme) => cardColor ?? scheme.surface;

  /// The card border colour after applying defaults.
  Color effectiveBorder(ColorScheme scheme) =>
      cardBorderColor ?? scheme.outlineVariant;

  /// The accent colour after applying defaults.
  Color effectiveAccent(ColorScheme scheme) => accentColor ?? scheme.primary;

  /// The text colour on the accent after applying defaults.
  Color effectiveOnAccent(ColorScheme scheme) =>
      onAccentColor ?? scheme.onPrimary;

  /// The secondary text colour after applying defaults.
  Color effectiveMuted(ColorScheme scheme) =>
      mutedColor ?? scheme.onSurfaceVariant;

  /// The card shadow after applying defaults.
  List<BoxShadow> effectiveShadow(ColorScheme scheme) =>
      cardShadow ??
      [
        BoxShadow(
          color: scheme.shadow.withValues(alpha: 0.3),
          blurRadius: 30,
          offset: const Offset(0, 12),
        ),
      ];

  /// The title style after applying defaults.
  TextStyle effectiveTitle(ThemeData theme) =>
      theme.textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.w800, height: 1.3)
          .merge(titleStyle) ??
      const TextStyle(fontSize: 17, fontWeight: FontWeight.w800);

  /// The body style after applying defaults.
  TextStyle effectiveBody(ThemeData theme) =>
      theme.textTheme.bodyMedium?.copyWith(height: 1.6).merge(bodyStyle) ??
      const TextStyle(fontSize: 14, height: 1.6);

  /// The counter style after applying defaults.
  TextStyle effectiveCounter(ThemeData theme) {
    final base = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: mutedColor ?? theme.colorScheme.onSurfaceVariant,
    );
    return base.merge(counterStyle);
  }

  /// A copy of this theme with the given fields replaced.
  TourTheme copyWith({
    Color? scrimColor,
    Color? ringColor,
    double? ringWidth,
    bool? glow,
    TourShape? holeShape,
    EdgeInsets? holePadding,
    Duration? holeDuration,
    Duration? cardDuration,
    Curve? curve,
    Color? cardColor,
    Color? cardBorderColor,
    double? cardRadius,
    List<BoxShadow>? cardShadow,
    double? cardMaxWidth,
    EdgeInsets? cardPadding,
    double? cardMargin,
    TextStyle? titleStyle,
    TextStyle? bodyStyle,
    TextStyle? counterStyle,
    Color? accentColor,
    Color? onAccentColor,
    Color? mutedColor,
    TourIconBuilder? iconBuilder,
    bool? pointer,
    Size? pointerSize,
    bool? pulse,
    Duration? fadeDuration,
  }) =>
      TourTheme(
        scrimColor: scrimColor ?? this.scrimColor,
        ringColor: ringColor ?? this.ringColor,
        ringWidth: ringWidth ?? this.ringWidth,
        glow: glow ?? this.glow,
        holeShape: holeShape ?? this.holeShape,
        holePadding: holePadding ?? this.holePadding,
        holeDuration: holeDuration ?? this.holeDuration,
        cardDuration: cardDuration ?? this.cardDuration,
        curve: curve ?? this.curve,
        cardColor: cardColor ?? this.cardColor,
        cardBorderColor: cardBorderColor ?? this.cardBorderColor,
        cardRadius: cardRadius ?? this.cardRadius,
        cardShadow: cardShadow ?? this.cardShadow,
        cardMaxWidth: cardMaxWidth ?? this.cardMaxWidth,
        cardPadding: cardPadding ?? this.cardPadding,
        cardMargin: cardMargin ?? this.cardMargin,
        titleStyle: titleStyle ?? this.titleStyle,
        bodyStyle: bodyStyle ?? this.bodyStyle,
        counterStyle: counterStyle ?? this.counterStyle,
        accentColor: accentColor ?? this.accentColor,
        onAccentColor: onAccentColor ?? this.onAccentColor,
        mutedColor: mutedColor ?? this.mutedColor,
        iconBuilder: iconBuilder ?? this.iconBuilder,
        pointer: pointer ?? this.pointer,
        pointerSize: pointerSize ?? this.pointerSize,
        pulse: pulse ?? this.pulse,
        fadeDuration: fadeDuration ?? this.fadeDuration,
      );
}
