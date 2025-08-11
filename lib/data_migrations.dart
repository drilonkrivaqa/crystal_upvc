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

Future<bool> _migrateGlasses() async {
  try {
    final box = await Hive.openBox<Glass>('glasses');
    for (final key in box.keys) {
      final glass = box.get(key);
      bool updated = false;
      if (glass != null) {
        if (glass.ug == null) {
          glass.ug = 0;
          updated = true;
        }
        if (glass.psi == null) {
          glass.psi = 0;
          updated = true;
        }
        if (updated) {
          await glass.save();
        }
      }
    }
    return true;
  } catch (e) {
    debugPrint('Failed to migrate glasses: $e');
    return false;
  }
}

Future<bool> _migrateOffers() async {
  try {
    final box = await Hive.openBox<Offer>('offers');
    for (final key in box.keys) {
      final offer = box.get(key);
      bool updated = false;
      if (offer != null) {
        final dynOffer = offer as dynamic;
        if (dynOffer.extraCharges == null) {
          offer.extraCharges = [];
          updated = true;
        }
        if (dynOffer.discountPercent == null) {
          offer.discountPercent = 0;
          updated = true;
        }
        if (dynOffer.discountAmount == null) {
          offer.discountAmount = 0;
          updated = true;
        }
        if (dynOffer.notes == null) {
          offer.notes = '';
          updated = true;
        }
        if (dynOffer.lastEdited == null) {
          offer.lastEdited = offer.date;
          updated = true;
        }
        if (updated) {
          await offer.save();
        }
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
    failures.add('klientët');
  }
  if (!await _migrateGlasses()) {
    failures.add('xhamat');
  }
  if (!await _migrateOffers()) {
    failures.add('ofertat');
  }
  return failures;
}
