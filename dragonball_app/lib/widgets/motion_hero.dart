import 'package:flutter/widgets.dart';

// LEARN (Hero + reduced motion): a Hero "flight" is an animation that Flutter
// runs during a route change, and it ignores the reduce-motion setting. The
// fix is to not be a Hero at all when motion is reduced. BOTH ends of a
// transition must use MotionHero: if only one end were a Hero, Flutter would
// simply play no flight, which is also fine, but keeping both consistent makes
// the behaviour easy to reason about.
class MotionHero extends StatelessWidget {
  const MotionHero({super.key, required this.tag, required this.child});

  final Object tag;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;

    return Hero(tag: tag, child: child);
  }
}