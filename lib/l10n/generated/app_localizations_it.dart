// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import '../../company_details.dart';
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => CompanyDetails.ofLanguageCode(localeName).name;

  @override
  String get homeCatalogs => 'Listino prezzi';

  @override
  String get homeCustomers => 'Clienti';

  @override
  String get homeOffers => 'Offerte';

  @override
  String get homeProduction => 'Produzione';

  @override
  String get productionTitle => 'Produzione';

  @override
  String get productionCutting => 'Taglio';

  @override
  String get productionGlass => 'Vetro';

  @override
  String get productionRollerShutter => 'Tapparella';

  @override
  String get productionIron => 'Ferro';

  @override
  String get productionRegisteredProfiles => 'Profili registrati';

  @override
  String productionCutSummary(Object needed, Object pipes, Object waste) {
    return 'Necessari $needed m, Tubi: $pipes, Scarto $waste m';
  }

  @override
  String productionBarDetail(
      Object combination, Object index, Object pipeLength, Object total) {
    return 'Barra $index: $combination = $total/$pipeLength';
  }

  @override
  String productionOffsetFrom(Object type) {
    return 'Offset da $type (mm)';
  }

  @override
  String productionOffsetsSummary(Object l, Object t, Object z) {
    return 'L: ${l}mm, Z: ${z}mm, T: ${t}mm';
  }

  @override
  String get cuttingPieceFrame => 'Telaio (L)';

  @override
  String get cuttingPieceSash => 'Anta (Z)';

  @override
  String get cuttingPieceT => 'T';

  @override
  String get cuttingPieceAdapter => 'Adattatore';

  @override
  String get cuttingPieceBead => 'Fermavetro';

  @override
  String get welcomeAddress =>
      CompanyDetails.ofLanguageCode(localeName).address;

  @override
  String get welcomePhones => CompanyDetails.ofLanguageCode(localeName).phones;

  @override
  String get welcomeWebsite =>
      CompanyDetails.ofLanguageCode(localeName).website;

  @override
  String get welcomeEnter => 'Entra';

  @override
  String get catalogsTitle => 'Listino prezzi';

  @override
  String get catalogProfile => 'Profilo';

  @override
  String get catalogGlass => 'Vetro';

  @override
  String get catalogBlind => 'Tapparella';

  @override
  String get catalogMechanism => 'Meccanismi';

  @override
  String get catalogAccessory => 'Accessori';

  @override
  String catalogAddTitle(Object type) {
    return 'Aggiungi $type';
  }

  @override
  String catalogEditTitle(Object name) {
    return 'Modifica $name';
  }

  @override
  String get catalogSectionGeneral => 'Generale';

  @override
  String get catalogSectionUw => 'Uw';

  @override
  String get catalogSectionProduction => 'Produzione';

  @override
  String get catalogFieldPriceFrame => 'Telaio (L) €/m';

  @override
  String get catalogFieldPriceSash => 'Anta (Z) €/m';

  @override
  String get catalogFieldPriceT => 'Profilo T €/m';

  @override
  String get catalogFieldPriceAdapter => 'Adattatore €/m';

  @override
  String get catalogFieldPriceBead => 'Fermavetro €/m';

  @override
  String get catalogFieldOuterThicknessL => 'Spessore esterno L (mm)';

  @override
  String get catalogFieldOuterThicknessZ => 'Spessore esterno Z (mm)';

  @override
  String get catalogFieldOuterThicknessT => 'Spessore esterno T (mm)';

  @override
  String get catalogFieldOuterThicknessAdapter =>
      'Spessore esterno Adattatore (mm)';

  @override
  String get catalogFieldUf => 'Uf (W/m²K)';

  @override
  String get catalogFieldMassL => 'Massa L kg/m';

  @override
  String get catalogFieldMassZ => 'Massa Z kg/m';

  @override
  String get catalogFieldMassT => 'Massa T kg/m';

  @override
  String get catalogFieldMassAdapter => 'Massa Adattatore kg/m';

  @override
  String get catalogFieldMassBead => 'Massa Fermavetro kg/m';

  @override
  String get catalogFieldInnerThicknessL => 'Spessore interno L (mm)';

  @override
  String get catalogFieldInnerThicknessZ => 'Spessore interno Z (mm)';

  @override
  String get catalogFieldInnerThicknessT => 'Spessore interno T (mm)';

  @override
  String get catalogFieldFixedGlassLoss => 'Perdita vetro fisso (mm)';

  @override
  String get catalogFieldSashGlassLoss => 'Perdita vetro anta (mm)';

  @override
  String get catalogFieldSashValue => 'Valore anta (+mm)';

  @override
  String get catalogFieldProfileLength => 'Lunghezza profilo (mm)';

  @override
  String get catalogFieldPricePerM2 => 'Prezzo €/m²';

  @override
  String get catalogFieldMassPerM2 => 'Massa kg/m²';

  @override
  String get catalogFieldUg => 'Ug (W/m²K)';

  @override
  String get catalogFieldPsi => 'Psi (W/mK)';

  @override
  String get catalogFieldBoxHeight => 'Altezza cassonetto (mm)';

  @override
  String get catalogFieldPrice => 'Prezzo (€)';

  @override
  String get catalogFieldMass => 'Massa (kg)';

  @override
  String get calculate => 'Calcola';

  @override
  String get pcs => 'pz';

  @override
  String get savePdf => 'Salva PDF';

  @override
  String get pdfDocument => 'Documento';

  @override
  String get pdfClient => 'Cliente';

  @override
  String get pdfPage => 'Pagina';

  @override
  String get pdfOffer => 'Offerta';

  @override
  String get pdfDate => 'Data:';

  @override
  String get pdfPhoto => 'Foto';

  @override
  String get pdfDetails => 'Dettagli';

  @override
  String get pdfPrice => 'Prezzo';

  @override
  String get pdfAdapter => 'Adattatore';

  @override
  String get pdfDimensions => 'Dimensioni:';

  @override
  String get pdfPieces => 'Pz:';

  @override
  String get pdfProfileType => 'Profilo (Tipo):';

  @override
  String get pdfGlass => 'Vetro:';

  @override
  String get pdfBlind => 'Tapparella:';

  @override
  String get pdfMechanism => 'Meccanismo:';

  @override
  String get pdfAccessory => 'Accessorio:';

  @override
  String get pdfExtra1 => 'Extra 1';

  @override
  String get pdfExtra2 => 'Extra 2';

  @override
  String get pdfNotesItem => 'Note:';

  @override
  String get pdfSections => 'Sezioni:';

  @override
  String get pdfOpening => 'Apertura:';

  @override
  String get pdfWidths => 'Larghezze:';

  @override
  String get pdfWidth => 'Larghezza:';

  @override
  String get pdfHeights => 'Altezze:';

  @override
  String get pdfHeight => 'Altezza:';

  @override
  String get pdfVDiv => 'V div:';

  @override
  String get pdfHDiv => 'H div:';

  @override
  String get pdfTotalMass => 'Massa totale:';

  @override
  String get pdfUf => 'Uf:';

  @override
  String get pdfUg => 'Ug:';

  @override
  String get pdfUw => 'Uw:';

  @override
  String get pdfTotalItems => 'Numero totale di articoli (pz)';

  @override
  String get pdfItemsPrice => 'Prezzo degli articoli (€)';

  @override
  String get pdfExtra => 'Extra';

  @override
  String get pdfDiscountAmount => 'Importo dello sconto';

  @override
  String get pdfDiscountPercent => 'Sconto %';

  @override
  String get pdfTotalPrice => 'Prezzo totale (€)';

  @override
  String get pdfNotes => 'Note:';

  @override
  String get defaultCharacteristics => 'Caratteristiche predefinite';

  @override
  String get defaultProfile => 'Profilo predefinito';

  @override
  String get defaultGlass => 'Vetro predefinito';
}
