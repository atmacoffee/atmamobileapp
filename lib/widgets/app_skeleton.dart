import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_theme.dart';

class AppSkeletonCard extends StatelessWidget {
  final double height;
  final double? width;
  final double radius;

  const AppSkeletonCard({
    super.key,
    this.height = 100,
    this.width,
    this.radius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppTheme.border.withValues(alpha: 0.4),
      highlightColor: AppTheme.surfaceMuted,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: const [
        SizedBox(height: 10),
        AppSkeletonCard(height: 60, radius: 18),
        SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: AppSkeletonCard(height: 90, radius: 22)),
            SizedBox(width: 10),
            Expanded(child: AppSkeletonCard(height: 90, radius: 22)),
          ],
        ),
        SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: AppSkeletonCard(height: 90, radius: 22)),
            SizedBox(width: 10),
            Expanded(child: AppSkeletonCard(height: 90, radius: 22)),
          ],
        ),
        SizedBox(height: 12),
        AppSkeletonCard(height: 80, radius: 24),
        SizedBox(height: 20),
        AppSkeletonCard(height: 80, radius: 24),
        SizedBox(height: 20),
        AppSkeletonCard(height: 280, radius: 24),
      ],
    );
  }
}
