import 'package:hive/hive.dart';

import '../models.dart';

const String profileSortOrderSettingsKey = 'profileSortOrder';

enum ProfileSortOrder { newest, nameAsc, nameDesc }

ProfileSortOrder profileSortOrderFromStorage(Box settingsBox) {
  final value = settingsBox.get(profileSortOrderSettingsKey) as String?;
  switch (value) {
    case 'nameAsc':
      return ProfileSortOrder.nameAsc;
    case 'nameDesc':
      return ProfileSortOrder.nameDesc;
    case 'newest':
    default:
      return ProfileSortOrder.newest;
  }
}

Future<void> saveProfileSortOrder(
    Box settingsBox, ProfileSortOrder sortOrder) async {
  String value;
  switch (sortOrder) {
    case ProfileSortOrder.nameAsc:
      value = 'nameAsc';
      break;
    case ProfileSortOrder.nameDesc:
      value = 'nameDesc';
      break;
    case ProfileSortOrder.newest:
    default:
      value = 'newest';
      break;
  }
  await settingsBox.put(profileSortOrderSettingsKey, value);
}

List<MapEntry<int, ProfileSet>> getSortedProfileEntries(
    Box<ProfileSet> box, ProfileSortOrder sortOrder) {
  final entries = <MapEntry<int, ProfileSet>>[];
  for (var i = 0; i < box.length; i++) {
    final profile = box.getAt(i);
    if (profile != null) {
      entries.add(MapEntry(i, profile));
    }
  }

  switch (sortOrder) {
    case ProfileSortOrder.nameAsc:
      entries.sort((a, b) =>
          a.value.name.toLowerCase().compareTo(b.value.name.toLowerCase()));
      break;
    case ProfileSortOrder.nameDesc:
      entries.sort((a, b) =>
          b.value.name.toLowerCase().compareTo(a.value.name.toLowerCase()));
      break;
    case ProfileSortOrder.newest:
      break;
  }

  return entries;
}
