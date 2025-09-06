import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const supportedLocales = [
    Locale('sq'),
    Locale('en'),
    Locale('de'),
    Locale('it'),
    Locale('fr'),
  ];

  static const Map<String, Map<String, String>> _localizedValues = {
    'sq': {
      'appTitle': 'TONI AL-PVC',
      'homeCatalogs': 'Çmimore',
      'homeCustomers': 'Klientët',
      'homeOffers': 'Ofertat',
      'homeProduction': 'Prodhimi',
      'welcomeAddress': 'Rr. Ilir Konushevci, Nr. 80, Kamenicë, Kosovë, 62000',
      'welcomePhones': '+38344357639 | +38344268300',
      'welcomeWebsite': 'www.tonialpvc.com | tonialpvc@gmail.com',
      'welcomeEnter': 'Hyr',
      'snackLoadFailure': 'Disa të dhëna nuk u ngarkuan: {names}',
      'snackMigrationFailure': 'Disa të dhëna nuk u migruan: {names}. Ju lutemi kontrolloni dhe rikuperoni manualisht nëse është e nevojshme.',
    },
    'en': {
      'appTitle': 'TONI AL-PVC',
      'homeCatalogs': 'Price List',
      'homeCustomers': 'Customers',
      'homeOffers': 'Offers',
      'homeProduction': 'Production',
      'welcomeAddress': 'Rr. Ilir Konushevci, Nr. 80, Kamenicë, Kosovë, 62000',
      'welcomePhones': '+38344357639 | +38344268300',
      'welcomeWebsite': 'www.tonialpvc.com | tonialpvc@gmail.com',
      'welcomeEnter': 'Enter',
      'snackLoadFailure': 'Some data failed to load: {names}',
      'snackMigrationFailure': 'Some data failed to migrate: {names}. Please check and recover manually if necessary.',
    },
    'de': {
      'appTitle': 'TONI AL-PVC',
      'homeCatalogs': 'Preisliste',
      'homeCustomers': 'Kunden',
      'homeOffers': 'Angebote',
      'homeProduction': 'Produktion',
      'welcomeAddress': 'Rr. Ilir Konushevci, Nr. 80, Kamenicë, Kosovë, 62000',
      'welcomePhones': '+38344357639 | +38344268300',
      'welcomeWebsite': 'www.tonialpvc.com | tonialpvc@gmail.com',
      'welcomeEnter': 'Betreten',
      'snackLoadFailure': 'Einige Daten konnten nicht geladen werden: {names}',
      'snackMigrationFailure': 'Einige Daten konnten nicht migriert werden: {names}. Bitte prüfen und ggf. manuell wiederherstellen.',
    },
    'it': {
      'appTitle': 'TONI AL-PVC',
      'homeCatalogs': 'Listino prezzi',
      'homeCustomers': 'Clienti',
      'homeOffers': 'Offerte',
      'homeProduction': 'Produzione',
      'welcomeAddress': 'Rr. Ilir Konushevci, Nr. 80, Kamenicë, Kosovë, 62000',
      'welcomePhones': '+38344357639 | +38344268300',
      'welcomeWebsite': 'www.tonialpvc.com | tonialpvc@gmail.com',
      'welcomeEnter': 'Entra',
      'snackLoadFailure': 'Alcuni dati non sono stati caricati: {names}',
      'snackMigrationFailure': 'Alcuni dati non sono stati migrati: {names}. Controlla e ripristina manualmente se necessario.',
    },
    'fr': {
      'appTitle': 'TONI AL-PVC',
      'homeCatalogs': 'Tarifs',
      'homeCustomers': 'Clients',
      'homeOffers': 'Offres',
      'homeProduction': 'Production',
      'welcomeAddress': 'Rr. Ilir Konushevci, Nr. 80, Kamenicë, Kosovë, 62000',
      'welcomePhones': '+38344357639 | +38344268300',
      'welcomeWebsite': 'www.tonialpvc.com | tonialpvc@gmail.com',
      'welcomeEnter': 'Entrer',
      'snackLoadFailure': "Certaines données n'ont pas été chargées : {names}",
      'snackMigrationFailure': "Certaines données n'ont pas été migrées : {names}. Veuillez vérifier et récupérer manuellement si nécessaire.",
    },
  };

  String get appTitle => _localizedValues[locale.languageCode]!['appTitle']!;
  String get homeCatalogs => _localizedValues[locale.languageCode]!['homeCatalogs']!;
  String get homeCustomers => _localizedValues[locale.languageCode]!['homeCustomers']!;
  String get homeOffers => _localizedValues[locale.languageCode]!['homeOffers']!;
  String get homeProduction => _localizedValues[locale.languageCode]!['homeProduction']!;
  String get welcomeAddress => _localizedValues[locale.languageCode]!['welcomeAddress']!;
  String get welcomePhones => _localizedValues[locale.languageCode]!['welcomePhones']!;
  String get welcomeWebsite => _localizedValues[locale.languageCode]!['welcomeWebsite']!;
  String get welcomeEnter => _localizedValues[locale.languageCode]!['welcomeEnter']!;

  String snackLoadFailure(String names) =>
      _localizedValues[locale.languageCode]!['snackLoadFailure']!.replaceFirst('{names}', names);
  String snackMigrationFailure(String names) =>
      _localizedValues[locale.languageCode]!['snackMigrationFailure']!.replaceFirst('{names}', names);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppLocalizations.supportedLocales.map((e) => e.languageCode).contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
