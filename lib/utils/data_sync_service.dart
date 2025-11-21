import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

import '../models.dart';

class DataSyncService {
  DataSyncService._({
    required this.firestore,
    required this.customerBox,
    required this.offerBox,
    required this.profileSetBox,
    required this.glassBox,
    required this.blindBox,
    required this.mechanismBox,
    required this.accessoryBox,
  }) {
    _channels = [
      _SyncChannel<Customer>(
        collection: 'customers',
        box: customerBox,
        docIdBuilder: (key, value) => key.toString(),
        localKeyResolver: (docId, box) => int.tryParse(docId),
        updatedAt: (value) => value.updatedAt ?? DateTime.now(),
        applyUpdatedAt: (value, date) => value..updatedAt = date,
        toMap: _customerToMap,
        fromMap: _customerFromMap,
      ),
      _SyncChannel<Offer>(
        collection: 'offers',
        box: offerBox,
        docIdBuilder: (_, value) => value.id,
        localKeyResolver: (docId, box) {
          for (final key in box.keys) {
            final offer = box.get(key);
            if (offer is Offer && offer.id == docId) {
              return key;
            }
          }
          return null;
        },
        updatedAt: (value) => value.lastEdited,
        applyUpdatedAt: (value, date) => value..lastEdited = date,
        toMap: _offerToMap,
        fromMap: _offerFromMap,
      ),
    ];
  }

  static DataSyncService? _instance;
  static DataSyncService get instance {
    final current = _instance;
    if (current == null) {
      throw StateError('DataSyncService not initialized');
    }
    return current;
  }

  static Future<DataSyncService> initialize(
    FirebaseFirestore firestore,
  ) async {
    final service = DataSyncService._(
      firestore: firestore,
      customerBox: Hive.box<Customer>('customers'),
      offerBox: Hive.box<Offer>('offers'),
      profileSetBox: Hive.box<ProfileSet>('profileSets'),
      glassBox: Hive.box<Glass>('glasses'),
      blindBox: Hive.box<Blind>('blinds'),
      mechanismBox: Hive.box<Mechanism>('mechanisms'),
      accessoryBox: Hive.box<Accessory>('accessories'),
    );
    _instance = service;
    await service.pullLatest();
    service._attachWatchers();
    return service;
  }

  final FirebaseFirestore firestore;
  final Box<Customer> customerBox;
  final Box<Offer> offerBox;
  final Box<ProfileSet> profileSetBox;
  final Box<Glass> glassBox;
  final Box<Blind> blindBox;
  final Box<Mechanism> mechanismBox;
  final Box<Accessory> accessoryBox;

  late final List<_SyncChannel<dynamic>> _channels;
  final List<StreamSubscription> _subscriptions = [];
  bool _applyingRemote = false;

  Future<void> dispose() async {
    for (final sub in _subscriptions) {
      await sub.cancel();
    }
  }

  Future<void> pullLatest() async {
    for (final channel in _channels) {
      await _syncChannel(channel);
    }
  }

  void _attachWatchers() {
    for (final channel in _channels) {
      final sub = channel.box.watch().listen((event) async {
        if (_applyingRemote) {
          return;
        }
        if (event.deleted) {
          await _pushDeletion(channel, event.key);
          return;
        }
        final value = event.value;
        if (value != null) {
          await _pushUpdate(channel, event.key, value);
        }
      });
      _subscriptions.add(sub);
    }
  }

  Future<void> _syncChannel<T>(_SyncChannel<T> channel) async {
    final snapshot = await firestore.collection(channel.collection).get();
    final remoteDocs = {for (final doc in snapshot.docs) doc.id: doc};

    // Pull remote changes
    for (final entry in remoteDocs.entries) {
      final doc = entry.value;
      final localKey = channel.localKeyResolver(doc.id, channel.box);
      if (localKey == null) continue;
      final remoteValue = channel.fromMap(doc.data());
      final remoteUpdated = _parseDate(doc.data()['updatedAt']) ??
          channel.updatedAt(remoteValue);
      final localValue = channel.box.get(localKey);

      if (localValue == null) {
        _applyingRemote = true;
        channel.applyUpdatedAt(remoteValue, remoteUpdated);
        await channel.box.put(localKey, remoteValue);
        _applyingRemote = false;
        continue;
      }

      final localUpdated = channel.updatedAt(localValue);
      if (remoteUpdated.isAfter(localUpdated)) {
        _applyingRemote = true;
        channel.applyUpdatedAt(remoteValue, remoteUpdated);
        await channel.box.put(localKey, remoteValue);
        _applyingRemote = false;
      } else if (localUpdated.isAfter(remoteUpdated)) {
        await _pushUpdate(channel, localKey, localValue);
      }
    }

    // Push local-only entries
    for (final key in channel.box.keys) {
      final value = channel.box.get(key);
      if (value == null) continue;
      final docId = channel.docIdBuilder(key, value);
      if (remoteDocs.containsKey(docId)) continue;
      await _pushUpdate(channel, key, value);
    }
  }

  Future<void> _pushUpdate<T>(
      _SyncChannel<T> channel, dynamic key, T value) async {
    final docId = channel.docIdBuilder(key, value);
    final payload = channel.toMap(value);
    payload['updatedAt'] = channel.updatedAt(value).toIso8601String();
    await firestore.collection(channel.collection).doc(docId).set(payload);
  }

  Future<void> _pushDeletion<T>(_SyncChannel<T> channel, dynamic key) async {
    final dummyValue = channel.box.get(key);
    final docId = dummyValue != null
        ? channel.docIdBuilder(key, dummyValue)
        : key.toString();
    await firestore.collection(channel.collection).doc(docId).delete();
  }

  Map<String, dynamic> _customerToMap(Customer value) {
    return {
      'name': value.name,
      'address': value.address,
      'phone': value.phone,
      'email': value.email,
    };
  }

  Customer _customerFromMap(Map<String, dynamic> data) {
    return Customer(
      name: data['name'] as String? ?? '',
      address: data['address'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      email: data['email'] as String? ?? '',
      updatedAt: _parseDate(data['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> _offerToMap(Offer value) {
    return {
      'id': value.id,
      'customerIndex': value.customerIndex,
      'date': value.date.toIso8601String(),
      'profitPercent': value.profitPercent,
      'extraCharges': value.extraCharges.map(_extraChargeToMap).toList(),
      'discountPercent': value.discountPercent,
      'discountAmount': value.discountAmount,
      'notes': value.notes,
      'lastEdited': value.lastEdited.toIso8601String(),
      'defaultProfileSetIndex': value.defaultProfileSetIndex,
      'defaultGlassIndex': value.defaultGlassIndex,
      'defaultBlindIndex': value.defaultBlindIndex,
      'offerNumber': value.offerNumber,
      'versions': value.versions.map(_offerVersionToMap).toList(),
      'items': value.items.map(_windowDoorItemToMap).toList(),
    };
  }

  Offer _offerFromMap(Map<String, dynamic> data) {
    return Offer(
      id: data['id'] as String? ?? '',
      customerIndex: data['customerIndex'] as int? ?? 0,
      date: _parseDate(data['date']) ?? DateTime.now(),
      items: _parseList<Map<String, dynamic>>(data['items'])
          .map(_windowDoorItemFromMap)
          .toList(),
      profitPercent: (data['profitPercent'] as num?)?.toDouble() ?? 0,
      extraCharges: _parseList<Map<String, dynamic>>(data['extraCharges'])
          .map(_extraChargeFromMap)
          .toList(),
      discountPercent: (data['discountPercent'] as num?)?.toDouble() ?? 0,
      discountAmount: (data['discountAmount'] as num?)?.toDouble() ?? 0,
      notes: data['notes'] as String? ?? '',
      defaultProfileSetIndex: data['defaultProfileSetIndex'] as int? ?? 0,
      defaultGlassIndex: data['defaultGlassIndex'] as int? ?? 0,
      defaultBlindIndex: data['defaultBlindIndex'] as int? ?? -1,
      versions: _parseList<Map<String, dynamic>>(data['versions'])
          .map(_offerVersionFromMap)
          .toList(),
      lastEdited: _parseDate(data['lastEdited']) ?? DateTime.now(),
      offerNumber: data['offerNumber'] as int? ?? 0,
    );
  }

  Map<String, dynamic> _windowDoorItemToMap(WindowDoorItem value) {
    return {
      'name': value.name,
      'width': value.width,
      'height': value.height,
      'quantity': value.quantity,
      'profileSetIndex': value.profileSetIndex,
      'glassIndex': value.glassIndex,
      'blindIndex': value.blindIndex,
      'mechanismIndex': value.mechanismIndex,
      'accessoryIndex': value.accessoryIndex,
      'openings': value.openings,
      'photoPath': value.photoPath,
      'manualPrice': value.manualPrice,
      'manualBasePrice': value.manualBasePrice,
      'extra1Price': value.extra1Price,
      'extra2Price': value.extra2Price,
      'extra1Desc': value.extra1Desc,
      'extra2Desc': value.extra2Desc,
      'verticalSections': value.verticalSections,
      'horizontalSections': value.horizontalSections,
      'fixedSectors': value.fixedSectors,
      'sectionWidths': value.sectionWidths,
      'sectionHeights': value.sectionHeights,
      'verticalAdapters': value.verticalAdapters,
      'horizontalAdapters': value.horizontalAdapters,
      'photoBytes':
          value.photoBytes != null ? base64Encode(value.photoBytes!) : null,
      'notes': value.notes,
      'perRowVerticalSections': value.perRowVerticalSections,
      'perRowSectionWidths': value.perRowSectionWidths,
      'perRowFixedSectors': value.perRowFixedSectors,
      'perRowVerticalAdapters': value.perRowVerticalAdapters,
    };
  }

  WindowDoorItem _windowDoorItemFromMap(Map<String, dynamic> data) {
    return WindowDoorItem(
      name: data['name'] as String? ?? '',
      width: data['width'] as int? ?? 0,
      height: data['height'] as int? ?? 0,
      quantity: data['quantity'] as int? ?? 0,
      profileSetIndex: data['profileSetIndex'] as int? ?? 0,
      glassIndex: data['glassIndex'] as int? ?? 0,
      blindIndex: data['blindIndex'] as int?,
      mechanismIndex: data['mechanismIndex'] as int?,
      accessoryIndex: data['accessoryIndex'] as int?,
      openings: data['openings'] as int? ?? 0,
      photoPath: data['photoPath'] as String?,
      photoBytes: _decodePhoto(data['photoBytes']),
      manualPrice: (data['manualPrice'] as num?)?.toDouble(),
      manualBasePrice: (data['manualBasePrice'] as num?)?.toDouble(),
      extra1Price: (data['extra1Price'] as num?)?.toDouble(),
      extra2Price: (data['extra2Price'] as num?)?.toDouble(),
      extra1Desc: data['extra1Desc'] as String?,
      extra2Desc: data['extra2Desc'] as String?,
      notes: data['notes'] as String?,
      verticalSections: data['verticalSections'] as int? ?? 1,
      horizontalSections: data['horizontalSections'] as int? ?? 1,
      fixedSectors:
          _parseList<bool>(data['fixedSectors'], fallback: false).toList(),
      sectionWidths: _parseList<int>(data['sectionWidths'], fallback: 0).toList(),
      sectionHeights:
          _parseList<int>(data['sectionHeights'], fallback: 0).toList(),
      verticalAdapters:
          _parseList<bool>(data['verticalAdapters'], fallback: false).toList(),
      horizontalAdapters:
          _parseList<bool>(data['horizontalAdapters'], fallback: false).toList(),
      perRowVerticalSections:
          _parseList<int>(data['perRowVerticalSections']).toList(),
      perRowSectionWidths:
          _parseNestedList<int>(data['perRowSectionWidths']).toList(),
      perRowFixedSectors:
          _parseNestedList<bool>(data['perRowFixedSectors']).toList(),
      perRowVerticalAdapters:
          _parseNestedList<bool>(data['perRowVerticalAdapters']).toList(),
    );
  }

  Map<String, dynamic> _extraChargeToMap(ExtraCharge charge) {
    return {
      'description': charge.description,
      'amount': charge.amount,
    };
  }

  ExtraCharge _extraChargeFromMap(Map<String, dynamic> data) {
    return ExtraCharge(
      description: data['description'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> _offerVersionToMap(OfferVersion version) {
    return {
      'name': version.name,
      'createdAt': version.createdAt.toIso8601String(),
      'items': version.items.map(_windowDoorItemToMap).toList(),
      'profitPercent': version.profitPercent,
      'extraCharges': version.extraCharges.map(_extraChargeToMap).toList(),
      'discountPercent': version.discountPercent,
      'discountAmount': version.discountAmount,
      'notes': version.notes,
      'defaultProfileSetIndex': version.defaultProfileSetIndex,
      'defaultGlassIndex': version.defaultGlassIndex,
      'defaultBlindIndex': version.defaultBlindIndex,
      'customerIndex': version.customerIndex,
    };
  }

  OfferVersion _offerVersionFromMap(Map<String, dynamic> data) {
    return OfferVersion(
      name: data['name'] as String? ?? '',
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      items: _parseList<Map<String, dynamic>>(data['items'])
          .map(_windowDoorItemFromMap)
          .toList(),
      profitPercent: (data['profitPercent'] as num?)?.toDouble() ?? 0,
      extraCharges: _parseList<Map<String, dynamic>>(data['extraCharges'])
          .map(_extraChargeFromMap)
          .toList(),
      discountPercent: (data['discountPercent'] as num?)?.toDouble() ?? 0,
      discountAmount: (data['discountAmount'] as num?)?.toDouble() ?? 0,
      notes: data['notes'] as String? ?? '',
      defaultProfileSetIndex: data['defaultProfileSetIndex'] as int? ?? 0,
      defaultGlassIndex: data['defaultGlassIndex'] as int? ?? 0,
      defaultBlindIndex: data['defaultBlindIndex'] as int? ?? 0,
      customerIndex: data['customerIndex'] as int? ?? 0,
    );
  }

  Uint8List? _decodePhoto(dynamic encoded) {
    if (encoded is String && encoded.isNotEmpty) {
      try {
        return base64Decode(encoded);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  List<T> _parseList<T>(dynamic value, {T? fallback}) {
    if (value is Iterable) {
      return value
          .map((e) => e is T ? e : fallback)
          .whereType<T>()
          .toList();
    }
    return <T>[];
  }

  List<List<T>> _parseNestedList<T>(dynamic value) {
    if (value is Iterable) {
      return value
          .map((row) =>
              (row is Iterable)
                  ? row.whereType<T>().toList()
                  : <T>[])
          .toList();
    }
    return <List<T>>[];
  }
}

class _SyncChannel<T> {
  _SyncChannel({
    required this.collection,
    required this.box,
    required this.docIdBuilder,
    required this.localKeyResolver,
    required this.updatedAt,
    required this.applyUpdatedAt,
    required this.toMap,
    required this.fromMap,
  });

  final String collection;
  final Box<T> box;
  final String Function(dynamic key, T value) docIdBuilder;
  final dynamic Function(String docId, Box<T> box) localKeyResolver;
  final DateTime Function(T value) updatedAt;
  final void Function(T value, DateTime updated) applyUpdatedAt;
  final Map<String, dynamic> Function(T value) toMap;
  final T Function(Map<String, dynamic> data) fromMap;
}
