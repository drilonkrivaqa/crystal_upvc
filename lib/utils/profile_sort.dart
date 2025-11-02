import 'package:hive/hive.dart';

import '../models.dart';

const String kProfileSortOrderKey = 'profileSortOrder';

enum ProfileSortOption { nameAsc, nameDesc, createdDesc, createdAsc }

ProfileSortOption profileSortOptionFromString(String? value) {
  if (value == null) {
    return ProfileSortOption.createdAsc;
  }
  return ProfileSortOption.values.firstWhere(
    (option) => option.name == value,
    orElse: () => ProfileSortOption.createdAsc,
  );
}

List<MapEntry<int, ProfileSet>> sortedProfileEntries(
  Box<ProfileSet> box,
  ProfileSortOption option,
) {
  final entries = <MapEntry<int, ProfileSet>>[];
  for (var i = 0; i < box.length; i++) {
    final profile = box.getAt(i);
    if (profile != null) {
      entries.add(MapEntry(i, profile));
    }
  }

  int compareNames(ProfileSet a, ProfileSet b) {
    final nameA = a.name.toLowerCase();
    final nameB = b.name.toLowerCase();
    final result = nameA.compareTo(nameB);
    if (result != 0) {
      return result;
    }
    return a.name.compareTo(b.name);
  }

  DateTime createdOrEpoch(ProfileSet profile) {
    return profile.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  entries.sort((a, b) {
    switch (option) {
      case ProfileSortOption.nameAsc:
        final result = compareNames(a.value, b.value);
        if (result != 0) return result;
        return a.key.compareTo(b.key);
      case ProfileSortOption.nameDesc:
        final result = compareNames(b.value, a.value);
        if (result != 0) return result;
        return a.key.compareTo(b.key);
      case ProfileSortOption.createdDesc:
        final result = createdOrEpoch(b.value).compareTo(createdOrEpoch(a.value));
        if (result != 0) return result;
        return compareNames(a.value, b.value);
      case ProfileSortOption.createdAsc:
        final result = createdOrEpoch(a.value).compareTo(createdOrEpoch(b.value));
        if (result != 0) return result;
        return compareNames(a.value, b.value);
    }
  });

  return entries;
}
