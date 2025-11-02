import 'package:flutter/widgets.dart';

class CompanyInfo {
  final String name;
  final String address;
  final String phones;
  final String website;

  const CompanyInfo({
    required this.name,
    required this.address,
    required this.phones,
    required this.website,
  });
}

class CompanyDetails {
  static const Map<String, CompanyInfo> _localizedDetails = {
    'sq': CompanyInfo(
      name: 'TONI AL-PVC',
      address: 'Rr. Ilir Konushevci, Nr. 80, Kamenicë, Kosovë, 62000',
      phones: '+38344357639 | +38344268300',
      website: 'www.tonialpvc.com | tonialpvc@gmail.com',
    ),
    'en': CompanyInfo(
      name: 'TONI AL-PVC',
      address: 'Ilir Konushevci St., No. 80, Kamenica, Kosovo, 62000',
      phones: '+38344357639 | +38344268300',
      website: 'www.tonialpvc.com | tonialpvc@gmail.com',
    ),
    'de': CompanyInfo(
      name: 'TONI AL-PVC',
      address: 'Ilir Konushevci Str., Nr. 80, Kamenica, Kosovo, 62000',
      phones: '+38344357639 | +38344268300',
      website: 'www.tonialpvc.com | tonialpvc@gmail.com',
    ),
    'fr': CompanyInfo(
      name: 'TONI AL-PVC',
      address: 'Rue Ilir Konushevci, n° 80, Kamenica, Kosovo, 62000',
      phones: '+38344357639 | +38344268300',
      website: 'www.tonialpvc.com | tonialpvc@gmail.com',
    ),
    'it': CompanyInfo(
      name: 'TONI AL-PVC',
      address: 'Via Ilir Konushevci, n. 80, Kamenica, Kosovo, 62000',
      phones: '+38344357639 | +38344268300',
      website: 'www.tonialpvc.com | tonialpvc@gmail.com',
    ),
  };

  static CompanyInfo ofLocale(Locale locale) {
    return ofLanguageCode(locale.languageCode);
  }

  static CompanyInfo ofLanguageCode(String languageCode) {
    final normalized = languageCode.toLowerCase();
    return _localizedDetails[normalized] ?? _localizedDetails['en']!;
  }

  static CompanyInfo get fallback => _localizedDetails['en']!;
}
