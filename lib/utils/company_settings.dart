import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../company_details.dart';

class CompanySettingsData {
  final String name;
  final String address;
  final String phones;
  final String website;
  final Uint8List? logoBytes;
  final String fallbackLogoAsset;

  const CompanySettingsData({
    required this.name,
    required this.address,
    required this.phones,
    required this.website,
    required this.logoBytes,
    required this.fallbackLogoAsset,
  });
}

class CompanySettings {
  static const String keyName = 'companyName';
  static const String keyAddress = 'companyAddress';
  static const String keyPhones = 'companyPhones';
  static const String keyWebsite = 'companyWebsite';
  static const String keyLogoBytes = 'companyLogoBytes';
  static const String keyEnableProduction = 'featureProductionEnabled';

  static CompanySettingsData read(Box settingsBox, Locale locale) {
    final fallback = CompanyDetails.ofLocale(locale);
    final name =
        settingsBox.get(keyName, defaultValue: fallback.name) as String;
    final address =
        settingsBox.get(keyAddress, defaultValue: fallback.address) as String;
    final phones =
        settingsBox.get(keyPhones, defaultValue: fallback.phones) as String;
    final website =
        settingsBox.get(keyWebsite, defaultValue: fallback.website) as String;
    final logoBytes = settingsBox.get(keyLogoBytes) as Uint8List?;

    return CompanySettingsData(
      name: name,
      address: address,
      phones: phones,
      website: website,
      logoBytes: logoBytes,
      fallbackLogoAsset: fallback.logoAsset,
    );
  }

  static bool isProductionEnabled(Box settingsBox) {
    return settingsBox.get(keyEnableProduction, defaultValue: true) as bool;
  }

  static Uint8List? logoBytes(Box settingsBox) {
    return settingsBox.get(keyLogoBytes) as Uint8List?;
  }
}
