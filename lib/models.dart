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
  Customer({required this.name, required this.address, required this.phone, required this.email});
}

// ProfileSet: full profile system (Trocal 88, Salamander, etc)
@HiveType(typeId: 1)
class ProfileSet extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  double priceL;         // Frame
  @HiveField(2)
  double priceZ;         // Sash
  @HiveField(3)
  double priceT;         // Mullion
  @HiveField(4)
  double priceAdapter;   // Adapter (for double sash)
  @HiveField(5)
  double priceLlajsne;   // Glazing bead

  ProfileSet({
    required this.name,
    required this.priceL,
    required this.priceZ,
    required this.priceT,
    required this.priceAdapter,
    required this.priceLlajsne,
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
  Blind({required this.name, required this.pricePerM2});
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

// Window/Door Item in Offer
@HiveType(typeId: 6)
class WindowDoorItem extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  int width;  // in mm
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
    this.manualPrice,
  });

  /// Returns the cost for profiles, given the selected ProfileSet
  double calculateProfileCost(ProfileSet set) {
    double frameLength = 2 * (width + height) / 1000.0 * set.priceL; // in meters
    double sashLength = 0;
    double adapterLength = 0;
    double tLength = 0;
    double glazingBeadLength = 0;
    // For every opening, add a sash. Sash size = (width-90) x (height-90)
    if (openings > 0) {
      double sashW = (width - 90).clamp(0, width).toDouble();
      double sashH = (height - 90).clamp(0, height).toDouble();
      sashLength = openings * 2 * (sashW + sashH) / 1000.0 * set.priceZ;
      // Adapter or T profile for multiple sashes
      if (openings == 2) {
        // For double sash: use adapter (vertical, frame height)
        adapterLength = (height / 1000.0) * set.priceAdapter;
      } else if (openings > 2) {
        // For more than 2 sashes: T profiles, (openings-1) verticals
        tLength = ((openings - 1) * height / 1000.0) * set.priceT;
      }
    }
    if (openings > 0) {
      double sashW = (width - 90).clamp(0, width).toDouble();
      double sashH = (height - 90).clamp(0, height).toDouble();
      // Perimeter of glazing per sash
      glazingBeadLength = openings * 2 * (sashW + sashH) / 1000.0 * set.priceLlajsne;
    } else {
      // Fixed window
      glazingBeadLength = 2 * (width + height - 40) / 1000.0 * set.priceLlajsne;
    }
    return frameLength + sashLength + adapterLength + tLength + glazingBeadLength;
  }

  /// Returns cost for glass, given selected Glass
  double calculateGlassCost(Glass glass) {
    double total = 0;
    if (openings > 0) {
      // For each sash/opening
      double sashW = (width - 90).clamp(0, width).toDouble();
      double sashH = (height - 90).clamp(0, height).toDouble();
      // Glass size per sash: (sashW - 10) x (sashH - 10)
      double area = ((sashW - 10) / 1000.0) * ((sashH - 10) / 1000.0);
      total += openings * area * glass.pricePerM2;
    }
    if (openings == 0) {
      // Fixed section, glass size: (width-20) x (height-20)
      double area = ((width - 20) / 1000.0) * ((height - 20) / 1000.0);
      total += area * glass.pricePerM2;
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
  Offer({
    required this.id,
    required this.customerIndex,
    required this.date,
    required this.items,
    this.profitPercent = 0,
  });
}
