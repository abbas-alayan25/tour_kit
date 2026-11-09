import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tour_kit/tour_kit.dart';

Future<void> settle(WidgetTester t, [int frames = 20]) async {
  for (var i = 0; i < frames; i++) {
    await t.pump(const Duration(milliseconds: 100));
  }
}

class Host extends StatelessWidget {
  const Host({
    super.key,
    required this.steps,
    this.options = const TourOptions(),
    this.cardBuilder,
    this.onOutcome,
    this.textDirection = TextDirection.ltr,
    this.body,
  });

  final List<TourStep> steps;
  final TourOptions options;
  final TourCardBuilder? cardBuilder;
  final ValueChanged<TourOutcome>? onOutcome;
  final TextDirection textDirection;
  final Widget? body;

  @override
  Widget build(BuildContext context) => MaterialApp(
        builder: (context, child) =>
            Directionality(textDirection: textDirection, child: child!),
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  key: const Key('start'),
                  onPressed: () async {
                    final outcome = await Tour.show(
                      context,
                      steps: steps,
                      options: options,
                      cardBuilder: cardBuilder,
                    );
                    onOutcome?.call(outcome.outcome);
                  },
                  child: const Text('start'),
                ),
                Expanded(
                  child: body ??
                      Column(
                        children: const [
                          TourTarget(id: 'a', child: Text('Target A')),
                          TourTarget(id: 'b', child: Text('Target B')),
                        ],
                      ),
                ),
              ],
            ),
          ),
        ),
      );
}

Future<void> start(WidgetTester t) async {
  await t.tap(find.byKey(const Key('start')));
  await settle(t);
}

void main() {
  group('TourShape', () {
    test('paths cover the hole', () {
      const hole = Rect.fromLTWH(10, 20, 100, 40);
      for (final shape in [
        const TourShape.rect(),
        const TourShape.rounded(),
        const TourShape.oval(),
      ]) {
        final bounds = shape.pathFor(hole).getBounds();
        expect(bounds.width, closeTo(100, 0.01));
        expect(bounds.height, closeTo(40, 0.01));
      }
      final circle = const TourShape.circle().pathFor(hole).getBounds();
      expect(circle.width, closeTo(100, 0.01));
      expect(circle.height, closeTo(100, 0.01));
    });
  });

  group('MemoryTourStorage', () {
    test('marks and resets', () async {
      final storage = MemoryTourStorage();
      expect(await storage.isCompleted('a'), isFalse);
      await storage.markCompleted('a');
      await storage.markCompleted('b');
      expect(await storage.isCompleted('a'), isTrue);
      await storage.reset('a');
      expect(await storage.isCompleted('a'), isFalse);
      await storage.reset();
      expect(await storage.isCompleted('b'), isFalse);
    });
  });

  group('Tour', () {
    testWidgets('walks through the steps and completes', (t) async {
      TourOutcome? outcome;
      await t.pumpWidget(
        Host(
          onOutcome: (o) => outcome = o,
          steps: const [
            TourStep(target: 'a', title: 'First', body: 'About A'),
            TourStep(target: 'b', title: 'Second', body: 'About B'),
          ],
        ),
      );
      await start(t);
      expect(find.text('First'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      await t.tap(find.text('Next'));
      await settle(t);
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Skip'), findsNothing);

      await t.tap(find.byIcon(Icons.arrow_back_rounded));
      await settle(t);
      expect(find.text('First'), findsOneWidget);

      await t.tap(find.text('Next'));
      await settle(t);
      await t.tap(find.text('Done'));
      await settle(t);
      expect(outcome, TourOutcome.completed);
      expect(find.text('Second'), findsNothing);
    });

    testWidgets('skip ends with the skipped outcome', (t) async {
      TourOutcome? outcome;
      await t.pumpWidget(
        Host(
          onOutcome: (o) => outcome = o,
          steps: const [
            TourStep(target: 'a', title: 'First'),
            TourStep(target: 'b', title: 'Second'),
          ],
        ),
      );
      await start(t);
      await t.tap(find.text('Skip'));
      await settle(t);
      expect(outcome, TourOutcome.skipped);
    });

    testWidgets('missing targets are skipped unless told otherwise', (t) async {
      await t.pumpWidget(
        const Host(
          steps: [
            TourStep(
              target: 'ghost',
              title: 'Ghost',
              waitFor: Duration(milliseconds: 200),
            ),
            TourStep(target: 'a', title: 'Real'),
          ],
        ),
      );
      await start(t);
      expect(find.text('Ghost'), findsNothing);
      expect(find.text('Real'), findsOneWidget);

      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(
        const Host(
          steps: [
            TourStep(
              target: 'ghost',
              title: 'Ghost',
              skipIfMissing: false,
              waitFor: Duration(milliseconds: 200),
            ),
          ],
        ),
      );
      await start(t);
      expect(find.text('Ghost'), findsOneWidget);
    });

    testWidgets('waits for a target that appears after onEnter (tabs)', (
      t,
    ) async {
      final tab = ValueNotifier<int>(0);
      final log = <String>[];
      await t.pumpWidget(
        Host(
          steps: [
            const TourStep(target: 'a', title: 'On first tab'),
            TourStep(
              target: 'late',
              title: 'On second tab',
              onEnter: (_) async {
                log.add('enter');
                tab.value = 1;
              },
              onExit: (_) => log.add('exit'),
            ),
          ],
          body: ValueListenableBuilder<int>(
            valueListenable: tab,
            builder: (context, index, _) => index == 0
                ? const TourTarget(id: 'a', child: Text('Tab one'))
                : FutureBuilder<void>(
                    future: Future<void>.delayed(
                      const Duration(milliseconds: 300),
                    ),
                    builder: (context, snapshot) => snapshot.connectionState ==
                            ConnectionState.done
                        ? const TourTarget(id: 'late', child: Text('Tab two'))
                        : const SizedBox(),
                  ),
          ),
        ),
      );
      await start(t);
      expect(find.text('On first tab'), findsOneWidget);
      await t.tap(find.text('Next'));
      await settle(t);
      expect(find.text('On second tab'), findsOneWidget);
      expect(log, ['enter']);
      await t.tap(find.text('Done'));
      await settle(t);
      expect(log, ['enter', 'exit']);
    });

    testWidgets('scrolls an off-screen target into view', (t) async {
      await t.pumpWidget(
        Host(
          steps: const [TourStep(target: 'far', title: 'Far away')],
          body: SingleChildScrollView(
            child: Column(
              children: [
                for (var i = 0; i < 40; i++)
                  SizedBox(height: 80, child: Text('$i')),
                const TourTarget(
                  id: 'far',
                  child: SizedBox(height: 60, child: Text('Far target')),
                ),
                const SizedBox(height: 1200),
              ],
            ),
          ),
        ),
      );
      await start(t);
      expect(find.text('Far away'), findsOneWidget);
      final top = t.getTopLeft(find.text('Far target')).dy;
      expect(top, greaterThan(0));
      expect(
        top,
        lessThan(t.view.physicalSize.height / t.view.devicePixelRatio),
      );
    });

    testWidgets('an onEnter scroll builds a lazy list item, then finds it', (
      t,
    ) async {
      final scroll = ScrollController();
      await t.pumpWidget(
        Host(
          steps: [
            TourStep(
              target: 'item-60',
              title: 'Lazy item',
              scroll: false,
              onEnter: (_) => scroll.jumpTo(60 * 80.0),
            ),
          ],
          body: ListView.builder(
            controller: scroll,
            itemCount: 100,
            itemBuilder: (context, i) => SizedBox(
              height: 80,
              child: TourTarget(id: 'item-$i', child: Text('Item $i')),
            ),
          ),
        ),
      );
      await start(t);
      expect(find.text('Lazy item'), findsOneWidget);
    });

    testWidgets('scrollController and scrollOffset reach a lazy item', (
      t,
    ) async {
      final scroll = ScrollController();
      await t.pumpWidget(
        Host(
          steps: [
            TourStep(
              target: 'item-70',
              title: 'Jumped',
              scrollController: scroll,
              scrollOffset: 70 * 80.0,
            ),
          ],
          body: ListView.builder(
            controller: scroll,
            itemCount: 100,
            itemBuilder: (context, i) => SizedBox(
              height: 80,
              child: TourTarget(id: 'item-$i', child: Text('Item $i')),
            ),
          ),
        ),
      );
      await start(t);
      expect(find.text('Jumped'), findsOneWidget);
    });

    testWidgets('tapping the highlighted target can continue the tour', (
      t,
    ) async {
      var tapped = 0;
      await t.pumpWidget(
        Host(
          options: const TourOptions(scrimTap: TourScrimTap.none),
          steps: [
            TourStep(
              target: 'a',
              title: 'Tap me',
              tapTargetToContinue: true,
              onTargetTap: (_) => tapped++,
            ),
            const TourStep(target: 'b', title: 'Then this'),
          ],
        ),
      );
      await start(t);
      await t.tapAt(const Offset(400, 600));
      await settle(t);
      expect(find.text('Tap me'), findsOneWidget);
      await t.tap(find.text('Target A'), warnIfMissed: false);
      await settle(t);
      expect(tapped, 1);
      expect(find.text('Then this'), findsOneWidget);
    });

    testWidgets('the system back button skips the tour', (t) async {
      TourOutcome? outcome;
      await t.pumpWidget(
        Host(
          onOutcome: (o) => outcome = o,
          steps: const [TourStep(target: 'a', title: 'First')],
        ),
      );
      await start(t);
      await t.binding.handlePopRoute();
      await settle(t);
      expect(outcome, TourOutcome.skipped);
    });

    testWidgets('a custom card builder replaces the default card', (t) async {
      await t.pumpWidget(
        Host(
          cardBuilder: (context, data) => TextButton(
            onPressed: data.next,
            child: Text('custom ${data.index + 1}/${data.count}'),
          ),
          steps: const [
            TourStep(target: 'a', title: 'First'),
            TourStep(target: 'b', title: 'Second'),
          ],
        ),
      );
      await start(t);
      expect(find.text('custom 1/2'), findsOneWidget);
      expect(find.text('First'), findsNothing);
      await t.tap(find.text('custom 1/2'));
      await settle(t);
      expect(find.text('custom 2/2'), findsOneWidget);
    });

    testWidgets('lays out in right-to-left', (t) async {
      await t.pumpWidget(
        const Host(
          textDirection: TextDirection.rtl,
          steps: [
            TourStep(target: 'a', title: 'عنوان', body: 'نص الشرح'),
            TourStep(target: 'b', title: 'الثاني'),
          ],
        ),
      );
      await start(t);
      expect(find.text('عنوان'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('reports step changes and ignores a second concurrent tour', (
      t,
    ) async {
      final seen = <int>[];
      late BuildContext captured;
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              captured = context;
              return const TourTarget(id: 'a', child: Text('A'));
            },
          ),
        ),
      );
      unawaited(
        Tour.show(
          captured,
          steps: const [TourStep(target: 'a', title: 'One')],
          onStepChanged: (i, _) => seen.add(i),
        ),
      );
      await settle(t);
      expect(seen, [0]);
      expect(Tour.isActive, isTrue);
      final second = await Tour.show(
        captured,
        steps: const [TourStep(target: 'a', title: 'Two')],
      );
      expect(second.outcome, TourOutcome.unavailable);
      await t.tap(find.text('Done'));
      await settle(t);
      expect(Tour.isActive, isFalse);
    });
  });

  group('TourLauncher', () {
    Widget app(TourStorage storage, {bool enabled = true}) => MaterialApp(
          home: Scaffold(
            body: TourLauncher(
              tourId: 'home',
              storage: storage,
              enabled: enabled,
              delay: const Duration(milliseconds: 100),
              steps: const [TourStep(target: 'a', title: 'Welcome')],
              child: const TourTarget(id: 'a', child: Text('Home')),
            ),
          ),
        );

    testWidgets('shows once and remembers it', (t) async {
      final storage = MemoryTourStorage();
      await t.pumpWidget(app(storage));
      await settle(t);
      expect(find.text('Welcome'), findsOneWidget);
      await t.tap(find.text('Done'));
      await settle(t);
      expect(await storage.isCompleted('home'), isTrue);

      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(app(storage));
      await settle(t);
      expect(find.text('Welcome'), findsNothing);
    });

    testWidgets('does nothing while disabled', (t) async {
      await t.pumpWidget(app(MemoryTourStorage(), enabled: false));
      await settle(t);
      expect(find.text('Welcome'), findsNothing);
    });
  });
}
