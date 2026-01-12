import 'package:flutter/material.dart';

class ProfileColorOption {
  final String label;
  final Color base;
  final Color shadow;
  const ProfileColorOption(this.label, this.base, this.shadow);
}

class SimpleColorOption {
  final String label;
  final Color color;
  const SimpleColorOption(this.label, this.color);
}

const profileColorOptions = <ProfileColorOption>[
  ProfileColorOption('White', Color(0xFFEDEFF2), Color(0xFFCCD2DA)),
  ProfileColorOption('Anthracite', Color(0xFF3C4047), Color(0xFF2F343A)),
  ProfileColorOption('Golden Oak', Color(0xFF704D27), Color(0xFF3D2712)),
];

const blindColorOptions = <SimpleColorOption>[
  SimpleColorOption('Grey', Color(0xFF737373)),
  SimpleColorOption('White', Color(0xFFEDEFF2)),
  SimpleColorOption('Anthracite', Color(0xFF303338)),
  SimpleColorOption('Golden Oak', Color(0xFF704D27)),
];

const glassColorOptions = <SimpleColorOption>[
  SimpleColorOption('Blue', Color(0xFFAEDCF2)),
  SimpleColorOption('White', Color(0xFFF7FAFC)),
  SimpleColorOption('Grey Blue', Color(0xFF9FB4C7)),
  SimpleColorOption('Anthracite', Color(0xFF303338)),
  SimpleColorOption('Golden Oak', Color(0xFF704D27)),
];

ProfileColorOption profileColorForIndex(int? index) {
  if (profileColorOptions.isEmpty) {
    return const ProfileColorOption('Default', Colors.white, Colors.black12);
  }
  final safeIndex = _clampIndex(index, profileColorOptions.length);
  return profileColorOptions[safeIndex];
}

ProfileColorOption profileColorForSelection({
  int? index,
  int? customColorValue,
}) {
  if (customColorValue != null) {
    final base = Color(customColorValue);
    final shadow = _darkenColor(base, 0.18);
    return ProfileColorOption('Custom', base, shadow);
  }
  return profileColorForIndex(index);
}

SimpleColorOption glassColorForIndex(int? index) {
  if (glassColorOptions.isEmpty) {
    return const SimpleColorOption('Default', Colors.white);
  }
  final safeIndex = _clampIndex(index, glassColorOptions.length);
  return glassColorOptions[safeIndex];
}

SimpleColorOption glassColorForSelection({
  int? index,
  int? customColorValue,
}) {
  if (customColorValue != null) {
    return SimpleColorOption('Custom', Color(customColorValue));
  }
  return glassColorForIndex(index);
}

SimpleColorOption blindColorForIndex(int? index) {
  if (blindColorOptions.isEmpty) {
    return const SimpleColorOption('Default', Colors.white);
  }
  final safeIndex = _clampIndex(index, blindColorOptions.length);
  return blindColorOptions[safeIndex];
}

int _clampIndex(int? index, int length) {
  if (length <= 0) {
    return 0;
  }
  final value = index ?? 0;
  if (value < 0) {
    return 0;
  }
  if (value >= length) {
    return length - 1;
  }
  return value;
}

Color _darkenColor(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
  return hsl.withLightness(lightness).toColor();
}
