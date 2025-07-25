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
  String email;
  Customer(
      {required this.name,
      required this.address,
      required this.phone,
      required this.email});
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

  ProfileSet({
    required this.name,
    required this.priceL,
    required this.priceZ,
    required this.priceT,
    required this.priceAdapter,
    required this.priceLlajsne,
    this.pipeLength = 6500,
  });
}

@HiveType(typeId: 2)
class Glass extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  double pricePerM2;
  Glass({required this.name, required this.pricePerM2});
}

@HiveType(typeId: 3)
class Blind extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  double pricePerM2;
  @HiveField(2)
  int boxHeight; // height of the box in mm
  Blind({required this.name, required this.pricePerM2, this.boxHeight = 0});
}

@HiveType(typeId: 4)
class Mechanism extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  double price;
  Mechanism({required this.name, required this.price});
}

@HiveType(typeId: 5)
class Accessory extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  double price;
  Accessory({required this.name, required this.price});
}

@HiveType(typeId: 8)
class ExtraCharge extends HiveObject {
  @HiveField(0)
  String description;
  @HiveField(1)
  double amount;
  ExtraCharge({this.description = '', this.amount = 0});
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
    this.extra1Price,
    this.extra2Price,
    this.extra1Desc,
    this.extra2Desc,
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
        if (!fixedSectors[idx]) {
          final sashW = (w - 90).clamp(0, w);
          final sashH = (h - 90).clamp(0, h);
          sashLength += 2 * (sashW + sashH) / 1000.0 * set.priceZ;
          final beadW = (sashW - 90).clamp(0, sashW);
          final beadH = (sashH - 90).clamp(0, sashH);
          glazingBeadLength +=
              2 * (beadW + beadH) / 1000.0 * set.priceLlajsne;
        } else {
          final beadW = (w - 90).clamp(0, w);
          final beadH = (h - 90).clamp(0, h);
          glazingBeadLength +=
              2 * (beadW + beadH) / 1000.0 * set.priceLlajsne;
        }
      }
    }

    for (int i = 0; i < verticalSections - 1; i++) {
      final len = (effectiveHeight - 80).clamp(0, effectiveHeight);
      if (verticalAdapters[i]) {
        adapterLength += (len / 1000.0) * set.priceAdapter;
      } else {
        tLength += (len / 1000.0) * set.priceT;
      }
    }
    for (int i = 0; i < horizontalSections - 1; i++) {
      final len = (width - 80).clamp(0, width);
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
  double calculateGlassCost(Glass glass, {int boxHeight = 0}) {
    final effectiveHeights = List<int>.from(sectionHeights);
    if (effectiveHeights.isNotEmpty) {
      effectiveHeights[effectiveHeights.length - 1] =
          (effectiveHeights.last - boxHeight).clamp(0, effectiveHeights.last);
    }
    double total = 0;
    for (int r = 0; r < horizontalSections; r++) {
      for (int c = 0; c < verticalSections; c++) {
        final w = sectionWidths[c].toDouble();
        final h = effectiveHeights[r].toDouble();
        final idx = r * verticalSections + c;
        if (!fixedSectors[idx]) {
          final sashW = (w - 90).clamp(0, w);
          final sashH = (h - 90).clamp(0, h);
          final area = ((sashW - 10) / 1000.0) * ((sashH - 10) / 1000.0);
          total += area * glass.pricePerM2;
        } else {
          final effectiveW = (w - 100).clamp(0, w);
          final effectiveH = (h - 100).clamp(0, h);
          final area = (effectiveW / 1000.0) * (effectiveH / 1000.0);
          total += area * glass.pricePerM2;
        }
      }
    }
    return total;
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
