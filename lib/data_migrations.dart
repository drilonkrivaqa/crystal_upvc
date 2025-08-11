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

Future<List<String>> runMigrations() async {
  final failures = <String>[];
  if (!await _migrateCustomers()) {
    failures.add('klientët');
  }
  return failures;
}
