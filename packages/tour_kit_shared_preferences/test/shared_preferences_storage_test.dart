import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tour_kit_shared_preferences/tour_kit_shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('remembers completed tours across instances', () async {
    final first = await SharedPreferencesTourStorage.create();
    expect(await first.isCompleted('home'), isFalse);
    await first.markCompleted('home');
    await first.markCompleted('settings');

    final second = await SharedPreferencesTourStorage.create();
    expect(await second.isCompleted('home'), isTrue);
    expect(await second.isCompleted('settings'), isTrue);
    expect(await second.isCompleted('other'), isFalse);
  });

  test('reset forgets one tour or all of them', () async {
    final storage = await SharedPreferencesTourStorage.create();
    await storage.markCompleted('a');
    await storage.markCompleted('b');
    await storage.reset('a');
    expect(await storage.isCompleted('a'), isFalse);
    expect(await storage.isCompleted('b'), isTrue);
    await storage.reset();
    expect(await storage.isCompleted('b'), isFalse);
  });

  test('a custom key keeps separate state', () async {
    final one = await SharedPreferencesTourStorage.create(key: 'one');
    final two = await SharedPreferencesTourStorage.create(key: 'two');
    await one.markCompleted('home');
    expect(await two.isCompleted('home'), isFalse);
  });
}
