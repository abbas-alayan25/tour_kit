/// A `tour_kit` storage backed by `shared_preferences`.
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'package:tour_kit/tour_kit.dart';

/// A [TourStorage] that saves the ids of finished tours with
/// `shared_preferences`, so each tour shows once per installation.
class SharedPreferencesTourStorage implements TourStorage {
  /// Creates a storage on top of an already opened [prefs].
  SharedPreferencesTourStorage(this._prefs, {this.key = defaultKey});

  /// The preference key used when none is given.
  static const defaultKey = 'tour_kit.completed';

  /// Opens `SharedPreferences` and creates a storage on it.
  static Future<SharedPreferencesTourStorage> create({
    String key = defaultKey,
  }) async => SharedPreferencesTourStorage(
    await SharedPreferences.getInstance(),
    key: key,
  );

  final SharedPreferences _prefs;

  /// The preference key the finished tour ids are stored under.
  final String key;

  Set<String> get _completed => (_prefs.getStringList(key) ?? const []).toSet();

  @override
  Future<bool> isCompleted(String tourId) async => _completed.contains(tourId);

  @override
  Future<void> markCompleted(String tourId) async {
    await _prefs.setStringList(key, {..._completed, tourId}.toList());
  }

  @override
  Future<void> reset([String? tourId]) async {
    if (tourId == null) {
      await _prefs.remove(key);
    } else {
      await _prefs.setStringList(key, (_completed..remove(tourId)).toList());
    }
  }
}
