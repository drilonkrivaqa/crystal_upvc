import 'package:flutter/material.dart';

import '../utils/company_settings.dart';

class CompanyLogo extends StatelessWidget {
  final CompanySettingsData company;
  final double width;

  const CompanyLogo({
    super.key,
    required this.company,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final logoBytes = company.logoBytes;
    if (logoBytes != null && logoBytes.isNotEmpty) {
      return Image.memory(
        logoBytes,
        width: width,
        fit: BoxFit.contain,
      );
    }
    return Image.asset(
      company.fallbackLogoAsset,
      width: width,
      fit: BoxFit.contain,
    );
  }
}
