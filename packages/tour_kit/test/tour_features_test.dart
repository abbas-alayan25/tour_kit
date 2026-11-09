import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_kit/tour_kit.dart';

Future<void> settle(WidgetTester t, [int frames = 20]) async {
  for (var i = 0; i < frames; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

Widget app({
  required Widget home,
  bool disableAnimations = false,
  EdgeInsets viewInsets = EdgeInsets.zero,
}) =>
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(
            disableAnimations: disableAnimations, viewInsets: viewInsets),
        child: child!,
      ),
      home: Scaffold(body: home),
    );

late BuildContext appContext;

Widget capture(Widget child) => Builder(
      builder: (context) {
        appContext = context;
        return child;
      },
    );

void main() {
  group('interactive steps', () {
    testWidgets('taps pass through to the real widget', (t) async {
      var presses = 0;
      var tapped = 0;
      await t.pumpWidget(
        app(
          home: capture(
            Center(
              child: TourTarget(
                id: 'button',
                child: ElevatedButton(
                  onPressed: () => presses++,
                  child: const Text('Press me'),
                ),
              ),
            ),
          ),
        ),
      );
      unawaited(
        Tour.show(
          appContext,
          steps: [
            TourStep(
              target: 'button',
              title: 'Try it',
              interactive: true,
              onTargetTap: (_) => tapped++,
            ),
          ],
        ),
      );
      await settle(t);
      expect(find.text('Try it'), findsOneWidget);
      await t.tap(find.text('Press me'));
      await settle(t, 3);
      expect(presses, 1);
      expect(tapped, 1);
    });

    testWidgets('a normal step blocks taps to the app', (t) async {
      var presses = 0;
      await t.pumpWidget(
        app(
          home: capture(
            Center(
              child: TourTarget(
                id: 'button',
                child: ElevatedButton(
                  onPressed: () => presses++,
                  child: const Text('Press me'),
                ),
              ),
            ),
          ),
        ),
      );
      unawaited(
        Tour.show(
          appContext,
          steps: const [TourStep(target: 'button', title: 'Look')],
          options: const TourOptions(scrimTap: TourScrimTap.none),
        ),
      );
      await settle(t);
      await t.tap(find.text('Press me'), warnIfMissed: false);
      await settle(t, 3);
      expect(presses, 0);
    });
  });

  group('cross-screen tours', () {
    testWidgets('a step can navigate and the tour stays on top', (t) async {
      await t.pumpWidget(
        app(
          home: capture(
            Column(
              children: const [
                TourTarget(id: 'first', child: Text('First screen')),
              ],
            ),
          ),
        ),
      );
      TourResult? result;
      unawaited(
        Tour.show(
          appContext,
          steps: [
            const TourStep(target: 'first', title: 'On the first screen'),
            TourStep(
              target: 'second',
              title: 'On the second screen',
              hookTimeout: const Duration(milliseconds: 200),
              onEnter: (context) => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const Scaffold(
                    body: Center(
                      child: TourTarget(
                        id: 'second',
                        child: Text('Second screen'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ).then((r) => result = r),
      );
      await settle(t);
      expect(find.text('On the first screen'), findsOneWidget);
      await t.tap(find.text('Next'));
      await settle(t);
      expect(find.text('Second screen'), findsOneWidget);
      expect(find.text('On the second screen'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.tap(find.text('Done'));
      await settle(t);
      expect(result?.outcome, TourOutcome.completed);
      expect(result?.lastIndex, 1);
    });
  });

  group('visibility', () {
    testWidgets('targets in a hidden IndexedStack tab are skipped', (t) async {
      await t.pumpWidget(
        app(
          home: capture(
            IndexedStack(
              index: 0,
              children: const [
                TourTarget(id: 'visible', child: Text('Shown tab')),
                TourTarget(id: 'hidden', child: Text('Hidden tab')),
              ],
            ),
          ),
        ),
      );
      unawaited(
        Tour.show(
          appContext,
          steps: const [
            TourStep(
              target: 'hidden',
              title: 'Hidden one',
              waitFor: Duration(milliseconds: 200),
            ),
            TourStep(target: 'visible', title: 'Visible one'),
          ],
        ),
      );
      await settle(t);
      expect(find.text('Hidden one'), findsNothing);
      expect(find.text('Visible one'), findsOneWidget);
    });
  });

  group('per-step overrides and control', () {
    testWidgets('a step can bring its own card', (t) async {
      await t.pumpWidget(
        app(
          home: capture(
            Column(
              children: const [
                TourTarget(id: 'a', child: Text('A')),
                TourTarget(id: 'b', child: Text('B')),
              ],
            ),
          ),
        ),
      );
      unawaited(
        Tour.show(
          appContext,
          steps: [
            TourStep(
              target: 'a',
              title: 'Special',
              cardBuilder: (context, data) =>
                  TextButton(onPressed: data.next, child: const Text('mine')),
            ),
            const TourStep(target: 'b', title: 'Plain'),
          ],
        ),
      );
      await settle(t);
      expect(find.text('mine'), findsOneWidget);
      expect(find.text('Special'), findsNothing);
      await t.tap(find.text('mine'));
      await settle(t);
      expect(find.text('Plain'), findsOneWidget);
    });

    testWidgets('Tour.controller drives the running tour from outside', (
      t,
    ) async {
      await t.pumpWidget(
        app(
          home: capture(
            Column(
              children: const [
                TourTarget(id: 'a', child: Text('A')),
                TourTarget(id: 'b', child: Text('B')),
              ],
            ),
          ),
        ),
      );
      expect(Tour.controller, isNull);
      unawaited(
        Tour.show(
          appContext,
          steps: const [
            TourStep(target: 'a', title: 'One'),
            TourStep(target: 'b', title: 'Two'),
          ],
        ),
      );
      await settle(t);
      expect(find.text('One'), findsOneWidget);
      unawaited(Tour.controller!.next());
      await settle(t);
      expect(find.text('Two'), findsOneWidget);
      unawaited(Tour.controller!.skip());
      await settle(t);
      expect(Tour.isActive, isFalse);
    });
  });

  group('result and "don\'t show again"', () {
    testWidgets('reports the last step and the checkbox', (t) async {
      await t.pumpWidget(
        app(
          home: capture(
            Column(
              children: const [
                TourTarget(id: 'a', child: Text('A')),
                TourTarget(id: 'b', child: Text('B')),
              ],
            ),
          ),
        ),
      );
      TourResult? result;
      unawaited(
        Tour.show(
          appContext,
          steps: const [
            TourStep(target: 'a', title: 'One'),
            TourStep(target: 'b', title: 'Two'),
          ],
          options: const TourOptions(offerDontShowAgain: true),
        ).then((r) => result = r),
      );
      await settle(t);
      await t.tap(find.text("Don't show again"));
      await settle(t, 3);
      await t.tap(find.text('Skip'));
      await settle(t);
      expect(result?.outcome, TourOutcome.skipped);
      expect(result?.lastIndex, 0);
      expect(result?.dontShowAgain, isTrue);
    });

    testWidgets('the launcher stores a skip only when asked or ticked', (
      t,
    ) async {
      final storage = MemoryTourStorage();
      Widget launcher() => app(
            home: TourLauncher(
              tourId: 'home',
              storage: storage,
              markCompletedOnSkip: false,
              delay: const Duration(milliseconds: 100),
              options: const TourOptions(offerDontShowAgain: true),
              steps: const [
                TourStep(target: 'a', title: 'One'),
                TourStep(target: 'a', title: 'Two'),
              ],
              child: const TourTarget(id: 'a', child: Text('A')),
            ),
          );
      await t.pumpWidget(launcher());
      await settle(t);
      await t.tap(find.text('Skip'));
      await settle(t);
      expect(await storage.isCompleted('home'), isFalse);
    });
  });

  group('navigation', () {
    testWidgets('does not make the app bar show a back arrow', (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              appContext = context;
              return Scaffold(
                appBar: AppBar(title: const Text('Home')),
                body: const TourTarget(id: 'a', child: Text('Target')),
              );
            },
          ),
        ),
      );
      expect(find.byType(BackButton), findsNothing);
      unawaited(
        Tour.show(
          appContext,
          steps: const [TourStep(target: 'a', title: 'Hello')],
        ),
      );
      await settle(t);
      expect(find.text('Hello'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(Navigator.of(appContext).canPop(), isFalse);
    });
  });

  group('appearance', () {
    testWidgets('pointer and pulse render without errors', (t) async {
      await t.pumpWidget(
        app(
          home: capture(
            const Align(
              alignment: Alignment.topCenter,
              child: TourTarget(id: 'a', child: Text('Target')),
            ),
          ),
        ),
      );
      unawaited(
        Tour.show(
          appContext,
          steps: const [TourStep(target: 'a', title: 'Pointing')],
          theme: const TourTheme(pointer: true, pulse: true),
        ),
      );
      await settle(t);
      expect(find.text('Pointing'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('works when the system asks to reduce motion', (t) async {
      await t.pumpWidget(
        app(
          disableAnimations: true,
          home: capture(
            const TourTarget(id: 'a', child: Text('Target')),
          ),
        ),
      );
      unawaited(
        Tour.show(
          appContext,
          steps: const [TourStep(target: 'a', title: 'Calm')],
          theme: const TourTheme(pulse: true),
        ),
      );
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('Calm'), findsOneWidget);
    });

    testWidgets('the card stays above the on-screen keyboard', (t) async {
      await t.pumpWidget(
        app(
          viewInsets: const EdgeInsets.only(bottom: 300),
          home: capture(
            const Align(
              alignment: Alignment(0, 0.2),
              child: TourTarget(id: 'a', child: Text('Target')),
            ),
          ),
        ),
      );
      unawaited(
        Tour.show(
          appContext,
          steps: const [
            TourStep(target: 'a', title: 'Above keyboard', body: 'Some text.'),
          ],
        ),
      );
      await settle(t);
      final bottom = t.getBottomLeft(find.text('Above keyboard')).dy;
      expect(bottom, lessThanOrEqualTo(600 - 300));
    });
  });
}
