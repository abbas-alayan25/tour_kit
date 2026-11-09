import 'package:flutter/widgets.dart';

/// Marks a widget so a [TourStep] can highlight it by [id].
///
/// Wrapping adds no visual change. A null [id] disables the marker.
class TourTarget extends StatelessWidget {
  /// Creates a marker around [child].
  const TourTarget({super.key, required this.id, required this.child});

  /// The name a step uses in [TourStep.target]. Must be unique on screen.
  final String? id;

  /// The widget to highlight.
  final Widget child;

  static final Map<String, Object> _ids = {};

  /// The key a [TourTarget] with this [id] uses, so other code can look it up.
  static GlobalKey keyFor(String id) =>
      GlobalObjectKey(_ids.putIfAbsent(id, () => _TourTargetId(id)));

  @override
  Widget build(BuildContext context) {
    final id = this.id;
    return id == null ? child : KeyedSubtree(key: keyFor(id), child: child);
  }
}

class _TourTargetId {
  const _TourTargetId(this.id);

  final String id;

  @override
  String toString() => 'TourTarget($id)';
}
