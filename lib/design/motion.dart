import 'package:flutter/material.dart';

/// Purposeful motion constants — curves and durations.
class AppMotion {
  AppMotion._();

  // Durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration dramatic = Duration(milliseconds: 800);
  static const Duration typewriter = Duration(milliseconds: 40);

  // Curves
  static const Curve emphasizedDecelerate = Curves.easeOutCubic;
  static const Curve emphasizedAccelerate = Curves.easeInCubic;
  static const Curve standard = Curves.easeInOut;
  static const Curve bounce = Curves.elasticOut;
  static const Curve smooth = Curves.easeOutQuart;

  /// Page transition for push navigation.
  static Widget buildPageTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: emphasizedDecelerate),
      child: SlideTransition(
        position:
            Tween<Offset>(
              begin: const Offset(0.0, 0.05),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: emphasizedDecelerate),
            ),
        child: child,
      ),
    );
  }
}
