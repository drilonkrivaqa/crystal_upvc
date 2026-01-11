import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';
import 'app_localizations_sq.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('fr'),
    Locale('it'),
    Locale('sq')
  ];

  /// No description provided for @homeCatalogs.
  ///
  /// In en, this message translates to:
  /// **'Pricelist'**
  String get homeCatalogs;

  /// No description provided for @homeCustomers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get homeCustomers;

  /// No description provided for @homeOffers.
  ///
  /// In en, this message translates to:
  /// **'Offers'**
  String get homeOffers;

  /// No description provided for @homeProduction.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get homeProduction;

  /// No description provided for @productionTitle.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get productionTitle;

  /// No description provided for @productionCutting.
  ///
  /// In en, this message translates to:
  /// **'Cutting'**
  String get productionCutting;

  /// No description provided for @productionGlass.
  ///
  /// In en, this message translates to:
  /// **'Glass'**
  String get productionGlass;

  /// No description provided for @productionRollerShutter.
  ///
  /// In en, this message translates to:
  /// **'Roller Shutter'**
  String get productionRollerShutter;

  /// No description provided for @productionIron.
  ///
  /// In en, this message translates to:
  /// **'Iron'**
  String get productionIron;

  /// No description provided for @productionRegisteredProfiles.
  ///
  /// In en, this message translates to:
  /// **'Registered Profiles'**
  String get productionRegisteredProfiles;

  /// No description provided for @productionCutSummary.
  ///
  /// In en, this message translates to:
  /// **'Needed {needed} m, Pipes: {pipes}, Waste {waste} m'**
  String productionCutSummary(Object needed, Object pipes, Object waste);

  /// No description provided for @productionBarDetail.
  ///
  /// In en, this message translates to:
  /// **'Bar {index}: {combination} = {total}/{pipeLength}'**
  String productionBarDetail(
      Object combination, Object index, Object pipeLength, Object total);

  /// No description provided for @productionOffsetFrom.
  ///
  /// In en, this message translates to:
  /// **'Offset from {type} (mm)'**
  String productionOffsetFrom(Object type);

  /// No description provided for @productionOffsetsSummary.
  ///
  /// In en, this message translates to:
  /// **'L: {l}mm, Z: {z}mm, T: {t}mm'**
  String productionOffsetsSummary(Object l, Object t, Object z);

  /// No description provided for @cuttingPieceFrame.
  ///
  /// In en, this message translates to:
  /// **'Frame (L)'**
  String get cuttingPieceFrame;

  /// No description provided for @cuttingPieceSash.
  ///
  /// In en, this message translates to:
  /// **'Sash (Z)'**
  String get cuttingPieceSash;

  /// No description provided for @cuttingPieceT.
  ///
  /// In en, this message translates to:
  /// **'T'**
  String get cuttingPieceT;

  /// No description provided for @cuttingPieceAdapter.
  ///
  /// In en, this message translates to:
  /// **'Adapter'**
  String get cuttingPieceAdapter;

  /// No description provided for @cuttingPieceBead.
  ///
  /// In en, this message translates to:
  /// **'Bead'**
  String get cuttingPieceBead;

  /// No description provided for @welcomeEnter.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get welcomeEnter;

  /// No description provided for @welcomePasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get welcomePasswordLabel;

  /// No description provided for @welcomePasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter password'**
  String get welcomePasswordHint;

  /// No description provided for @welcomeInvalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get welcomeInvalidPassword;

  /// No description provided for @catalogsTitle.
  ///
  /// In en, this message translates to:
  /// **'Price List'**
  String get catalogsTitle;

  /// No description provided for @catalogProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get catalogProfile;

  /// No description provided for @catalogGlass.
  ///
  /// In en, this message translates to:
  /// **'Glass'**
  String get catalogGlass;

  /// No description provided for @catalogBlind.
  ///
  /// In en, this message translates to:
  /// **'Roller Shutter'**
  String get catalogBlind;

  /// No description provided for @catalogMechanism.
  ///
  /// In en, this message translates to:
  /// **'Mechanisms'**
  String get catalogMechanism;

  /// No description provided for @catalogAccessory.
  ///
  /// In en, this message translates to:
  /// **'Accessories'**
  String get catalogAccessory;

  /// No description provided for @catalogAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add {type}'**
  String catalogAddTitle(Object type);

  /// No description provided for @catalogEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit {name}'**
  String catalogEditTitle(Object name);

  /// No description provided for @catalogSectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get catalogSectionGeneral;

  /// No description provided for @catalogSectionUw.
  ///
  /// In en, this message translates to:
  /// **'Uw'**
  String get catalogSectionUw;

  /// No description provided for @catalogSectionProduction.
  ///
  /// In en, this message translates to:
  /// **'Production'**
  String get catalogSectionProduction;

  /// No description provided for @catalogFieldPriceFrame.
  ///
  /// In en, this message translates to:
  /// **'Frame (L) €/m'**
  String get catalogFieldPriceFrame;

  /// No description provided for @catalogFieldPriceSash.
  ///
  /// In en, this message translates to:
  /// **'Sash (Z) €/m'**
  String get catalogFieldPriceSash;

  /// No description provided for @catalogFieldPriceT.
  ///
  /// In en, this message translates to:
  /// **'T Profile €/m'**
  String get catalogFieldPriceT;

  /// No description provided for @catalogFieldPriceAdapter.
  ///
  /// In en, this message translates to:
  /// **'Adapter €/m'**
  String get catalogFieldPriceAdapter;

  /// No description provided for @catalogFieldPriceBead.
  ///
  /// In en, this message translates to:
  /// **'Bead €/m'**
  String get catalogFieldPriceBead;

  /// No description provided for @catalogFieldOuterThicknessL.
  ///
  /// In en, this message translates to:
  /// **'Outer thickness L (mm)'**
  String get catalogFieldOuterThicknessL;

  /// No description provided for @catalogFieldOuterThicknessZ.
  ///
  /// In en, this message translates to:
  /// **'Outer thickness Z (mm)'**
  String get catalogFieldOuterThicknessZ;

  /// No description provided for @catalogFieldOuterThicknessT.
  ///
  /// In en, this message translates to:
  /// **'Outer thickness T (mm)'**
  String get catalogFieldOuterThicknessT;

  /// No description provided for @catalogFieldOuterThicknessAdapter.
  ///
  /// In en, this message translates to:
  /// **'Outer thickness Adapter (mm)'**
  String get catalogFieldOuterThicknessAdapter;

  /// No description provided for @catalogFieldUf.
  ///
  /// In en, this message translates to:
  /// **'Uf (W/m²K)'**
  String get catalogFieldUf;

  /// No description provided for @catalogFieldMassL.
  ///
  /// In en, this message translates to:
  /// **'Mass L kg/m'**
  String get catalogFieldMassL;

  /// No description provided for @catalogFieldMassZ.
  ///
  /// In en, this message translates to:
  /// **'Mass Z kg/m'**
  String get catalogFieldMassZ;

  /// No description provided for @catalogFieldMassT.
  ///
  /// In en, this message translates to:
  /// **'Mass T kg/m'**
  String get catalogFieldMassT;

  /// No description provided for @catalogFieldMassAdapter.
  ///
  /// In en, this message translates to:
  /// **'Mass Adapter kg/m'**
  String get catalogFieldMassAdapter;

  /// No description provided for @catalogFieldMassBead.
  ///
  /// In en, this message translates to:
  /// **'Mass Bead kg/m'**
  String get catalogFieldMassBead;

  /// No description provided for @catalogFieldInnerThicknessL.
  ///
  /// In en, this message translates to:
  /// **'Inner thickness L (mm)'**
  String get catalogFieldInnerThicknessL;

  /// No description provided for @catalogFieldInnerThicknessZ.
  ///
  /// In en, this message translates to:
  /// **'Inner thickness Z (mm)'**
  String get catalogFieldInnerThicknessZ;

  /// No description provided for @catalogFieldInnerThicknessT.
  ///
  /// In en, this message translates to:
  /// **'Inner thickness T (mm)'**
  String get catalogFieldInnerThicknessT;

  /// No description provided for @catalogFieldFixedGlassLoss.
  ///
  /// In en, this message translates to:
  /// **'Fixed glass loss (mm)'**
  String get catalogFieldFixedGlassLoss;

  /// No description provided for @catalogFieldSashGlassLoss.
  ///
  /// In en, this message translates to:
  /// **'Sash glass loss (mm)'**
  String get catalogFieldSashGlassLoss;

  /// No description provided for @catalogFieldSashValue.
  ///
  /// In en, this message translates to:
  /// **'Sash value (+mm)'**
  String get catalogFieldSashValue;

  /// No description provided for @catalogFieldProfileLength.
  ///
  /// In en, this message translates to:
  /// **'Profile length (mm)'**
  String get catalogFieldProfileLength;

  /// No description provided for @catalogFieldPricePerM2.
  ///
  /// In en, this message translates to:
  /// **'Price €/m²'**
  String get catalogFieldPricePerM2;

  /// No description provided for @catalogFieldMassPerM2.
  ///
  /// In en, this message translates to:
  /// **'Mass kg/m²'**
  String get catalogFieldMassPerM2;

  /// No description provided for @catalogFieldProfileColor.
  ///
  /// In en, this message translates to:
  /// **'Profile color'**
  String get catalogFieldProfileColor;

  /// No description provided for @catalogFieldGlassColor.
  ///
  /// In en, this message translates to:
  /// **'Glass color'**
  String get catalogFieldGlassColor;

  /// No description provided for @catalogFieldUg.
  ///
  /// In en, this message translates to:
  /// **'Ug (W/m²K)'**
  String get catalogFieldUg;

  /// No description provided for @catalogFieldPsi.
  ///
  /// In en, this message translates to:
  /// **'Psi (W/mK)'**
  String get catalogFieldPsi;

  /// No description provided for @catalogFieldBoxHeight.
  ///
  /// In en, this message translates to:
  /// **'Box height (mm)'**
  String get catalogFieldBoxHeight;

  /// No description provided for @catalogFieldPrice.
  ///
  /// In en, this message translates to:
  /// **'Price (€)'**
  String get catalogFieldPrice;

  /// No description provided for @catalogFieldMass.
  ///
  /// In en, this message translates to:
  /// **'Mass (kg)'**
  String get catalogFieldMass;

  /// No description provided for @calculate.
  ///
  /// In en, this message translates to:
  /// **'Calculate'**
  String get calculate;

  /// No description provided for @pcs.
  ///
  /// In en, this message translates to:
  /// **'pcs'**
  String get pcs;

  /// No description provided for @savePdf.
  ///
  /// In en, this message translates to:
  /// **'Save PDF'**
  String get savePdf;

  /// No description provided for @pdfDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get pdfDocument;

  /// No description provided for @pdfClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get pdfClient;

  /// No description provided for @pdfPage.
  ///
  /// In en, this message translates to:
  /// **'Page'**
  String get pdfPage;

  /// No description provided for @pdfOffer.
  ///
  /// In en, this message translates to:
  /// **'Offer'**
  String get pdfOffer;

  /// No description provided for @pdfDate.
  ///
  /// In en, this message translates to:
  /// **'Date:'**
  String get pdfDate;

  /// No description provided for @pdfPhoto.
  ///
  /// In en, this message translates to:
  /// **'Photo'**
  String get pdfPhoto;

  /// No description provided for @pdfDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get pdfDetails;

  /// No description provided for @pdfPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get pdfPrice;

  /// No description provided for @pdfAdapter.
  ///
  /// In en, this message translates to:
  /// **'Adapter'**
  String get pdfAdapter;

  /// No description provided for @pdfDimensions.
  ///
  /// In en, this message translates to:
  /// **'Dimensions:'**
  String get pdfDimensions;

  /// No description provided for @pdfPieces.
  ///
  /// In en, this message translates to:
  /// **'Pcs:'**
  String get pdfPieces;

  /// No description provided for @pdfProfileType.
  ///
  /// In en, this message translates to:
  /// **'Profile (Type):'**
  String get pdfProfileType;

  /// No description provided for @pdfGlass.
  ///
  /// In en, this message translates to:
  /// **'Glass:'**
  String get pdfGlass;

  /// No description provided for @pdfBlind.
  ///
  /// In en, this message translates to:
  /// **'Blind:'**
  String get pdfBlind;

  /// No description provided for @pdfMechanism.
  ///
  /// In en, this message translates to:
  /// **'Mechanism:'**
  String get pdfMechanism;

  /// No description provided for @pdfAccessory.
  ///
  /// In en, this message translates to:
  /// **'Accessory:'**
  String get pdfAccessory;

  /// No description provided for @pdfExtra1.
  ///
  /// In en, this message translates to:
  /// **'Extra 1'**
  String get pdfExtra1;

  /// No description provided for @pdfExtra2.
  ///
  /// In en, this message translates to:
  /// **'Extra 2'**
  String get pdfExtra2;

  /// No description provided for @pdfNotesItem.
  ///
  /// In en, this message translates to:
  /// **'Notes:'**
  String get pdfNotesItem;

  /// No description provided for @pdfSections.
  ///
  /// In en, this message translates to:
  /// **'Sections:'**
  String get pdfSections;

  /// No description provided for @pdfOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening:'**
  String get pdfOpening;

  /// No description provided for @pdfWidths.
  ///
  /// In en, this message translates to:
  /// **'Widths:'**
  String get pdfWidths;

  /// No description provided for @pdfWidth.
  ///
  /// In en, this message translates to:
  /// **'Width:'**
  String get pdfWidth;

  /// No description provided for @pdfHeights.
  ///
  /// In en, this message translates to:
  /// **'Heights:'**
  String get pdfHeights;

  /// No description provided for @pdfHeight.
  ///
  /// In en, this message translates to:
  /// **'Height:'**
  String get pdfHeight;

  /// No description provided for @pdfVDiv.
  ///
  /// In en, this message translates to:
  /// **'V div:'**
  String get pdfVDiv;

  /// No description provided for @pdfHDiv.
  ///
  /// In en, this message translates to:
  /// **'H div:'**
  String get pdfHDiv;

  /// No description provided for @pdfTotalMass.
  ///
  /// In en, this message translates to:
  /// **'Total mass:'**
  String get pdfTotalMass;

  /// No description provided for @pdfTotalArea.
  ///
  /// In en, this message translates to:
  /// **'Total area:'**
  String get pdfTotalArea;

  /// No description provided for @pdfUf.
  ///
  /// In en, this message translates to:
  /// **'Uf:'**
  String get pdfUf;

  /// No description provided for @pdfUg.
  ///
  /// In en, this message translates to:
  /// **'Ug:'**
  String get pdfUg;

  /// No description provided for @pdfUw.
  ///
  /// In en, this message translates to:
  /// **'Uw:'**
  String get pdfUw;

  /// No description provided for @pdfTotalItems.
  ///
  /// In en, this message translates to:
  /// **'Total items (pcs)'**
  String get pdfTotalItems;

  /// No description provided for @pdfItemsPrice.
  ///
  /// In en, this message translates to:
  /// **'Items price (€)'**
  String get pdfItemsPrice;

  /// No description provided for @pdfExtra.
  ///
  /// In en, this message translates to:
  /// **'Extra'**
  String get pdfExtra;

  /// No description provided for @pdfDiscountAmount.
  ///
  /// In en, this message translates to:
  /// **'Discount amount'**
  String get pdfDiscountAmount;

  /// No description provided for @pdfDiscountPercent.
  ///
  /// In en, this message translates to:
  /// **'Discount %'**
  String get pdfDiscountPercent;

  /// No description provided for @pdfTotalPrice.
  ///
  /// In en, this message translates to:
  /// **'Total price (€)'**
  String get pdfTotalPrice;

  /// No description provided for @pdfNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes:'**
  String get pdfNotes;

  /// No description provided for @defaultCharacteristics.
  ///
  /// In en, this message translates to:
  /// **'Default characteristics'**
  String get defaultCharacteristics;

  /// No description provided for @defaultProfile.
  ///
  /// In en, this message translates to:
  /// **'Default profile'**
  String get defaultProfile;

  /// No description provided for @defaultGlass.
  ///
  /// In en, this message translates to:
  /// **'Default glass'**
  String get defaultGlass;

  /// No description provided for @defaultBlind.
  ///
  /// In en, this message translates to:
  /// **'Default blind'**
  String get defaultBlind;

  /// No description provided for @applyDefaultsMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose which windows/doors should use the updated default profile, glass, and blind. Uncheck the items you want to exclude.'**
  String get applyDefaultsMessage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'fr', 'it', 'sq'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
    case 'sq':
      return AppLocalizationsSq();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
