## 0.1.0

* Spotlight tours with scrolling, hooks (`onEnter`/`onExit`) and waiting for late targets (tabs).
* Cross-screen tours: the overlay lives in the root overlay and stays above pushed screens.
* Interactive steps: taps inside the highlight reach the real widget.
* External control through `Tour.controller`, and a full `TourResult` (outcome, last step, don't show again).
* Per-step theme and card builder, callout pointer, pulsing outline, and a "don't show again" option.
* Lazy list support with `scrollController` and `scrollOffset`.
* Theming, localisation, custom cards, shapes, keyboard and back-button handling, right-to-left layout.
* Respects reduce-motion and the on-screen keyboard; ignores targets in hidden tabs.
* `TourLauncher` shows a tour once through a `TourStorage`.
