import 'package:flutter/material.dart';

// LEARN (theming / design tokens): instead of typing 12, 16, 20 everywhere,
// every spacing, radius and duration lives here. Change one number and the
// whole app follows. `abstract final class` = a namespace that can never be
// instantiated or subclassed (Dart 3 class modifier).

/// 4-point grid. x3 = 12px, x4 = 16px ...
abstract final class AppSpace {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
}

/// Three radii only: small (chips/bars), medium (controls), large (cards).
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;

  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
}

/// Animation durations + one shared curve, so motion feels consistent.
///
/// LEARN (one place decides about motion): most Flutter animation widgets
/// (AnimatedSize, AnimatedSwitcher, AnimatedScale, PageController.animateToPage)
/// do NOT look at the "reduce motion" setting by themselves. Every call site
/// has to ask. Instead of each one repeating the MediaQuery check, they all go
/// through [resolve]: if motion is reduced it returns Duration.zero, which
/// makes an implicit animation jump straight to its end value.
///
/// MediaQuery.disableAnimations is true when EITHER the Android system setting
/// ("Remove animations") is on OR the in-app toggle is on (main.dart merges the
/// in-app toggle into MediaQuery).
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration base = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 450);
  static const Curve curve = Curves.easeOutCubic;

  static bool isReduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// `duration` normally, Duration.zero when motion is reduced.
  static Duration resolve(BuildContext context, Duration duration) =>
      isReduced(context) ? Duration.zero : duration;
}

/// LEARN (responsive layout): width -> number of grid columns, plus a
/// maximum content width so web / tablet layouts do not stretch forever.
abstract final class Breakpoints {
  static const double medium = 600;
  static const double large = 900;
  static const double xl = 1200;
  static const double maxContent = 1100;

  static int gridColumns(double width) {
    if (width < medium) return 2;
    if (width < large) return 3;
    if (width < xl) return 4;
    return 5;
  }
}