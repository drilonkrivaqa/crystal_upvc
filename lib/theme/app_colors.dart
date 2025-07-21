import 'package:flutter/material.dart';

class AppColors {
  static const MaterialColor primary = MaterialColor(
    0xFF3D7774,
    <int, Color>{
      50: Color(0xFFE3EEED),
      100: Color(0xFFB9D3D1),
      200: Color(0xFF8CB6B3),
      300: Color(0xFF5F9894),
      400: Color(0xFF3D7774),
      500: Color(0xFF326562),
      600: Color(0xFF285352),
      700: Color(0xFF1E4241),
      800: Color(0xFF153130),
      900: Color(0xFF0B2020),
    },
  );

  static const Color background = Color(0xFFF1F7F6);
  static Color get primaryDark => const Color(0xFF1E4241);
  static Color get primaryLight => const Color(0xFFB9D3D1);
  static const Color accent = Color(0xFF85A8A6);
  static Color get grey300 => Colors.grey.shade300;
  static Color get grey400 => Colors.grey.shade400;
  static Color get lightGreen300 => const Color(0xFFA8D5BB); // soft complementary
  static const Color delete = Colors.redAccent;
}
