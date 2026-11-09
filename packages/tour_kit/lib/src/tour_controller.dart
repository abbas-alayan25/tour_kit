import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'tour_result.dart';
import 'tour_step.dart';
import 'tour_target.dart';

/// Called whenever a step is presented, with its [index] and the [step].
typedef TourStepChanged = void Function(int index, TourStep step);

/// Runs a tour: moves between steps, waits for targets, runs hooks and
/// measures the highlighted area.
///
/// Usually created for you by [Tour.show], which also exposes the running one
/// as [Tour.controller]. Use it directly only to build your own overlay.
class TourController extends ChangeNotifier with WidgetsBindingObserver {
  /// Creates a controller for [steps].
  TourController({
    required List<TourStep> steps,
    this.onStepChanged,
    this.pollInterval = const Duration(milliseconds: 50),
  }) : steps = List.unmodifiable(steps);

  /// The steps of the tour.
  final List<TourStep> steps;

  /// Called when a step is presented.
  final TourStepChanged? onStepChanged;

  /// How often to look for a target that has not appeared yet.
  final Duration pollInterval;

  int _index = -1;
  int _exited = -1;
  Rect? _hole;
  int _token = 0;
  bool _active = false;
  bool _dontShowAgain = false;
  bool _disposed = false;
  TourResult? _result;
  BuildContext? _context;
  RenderObject? Function()? _space;
  VoidCallback? _raise;

  /// The current step, or -1 before the first one is shown.
  int get index => _index;

  /// The number of steps.
  int get count => steps.length;

  /// The highlighted area in the overlay's coordinates, or null for a
  /// centred card.
  Rect? get hole => _hole;

  /// Whether the tour is running.
  bool get isActive => _active;

  /// The result, once the tour has ended.
  TourResult? get result => _result;

  /// How the tour ended, once it has.
  TourOutcome? get outcome => _result?.outcome;

  /// Whether the user ticked "don't show again".
  bool get dontShowAgain => _dontShowAgain;

  /// The step currently shown.
  TourStep? get step =>
      _index >= 0 && _index < steps.length ? steps[_index] : null;

  /// Whether the current step is the first.
  bool get isFirst => _index <= 0;

  /// Whether the current step is the last.
  bool get isLast => _index == steps.length - 1;

  /// Connects the controller to the overlay that shows it.
  ///
  /// [raise] moves the overlay above newly pushed screens.
  void attach({
    required BuildContext context,
    required RenderObject? Function() space,
    VoidCallback? raise,
  }) {
    _context = context;
    _space = space;
    _raise = raise;
  }

  /// Starts the tour at [initialIndex].
  Future<void> begin([int initialIndex = 0]) async {
    if (_active || steps.isEmpty) return;
    _active = true;
    WidgetsBinding.instance.addObserver(this);
    await _go(initialIndex.clamp(0, steps.length - 1), 1);
  }

  /// Goes to the next step, or finishes after the last one.
  Future<void> next() => _go(_index + 1, 1);

  /// Goes to the previous step.
  Future<void> back() =>
      _index <= 0 ? Future<void>.value() : _go(_index - 1, -1);

  /// Goes to the step at [index].
  Future<void> goTo(int index) => _go(index, index >= _index ? 1 : -1);

  /// Ends the tour with [TourOutcome.skipped].
  Future<void> skip() => _finish(TourOutcome.skipped);

  /// Ends the tour with [TourOutcome.completed].
  Future<void> finish() => _finish(TourOutcome.completed);

  /// Sets whether the user chose "don't show again".
  void setDontShowAgain(bool value) {
    if (_dontShowAgain == value) return;
    _dontShowAgain = value;
    notifyListeners();
  }

  /// Handles a tap inside the highlighted area.
  Future<void> tapTarget() async {
    final current = step;
    if (current == null) return;
    await _run(current.onTargetTap, current.hookTimeout);
    if (current.tapTargetToContinue) await next();
  }

  bool _alive(int token) => _active && token == _token;

  Future<void> _run(TourHook? hook, Duration timeout) async {
    final context = _context;
    if (hook == null || context == null) return;
    try {
      await Future<void>.sync(() => hook(context)).timeout(timeout);
    } on TimeoutException {
      return;
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'tour_kit',
          context: ErrorDescription('while running a tour step hook'),
        ),
      );
    }
  }

  BuildContext? _lookup(TourStep step) {
    final key = step.targetKey ??
        (step.target == null ? null : TourTarget.keyFor(step.target!));
    final context = key?.currentContext;
    return context != null && context.mounted ? context : null;
  }

  bool _isShown(BuildContext target) {
    var shown = true;
    Element? child = target is Element ? target : null;
    target.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is Offstage && widget.offstage) {
        shown = false;
        return false;
      }
      if (element is RenderObjectElement) {
        final render = element.renderObject;
        if (render is RenderIndexedStack) {
          final wanted = child?.renderObject;
          var position = 0;
          RenderBox? cursor = render.firstChild;
          while (cursor != null && cursor != wanted) {
            cursor = render.childAfter(cursor);
            position++;
          }
          if (cursor == null || position != render.index) {
            shown = false;
            return false;
          }
        }
      }
      child = element;
      return true;
    });
    return shown;
  }

  Future<BuildContext?> _awaitTarget(TourStep step, int token) async {
    final interval =
        pollInterval.inMicroseconds == 0 ? 1 : pollInterval.inMicroseconds;
    var attempts = (step.waitFor.inMicroseconds / interval).ceil();
    while (true) {
      final context = _lookup(step);
      if (context != null && context.mounted) {
        final box = context.findRenderObject();
        if (box is RenderBox &&
            box.attached &&
            box.hasSize &&
            _isShown(context)) {
          return context;
        }
      }
      if (!_alive(token) || attempts-- <= 0) return null;
      _raise?.call();
      await Future<void>.delayed(pollInterval);
    }
  }

  Future<void> _preScroll(TourStep step, int token) async {
    final scroller = step.scrollController;
    final offset = step.scrollOffset;
    if (scroller == null || offset == null) return;
    final interval =
        pollInterval.inMicroseconds == 0 ? 1 : pollInterval.inMicroseconds;
    var attempts = (step.waitFor.inMicroseconds / interval).ceil();
    while (!scroller.hasClients) {
      if (!_alive(token) || attempts-- <= 0) return;
      await Future<void>.delayed(pollInterval);
    }
    final position = scroller.position;
    scroller.jumpTo(
      offset.clamp(position.minScrollExtent, position.maxScrollExtent),
    );
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _scroll(TourStep step, BuildContext target) async {
    if (!step.scroll) return;
    try {
      final scroller = step.scrollTo;
      if (scroller != null) {
        await scroller(_context ?? target, target);
      } else {
        await Scrollable.ensureVisible(
          target,
          alignment: step.scrollAlignment,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
    } catch (_) {}
  }

  Rect? _measure(BuildContext target) {
    if (!target.mounted) return null;
    final box = target.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    final space = _space?.call();
    return MatrixUtils.transformRect(
      box.getTransformTo(space is RenderBox ? space : null),
      Offset.zero & box.size,
    );
  }

  Future<void> _go(int target, int direction) async {
    if (!_active) return;
    final token = ++_token;
    var i = target;
    var dir = direction;
    final previous = step;
    if (previous != null) {
      _exited = _index;
      await _run(previous.onExit, previous.hookTimeout);
      if (!_alive(token)) return;
    }
    while (true) {
      if (i >= steps.length) {
        await _finish(TourOutcome.completed);
        return;
      }
      if (i < 0) {
        i = 0;
        dir = 1;
      }
      final current = steps[i];
      await _run(current.onEnter, current.hookTimeout);
      if (!_alive(token)) return;
      if (!current.hasTarget) {
        _present(i, null);
        return;
      }
      await _preScroll(current, token);
      if (!_alive(token)) return;
      final context = await _awaitTarget(current, token);
      if (!_alive(token)) return;
      if (context == null) {
        if (current.skipIfMissing) {
          await _run(current.onExit, current.hookTimeout);
          if (!_alive(token)) return;
          i += dir;
          continue;
        }
        _present(i, null);
        return;
      }
      if (!context.mounted) {
        i += dir;
        continue;
      }
      await _scroll(current, context);
      if (!_alive(token)) return;
      await WidgetsBinding.instance.endOfFrame;
      if (!_alive(token)) return;
      if (!context.mounted) {
        i += dir;
        continue;
      }
      final rect = _measure(context);
      if (rect == null) {
        i += dir;
        continue;
      }
      _present(i, rect);
      return;
    }
  }

  void _present(int index, Rect? hole) {
    _index = index;
    _exited = -1;
    _hole = hole;
    _raise?.call();
    if (_disposed) return;
    notifyListeners();
    onStepChanged?.call(index, steps[index]);
  }

  Future<void> _finish(TourOutcome outcome) async {
    if (!_active) return;
    final leaving = step;
    final last = _index;
    _active = false;
    _token++;
    WidgetsBinding.instance.removeObserver(this);
    if (leaving != null && _exited != _index) {
      await _run(leaving.onExit, leaving.hookTimeout);
    }
    _result = TourResult(
      outcome: outcome,
      lastIndex: last,
      dontShowAgain: _dontShowAgain,
    );
    if (!_disposed) notifyListeners();
  }

  @override
  void didChangeMetrics() {
    if (!_active || _hole == null) return;
    final i = _index;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_active || i != _index) return;
      final context = _lookup(steps[i]);
      if (context == null) return;
      final rect = _measure(context);
      if (rect == null) return;
      _hole = rect;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _active = false;
    _token++;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
