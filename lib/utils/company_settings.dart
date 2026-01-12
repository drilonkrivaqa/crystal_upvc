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
  static const String keyMechanismCompanies = 'mechanismCompanies';
  static const String keyEnableProduction = 'featureProductionEnabled';
  static const String keyLicenseExpiresAt = 'licenseExpiresAt';
  static const String keyLicenseUnlimited = 'licenseUnlimited';

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

  static List<String> readMechanismCompanies(Box settingsBox) {
    final raw = settingsBox.get(keyMechanismCompanies);
    if (raw is! List) {
      return [];
    }
    final companies = <String>{};
    for (final entry in raw) {
      if (entry is String) {
        final trimmed = entry.trim();
        if (trimmed.isNotEmpty) {
          companies.add(trimmed);
        }
      }
    }
    final list = companies.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return list;
  }

  static bool isProductionAvailable(Box settingsBox) {
    if (!isProductionEnabled(settingsBox)) {
      return false;
    }
    if (isLicenseExpired(settingsBox)) {
      return false;
    }
    return true;
  }

  static Uint8List? logoBytes(Box settingsBox) {
    return settingsBox.get(keyLogoBytes) as Uint8List?;
  }

  static bool isLicenseUnlimited(Box settingsBox) {
    return settingsBox.get(keyLicenseUnlimited, defaultValue: true) as bool;
  }

  static DateTime? licenseExpiresAt(Box settingsBox) {
    final value = settingsBox.get(keyLicenseExpiresAt);
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  static bool isLicenseExpired(Box settingsBox) {
    if (isLicenseUnlimited(settingsBox)) {
      return false;
    }
    final expiresAt = licenseExpiresAt(settingsBox);
    if (expiresAt == null) {
      return false;
    }
    return DateTime.now().isAfter(expiresAt);
  }
}
