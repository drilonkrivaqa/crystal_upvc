import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'models.dart';

Future<Box<T>?> _openBoxWithRecovery<T>(String name) async {
  try {
    return await Hive.openBox<T>(name, crashRecovery: true);
  } catch (e) {
    debugPrint('Failed to open box $name: $e');
    return null;
  }
}

Future<bool> _migrateCustomers() async {
  try {
    final box = await _openBoxWithRecovery<Customer>('customers');
    if (box == null) return false;
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
    final box = await _openBoxWithRecovery<ProfileSet>('profileSets');
    if (box == null) return false;
    for (final key in box.keys) {
      final profile = box.get(key);
      if (profile != null) {
        try {
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
          if ((p.pipeLength ?? 0) <= 0) {
            profile.pipeLength = 6500;
            changed = true;
          }
          if ((p.hekriPipeLength ?? 0) <= 0) {
            profile.hekriPipeLength = 6000;
            changed = true;
          }
          if (profile.shtesaOptions == null) {
            profile.shtesaOptions = const [];
            changed = true;
          }
          if (changed) {
            await profile.save();
          }
        } catch (e) {
          debugPrint('Failed to migrate profile set $key: $e');
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
    final box = await _openBoxWithRecovery<Blind>('blinds');
    if (box == null) return false;
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
    final box = await _openBoxWithRecovery<Mechanism>('mechanisms');
    if (box == null) return false;
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
    final box = await _openBoxWithRecovery<Accessory>('accessories');
    if (box == null) return false;
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
    final box = await _openBoxWithRecovery<Offer>('offers');
    final profileBox = await _openBoxWithRecovery<ProfileSet>('profileSets');
    final glassBox = await _openBoxWithRecovery<Glass>('glasses');
    final blindBox = await _openBoxWithRecovery<Blind>('blinds');
    final mechanismBox = await _openBoxWithRecovery<Mechanism>('mechanisms');
    final accessoryBox = await _openBoxWithRecovery<Accessory>('accessories');
    if ([box, profileBox, glassBox, blindBox, mechanismBox, accessoryBox]
        .any((b) => b == null)) {
      return false;
    }

    final offers = box!;
    final profiles = profileBox!;
    final glasses = glassBox!;
    final blinds = blindBox!;
    final mechanisms = mechanismBox!;
    final accessories = accessoryBox!;
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

    int? normalizeOptional(int? value, int length) {
      if (value == null) return null;
      if (length <= 0 || value < 0) return null;
      if (value >= length) return length - 1;
      return value;
    }

    var maxNumber = 0;
    for (final key in offers.keys) {
      final offer = offers.get(key);
      if (offer == null) continue;
      if (offer.offerNumber > maxNumber) {
        maxNumber = offer.offerNumber;
      }
    }
    var nextNumber = maxNumber;
    for (final key in offers.keys) {
      final offer = offers.get(key);
      if (offer == null) continue;
      bool changed = false;
      final normalizedProfile =
          normalize(offer.defaultProfileSetIndex, profiles.length);
      final normalizedGlass =
          normalize(offer.defaultGlassIndex, glasses.length);
      final normalizedBlind = normalize(
          offer.defaultBlindIndex, blinds.length,
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
      ProfileSet? offerProfileSet(int index) {
        if (index < 0 || index >= profiles.length) return null;
        return profiles.getAt(index);
      }
      for (final item in offer.items) {
        final normalizedItemProfile =
            normalize(item.profileSetIndex, profiles.length);
        final normalizedItemGlass = normalize(item.glassIndex, glasses.length);
        final normalizedItemBlind =
            normalizeOptional(item.blindIndex, blinds.length);
        final normalizedItemMechanism =
            normalizeOptional(item.mechanismIndex, mechanisms.length);
        final normalizedItemAccessory =
            normalizeOptional(item.accessoryIndex, accessories.length);

        if (normalizedItemProfile != item.profileSetIndex) {
          item.profileSetIndex = normalizedItemProfile;
          changed = true;
        }
        if (normalizedItemGlass != item.glassIndex) {
          item.glassIndex = normalizedItemGlass;
          changed = true;
        }
        if (normalizedItemBlind != item.blindIndex) {
          item.blindIndex = normalizedItemBlind;
          changed = true;
        }
        if (normalizedItemMechanism != item.mechanismIndex) {
          item.mechanismIndex = normalizedItemMechanism;
          changed = true;
        }
        if (normalizedItemAccessory != item.accessoryIndex) {
          item.accessoryIndex = normalizedItemAccessory;
          changed = true;
        }
        final profile = offerProfileSet(item.profileSetIndex);
        if (profile != null) {
          final normalizedShtesa = item.sanitizeShtesaSelections(profile);
          if (normalizedShtesa != item.shtesaSelections) {
            item.shtesaSelections = normalizedShtesa;
            changed = true;
          }
        }
      }
      for (final version in offer.versions) {
        final normalizedVersionProfile =
            normalize(version.defaultProfileSetIndex, profiles.length);
        final normalizedVersionGlass =
            normalize(version.defaultGlassIndex, glasses.length);
        final normalizedVersionBlind = normalize(
            (version as dynamic).defaultBlindIndex ?? -1, blinds.length,
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
        for (final item in version.items) {
          final normalizedItemProfile =
              normalize(item.profileSetIndex, profiles.length);
          final normalizedItemGlass = normalize(item.glassIndex, glasses.length);
          final normalizedItemBlind =
              normalizeOptional(item.blindIndex, blinds.length);
          final normalizedItemMechanism =
              normalizeOptional(item.mechanismIndex, mechanisms.length);
          final normalizedItemAccessory =
              normalizeOptional(item.accessoryIndex, accessories.length);

          if (normalizedItemProfile != item.profileSetIndex) {
            item.profileSetIndex = normalizedItemProfile;
            changed = true;
          }
          if (normalizedItemGlass != item.glassIndex) {
            item.glassIndex = normalizedItemGlass;
            changed = true;
          }
          if (normalizedItemBlind != item.blindIndex) {
            item.blindIndex = normalizedItemBlind;
            changed = true;
          }
          if (normalizedItemMechanism != item.mechanismIndex) {
            item.mechanismIndex = normalizedItemMechanism;
            changed = true;
          }
          if (normalizedItemAccessory != item.accessoryIndex) {
            item.accessoryIndex = normalizedItemAccessory;
            changed = true;
          }
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
