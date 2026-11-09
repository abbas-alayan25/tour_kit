import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tour_card.dart';
import 'tour_controller.dart';
import 'tour_options.dart';
import 'tour_shape.dart';
import 'tour_step.dart';
import 'tour_strings.dart';
import 'tour_theme.dart';

/// The dimmed overlay, highlight and card of a running tour.
///
/// Inserted into the root overlay by [Tour.show].
class TourHost extends StatefulWidget {
  /// Creates the host for [controller].
  const TourHost({
    super.key,
    required this.controller,
    required this.theme,
    required this.strings,
    required this.options,
    required this.onClosed,
    this.cardBuilder,
    this.startVisible = false,
    this.onFadedIn,
  });

  /// The controller driving this overlay.
  final TourController controller;

  /// The theme in use.
  final TourTheme theme;

  /// The texts in use.
  final TourStrings strings;

  /// The options in use.
  final TourOptions options;

  /// A custom card, if any.
  final TourCardBuilder? cardBuilder;

  /// Called once the overlay has faded out ([overlayGone] false), or when the
  /// overlay is disposed while the tour was still showing ([overlayGone] true).
  final void Function(bool overlayGone) onClosed;

  /// Whether to appear fully visible at once instead of fading in.
  final bool startVisible;

  /// Called once the overlay has finished fading in.
  final VoidCallback? onFadedIn;

  @override
  State<TourHost> createState() => _TourHostState();
}

class _TourHostState extends State<TourHost> with TickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: widget.theme.fadeDuration,
    value: widget.startVisible ? 1 : 0,
  );
  AnimationController? _pulse;
  bool _closing = false;
  bool _notified = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onController);
    if (!widget.startVisible) {
      _fade.forward().whenComplete(() => widget.onFadedIn?.call());
    }
    if (widget.theme.pulse) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1400),
      )..repeat(reverse: true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _fade.duration = Duration.zero;
      _pulse?.stop();
    }
  }

  void _onController() {
    if (widget.controller.outcome == null || _closing) return;
    _closing = true;
    _fade.reverse().whenComplete(() {
      if (_notified) return;
      _notified = true;
      widget.onClosed(false);
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onController);
    _fade.dispose();
    _pulse?.dispose();
    if (!_notified) {
      _notified = true;
      widget.onClosed(true);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final options = widget.options;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final forward =
        rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight;
    final backward =
        rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft;

    Widget body = Material(
      type: MaterialType.transparency,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => _buildScene(context),
      ),
    );

    if (options.keyboard) {
      body = CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): controller.skip,
          SingleActivator(forward): controller.next,
          SingleActivator(backward): controller.back,
          const SingleActivator(LogicalKeyboardKey.enter): controller.next,
        },
        child: Focus(autofocus: true, child: body),
      );
    }
    return FadeTransition(opacity: _fade, child: body);
  }

  Widget _buildScene(BuildContext context) {
    final controller = widget.controller;
    final options = widget.options;
    final step = controller.step;
    final theme = step?.theme ?? widget.theme;
    final scheme = Theme.of(context).colorScheme;
    final reduce = MediaQuery.disableAnimationsOf(context);
    final media = MediaQuery.of(context);
    final insets = EdgeInsets.fromLTRB(
      media.padding.left,
      media.padding.top,
      media.padding.right,
      math.max(media.padding.bottom, media.viewInsets.bottom),
    );
    final shape = step?.shape ?? theme.holeShape;
    final inflate = step?.padding ?? theme.holePadding;
    final hole =
        controller.hole == null ? null : inflate.inflateRect(controller.hole!);
    final screen = media.size;
    final collapsed = Rect.fromCenter(
      center: screen.center(Offset.zero),
      width: 0,
      height: 0,
    );
    final interactive = step != null && step.interactive && hole != null;

    void scrimTap() {
      switch (options.scrimTap) {
        case TourScrimTap.next:
          controller.next();
        case TourScrimTap.skip:
          controller.skip();
        case TourScrimTap.none:
          break;
      }
    }

    final painter = TweenAnimationBuilder<Rect?>(
      tween: RectTween(end: hole ?? collapsed),
      duration: reduce ? Duration.zero : theme.holeDuration,
      curve: theme.curve,
      builder: (context, value, _) => CustomPaint(
        painter: _ScrimPainter(
          hole: hole == null ? null : value,
          shape: shape,
          scrim: theme.effectiveScrim(scheme),
          ring: theme.effectiveRing(scheme),
          ringWidth: theme.ringWidth,
          glow: theme.glow,
          pulse: reduce ? null : _pulse,
        ),
      ),
    );

    final Widget scrim;
    if (interactive) {
      scrim = Stack(
        children: [
          Positioned.fill(child: IgnorePointer(child: painter)),
          ..._absorbers(screen, hole, scrimTap),
          Positioned.fromRect(
            rect: hole,
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerUp: (_) => controller.tapTarget(),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      );
    } else {
      scrim = BlockSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: step == null
              ? null
              : (details) {
                  if (hole != null && hole.contains(details.localPosition)) {
                    controller.tapTarget();
                  } else {
                    scrimTap();
                  }
                },
          child: SizedBox.expand(child: painter),
        ),
      );
    }

    final cardBuilder = step?.cardBuilder ?? widget.cardBuilder;
    final showPointer = theme.pointer &&
        hole != null &&
        step?.placement != TourCardPlacement.center;

    return Stack(
      children: [
        Positioned.fill(child: scrim),
        if (step != null)
          Positioned.fill(
            child: CustomMultiChildLayout(
              delegate: _CalloutLayout(
                hole: hole,
                insets: insets,
                maxWidth: theme.cardMaxWidth,
                margin: theme.cardMargin,
                placement: step.placement,
                pointerSize: theme.pointerSize,
                pointerInset: theme.cardRadius,
                showPointer: showPointer,
              ),
              children: [
                LayoutId(
                  id: _CalloutLayout.card,
                  child: AnimatedSwitcher(
                    duration: reduce ? Duration.zero : theme.cardDuration,
                    child: Semantics(
                      key: ValueKey(controller.index),
                      container: true,
                      liveRegion: true,
                      child: _buildCard(
                        context,
                        step,
                        controller.index,
                        theme,
                        cardBuilder,
                      ),
                    ),
                  ),
                ),
                for (final up in [true, false])
                  LayoutId(
                    id: up ? _CalloutLayout.up : _CalloutLayout.down,
                    child: CustomPaint(
                      painter: _PointerPainter(
                        up: up,
                        fill: theme.effectiveCard(scheme),
                        border: theme.effectiveBorder(scheme),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  List<Widget> _absorbers(Size screen, Rect hole, VoidCallback onTap) {
    Widget block(Rect rect) => Positioned.fromRect(
          rect: rect,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: const SizedBox.expand(),
          ),
        );
    return [
      block(Rect.fromLTRB(0, 0, screen.width, hole.top)),
      block(Rect.fromLTRB(0, hole.bottom, screen.width, screen.height)),
      block(Rect.fromLTRB(0, hole.top, hole.left, hole.bottom)),
      block(Rect.fromLTRB(hole.right, hole.top, screen.width, hole.bottom)),
    ];
  }

  Widget _buildCard(
    BuildContext context,
    TourStep step,
    int index,
    TourTheme theme,
    TourCardBuilder? cardBuilder,
  ) {
    final controller = widget.controller;
    final data = TourCardData(
      step: step,
      index: index,
      count: controller.count,
      theme: theme,
      strings: widget.strings,
      options: widget.options,
      next: controller.next,
      back: controller.back,
      skip: controller.skip,
      dontShowAgain: controller.dontShowAgain,
      setDontShowAgain: controller.setDontShowAgain,
    );
    return cardBuilder?.call(context, data) ?? DefaultTourCard(data: data);
  }
}

class _CalloutLayout extends MultiChildLayoutDelegate {
  _CalloutLayout({
    required this.hole,
    required this.insets,
    required this.maxWidth,
    required this.margin,
    required this.placement,
    required this.pointerSize,
    required this.pointerInset,
    required this.showPointer,
  });

  static const card = 'card';
  static const up = 'up';
  static const down = 'down';

  final Rect? hole;
  final EdgeInsets insets;
  final double maxWidth;
  final double margin;
  final TourCardPlacement placement;
  final Size pointerSize;
  final double pointerInset;
  final bool showPointer;

  @override
  void performLayout(Size size) {
    final cardSize = layoutChild(
      card,
      BoxConstraints(
        maxWidth: math.min(maxWidth, size.width - margin * 2),
        maxHeight: math.max(0, size.height - insets.vertical - margin * 2),
      ),
    );
    final offset = _position(size, cardSize);
    positionChild(card, offset);
    final rect = offset & cardSize;
    final hole = this.hole;
    var upOffset = Offset.zero;
    var downOffset = Offset.zero;
    var upSize = Size.zero;
    var downSize = Size.zero;
    if (showPointer && hole != null) {
      final low = rect.left + pointerInset + pointerSize.width / 2;
      final high = rect.right - pointerInset - pointerSize.width / 2;
      final cx = low <= high ? hole.center.dx.clamp(low, high) : rect.center.dx;
      if (rect.top >= hole.bottom - 0.5) {
        upSize = pointerSize;
        upOffset = Offset(
            cx - pointerSize.width / 2, rect.top - pointerSize.height + 1);
      } else if (rect.bottom <= hole.top + 0.5) {
        downSize = pointerSize;
        downOffset = Offset(cx - pointerSize.width / 2, rect.bottom - 1);
      }
    }
    layoutChild(up, BoxConstraints.tight(upSize));
    positionChild(up, upOffset);
    layoutChild(down, BoxConstraints.tight(downSize));
    positionChild(down, downOffset);
  }

  Offset _position(Size size, Size childSize) {
    final x = (size.width - childSize.width) / 2;
    final hole = this.hole;
    if (hole == null || placement == TourCardPlacement.center) {
      return Offset(x, (size.height - childSize.height) / 2);
    }
    final gap = margin + (showPointer ? pointerSize.height : 0);
    final top = insets.top + margin;
    final bottom = size.height - insets.bottom - margin;
    final below = hole.bottom + gap;
    final above = hole.top - gap - childSize.height;
    final double y;
    switch (placement) {
      case TourCardPlacement.below:
        y = below;
      case TourCardPlacement.above:
        y = above;
      default:
        if (below + childSize.height <= bottom) {
          y = below;
        } else if (above >= top) {
          y = above;
        } else {
          y = bottom - childSize.height;
        }
    }
    final hx = (hole.center.dx - childSize.width / 2).clamp(
      margin,
      math.max(margin, size.width - childSize.width - margin),
    );
    return Offset(
      size.width >= 700 ? hx.toDouble() : x,
      y.clamp(top, math.max(top, bottom - childSize.height)),
    );
  }

  @override
  bool shouldRelayout(_CalloutLayout old) =>
      old.hole != hole ||
      old.insets != insets ||
      old.maxWidth != maxWidth ||
      old.margin != margin ||
      old.placement != placement ||
      old.pointerSize != pointerSize ||
      old.pointerInset != pointerInset ||
      old.showPointer != showPointer;
}

class _PointerPainter extends CustomPainter {
  const _PointerPainter({
    required this.up,
    required this.fill,
    required this.border,
  });

  final bool up;
  final Color fill;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final path = Path();
    if (up) {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height);
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0);
    }
    canvas.drawPath(
      Path.from(path)..close(),
      Paint()..color = fill,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_PointerPainter old) =>
      old.up != up || old.fill != fill || old.border != border;
}

class _ScrimPainter extends CustomPainter {
  _ScrimPainter({
    required this.hole,
    required this.shape,
    required this.scrim,
    required this.ring,
    required this.ringWidth,
    required this.glow,
    required this.pulse,
  }) : super(repaint: pulse);

  final Rect? hole;
  final TourShape shape;
  final Color scrim;
  final Color ring;
  final double ringWidth;
  final bool glow;
  final Animation<double>? pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final full = Path()..addRect(Offset.zero & size);
    final hole = this.hole;
    if (hole == null || hole.shortestSide < 1) {
      canvas.drawPath(full, Paint()..color = scrim);
      return;
    }
    final beat = pulse?.value ?? 0;
    final cutout = shape.pathFor(hole);
    canvas.drawPath(
      Path.combine(PathOperation.difference, full, cutout),
      Paint()..color = scrim,
    );
    if (glow) {
      canvas.drawPath(
        cutout,
        Paint()
          ..color = ring.withValues(alpha: 0.35 + 0.3 * beat)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6 + 6 * beat
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    if (ringWidth > 0) {
      canvas.drawPath(
        cutout,
        Paint()
          ..color = ring
          ..style = PaintingStyle.stroke
          ..strokeWidth = ringWidth + beat,
      );
    }
  }

  @override
  bool shouldRepaint(_ScrimPainter old) =>
      old.hole != hole ||
      old.shape != shape ||
      old.scrim != scrim ||
      old.ring != ring ||
      old.ringWidth != ringWidth ||
      old.glow != glow ||
      old.pulse != pulse;
}
