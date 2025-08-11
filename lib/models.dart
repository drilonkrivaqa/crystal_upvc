import 'dart:typed_data';
import 'package:hive/hive.dart';
part 'models.g.dart';

// Customer
@HiveType(typeId: 0)
class Customer extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  String address;
  @HiveField(2)
  String phone;
  @HiveField(3)
  String? email;
  Customer({
    required this.name,
    required this.address,
    required this.phone,
    this.email = '',
  });
}

// ProfileSet: full profile system (Trocal 88, Salamander, etc)
@HiveType(typeId: 1)
class ProfileSet extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  double priceL; // Frame
  @HiveField(2)
  double priceZ; // Sash
  @HiveField(3)
  double priceT; // Mullion
  @HiveField(4)
  double priceAdapter; // Adapter (for double sash)
  @HiveField(5)
  double priceLlajsne; // Glazing bead
  @HiveField(6)
  int pipeLength; // Standard pipe length in mm
  @HiveField(7)
  int hekriOffsetL; // Hekri length difference for L profile
  @HiveField(8)
  int hekriOffsetZ; // Hekri length difference for Z profile
  @HiveField(9)
  int hekriOffsetT; // Hekri length difference for T profile
  @HiveField(10)
  double massL; // Mass per meter for L profile
  @HiveField(11)
  double massZ; // Mass per meter for Z profile
  @HiveField(12)
  double massT; // Mass per meter for T profile
  @HiveField(13)
  double massAdapter; // Mass per meter for Adapter
  @HiveField(14)
  double massLlajsne; // Mass per meter for Glazing bead
  @HiveField(15)
  int lInnerThickness; // Inner thickness of L profile
  @HiveField(16)
  int zInnerThickness; // Inner thickness of Z profile
  @HiveField(17)
  int tInnerThickness; // Inner thickness of T profile
  @HiveField(18)
  int fixedGlassTakeoff; // Takeoff for fixed glass
  @HiveField(19)
  int sashGlassTakeoff; // Takeoff for sash glass
  @HiveField(20)
  int sashValue; // Value added for sash calculation
  @HiveField(21)
  double? uf; // Thermal transmittance of profiles
  @HiveField(22)
  int lOuterThickness; // Outer thickness of L profile
  @HiveField(23)
  int zOuterThickness; // Outer thickness of Z profile
  @HiveField(24)
  int tOuterThickness; // Outer thickness of T profile
  @HiveField(25)
  int adapterOuterThickness; // Outer thickness of Adapter

  ProfileSet({
    required this.name,
    required this.priceL,
    required this.priceZ,
    required this.priceT,
    required this.priceAdapter,
    required this.priceLlajsne,
    this.pipeLength = 6500,
    this.hekriOffsetL = 0,
    this.hekriOffsetZ = 0,
    this.hekriOffsetT = 0,
    this.massL = 0,
    this.massZ = 0,
    this.massT = 0,
    this.massAdapter = 0,
    this.massLlajsne = 0,
    this.lInnerThickness = 40,
    this.zInnerThickness = 40,
    this.tInnerThickness = 40,
    this.fixedGlassTakeoff = 15,
    this.sashGlassTakeoff = 10,
    this.sashValue = 22,
    this.uf,
    this.lOuterThickness = 0,
    this.zOuterThickness = 0,
    this.tOuterThickness = 0,
    this.adapterOuterThickness = 0,
  });
}

@HiveType(typeId: 2)
class Glass extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  double pricePerM2;
  @HiveField(2)
  double massPerM2;
  @HiveField(3)
  double? ug; // Thermal transmittance of glass
  @HiveField(4)
  double? psi; // Linear thermal transmittance of glass
  Glass({
    required this.name,
    required this.pricePerM2,
    this.massPerM2 = 0,
    this.ug = 0,
    this.psi = 0,
  });
}

@HiveType(typeId: 3)
class Blind extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  double pricePerM2;
  @HiveField(2)
  int boxHeight; // height of the box in mm
  @HiveField(3)
  double massPerM2;
  Blind({
    required this.name,
    required this.pricePerM2,
    this.boxHeight = 0,
    this.massPerM2 = 0,
  });
}

@HiveType(typeId: 4)
class Mechanism extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  double price;
  @HiveField(2)
  double mass;
  Mechanism({required this.name, required this.price, this.mass = 0});
}

@HiveType(typeId: 5)
class Accessory extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  double price;
  @HiveField(2)
  double mass;
  Accessory({required this.name, required this.price, this.mass = 0});
}

@HiveType(typeId: 8)
class ExtraCharge extends HiveObject {
  @HiveField(0)
  String description;
  @HiveField(1)
  double amount;
ExtraCharge({this.description = '', this.amount = 0});
}

class SectionInsets {
  final double left;
  final double right;
  final double top;
  final double bottom;
  const SectionInsets({
    required this.left,
    required this.right,
    required this.top,
    required this.bottom,
  });
}

// Window/Door Item in Offer
@HiveType(typeId: 6)
class WindowDoorItem extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  int width; // in mm
  @HiveField(2)
  int height; // in mm
  @HiveField(3)
  int quantity;
  @HiveField(4)
  int profileSetIndex;
  @HiveField(5)
  int glassIndex;
  @HiveField(6)
  int? blindIndex;
  @HiveField(7)
  int? mechanismIndex;
  @HiveField(8)
  int? accessoryIndex;
  @HiveField(9)
  int openings; // Number of sashes/openings, 0 means fixed
  @HiveField(10)
  String? photoPath; // path to a photo of this item
  @HiveField(11)
  double? manualPrice; // optional manual override for final price
  @HiveField(25)
  double? manualBasePrice; // optional manual override for base price (0% profit)
  @HiveField(12)
  double? extra1Price; // optional extra price 1
  @HiveField(13)
  double? extra2Price; // optional extra price 2
  @HiveField(14)
  String? extra1Desc; // description for extra price 1
  @HiveField(15)
  String? extra2Desc; // description for extra price 2
  @HiveField(16)
  int verticalSections; // number of sections horizontally
  @HiveField(17)
  int horizontalSections; // number of sections vertically
  @HiveField(18)
  List<bool> fixedSectors; // true if sector is fixed, false if it has a sash
  @HiveField(19)
  List<int> sectionWidths; // width of each vertical section
  @HiveField(20)
  List<int> sectionHeights; // height of each horizontal section
  @HiveField(21)
  List<bool> verticalAdapters; // true = adapter, false = T profile
  @HiveField(22)
  List<bool> horizontalAdapters; // true = adapter, false = T profile
  @HiveField(23)
  Uint8List? photoBytes; // raw image bytes
  @HiveField(24)
  String? notes; // optional notes for this item

  WindowDoorItem({
    required this.name,
    required this.width,
    required this.height,
    required this.quantity,
    required this.profileSetIndex,
    required this.glassIndex,
    this.blindIndex,
    this.mechanismIndex,
    this.accessoryIndex,
    this.openings = 0,
    this.photoPath,
    this.photoBytes,
    this.manualPrice,
    this.manualBasePrice,
    this.extra1Price,
    this.extra2Price,
    this.extra1Desc,
    this.extra2Desc,
    this.notes,
    this.verticalSections = 1,
    this.horizontalSections = 1,
    List<bool>? fixedSectors,
    List<int>? sectionWidths,
    List<int>? sectionHeights,
    List<bool>? verticalAdapters,
    List<bool>? horizontalAdapters,
  })  : fixedSectors = fixedSectors ??
            List<bool>.filled(verticalSections * horizontalSections, false),
        sectionWidths = sectionWidths ?? List<int>.filled(verticalSections, 0),
        sectionHeights =
            sectionHeights ?? List<int>.filled(horizontalSections, 0),
        verticalAdapters = verticalAdapters ??
            List<bool>.filled(
                verticalSections > 0 ? verticalSections - 1 : 0, false),
        horizontalAdapters = horizontalAdapters ??
            List<bool>.filled(
                horizontalSections > 0 ? horizontalSections - 1 : 0, false);

  SectionInsets sectionInsets(ProfileSet set, int row, int col) {
    final halfT = set.tInnerThickness.toDouble() / 2;
    final l = set.lInnerThickness.toDouble();
    return SectionInsets(
      left: col == 0 ? l : halfT,
      right: col == verticalSections - 1 ? l : halfT,
      top: row == 0 ? l : halfT,
      bottom: row == horizontalSections - 1 ? l : halfT,
    );
  }

  /// Returns the cost for profiles using the exact section sizes.
  /// If [boxHeight] is provided, it will be subtracted from the total height
  /// (including the last section height) before calculating the cost.
  double calculateProfileCost(ProfileSet set, {int boxHeight = 0}) {
    final effectiveHeight = (height - boxHeight).clamp(0, height);
    final effectiveHeights = List<int>.from(sectionHeights);
    if (effectiveHeights.isNotEmpty) {
      effectiveHeights[effectiveHeights.length - 1] =
          (effectiveHeights.last - boxHeight).clamp(0, effectiveHeights.last);
    }
    final l = set.lInnerThickness.toDouble();
    final z = set.zInnerThickness.toDouble();
    const melt = 6.0;
    final sashAdd = set.sashValue.toDouble();

    double frameLength = 2 * (width + effectiveHeight) / 1000.0 * set.priceL;
    double sashLength = 0;
    double adapterLength = 0;
    double tLength = 0;
    double glazingBeadLength = 0;

    for (int r = 0; r < horizontalSections; r++) {
      for (int c = 0; c < verticalSections; c++) {
        final w = sectionWidths[c].toDouble();
        final h = effectiveHeights[r].toDouble();
        final idx = r * verticalSections + c;
        final insets = sectionInsets(set, r, c);
        if (!fixedSectors[idx]) {
          final sashW =
              (w - insets.left - insets.right + sashAdd).clamp(0, w);
          final sashH =
              (h - insets.top - insets.bottom + sashAdd).clamp(0, h);
          sashLength += 2 * (sashW + sashH) / 1000.0 * set.priceZ;
          final beadW = (sashW - melt - 2 * z).clamp(0, sashW);
          final beadH = (sashH - melt - 2 * z).clamp(0, sashH);
          glazingBeadLength +=
              2 * (beadW + beadH) / 1000.0 * set.priceLlajsne;
        } else {
          final beadW =
              (w - insets.left - insets.right).clamp(0, w);
          final beadH =
              (h - insets.top - insets.bottom).clamp(0, h);
          glazingBeadLength +=
              2 * (beadW + beadH) / 1000.0 * set.priceLlajsne;
        }
      }
    }

    for (int i = 0; i < verticalSections - 1; i++) {
      final len = (effectiveHeight - 2 * l).clamp(0, effectiveHeight);
      if (verticalAdapters[i]) {
        adapterLength += (len / 1000.0) * set.priceAdapter;
      } else {
        tLength += (len / 1000.0) * set.priceT;
      }
    }
    for (int i = 0; i < horizontalSections - 1; i++) {
      final len = (width - 2 * l).clamp(0, width);
      if (horizontalAdapters[i]) {
        adapterLength += (len / 1000.0) * set.priceAdapter;
      } else {
        tLength += (len / 1000.0) * set.priceT;
      }
    }

    return frameLength +
        sashLength +
        adapterLength +
        tLength +
        glazingBeadLength;
  }

  /// Returns cost for glass, given selected [Glass] and section sizes.
  double calculateGlassCost(ProfileSet set, Glass glass, {int boxHeight = 0}) {
    final effectiveHeights = List<int>.from(sectionHeights);
    if (effectiveHeights.isNotEmpty) {
      effectiveHeights[effectiveHeights.length - 1] =
          (effectiveHeights.last - boxHeight).clamp(0, effectiveHeights.last);
    }
    final l = set.lInnerThickness.toDouble();
    final z = set.zInnerThickness.toDouble();
    const melt = 6.0;
    final sashAdd = set.sashValue.toDouble();
    final fixedTakeoff = set.fixedGlassTakeoff.toDouble();
    final sashTakeoff = set.sashGlassTakeoff.toDouble();

    double total = 0;
    for (int r = 0; r < horizontalSections; r++) {
      for (int c = 0; c < verticalSections; c++) {
        final w = sectionWidths[c].toDouble();
        final h = effectiveHeights[r].toDouble();
        final idx = r * verticalSections + c;
        final insets = sectionInsets(set, r, c);
        if (!fixedSectors[idx]) {
          final sashW =
              (w - insets.left - insets.right + sashAdd).clamp(0, w);
          final sashH =
              (h - insets.top - insets.bottom + sashAdd).clamp(0, h);
          final glassW =
              (sashW - melt - 2 * z - sashTakeoff).clamp(0, sashW);
          final glassH =
              (sashH - melt - 2 * z - sashTakeoff).clamp(0, sashH);
          final area = (glassW / 1000.0) * (glassH / 1000.0);
          total += area * glass.pricePerM2;
        } else {
          final effectiveW =
              (w - insets.left - insets.right - fixedTakeoff).clamp(0, w);
          final effectiveH =
              (h - insets.top - insets.bottom - fixedTakeoff).clamp(0, h);
          final area = (effectiveW / 1000.0) * (effectiveH / 1000.0);
          total += area * glass.pricePerM2;
        }
      }
    }
    return total;
  }

  /// Returns the mass for profiles using the exact section sizes.
  /// Follows the same logic as [calculateProfileCost] but multiplies lengths
  /// with the corresponding mass per meter from [ProfileSet].
  double calculateProfileMass(ProfileSet set, {int boxHeight = 0}) {
    final effectiveHeight = (height - boxHeight).clamp(0, height);
    final effectiveHeights = List<int>.from(sectionHeights);
    if (effectiveHeights.isNotEmpty) {
      effectiveHeights[effectiveHeights.length - 1] =
          (effectiveHeights.last - boxHeight).clamp(0, effectiveHeights.last);
    }
    final l = set.lInnerThickness.toDouble();
    final z = set.zInnerThickness.toDouble();
    const melt = 6.0;
    final sashAdd = set.sashValue.toDouble();

    double frameLength = 2 * (width + effectiveHeight) / 1000.0 * set.massL;
    double sashLength = 0;
    double adapterLength = 0;
    double tLength = 0;
    double glazingBeadLength = 0;

    for (int r = 0; r < horizontalSections; r++) {
      for (int c = 0; c < verticalSections; c++) {
        final w = sectionWidths[c].toDouble();
        final h = effectiveHeights[r].toDouble();
        final idx = r * verticalSections + c;
        final insets = sectionInsets(set, r, c);
        if (!fixedSectors[idx]) {
          final sashW =
              (w - insets.left - insets.right + sashAdd).clamp(0, w);
          final sashH =
              (h - insets.top - insets.bottom + sashAdd).clamp(0, h);
          sashLength += 2 * (sashW + sashH) / 1000.0 * set.massZ;
          final beadW = (sashW - melt - 2 * z).clamp(0, sashW);
          final beadH = (sashH - melt - 2 * z).clamp(0, sashH);
          glazingBeadLength +=
              2 * (beadW + beadH) / 1000.0 * set.massLlajsne;
        } else {
          final beadW =
              (w - insets.left - insets.right).clamp(0, w);
          final beadH =
              (h - insets.top - insets.bottom).clamp(0, h);
          glazingBeadLength +=
              2 * (beadW + beadH) / 1000.0 * set.massLlajsne;
        }
      }
    }

    for (int i = 0; i < verticalSections - 1; i++) {
      final len = (effectiveHeight - 2 * l).clamp(0, effectiveHeight);
      if (verticalAdapters[i]) {
        adapterLength += (len / 1000.0) * set.massAdapter;
      } else {
        tLength += (len / 1000.0) * set.massT;
      }
    }
    for (int i = 0; i < horizontalSections - 1; i++) {
      final len = (width - 2 * l).clamp(0, width);
      if (horizontalAdapters[i]) {
        adapterLength += (len / 1000.0) * set.massAdapter;
      } else {
        tLength += (len / 1000.0) * set.massT;
      }
    }

    return frameLength +
        sashLength +
        adapterLength +
        tLength +
        glazingBeadLength;
  }

  /// Returns mass for glass, given selected [Glass] and section sizes.
  double calculateGlassMass(ProfileSet set, Glass glass, {int boxHeight = 0}) {
    final effectiveHeights = List<int>.from(sectionHeights);
    if (effectiveHeights.isNotEmpty) {
      effectiveHeights[effectiveHeights.length - 1] =
          (effectiveHeights.last - boxHeight).clamp(0, effectiveHeights.last);
    }
    final l = set.lInnerThickness.toDouble();
    final z = set.zInnerThickness.toDouble();
    const melt = 6.0;
    final sashAdd = set.sashValue.toDouble();
    final fixedTakeoff = set.fixedGlassTakeoff.toDouble();
    final sashTakeoff = set.sashGlassTakeoff.toDouble();

    double total = 0;
    for (int r = 0; r < horizontalSections; r++) {
      for (int c = 0; c < verticalSections; c++) {
        final w = sectionWidths[c].toDouble();
        final h = effectiveHeights[r].toDouble();
        final idx = r * verticalSections + c;
        final insets = sectionInsets(set, r, c);
        if (!fixedSectors[idx]) {
          final sashW =
              (w - insets.left - insets.right + sashAdd).clamp(0, w);
          final sashH =
              (h - insets.top - insets.bottom + sashAdd).clamp(0, h);
          final glassW =
              (sashW - melt - 2 * z - sashTakeoff).clamp(0, sashW);
          final glassH =
              (sashH - melt - 2 * z - sashTakeoff).clamp(0, sashH);
          final area = (glassW / 1000.0) * (glassH / 1000.0);
          total += area * glass.massPerM2;
        } else {
          final effectiveW =
              (w - insets.left - insets.right - fixedTakeoff).clamp(0, w);
          final effectiveH =
              (h - insets.top - insets.bottom - fixedTakeoff).clamp(0, h);
          final area = (effectiveW / 1000.0) * (effectiveH / 1000.0);
          total += area * glass.massPerM2;
        }
      }
    }
    return total;
  }

  /// Calculates Uw value for the window/door item. Returns null if any
  /// required parameter is missing.
  double? calculateUw(ProfileSet set, Glass glass, {int boxHeight = 0}) {
    final uf = set.uf;
    final ug = glass.ug;
    final psi = glass.psi;
    if (uf == null || ug == null || psi == null) return null;

    final effectiveHeight = (height - boxHeight).clamp(0, height);
    final effectiveHeights = List<int>.from(sectionHeights);
    if (effectiveHeights.isNotEmpty) {
      effectiveHeights[effectiveHeights.length - 1] =
          (effectiveHeights.last - boxHeight).clamp(0, effectiveHeights.last);
    }
    final l = set.lInnerThickness.toDouble();
    final z = set.zInnerThickness.toDouble();
    const melt = 6.0;
    final sashAdd = set.sashValue.toDouble();
    final fixedTakeoff = set.fixedGlassTakeoff.toDouble();
    final sashTakeoff = set.sashGlassTakeoff.toDouble();

    double frameLen = 2 * (width + effectiveHeight) / 1000.0;
    double sashLen = 0;
    double adapterLen = 0;
    double tLen = 0;
    double ag = 0;
    double lg = 0;

    for (int r = 0; r < horizontalSections; r++) {
      for (int c = 0; c < verticalSections; c++) {
        final w = sectionWidths[c].toDouble();
        final h = effectiveHeights[r].toDouble();
        final idx = r * verticalSections + c;
        final insets = sectionInsets(set, r, c);
        double glassW;
        double glassH;
        if (!fixedSectors[idx]) {
          final sashW =
              (w - insets.left - insets.right + sashAdd).clamp(0, w).toDouble();
          final sashH =
              (h - insets.top - insets.bottom + sashAdd).clamp(0, h).toDouble();
          sashLen += 2 * (sashW + sashH) / 1000.0;
          glassW = (sashW - melt - 2 * z - sashTakeoff)
              .clamp(0, sashW)
              .toDouble();
          glassH = (sashH - melt - 2 * z - sashTakeoff)
              .clamp(0, sashH)
              .toDouble();
        } else {
          glassW = (w - insets.left - insets.right - fixedTakeoff)
              .clamp(0, w)
              .toDouble();
          glassH = (h - insets.top - insets.bottom - fixedTakeoff)
              .clamp(0, h)
              .toDouble();
        }
        ag += (glassW / 1000.0) * (glassH / 1000.0);
        lg += 2 * ((glassW + glassH) / 1000.0);
      }
    }

    for (int i = 0; i < verticalSections - 1; i++) {
      final len = (effectiveHeight - 2 * l).clamp(0, effectiveHeight) / 1000.0;
      if (verticalAdapters[i]) {
        adapterLen += len;
      } else {
        tLen += len;
      }
    }
    for (int i = 0; i < horizontalSections - 1; i++) {
      final len = (width - 2 * l).clamp(0, width) / 1000.0;
      if (horizontalAdapters[i]) {
        adapterLen += len;
      } else {
        tLen += len;
      }
    }

    final af =
        frameLen * (set.lOuterThickness / 1000.0) +
            sashLen * (set.zOuterThickness / 1000.0) +
            adapterLen * (set.adapterOuterThickness / 1000.0) +
            tLen * (set.tOuterThickness / 1000.0);

    final denom = ag + af;
    if (denom == 0) return null;
    return (af * uf + ag * ug + lg * psi) / denom;
  }
}

@HiveType(typeId: 7)
class Offer extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  int customerIndex;
  @HiveField(2)
  DateTime date;
  @HiveField(3)
  List<WindowDoorItem> items;
  @HiveField(4)
  double profitPercent;
  @HiveField(5)
  List<ExtraCharge> extraCharges;
  @HiveField(6)
  double discountPercent;
  @HiveField(7)
  double discountAmount;
  @HiveField(8)
  String notes;
  @HiveField(9)
  DateTime lastEdited;
  Offer({
    required this.id,
    required this.customerIndex,
    required this.date,
    required this.items,
    this.profitPercent = 0,
    List<ExtraCharge>? extraCharges,
    this.discountPercent = 0,
    this.discountAmount = 0,
    this.notes = '',
    DateTime? lastEdited,
  })  : lastEdited = lastEdited ?? DateTime.now(),
        extraCharges = extraCharges ?? [];
}
