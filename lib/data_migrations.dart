import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'models.dart';

Future<bool> _migrateCustomers() async {
  try {
    final box = await Hive.openBox<Customer>('customers');
    for (final key in box.keys) {
      final customer = box.get(key);
      if (customer != null && (customer.email == null)) {
        customer.email = '';
        await customer.save();
      }
    }
    return true;
  } catch (e) {
    debugPrint('Failed to migrate customers: $e');
    return false;
  }
}

Future<bool> _migrateProfileSets() async {
  try {
    final box = await Hive.openBox<ProfileSet>('profileSets');
    for (final key in box.keys) {
      final profile = box.get(key);
      if (profile != null) {
        bool changed = false;
        final p = profile as dynamic;
        if (p.massL == null) {
          profile.massL = 0;
          changed = true;
        }
        if (p.massZ == null) {
          profile.massZ = 0;
          changed = true;
        }
        if (p.massT == null) {
          profile.massT = 0;
          changed = true;
        }
        if (p.massAdapter == null) {
          profile.massAdapter = 0;
          changed = true;
        }
        if (p.massLlajsne == null) {
          profile.massLlajsne = 0;
          changed = true;
        }
        if (p.lOuterThickness == null) {
          profile.lOuterThickness = 0;
          changed = true;
        }
        if (p.zOuterThickness == null) {
          profile.zOuterThickness = 0;
          changed = true;
        }
        if (p.tOuterThickness == null) {
          profile.tOuterThickness = 0;
          changed = true;
        }
        if (p.adapterOuterThickness == null) {
          profile.adapterOuterThickness = 0;
          changed = true;
        }
        if (p.shtesaOptions == null) {
          profile.shtesaOptions = [];
          changed = true;
        }
        if (changed) {
          await profile.save();
        }
      }
    }
    return true;
  } catch (e) {
    debugPrint('Failed to migrate profile sets: $e');
    return false;
  }
}

Future<bool> _migrateBlinds() async {
  try {
    final box = await Hive.openBox<Blind>('blinds');
    for (final key in box.keys) {
      final blind = box.get(key);
      if (blind != null) {
        bool changed = false;
        final b = blind as dynamic;
        if (b.boxHeight == null) {
          blind.boxHeight = 0;
          changed = true;
        }
        if (b.massPerM2 == null) {
          blind.massPerM2 = 0;
          changed = true;
        }
        if (changed) {
          await blind.save();
        }
      }
    }
    return true;
  } catch (e) {
    debugPrint('Failed to migrate blinds: $e');
    return false;
  }
}

Future<bool> _migrateMechanisms() async {
  try {
    final box = await Hive.openBox<Mechanism>('mechanisms');
    for (final key in box.keys) {
      final mechanism = box.get(key);
      if (mechanism != null) {
        final m = mechanism as dynamic;
        if (m.mass == null) {
          mechanism.mass = 0;
          await mechanism.save();
        }
      }
    }
    return true;
  } catch (e) {
    debugPrint('Failed to migrate mechanisms: $e');
    return false;
  }
}

Future<bool> _migrateAccessories() async {
  try {
    final box = await Hive.openBox<Accessory>('accessories');
    for (final key in box.keys) {
      final accessory = box.get(key);
      if (accessory != null) {
        final a = accessory as dynamic;
        if (a.mass == null) {
          accessory.mass = 0;
          await accessory.save();
        }
      }
    }
    return true;
  } catch (e) {
    debugPrint('Failed to migrate accessories: $e');
    return false;
  }
}

Future<bool> _migrateOffers() async {
  try {
    final box = await Hive.openBox<Offer>('offers');
    final profileBox = await Hive.openBox<ProfileSet>('profileSets');
    final glassBox = await Hive.openBox<Glass>('glasses');
    final blindBox = await Hive.openBox<Blind>('blinds');
    int normalize(int value, int length, {bool allowNegative = false}) {
      if (length <= 0) {
        return allowNegative ? -1 : 0;
      }
      if (value < 0) {
        return allowNegative ? -1 : 0;
      }
      if (value >= length) {
        return length - 1;
      }
      return value;
    }

    var maxNumber = 0;
    for (final key in box.keys) {
      final offer = box.get(key);
      if (offer == null) continue;
      if (offer.offerNumber > maxNumber) {
        maxNumber = offer.offerNumber;
      }
    }
    var nextNumber = maxNumber;
    for (final key in box.keys) {
      final offer = box.get(key);
      if (offer == null) continue;
      bool changed = false;
      final normalizedProfile =
          normalize(offer.defaultProfileSetIndex, profileBox.length);
      final normalizedGlass =
          normalize(offer.defaultGlassIndex, glassBox.length);
      final normalizedBlind = normalize(
          offer.defaultBlindIndex, blindBox.length,
          allowNegative: true);
      if (normalizedProfile != offer.defaultProfileSetIndex) {
        offer.defaultProfileSetIndex = normalizedProfile;
        changed = true;
      }
      if (normalizedGlass != offer.defaultGlassIndex) {
        offer.defaultGlassIndex = normalizedGlass;
        changed = true;
      }
      if ((offer as dynamic).defaultBlindIndex == null ||
          normalizedBlind != offer.defaultBlindIndex) {
        offer.defaultBlindIndex = normalizedBlind;
        changed = true;
      }
      for (final version in offer.versions) {
        final normalizedVersionProfile =
            normalize(version.defaultProfileSetIndex, profileBox.length);
        final normalizedVersionGlass =
            normalize(version.defaultGlassIndex, glassBox.length);
        final normalizedVersionBlind = normalize(
            (version as dynamic).defaultBlindIndex ?? -1, blindBox.length,
            allowNegative: true);
        if (normalizedVersionProfile != version.defaultProfileSetIndex) {
          version.defaultProfileSetIndex = normalizedVersionProfile;
          changed = true;
        }
        if (normalizedVersionGlass != version.defaultGlassIndex) {
          version.defaultGlassIndex = normalizedVersionGlass;
          changed = true;
        }
        if (normalizedVersionBlind != version.defaultBlindIndex) {
          version.defaultBlindIndex = normalizedVersionBlind;
          changed = true;
        }
      }
      if (offer.offerNumber <= 0) {
        nextNumber += 1;
        offer
          ..offerNumber = nextNumber
          ..lastEdited = offer.lastEdited
          ..save();
        continue;
      }
      if (changed) {
        offer
          ..lastEdited = offer.lastEdited
          ..save();
      }
    }
    return true;
  } catch (e) {
    debugPrint('Failed to migrate offers: $e');
    return false;
  }
}

Future<List<String>> runMigrations() async {
  final failures = <String>[];
  if (!await _migrateCustomers()) {
    failures.add('customers');
  }
  if (!await _migrateProfileSets()) {
    failures.add('profiles');
  }
  if (!await _migrateBlinds()) {
    failures.add('blinds');
  }
  if (!await _migrateMechanisms()) {
    failures.add('mechanisms');
  }
  if (!await _migrateAccessories()) {
    failures.add('accessories');
  }
  if (!await _migrateOffers()) {
    failures.add('offers');
  }
  return failures;
}
