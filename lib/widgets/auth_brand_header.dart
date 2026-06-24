import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    super.key,
    this.imageSize = 96,
    this.gapAfterImage = 18,
  });

  final double imageSize;
  final double gapAfterImage;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: imageSize + 24,
          height: imageSize + 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.72),
            border: Border.all(color: AppTheme.border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F0A05),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: ClipOval(
              child: Image.asset(
                'assets/ATMA.jpeg',
                width: imageSize,
                height: imageSize,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        SizedBox(height: gapAfterImage),
      ],
    );
  }
}
