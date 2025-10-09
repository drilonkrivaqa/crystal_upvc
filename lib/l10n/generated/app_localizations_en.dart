// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TONI AL-PVC';

  @override
  String get homeCatalogs => 'Pricelist';

  @override
  String get homeCustomers => 'Customers';

  @override
  String get homeOffers => 'Offers';

  @override
  String get homeProduction => 'Production';

  @override
  String get productionTitle => 'Production';

  @override
  String get productionCutting => 'Cutting';

  @override
  String get productionGlass => 'Glass';

  @override
  String get productionRollerShutter => 'Roller Shutter';

  @override
  String get productionIron => 'Iron';

  @override
  String get productionRegisteredProfiles => 'Registered Profiles';

  @override
  String productionCutSummary(Object needed, Object pipes, Object waste) {
    return 'Needed $needed m, Pipes: $pipes, Waste $waste m';
  }

  @override
  String productionBarDetail(
      Object combination, Object index, Object pipeLength, Object total) {
    return 'Bar $index: $combination = $total/$pipeLength';
  }

  @override
  String productionOffsetFrom(Object type) {
    return 'Offset from $type (mm)';
  }

  @override
  String productionOffsetsSummary(Object l, Object t, Object z) {
    return 'L: ${l}mm, Z: ${z}mm, T: ${t}mm';
  }

  @override
  String get cuttingPieceFrame => 'Frame (L)';

  @override
  String get cuttingPieceSash => 'Sash (Z)';

  @override
  String get cuttingPieceT => 'T';

  @override
  String get cuttingPieceAdapter => 'Adapter';

  @override
  String get cuttingPieceBead => 'Bead';

  @override
  String get welcomeAddress =>
      'Ilir Konushevci St., No. 80, Kamenica, Kosovo, 62000';

  @override
  String get welcomePhones => '+38344357639 | +38344268300';

  @override
  String get welcomeWebsite => 'www.tonialpvc.com | tonialpvc@gmail.com';

  @override
  String get welcomeEnter => 'Enter';

  @override
  String get catalogsTitle => 'Price List';

  @override
  String get catalogProfile => 'Profile';

  @override
  String get catalogGlass => 'Glass';

  @override
  String get catalogBlind => 'Roller Shutter';

  @override
  String get catalogMechanism => 'Mechanisms';

  @override
  String get catalogAccessory => 'Accessories';

  @override
  String catalogAddTitle(Object type) {
    return 'Add $type';
  }

  @override
  String catalogEditTitle(Object name) {
    return 'Edit $name';
  }

  @override
  String get catalogSectionGeneral => 'General';

  @override
  String get catalogSectionUw => 'Uw';

  @override
  String get catalogSectionProduction => 'Production';

  @override
  String get catalogFieldPriceFrame => 'Frame (L) €/m';

  @override
  String get catalogFieldPriceSash => 'Sash (Z) €/m';

  @override
  String get catalogFieldPriceT => 'T Profile €/m';

  @override
  String get catalogFieldPriceAdapter => 'Adapter €/m';

  @override
  String get catalogFieldPriceBead => 'Bead €/m';

  @override
  String get catalogFieldOuterThicknessL => 'Outer thickness L (mm)';

  @override
  String get catalogFieldOuterThicknessZ => 'Outer thickness Z (mm)';

  @override
  String get catalogFieldOuterThicknessT => 'Outer thickness T (mm)';

  @override
  String get catalogFieldOuterThicknessAdapter =>
      'Outer thickness Adapter (mm)';

  @override
  String get catalogFieldUf => 'Uf (W/m²K)';

  @override
  String get catalogFieldMassL => 'Mass L kg/m';

  @override
  String get catalogFieldMassZ => 'Mass Z kg/m';

  @override
  String get catalogFieldMassT => 'Mass T kg/m';

  @override
  String get catalogFieldMassAdapter => 'Mass Adapter kg/m';

  @override
  String get catalogFieldMassBead => 'Mass Bead kg/m';

  @override
  String get catalogFieldInnerThicknessL => 'Inner thickness L (mm)';

  @override
  String get catalogFieldInnerThicknessZ => 'Inner thickness Z (mm)';

  @override
  String get catalogFieldInnerThicknessT => 'Inner thickness T (mm)';

  @override
  String get catalogFieldFixedGlassLoss => 'Fixed glass loss (mm)';

  @override
  String get catalogFieldSashGlassLoss => 'Sash glass loss (mm)';

  @override
  String get catalogFieldSashValue => 'Sash value (+mm)';

  @override
  String get catalogFieldProfileLength => 'Profile length (mm)';

  @override
  String get catalogFieldPricePerM2 => 'Price €/m²';

  @override
  String get catalogFieldMassPerM2 => 'Mass kg/m²';

  @override
  String get catalogFieldUg => 'Ug (W/m²K)';

  @override
  String get catalogFieldPsi => 'Psi (W/mK)';

  @override
  String get catalogFieldBoxHeight => 'Box height (mm)';

  @override
  String get catalogFieldPrice => 'Price (€)';

  @override
  String get catalogFieldMass => 'Mass (kg)';

  @override
  String get calculate => 'Calculate';

  @override
  String get pcs => 'pcs';

  @override
  String get savePdf => 'Save PDF';

  @override
  String get pdfDocument => 'Document';

  @override
  String get pdfClient => 'Client';

  @override
  String get pdfPage => 'Page';

  @override
  String get pdfOffer => 'Offer';

  @override
  String get pdfDate => 'Date:';

  @override
  String get pdfPhoto => 'Photo';

  @override
  String get pdfDetails => 'Details';

  @override
  String get pdfPrice => 'Price';

  @override
  String get pdfAdapter => 'Adapter';

  @override
  String get pdfDimensions => 'Dimensions:';

  @override
  String get pdfPieces => 'Pcs:';

  @override
  String get pdfProfileType => 'Profile (Type):';

  @override
  String get pdfGlass => 'Glass:';

  @override
  String get pdfBlind => 'Blind:';

  @override
  String get pdfMechanism => 'Mechanism:';

  @override
  String get pdfAccessory => 'Accessory:';

  @override
  String get pdfExtra1 => 'Extra 1';

  @override
  String get pdfExtra2 => 'Extra 2';

  @override
  String get pdfNotesItem => 'Notes:';

  @override
  String get pdfSections => 'Sections:';

  @override
  String get pdfOpening => 'Opening:';

  @override
  String get pdfWidths => 'Widths:';

  @override
  String get pdfWidth => 'Width:';

  @override
  String get pdfHeights => 'Heights:';

  @override
  String get pdfHeight => 'Height:';

  @override
  String get pdfVDiv => 'V div:';

  @override
  String get pdfHDiv => 'H div:';

  @override
  String get pdfTotalMass => 'Total mass:';

  @override
  String get pdfUf => 'Uf:';

  @override
  String get pdfUg => 'Ug:';

  @override
  String get pdfUw => 'Uw:';

  @override
  String get pdfTotalItems => 'Total items (pcs)';

  @override
  String get pdfItemsPrice => 'Items price (€)';

  @override
  String get pdfExtra => 'Extra';

  @override
  String get pdfDiscountAmount => 'Discount amount';

  @override
  String get pdfDiscountPercent => 'Discount %';

  @override
  String get pdfTotalPrice => 'Total price (€)';

  @override
  String get pdfNotes => 'Notes:';

  @override
  String get defaultCharacteristics => 'Default characteristics';

  @override
  String get defaultProfile => 'Default profile';

  @override
  String get defaultGlass => 'Default glass';
}
