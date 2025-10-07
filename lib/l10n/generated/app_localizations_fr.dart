// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'TONI AL-PVC';

  @override
  String get homeCatalogs => 'Liste de prix';

  @override
  String get homeCustomers => 'Clients';

  @override
  String get homeOffers => 'Offres';

  @override
  String get homeProduction => 'Production';

  @override
  String get productionTitle => 'Production';

  @override
  String get productionCutting => 'Découpe';

  @override
  String get productionGlass => 'Verre';

  @override
  String get productionRollerShutter => 'Volet roulant';

  @override
  String get productionIron => 'Fer';

  @override
  String get productionRegisteredProfiles => 'Profils enregistrés';

  @override
  String productionCutSummary(Object needed, Object pipes, Object waste) {
    return 'Nécessaire $needed m, Tubes : $pipes, Perte $waste m';
  }

  @override
  String productionBarDetail(
      Object combination, Object index, Object pipeLength, Object total) {
    return 'Barre $index : $combination = $total/$pipeLength';
  }

  @override
  String productionOffsetFrom(Object type) {
    return 'Décalage depuis $type (mm)';
  }

  @override
  String productionOffsetsSummary(Object l, Object t, Object z) {
    return 'L : ${l}mm, Z : ${z}mm, T : ${t}mm';
  }

  @override
  String get cuttingPieceFrame => 'Cadre (L)';

  @override
  String get cuttingPieceSash => 'Ouvrant (Z)';

  @override
  String get cuttingPieceT => 'T';

  @override
  String get cuttingPieceAdapter => 'Adaptateur';

  @override
  String get cuttingPieceBead => 'Parclose';

  @override
  String get welcomeAddress =>
      'Rue Ilir Konushevci, n° 80, Kamenica, Kosovo, 62000';

  @override
  String get welcomePhones => '+38344357639 | +38344268300';

  @override
  String get welcomeWebsite => 'www.tonialpvc.com | tonialpvc@gmail.com';

  @override
  String get welcomeEnter => 'Entrer';

  @override
  String get catalogsTitle => 'Liste de prix';

  @override
  String get catalogProfile => 'Profil';

  @override
  String get catalogGlass => 'Verre';

  @override
  String get catalogBlind => 'Volet roulant';

  @override
  String get catalogMechanism => 'Mécanismes';

  @override
  String get catalogAccessory => 'Accessoires';

  @override
  String catalogAddTitle(Object type) {
    return 'Ajouter $type';
  }

  @override
  String catalogEditTitle(Object name) {
    return 'Modifier $name';
  }

  @override
  String get catalogSectionGeneral => 'Général';

  @override
  String get catalogSectionUw => 'Uw';

  @override
  String get catalogSectionProduction => 'Production';

  @override
  String get catalogFieldPriceFrame => 'Cadre (L) €/m';

  @override
  String get catalogFieldPriceSash => 'Ouvrant (Z) €/m';

  @override
  String get catalogFieldPriceT => 'Profilé T €/m';

  @override
  String get catalogFieldPriceAdapter => 'Adaptateur €/m';

  @override
  String get catalogFieldPriceBead => 'Parclose €/m';

  @override
  String get catalogFieldOuterThicknessL => 'Épaisseur extérieure L (mm)';

  @override
  String get catalogFieldOuterThicknessZ => 'Épaisseur extérieure Z (mm)';

  @override
  String get catalogFieldOuterThicknessT => 'Épaisseur extérieure T (mm)';

  @override
  String get catalogFieldOuterThicknessAdapter =>
      'Épaisseur extérieure Adaptateur (mm)';

  @override
  String get catalogFieldUf => 'Uf (W/m²K)';

  @override
  String get catalogFieldMassL => 'Masse L kg/m';

  @override
  String get catalogFieldMassZ => 'Masse Z kg/m';

  @override
  String get catalogFieldMassT => 'Masse T kg/m';

  @override
  String get catalogFieldMassAdapter => 'Masse Adaptateur kg/m';

  @override
  String get catalogFieldMassBead => 'Masse Parclose kg/m';

  @override
  String get catalogFieldInnerThicknessL => 'Épaisseur intérieure L (mm)';

  @override
  String get catalogFieldInnerThicknessZ => 'Épaisseur intérieure Z (mm)';

  @override
  String get catalogFieldInnerThicknessT => 'Épaisseur intérieure T (mm)';

  @override
  String get catalogFieldFixedGlassLoss => 'Perte vitrage fixe (mm)';

  @override
  String get catalogFieldSashGlassLoss => 'Perte vitrage ouvrant (mm)';

  @override
  String get catalogFieldSashValue => 'Valeur ouvrant (+mm)';

  @override
  String get catalogFieldProfileLength => 'Longueur profil (mm)';

  @override
  String get catalogFieldPricePerM2 => 'Prix €/m²';

  @override
  String get catalogFieldMassPerM2 => 'Masse kg/m²';

  @override
  String get catalogFieldUg => 'Ug (W/m²K)';

  @override
  String get catalogFieldPsi => 'Psi (W/mK)';

  @override
  String get catalogFieldBoxHeight => 'Hauteur caisson (mm)';

  @override
  String get catalogFieldPrice => 'Prix (€)';

  @override
  String get catalogFieldMass => 'Masse (kg)';

  @override
  String get calculate => 'Calculer';

  @override
  String get pcs => 'pcs';

  @override
  String get savePdf => 'Enregistrer le PDF';

  @override
  String get pdfDocument => 'Document';

  @override
  String get pdfClient => 'Client';

  @override
  String get pdfPage => 'Page';

  @override
  String get pdfOffer => 'Offre';

  @override
  String get pdfDate => 'Date :';

  @override
  String get pdfPhoto => 'Photo';

  @override
  String get pdfDetails => 'Détails';

  @override
  String get pdfPrice => 'Prix';

  @override
  String get pdfAdapter => 'Adaptateur';

  @override
  String get pdfDimensions => 'Dimensions :';

  @override
  String get pdfPieces => 'Pcs :';

  @override
  String get pdfProfileType => 'Profil (Type) :';

  @override
  String get pdfGlass => 'Verre :';

  @override
  String get pdfBlind => 'Volet :';

  @override
  String get pdfMechanism => 'Mécanisme :';

  @override
  String get pdfAccessory => 'Accessoire :';

  @override
  String get pdfExtra1 => 'Extra 1';

  @override
  String get pdfExtra2 => 'Extra 2';

  @override
  String get pdfNotesItem => 'Notes :';

  @override
  String get pdfSections => 'Sections :';

  @override
  String get pdfOpening => 'Ouverture :';

  @override
  String get pdfWidths => 'Largeurs :';

  @override
  String get pdfWidth => 'Largeur :';

  @override
  String get pdfHeights => 'Hauteurs :';

  @override
  String get pdfHeight => 'Hauteur :';

  @override
  String get pdfVDiv => 'V div :';

  @override
  String get pdfHDiv => 'H div :';

  @override
  String get pdfTotalMass => 'Masse totale :';

  @override
  String get pdfUf => 'Uf :';

  @override
  String get pdfUg => 'Ug :';

  @override
  String get pdfUw => 'Uw :';

  @override
  String get pdfTotalItems => 'Nombre total d\'articles (pcs)';

  @override
  String get pdfItemsPrice => 'Prix des articles (€)';

  @override
  String get pdfExtra => 'Extra';

  @override
  String get pdfDiscountAmount => 'Montant de la remise';

  @override
  String get pdfDiscountPercent => 'Remise %';

  @override
  String get pdfTotalPrice => 'Prix total (€)';

  @override
  String get pdfNotes => 'Notes :';
}
