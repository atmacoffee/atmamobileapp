import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_surface.dart';

class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    this.title,
    this.leading,
    this.trailing,
    this.center,
    this.centerTitle = false,
  });

  final String? title;
  final Widget? leading;
  final Widget? trailing;
  final Widget? center;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: AppSurface(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        radius: 26,
        child: SizedBox(
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: leading ?? _titleText(),
              ),
              Center(
                child: center ?? (centerTitle ? _titleText() : const SizedBox()),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: trailing ?? const SizedBox(width: 40),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titleText() {
    final text = title;
    if (text == null || text.isEmpty) {
      return const SizedBox(width: 40);
    }

    return Text(
      text,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class AtmaHeaderLogo extends StatelessWidget {
  const AtmaHeaderLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/atma-ver_nobg.png',
      width: 52,
      height: 40,
      fit: BoxFit.contain,
    );
  }
}

class HeaderStatusPill extends StatelessWidget {
  const HeaderStatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
          ] else ...[
            Icon(Icons.circle, color: color, size: 8),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class HeaderIconButton extends StatelessWidget {
  const HeaderIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.badge,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          onPressed: onPressed,
          icon: Icon(icon, color: AppTheme.textPrimary),
        ),
        if (badge != null && badge!.isNotEmpty)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Text(
                badge!,
                style: const TextStyle(color: Colors.white, fontSize: 9),
              ),
            ),
          ),
      ],
    );
  }
}
