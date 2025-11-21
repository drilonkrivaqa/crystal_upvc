import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryLight,
            AppColors.background,
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -80,
            child: _AccentBlob(
              size: 260,
              color: AppColors.accent.withOpacity(0.55),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -60,
            child: _AccentBlob(
              size: 220,
              color: AppColors.highlight.withOpacity(0.4),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _AccentBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _AccentBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 40,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}
