import 'package:flutter/widgets.dart';

/// Scroll physics that keeps pull-to-refresh available on short lists without
/// visibly dragging the whole content down from the top edge.
class TopRefreshScrollPhysics extends ClampingScrollPhysics {
  const TopRefreshScrollPhysics({super.parent});

  @override
  TopRefreshScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return TopRefreshScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => true;
}
