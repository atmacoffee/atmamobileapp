import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_surface.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.maxWidth = 420,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE7D6BF),
              Color(0xFFF5EFE4),
              Color(0xFFE4ECDD),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: AppSurface(
                  padding: const EdgeInsets.all(28),
                  backgroundColor: AppTheme.surface.withValues(alpha: 0.92),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
