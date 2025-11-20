import 'package:flutter/material.dart';

class AppColors {
  static const MaterialColor primary = MaterialColor(
    0xFF1F6C8F,
    <int, Color>{
      50: Color(0xFFE6F0F6),
      100: Color(0xFFC1D9E7),
      200: Color(0xFF99C0D7),
      300: Color(0xFF71A6C7),
      400: Color(0xFF5291BA),
      500: Color(0xFF347CAC),
      600: Color(0xFF2D6F9A),
      700: Color(0xFF265E82),
      800: Color(0xFF1F4C69),
      900: Color(0xFF16364A),
    },
  );

  static const Color background = Color(0xFFF4F6FB);
  static Color get primaryDark => const Color(0xFF16364A);
  static Color get primaryLight => const Color(0xFFE3EDF7);
  static const Color accent = Color(0xFF8AE1CF);
  static const Color surface = Color(0xFFFBFCFF);
  static const Color muted = Color(0xFF8A92A6);
  static Color get grey300 => Colors.grey.shade300;
  static Color get grey400 => Colors.grey.shade400;
  static const Color delete = Color(0xFFE85B81);
}
