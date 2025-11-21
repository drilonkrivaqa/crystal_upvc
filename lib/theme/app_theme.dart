import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static BorderRadius get radius => BorderRadius.circular(20);

  static ThemeData get light => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Roboto',
        textTheme: ThemeData.light().textTheme.apply(
              bodyColor: AppColors.primaryDark,
              displayColor: AppColors.primaryDark,
            ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.primaryDark,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: radius),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.highlight,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: radius),
            backgroundColor: AppColors.highlight,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            elevation: 0,
          ),
        ),
      );
}
