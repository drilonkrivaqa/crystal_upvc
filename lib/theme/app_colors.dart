import 'package:flutter/material.dart';

class AppColors {
  static const MaterialColor primary = MaterialColor(
    0xFF1E7A74,
    <int, Color>{
      50: Color(0xFFE5F5F3),
      100: Color(0xFFBDE3DF),
      200: Color(0xFF92D1C9),
      300: Color(0xFF67BFB3),
      400: Color(0xFF46B1A2),
      500: Color(0xFF1E7A74),
      600: Color(0xFF1B6E69),
      700: Color(0xFF175E5A),
      800: Color(0xFF124D4A),
      900: Color(0xFF0C3836),
    },
  );

  static const Color background = Color(0xFFF6F8FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color accent = Color(0xFF77E7D5);
  static const Color highlight = Color(0xFF0F9FA1);
  static Color get primaryDark => const Color(0xFF0C3836);
  static Color get primaryLight => const Color(0xFFE9F7F5);
  static Color get grey300 => Colors.grey.shade300;
  static Color get grey400 => Colors.grey.shade400;
  static Color get mutedText => Colors.grey.shade700;
  static const Color delete = Colors.redAccent;
}
