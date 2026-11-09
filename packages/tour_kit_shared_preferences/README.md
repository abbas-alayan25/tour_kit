# tour_kit_shared_preferences

A `TourStorage` for [`tour_kit`](../tour_kit) that remembers finished tours with `shared_preferences`.

```dart
final storage = await SharedPreferencesTourStorage.create();

TourLauncher(
  tourId: 'home',
  storage: storage,
  steps: steps,
  child: const HomeScreen(),
)
```

Call `storage.reset()` to show every tour again, or `storage.reset('home')` for one.
