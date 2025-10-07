// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'TONI AL-PVC';

  @override
  String get homeCatalogs => 'Preisliste';

  @override
  String get homeCustomers => 'Kunden';

  @override
  String get homeOffers => 'Angebote';

  @override
  String get homeProduction => 'Produktion';

  @override
  String get productionTitle => 'Produktion';

  @override
  String get productionCutting => 'Zuschnitt';

  @override
  String get productionGlass => 'Glas';

  @override
  String get productionRollerShutter => 'Rollladen';

  @override
  String get productionIron => 'Eisen';

  @override
  String get productionRegisteredProfiles => 'Registrierte Profile';

  @override
  String productionCutSummary(Object needed, Object pipes, Object waste) {
    return 'Benötigt $needed m, Rohre: $pipes, Verschnitt $waste m';
  }

  @override
  String productionBarDetail(
      Object combination, Object index, Object pipeLength, Object total) {
    return 'Stab $index: $combination = $total/$pipeLength';
  }

  @override
  String productionOffsetFrom(Object type) {
    return 'Versatz von $type (mm)';
  }

  @override
  String productionOffsetsSummary(Object l, Object t, Object z) {
    return 'L: ${l}mm, Z: ${z}mm, T: ${t}mm';
  }

  @override
  String get productionOfferLettersTitle => 'Angebotsbuchstaben';

  @override
  String get productionOfferLettersSubtitle =>
      'Die Buchstaben zeigen, zu welchem Angebot jedes Teil gehört.';

  @override
  String get productionOfferLettersLetterHeader => 'Buchstabe';

  @override
  String get productionOfferLettersOfferHeader => 'Angebot';

  @override
  String get cuttingPieceFrame => 'Rahmen (L)';

  @override
  String get cuttingPieceSash => 'Flügel (Z)';

  @override
  String get cuttingPieceT => 'T';

  @override
  String get cuttingPieceAdapter => 'Adapter';

  @override
  String get cuttingPieceBead => 'Glasleiste';

  @override
  String get welcomeAddress =>
      'Ilir Konushevci Str., Nr. 80, Kamenica, Kosovo, 62000';

  @override
  String get welcomePhones => '+38344357639 | +38344268300';

  @override
  String get welcomeWebsite => 'www.tonialpvc.com | tonialpvc@gmail.com';

  @override
  String get welcomeEnter => 'Eintreten';

  @override
  String get catalogsTitle => 'Preisliste';

  @override
  String get catalogProfile => 'Profil';

  @override
  String get catalogGlass => 'Glas';

  @override
  String get catalogBlind => 'Rollladen';

  @override
  String get catalogMechanism => 'Mechanismen';

  @override
  String get catalogAccessory => 'Zubehör';

  @override
  String catalogAddTitle(Object type) {
    return '$type hinzufügen';
  }

  @override
  String catalogEditTitle(Object name) {
    return '$name bearbeiten';
  }

  @override
  String get catalogSectionGeneral => 'Allgemein';

  @override
  String get catalogSectionUw => 'Uw';

  @override
  String get catalogSectionProduction => 'Produktion';

  @override
  String get catalogFieldPriceFrame => 'Rahmen (L) €/m';

  @override
  String get catalogFieldPriceSash => 'Flügel (Z) €/m';

  @override
  String get catalogFieldPriceT => 'T-Profil €/m';

  @override
  String get catalogFieldPriceAdapter => 'Adapter €/m';

  @override
  String get catalogFieldPriceBead => 'Glasleiste €/m';

  @override
  String get catalogFieldOuterThicknessL => 'Außenstärke L (mm)';

  @override
  String get catalogFieldOuterThicknessZ => 'Außenstärke Z (mm)';

  @override
  String get catalogFieldOuterThicknessT => 'Außenstärke T (mm)';

  @override
  String get catalogFieldOuterThicknessAdapter => 'Außenstärke Adapter (mm)';

  @override
  String get catalogFieldUf => 'Uf (W/m²K)';

  @override
  String get catalogFieldMassL => 'Masse L kg/m';

  @override
  String get catalogFieldMassZ => 'Masse Z kg/m';

  @override
  String get catalogFieldMassT => 'Masse T kg/m';

  @override
  String get catalogFieldMassAdapter => 'Masse Adapter kg/m';

  @override
  String get catalogFieldMassBead => 'Masse Glasleiste kg/m';

  @override
  String get catalogFieldInnerThicknessL => 'Innenstärke L (mm)';

  @override
  String get catalogFieldInnerThicknessZ => 'Innenstärke Z (mm)';

  @override
  String get catalogFieldInnerThicknessT => 'Innenstärke T (mm)';

  @override
  String get catalogFieldFixedGlassLoss => 'Verlust Fixglas (mm)';

  @override
  String get catalogFieldSashGlassLoss => 'Verlust Flügelglas (mm)';

  @override
  String get catalogFieldSashValue => 'Flügelzugabe (+mm)';

  @override
  String get catalogFieldProfileLength => 'Profillänge (mm)';

  @override
  String get catalogFieldPricePerM2 => 'Preis €/m²';

  @override
  String get catalogFieldMassPerM2 => 'Masse kg/m²';

  @override
  String get catalogFieldUg => 'Ug (W/m²K)';

  @override
  String get catalogFieldPsi => 'Psi (W/mK)';

  @override
  String get catalogFieldBoxHeight => 'Kastenhöhe (mm)';

  @override
  String get catalogFieldPrice => 'Preis (€)';

  @override
  String get catalogFieldMass => 'Masse (kg)';

  @override
  String get calculate => 'Berechne';

  @override
  String get pcs => 'Stk.';

  @override
  String get savePdf => 'PDF speichern';

  @override
  String get pdfDocument => 'Dokument';

  @override
  String get pdfClient => 'Kunde';

  @override
  String get pdfPage => 'Seite';

  @override
  String get pdfOffer => 'Angebot';

  @override
  String get pdfDate => 'Datum:';

  @override
  String get pdfPhoto => 'Foto';

  @override
  String get pdfDetails => 'Details';

  @override
  String get pdfPrice => 'Preis';

  @override
  String get pdfAdapter => 'Adapter';

  @override
  String get pdfDimensions => 'Abmessungen:';

  @override
  String get pdfPieces => 'Stk:';

  @override
  String get pdfProfileType => 'Profil (Typ):';

  @override
  String get pdfGlass => 'Glas:';

  @override
  String get pdfBlind => 'Rollladen:';

  @override
  String get pdfMechanism => 'Mechanismus:';

  @override
  String get pdfAccessory => 'Zubehör:';

  @override
  String get pdfExtra1 => 'Extra 1';

  @override
  String get pdfExtra2 => 'Extra 2';

  @override
  String get pdfNotesItem => 'Notizen:';

  @override
  String get pdfSections => 'Sektionen:';

  @override
  String get pdfOpening => 'Öffnung:';

  @override
  String get pdfWidths => 'Breiten:';

  @override
  String get pdfWidth => 'Breite:';

  @override
  String get pdfHeights => 'Höhen:';

  @override
  String get pdfHeight => 'Höhe:';

  @override
  String get pdfVDiv => 'V Div:';

  @override
  String get pdfHDiv => 'H Div:';

  @override
  String get pdfTotalMass => 'Gesamtmasse:';

  @override
  String get pdfUf => 'Uf:';

  @override
  String get pdfUg => 'Ug:';

  @override
  String get pdfUw => 'Uw:';

  @override
  String get pdfTotalItems => 'Gesamtanzahl der Artikel (Stk)';

  @override
  String get pdfItemsPrice => 'Artikelpreis (€)';

  @override
  String get pdfExtra => 'Extra';

  @override
  String get pdfDiscountAmount => 'Rabattbetrag';

  @override
  String get pdfDiscountPercent => 'Rabatt %';

  @override
  String get pdfTotalPrice => 'Gesamtpreis (€)';

  @override
  String get pdfNotes => 'Notizen:';
}
