// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Albanian (`sq`).
class AppLocalizationsSq extends AppLocalizations {
  AppLocalizationsSq([String locale = 'sq']) : super(locale);

  @override
  String get homeCatalogs => 'Çmimore';

  @override
  String get homeCustomers => 'Klientët';

  @override
  String get homeOffers => 'Ofertat';

  @override
  String get homeProduction => 'Prodhimi';

  @override
  String get productionTitle => 'Prodhimi';

  @override
  String get productionCutting => 'Prerja';

  @override
  String get productionGlass => 'Xhami';

  @override
  String get productionRollerShutter => 'Roleta';

  @override
  String get productionIron => 'Hekur';

  @override
  String get productionRegisteredProfiles => 'Profilet e regjistruara';

  @override
  String productionCutSummary(Object needed, Object pipes, Object waste) {
    return 'Nevojiten $needed m, Tuba: $pipes, Humbje $waste m';
  }

  @override
  String productionBarDetail(
      Object combination, Object index, Object pipeLength, Object total) {
    return 'Shufra $index: $combination = $total/$pipeLength';
  }

  @override
  String productionOffsetFrom(Object type) {
    return 'Offset nga $type (mm)';
  }

  @override
  String productionOffsetsSummary(Object l, Object t, Object z) {
    return 'L: ${l}mm, Z: ${z}mm, T: ${t}mm';
  }

  @override
  String get cuttingPieceFrame => 'Korniza (L)';

  @override
  String get cuttingPieceSash => 'Krah (Z)';

  @override
  String get cuttingPieceT => 'T';

  @override
  String get cuttingPieceAdapter => 'Adapter';

  @override
  String get cuttingPieceBead => 'Llajsne';

  @override
  String get welcomeEnter => 'Hyr';

  @override
  String get welcomePasswordLabel => 'Fjalëkalimi';

  @override
  String get welcomePasswordHint => 'Shkruani fjalëkalimin';

  @override
  String get welcomeInvalidPassword => 'Fjalëkalim i pasaktë';

  @override
  String get catalogsTitle => 'Çmimorja';

  @override
  String get catalogProfile => 'Profili';

  @override
  String get catalogGlass => 'Xhami';

  @override
  String get catalogBlind => 'Roleta';

  @override
  String get catalogMechanism => 'Mekanizma';

  @override
  String get catalogAccessory => 'Aksesorë';

  @override
  String get catalogShtesa => 'Shtesa (Shtesë)';

  @override
  String catalogAddTitle(Object type) {
    return 'Shto $type';
  }

  @override
  String catalogEditTitle(Object name) {
    return 'Ndrysho $name';
  }

  @override
  String get catalogSectionGeneral => 'Të përgjithshme';

  @override
  String get catalogSectionUw => 'Uw';

  @override
  String get catalogSectionProduction => 'Prodhimi';

  @override
  String get catalogFieldPriceFrame => 'Korniza (L) €/m';

  @override
  String get catalogFieldPriceSash => 'Krahu (Z) €/m';

  @override
  String get catalogFieldPriceT => 'Profili T €/m';

  @override
  String get catalogFieldPriceAdapter => 'Adapter €/m';

  @override
  String get catalogFieldPriceBead => 'Llajsne €/m';

  @override
  String get catalogFieldOuterThicknessL => 'Trashësia e jashtme L (mm)';

  @override
  String get catalogFieldOuterThicknessZ => 'Trashësia e jashtme Z (mm)';

  @override
  String get catalogFieldOuterThicknessT => 'Trashësia e jashtme T (mm)';

  @override
  String get catalogFieldOuterThicknessAdapter =>
      'Trashësia e jashtme Adapter (mm)';

  @override
  String get catalogFieldUf => 'Uf (W/m²K)';

  @override
  String get catalogFieldMassL => 'Masa L kg/m';

  @override
  String get catalogFieldMassZ => 'Masa Z kg/m';

  @override
  String get catalogFieldMassT => 'Masa T kg/m';

  @override
  String get catalogFieldMassAdapter => 'Masa Adapter kg/m';

  @override
  String get catalogFieldMassBead => 'Masa Llajsne kg/m';

  @override
  String get catalogFieldInnerThicknessL => 'Trashësia e brendshme L (mm)';

  @override
  String get catalogFieldInnerThicknessZ => 'Trashësia e brendshme Z (mm)';

  @override
  String get catalogFieldInnerThicknessT => 'Trashësia e brendshme T (mm)';

  @override
  String get catalogFieldFixedGlassLoss => 'Humbja e xhamit fiks (mm)';

  @override
  String get catalogFieldSashGlassLoss => 'Humbja e xhamit të krahut (mm)';

  @override
  String get catalogFieldSashValue => 'Vlera e krahut (+mm)';

  @override
  String get catalogFieldProfileLength => 'Gjatësia e profilit (mm)';

  @override
  String get catalogFieldPricePerM2 => 'Çmimi €/m²';

  @override
  String get catalogFieldMassPerM2 => 'Masa kg/m²';

  @override
  String get catalogFieldUg => 'Ug (W/m²K)';

  @override
  String get catalogFieldPsi => 'Psi (W/mK)';

  @override
  String get catalogFieldBoxHeight => 'Lartësia e kutisë (mm)';

  @override
  String get catalogFieldPrice => 'Çmimi (€)';

  @override
  String get catalogFieldMass => 'Masa (kg)';

  @override
  String get calculate => 'Kalkulo';

  @override
  String get pcs => 'copë';

  @override
  String get savePdf => 'Ruaj PDF';

  @override
  String get pdfDocument => 'Dokument';

  @override
  String get pdfClient => 'Klienti';

  @override
  String get pdfPage => 'Faqja';

  @override
  String get pdfOffer => 'Oferta';

  @override
  String get pdfDate => 'Data:';

  @override
  String get pdfPhoto => 'Foto';

  @override
  String get pdfDetails => 'Detajet';

  @override
  String get pdfPrice => 'Çmimi';

  @override
  String get pdfAdapter => 'Adapter';

  @override
  String get pdfDimensions => 'Dimenzionet:';

  @override
  String get pdfPieces => 'Pcs:';

  @override
  String get pdfProfileType => 'Profili (Lloji):';

  @override
  String get pdfGlass => 'Xhami:';

  @override
  String get pdfBlind => 'Roleta:';

  @override
  String get pdfMechanism => 'Mekanizmi:';

  @override
  String get pdfAccessory => 'Aksesori:';

  @override
  String get pdfExtra1 => 'Ekstra 1';

  @override
  String get pdfExtra2 => 'Ekstra 2';

  @override
  String get pdfNotesItem => 'Shënime:';

  @override
  String get pdfSections => 'Sektorët:';

  @override
  String get pdfOpening => 'Hapje:';

  @override
  String get pdfWidths => 'Gjerësitë:';

  @override
  String get pdfWidth => 'Gjerësia:';

  @override
  String get pdfHeights => 'Lartësitë:';

  @override
  String get pdfHeight => 'Lartësia:';

  @override
  String get pdfVDiv => 'V div:';

  @override
  String get pdfHDiv => 'H div:';

  @override
  String get pdfTotalMass => 'Masa totale:';

  @override
  String get pdfTotalArea => 'Sipërfaqja totale:';

  @override
  String get pdfUf => 'Uf:';

  @override
  String get pdfUg => 'Ug:';

  @override
  String get pdfUw => 'Uw:';

  @override
  String get pdfTotalItems => 'Numri total i artikujve (pcs)';

  @override
  String get pdfItemsPrice => 'Çmimi i artikujve (€)';

  @override
  String get pdfExtra => 'Ekstra';

  @override
  String get pdfDiscountAmount => 'Shuma e zbritjes';

  @override
  String get pdfDiscountPercent => 'Zbritje %';

  @override
  String get pdfTotalPrice => 'Çmimi total (€)';

  @override
  String get pdfNotes => 'Vërejtje/Notes:';

  @override
  String get defaultCharacteristics => 'Karakteristikat e paracaktuara';

  @override
  String get defaultProfile => 'Profili i paracaktuar';

  @override
  String get defaultGlass => 'Xhami i paracaktuar';

  @override
  String get defaultBlind => 'Roleta e paracaktuar';

  @override
  String get shtesaLabel => 'Shtesa (Shtesë)';

  @override
  String get shtesaNone => 'Asnjë';

  @override
  String get shtesaNoOptions => 'Nuk ka madhësi shtese të konfiguruara për këtë profil.';

  @override
  String get shtesaLeft => 'Shtesa majtas (mm)';

  @override
  String get shtesaRight => 'Shtesa djathtas (mm)';

  @override
  String get shtesaTop => 'Shtesa sipër (mm)';

  @override
  String get shtesaBottom => 'Shtesa poshtë (mm)';

  @override
  String shtesaFinalSize(Object width, Object height) {
    return 'Përmasa finale: $width x $height mm';
  }

  @override
  String shtesaVerticalLength(Object length) {
    return 'Gjatësia vertikale e shtesës: $length mm';
  }

  @override
  String shtesaHorizontalLength(Object length) {
    return 'Gjatësia horizontale e shtesës: $length mm';
  }

  @override
  String get shtesaLengthLabel => 'Madhësia e shtesës (mm)';

  @override
  String get shtesaPriceLabel => 'Çmimi për metër';

  @override
  String get applyDefaultsMessage =>
      'Zgjidhni cilat dritare/dyer duhet të përdorin profilin, xhamin dhe roletën e re të paracaktuar. Hiqni shenjën nga ato që dëshironi t\'i përjashtoni.';
}
