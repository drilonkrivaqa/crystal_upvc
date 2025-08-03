import 'package:hive/hive.dart';
import 'models.dart';

Future<void> _migrateCustomers() async {
  final box = await Hive.openBox<Customer>('customers');
  for (final key in box.keys) {
    final customer = box.get(key);
    if (customer != null && (customer.email == null)) {
      customer.email = '';
      await customer.save();
    }
  }
}

Future<void> runMigrations() async {
  await _migrateCustomers();
}
