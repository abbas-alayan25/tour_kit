/// Remembers which tours the user has already seen.
///
/// Implement this to persist the state in your own storage, or use
/// [MemoryTourStorage] for tests and demos.
abstract interface class TourStorage {
  /// Whether the tour [tourId] was already shown.
  Future<bool> isCompleted(String tourId);

  /// Records that the tour [tourId] was shown.
  Future<void> markCompleted(String tourId);

  /// Forgets one tour, or every tour when [tourId] is null.
  Future<void> reset([String? tourId]);
}

/// A [TourStorage] that keeps its state in memory only.
class MemoryTourStorage implements TourStorage {
  /// Creates a storage, optionally starting with some tours already [completed].
  MemoryTourStorage([Iterable<String> completed = const []])
      : _completed = {...completed};

  final Set<String> _completed;

  @override
  Future<bool> isCompleted(String tourId) async => _completed.contains(tourId);

  @override
  Future<void> markCompleted(String tourId) async => _completed.add(tourId);

  @override
  Future<void> reset([String? tourId]) async {
    if (tourId == null) {
      _completed.clear();
    } else {
      _completed.remove(tourId);
    }
  }
}
