import 'dart:async';

import 'package:flutter/widgets.dart';

import 'tour_card.dart';
import 'tour_controller.dart';
import 'tour_options.dart';
import 'tour_overlay.dart';
import 'tour_result.dart';
import 'tour_step.dart';
import 'tour_strings.dart';
import 'tour_theme.dart';

class _BackInterceptor implements PopEntry<Object?> {
  _BackInterceptor(this._onBack);

  final VoidCallback _onBack;

  @override
  final ValueNotifier<bool> canPopNotifier = ValueNotifier<bool>(false);

  @override
  void onPopInvoked(bool didPop) {}

  @override
  void onPopInvokedWithResult(bool didPop, Object? result) {
    if (!didPop) _onBack();
  }
}

class _Session {
  _Session(this.controller, this.raise);

  final TourController controller;
  final VoidCallback raise;
}

/// Entry point for showing a tour.
abstract final class Tour {
  static _Session? _session;

  /// Whether a tour is currently showing.
  static bool get isActive => _session != null;

  /// The controller of the tour that is showing, for driving it from outside
  /// (for example `Tour.controller?.next()`), or null.
  static TourController? get controller => _session?.controller;

  /// Moves the running tour's overlay above every other screen.
  ///
  /// Called automatically while a step waits for its target. Call it yourself
  /// if you push a screen from outside the tour while it is showing.
  static void bringToFront() => _session?.raise();

  /// Shows a tour above the current screen.
  ///
  /// Resolves with how it ended. Returns [TourResult.unavailable] at once when
  /// [steps] is empty, no overlay is available, or another tour is showing.
  ///
  /// The tour lives in the root overlay, not in a route. Taps reach the app
  /// through steps marked [TourStep.interactive], and a step's `onEnter` can
  /// navigate to another screen: the overlay stays on top while it waits for
  /// the new target.
  static Future<TourResult> show(
    BuildContext context, {
    required List<TourStep> steps,
    TourTheme theme = const TourTheme(),
    TourStrings strings = const TourStrings(),
    TourOptions options = const TourOptions(),
    TourCardBuilder? cardBuilder,
    TourStepChanged? onStepChanged,
  }) {
    if (isActive || steps.isEmpty) return Future.value(TourResult.unavailable);
    final overlay = Overlay.maybeOf(
      context,
      rootOverlay: options.rootNavigator,
    );
    if (overlay == null) return Future.value(TourResult.unavailable);

    final controller = TourController(
      steps: steps,
      onStepChanged: onStepChanged,
    );
    final completer = Completer<TourResult>();
    _BackInterceptor? back;
    ModalRoute<dynamic>? backRoute;
    var finished = false;
    var generation = 0;
    var fadedIn = false;
    var hostKey = GlobalKey();
    late OverlayEntry entry;
    late final _Session session;

    void close(bool overlayGone) {
      if (finished) return;
      finished = true;
      if (identical(_session, session)) _session = null;
      final result = controller.result ??
          TourResult(
            outcome: TourOutcome.skipped,
            lastIndex: controller.index,
            dontShowAgain: controller.dontShowAgain,
          );
      if (!overlayGone) {
        entry.remove();
        entry.dispose();
      }
      if (back != null) backRoute?.unregisterPopEntry(back!);
      back = null;
      backRoute = null;
      controller.dispose();
      completer.complete(result);
    }

    OverlayEntry buildEntry() {
      final mine = ++generation;
      hostKey = GlobalKey();
      return OverlayEntry(
        maintainState: true,
        builder: (context) => TourHost(
          key: hostKey,
          controller: controller,
          theme: theme,
          strings: strings,
          options: options,
          cardBuilder: cardBuilder,
          startVisible: fadedIn,
          onFadedIn: () => fadedIn = true,
          onClosed: (gone) {
            if (mine == generation) close(gone);
          },
        ),
      );
    }

    bool isOnTop() {
      final host = hostKey.currentContext;
      if (host == null) return true;
      Element? top;
      overlay.context.visitChildElements((theater) {
        theater.visitChildren((child) => top = child);
      });
      if (top == null) return true;
      var found = false;
      host.visitAncestorElements((ancestor) {
        if (identical(ancestor, top)) {
          found = true;
          return false;
        }
        return true;
      });
      return found;
    }

    void raise() {
      if (finished || !entry.mounted || isOnTop()) return;
      entry.remove();
      entry.dispose();
      entry = buildEntry();
      overlay.insert(entry);
    }

    session = _Session(controller, raise);
    entry = buildEntry();

    final route = ModalRoute.of(context);
    if (route != null) {
      back = _BackInterceptor(controller.skip);
      backRoute = route;
      route.registerPopEntry(back!);
    }

    controller.attach(
      context: context,
      space: () => overlay.context.findRenderObject(),
      raise: raise,
    );
    _session = session;
    overlay.insert(entry);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => controller.begin(options.initialIndex),
    );
    return completer.future;
  }
}
