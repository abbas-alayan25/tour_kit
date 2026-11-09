import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tour_kit/tour_kit.dart';
import 'package:tour_kit_shared_preferences/tour_kit_shared_preferences.dart';

const autoplay = bool.fromEnvironment('AUTOPLAY');

late final TourStorage storage;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  storage = autoplay
      ? MemoryTourStorage()
      : await SharedPreferencesTourStorage.create();
  runApp(const DemoApp());
}

class Settings extends ChangeNotifier {
  bool dark = false;
  bool rtl = false;
  bool customCard = false;
  bool counter = false;
  bool pointer = true;
  bool pulse = true;
  TourScrimTap scrimTap = TourScrimTap.next;

  void update(void Function() change) {
    change();
    notifyListeners();
  }
}

final settings = Settings();

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: settings,
    builder: (context, _) => MaterialApp(
      title: 'tour_kit demo',
      debugShowCheckedModeBanner: false,
      themeMode: settings.dark ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      builder: (context, child) => Directionality(
        textDirection: settings.rtl ? TextDirection.rtl : TextDirection.ltr,
        child: child!,
      ),
      home: const Shell(),
    ),
  );
}

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  final scroll = ScrollController();
  Timer? _autoplay;

  @override
  void initState() {
    super.initState();
    if (autoplay) {
      _autoplay = Timer.periodic(
        const Duration(milliseconds: 3500),
        (_) => Tour.controller?.next(),
      );
    }
  }

  @override
  void dispose() {
    _autoplay?.cancel();
    scroll.dispose();
    super.dispose();
  }

  void setTab(int value) => setState(() => tab = value);

  TourTheme get tourTheme =>
      TourTheme(pointer: settings.pointer, pulse: settings.pulse);

  TourOptions get tourOptions => TourOptions(
    progress: settings.counter
        ? TourProgressStyle.counter
        : TourProgressStyle.dots,
    scrimTap: settings.scrimTap,
    offerDontShowAgain: true,
  );

  List<TourStep> get steps => [
    const TourStep(
      icon: Icons.waving_hand_rounded,
      title: 'Welcome to tour_kit',
      body:
          'A step without a target shows a centred card. '
          'Tap anywhere or use the buttons to continue.',
    ),
    TourStep(
      target: 'home-text',
      placement: TourCardPlacement.above,
      icon: Icons.widgets_rounded,
      title: 'Rich content',
      content: const Wrap(
        spacing: 8,
        children: [
          Chip(label: Text('Any widget')),
          Chip(label: Text('Card above')),
          Chip(label: Text('Saved once')),
        ],
      ),
      onEnter: (_) => setTab(0),
    ),
    TourStep(
      target: 'counter-button',
      interactive: true,
      tapTargetToContinue: true,
      icon: Icons.touch_app_rounded,
      title: 'Tap through',
      body:
          'This step is interactive: press the real button. It works, and the '
          'tour moves on.',
      onEnter: (_) => setTab(0),
    ),
    const TourStep(
      target: 'fab',
      shape: TourShape.circle(),
      icon: Icons.add_rounded,
      title: 'Circle cut-out',
      body: 'Shapes can be rect, rounded, circle or oval.',
    ),
    const TourStep(
      target: 'tab-list',
      shape: TourShape.oval(),
      icon: Icons.view_list_rounded,
      title: 'Oval cut-out',
      body: 'Next, the tour switches to this tab by itself.',
    ),
    TourStep(
      target: 'item-40',
      scroll: false,
      scrollController: scroll,
      scrollOffset: 40 * 72.0,
      icon: Icons.swipe_vertical_rounded,
      title: 'Lazy list item',
      body:
          'Item 40 was not built yet. The step switched the tab and jumped '
          'the list with scrollController and scrollOffset, then waited for '
          'the item to appear.',
      onEnter: (_) => setTab(1),
    ),
    TourStep(
      target: 'details-title',
      icon: Icons.open_in_new_rounded,
      title: 'Another screen',
      body:
          'The step opened a new screen and the tour followed it. Going '
          'forward or back closes it again.',
      onEnter: (context) {
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => const DetailsPage()));
      },
      onExit: (context) => Navigator.of(context).pop(),
    ),
    TourStep(
      target: 'theme-switch',
      icon: Icons.dark_mode_rounded,
      title: 'Tap the highlight',
      body: 'This step continues when you tap the highlighted switch.',
      tapTargetToContinue: true,
      onEnter: (_) => setTab(2),
      onTargetTap: (_) => settings.update(() => settings.dark = !settings.dark),
    ),
    TourStep(
      icon: Icons.timer_rounded,
      title: 'Driven from outside',
      body:
          'This step moves on by itself in three seconds, using '
          'Tour.controller?.next().',
      onEnter: (_) {
        if (!autoplay) {
          Timer(const Duration(seconds: 3), () => Tour.controller?.next());
        }
      },
    ),
    TourStep(
      target: 'restart',
      icon: Icons.replay_rounded,
      title: 'Run it again',
      body: 'Use this button to restart the tour any time.',
      onEnter: (_) => setTab(0),
    ),
  ];

  Future<void> run() => Tour.show(
    context,
    steps: steps,
    theme: tourTheme,
    options: tourOptions,
    cardBuilder: settings.customCard
        ? (context, data) => Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.step.title ?? '',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(data.step.body ?? ''),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('${data.index + 1}/${data.count}'),
                      const Spacer(),
                      TextButton(
                        onPressed: data.skip,
                        child: const Text('Close'),
                      ),
                      FilledButton(
                        onPressed: data.next,
                        child: Text(data.isLast ? 'Finish' : 'Go'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        : null,
  );

  @override
  Widget build(BuildContext context) => TourLauncher(
    tourId: 'demo',
    storage: storage,
    steps: steps,
    theme: tourTheme,
    options: tourOptions,
    markCompletedOnSkip: false,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('tour_kit demo'),
        actions: [
          TourTarget(
            id: 'restart',
            child: IconButton(
              tooltip: 'Start tour',
              onPressed: run,
              icon: const Icon(Icons.play_circle_rounded),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: tab,
        children: [
          const _Home(),
          _Items(controller: scroll),
          const _Options(),
        ],
      ),
      floatingActionButton: TourTarget(
        id: 'fab',
        child: FloatingActionButton(
          onPressed: () {},
          child: const Icon(Icons.add_rounded),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: setTab,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: TourTarget(
              id: 'tab-list',
              child: const Icon(Icons.view_list_rounded),
            ),
            label: 'List',
          ),
          const NavigationDestination(
            icon: Icon(Icons.tune_rounded),
            label: 'Options',
          ),
        ],
      ),
    ),
  );
}

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  int taps = 0;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TourTarget(
            id: 'home-text',
            child: Text(
              'The tour starts by itself the first time this screen opens '
              'and is remembered once you finish it, or tick "Don\'t show '
              'again".\n\nPress the play button above to run it again, or '
              'open the Options tab to try dark mode, right-to-left, a custom '
              'card and more.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 24),
          TourTarget(
            id: 'counter-button',
            child: FilledButton.icon(
              onPressed: () => setState(() => taps++),
              icon: const Icon(Icons.add_rounded),
              label: Text('Pressed $taps times'),
            ),
          ),
        ],
      ),
    ),
  );
}

class DetailsPage extends StatelessWidget {
  const DetailsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Details')),
    body: const Center(
      child: TourTarget(
        id: 'details-title',
        child: Text('A second screen', style: TextStyle(fontSize: 24)),
      ),
    ),
  );
}

class _Items extends StatelessWidget {
  const _Items({required this.controller});

  final ScrollController controller;

  @override
  Widget build(BuildContext context) => ListView.builder(
    controller: controller,
    itemCount: 100,
    itemBuilder: (context, i) => SizedBox(
      height: 72,
      child: TourTarget(
        id: 'item-$i',
        child: ListTile(
          leading: CircleAvatar(child: Text('$i')),
          title: Text('Item $i'),
          subtitle: const Text('Built lazily by ListView.builder'),
        ),
      ),
    ),
  );
}

class _Options extends StatelessWidget {
  const _Options();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: settings,
    builder: (context, _) => ListView(
      children: [
        TourTarget(
          id: 'theme-switch',
          child: SwitchListTile(
            title: const Text('Dark mode'),
            value: settings.dark,
            onChanged: (v) => settings.update(() => settings.dark = v),
          ),
        ),
        SwitchListTile(
          title: const Text('Right-to-left'),
          value: settings.rtl,
          onChanged: (v) => settings.update(() => settings.rtl = v),
        ),
        SwitchListTile(
          title: const Text('Custom card builder'),
          value: settings.customCard,
          onChanged: (v) => settings.update(() => settings.customCard = v),
        ),
        SwitchListTile(
          title: const Text('Pointer arrow on the card'),
          value: settings.pointer,
          onChanged: (v) => settings.update(() => settings.pointer = v),
        ),
        SwitchListTile(
          title: const Text('Pulsing outline'),
          value: settings.pulse,
          onChanged: (v) => settings.update(() => settings.pulse = v),
        ),
        SwitchListTile(
          title: const Text('Counter instead of dots'),
          value: settings.counter,
          onChanged: (v) => settings.update(() => settings.counter = v),
        ),
        ListTile(
          title: const Text('Forget that the tour was seen'),
          subtitle: const Text('It shows again on the next launch.'),
          trailing: FilledButton.tonal(
            onPressed: () async {
              await storage.reset('demo');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Restart the app to see it.')),
                );
              }
            },
            child: const Text('Reset'),
          ),
        ),
        ListTile(
          title: const Text('Tap on the dimmed area'),
          trailing: SegmentedButton<TourScrimTap>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: TourScrimTap.next, label: Text('Next')),
              ButtonSegment(value: TourScrimTap.skip, label: Text('Skip')),
              ButtonSegment(value: TourScrimTap.none, label: Text('None')),
            ],
            selected: {settings.scrimTap},
            onSelectionChanged: (v) =>
                settings.update(() => settings.scrimTap = v.first),
          ),
        ),
      ],
    ),
  );
}
