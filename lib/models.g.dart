// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomerAdapter extends TypeAdapter<Customer> {
  @override
  final int typeId = 0;

  @override
  Customer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Customer(
      name: fields[0] as String,
      address: fields[1] as String,
      phone: fields[2] as String,
      email: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Customer obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.address)
      ..writeByte(2)
      ..write(obj.phone)
      ..writeByte(3)
      ..write(obj.email);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProfileSetAdapter extends TypeAdapter<ProfileSet> {
  @override
  final int typeId = 1;

  @override
  ProfileSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProfileSet(
      name: fields[0] as String,
      priceL: fields[1] as double,
      priceZ: fields[2] as double,
      priceT: fields[3] as double,
      priceAdapter: fields[4] as double,
      priceLlajsne: fields[5] as double,
      pipeLength: fields[6] == null ? 0 : fields[6] as int,
      hekriPipeLength: fields[26] == null ? 6000 : fields[26] as int,
      hekriOffsetL: fields[7] == null ? 0 : fields[7] as int,
      hekriOffsetZ: fields[8] == null ? 0 : fields[8] as int,
      hekriOffsetT: fields[9] == null ? 0 : fields[9] as int,
      massL: fields[10] == null ? 0 : fields[10] as double,
      massZ: fields[11] == null ? 0 : fields[11] as double,
      massT: fields[12] == null ? 0 : fields[12] as double,
      massAdapter: fields[13] == null ? 0 : fields[13] as double,
      massLlajsne: fields[14] == null ? 0 : fields[14] as double,
      lInnerThickness: fields[15] == null ? 0 : fields[15] as int,
      zInnerThickness: fields[16] == null ? 0 : fields[16] as int,
      tInnerThickness: fields[17] == null ? 0 : fields[17] as int,
      fixedGlassTakeoff: fields[18] == null ? 0 : fields[18] as int,
      sashGlassTakeoff: fields[19] == null ? 0 : fields[19] as int,
      sashValue: fields[20] == null ? 0 : fields[20] as int,
      uf: fields[21] == null ? 0 : fields[21] as double?,
      lOuterThickness: fields[22] == null ? 0 : fields[22] as int,
      zOuterThickness: fields[23] == null ? 0 : fields[23] as int,
      tOuterThickness: fields[24] == null ? 0 : fields[24] as int,
      adapterOuterThickness: fields[25] == null ? 0 : fields[25] as int,
      colorIndex: fields[27] == null ? 0 : fields[27] as int,
      customColorValue: fields[28] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ProfileSet obj) {
    writer
      ..writeByte(29)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.priceL)
      ..writeByte(2)
      ..write(obj.priceZ)
      ..writeByte(3)
      ..write(obj.priceT)
      ..writeByte(4)
      ..write(obj.priceAdapter)
      ..writeByte(5)
      ..write(obj.priceLlajsne)
      ..writeByte(6)
      ..write(obj.pipeLength)
      ..writeByte(7)
      ..write(obj.hekriOffsetL)
      ..writeByte(8)
      ..write(obj.hekriOffsetZ)
      ..writeByte(9)
      ..write(obj.hekriOffsetT)
      ..writeByte(10)
      ..write(obj.massL)
      ..writeByte(11)
      ..write(obj.massZ)
      ..writeByte(12)
      ..write(obj.massT)
      ..writeByte(13)
      ..write(obj.massAdapter)
      ..writeByte(14)
      ..write(obj.massLlajsne)
      ..writeByte(15)
      ..write(obj.lInnerThickness)
      ..writeByte(16)
      ..write(obj.zInnerThickness)
      ..writeByte(17)
      ..write(obj.tInnerThickness)
      ..writeByte(18)
      ..write(obj.fixedGlassTakeoff)
      ..writeByte(19)
      ..write(obj.sashGlassTakeoff)
      ..writeByte(20)
      ..write(obj.sashValue)
      ..writeByte(21)
      ..write(obj.uf)
      ..writeByte(22)
      ..write(obj.lOuterThickness)
      ..writeByte(23)
      ..write(obj.zOuterThickness)
      ..writeByte(24)
      ..write(obj.tOuterThickness)
      ..writeByte(25)
      ..write(obj.adapterOuterThickness)
      ..writeByte(26)
      ..write(obj.hekriPipeLength)
      ..writeByte(27)
      ..write(obj.colorIndex)
      ..writeByte(28)
      ..write(obj.customColorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfileSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GlassAdapter extends TypeAdapter<Glass> {
  @override
  final int typeId = 2;

  @override
  Glass read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Glass(
      name: fields[0] as String,
      pricePerM2: fields[1] as double,
      massPerM2: fields[2] == null ? 0 : fields[2] as double,
      ug: fields[3] == null ? 0 : fields[3] as double?,
      psi: fields[4] == null ? 0 : fields[4] as double?,
      colorIndex: fields[5] == null ? 0 : fields[5] as int,
      customColorValue: fields[6] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Glass obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.pricePerM2)
      ..writeByte(2)
      ..write(obj.massPerM2)
      ..writeByte(3)
      ..write(obj.ug)
      ..writeByte(4)
      ..write(obj.psi)
      ..writeByte(5)
      ..write(obj.colorIndex)
      ..writeByte(6)
      ..write(obj.customColorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GlassAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BlindAdapter extends TypeAdapter<Blind> {
  @override
  final int typeId = 3;

  @override
  Blind read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Blind(
      name: fields[0] as String,
      pricePerM2: fields[1] as double,
      boxHeight: fields[2] == null ? 0 : fields[2] as int,
      massPerM2: fields[3] == null ? 0 : fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Blind obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.pricePerM2)
      ..writeByte(2)
      ..write(obj.boxHeight)
      ..writeByte(3)
      ..write(obj.massPerM2);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlindAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MechanismAdapter extends TypeAdapter<Mechanism> {
  @override
  final int typeId = 4;

  @override
  Mechanism read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Mechanism(
      name: fields[0] as String,
      price: fields[1] as double,
      mass: fields[2] == null ? 0 : fields[2] as double,
      minWidth: fields[3] == null ? 0 : fields[3] as int,
      maxWidth: fields[4] == null ? 0 : fields[4] as int,
      minHeight: fields[5] == null ? 0 : fields[5] as int,
      maxHeight: fields[6] == null ? 0 : fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Mechanism obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.price)
      ..writeByte(2)
      ..write(obj.mass)
      ..writeByte(3)
      ..write(obj.minWidth)
      ..writeByte(4)
      ..write(obj.maxWidth)
      ..writeByte(5)
      ..write(obj.minHeight)
      ..writeByte(6)
      ..write(obj.maxHeight);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MechanismAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AccessoryAdapter extends TypeAdapter<Accessory> {
  @override
  final int typeId = 5;

  @override
  Accessory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Accessory(
      name: fields[0] as String,
      price: fields[1] as double,
      mass: fields[2] == null ? 0 : fields[2] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Accessory obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.price)
      ..writeByte(2)
      ..write(obj.mass);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccessoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExtraChargeAdapter extends TypeAdapter<ExtraCharge> {
  @override
  final int typeId = 8;

  @override
  ExtraCharge read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExtraCharge(
      description: fields[0] as String,
      amount: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, ExtraCharge obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.description)
      ..writeByte(1)
      ..write(obj.amount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtraChargeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WindowDoorItemAdapter extends TypeAdapter<WindowDoorItem> {
  @override
  final int typeId = 6;

  @override
  WindowDoorItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WindowDoorItem(
      name: fields[0] as String,
      width: fields[1] as int,
      height: fields[2] as int,
      quantity: fields[3] as int,
      profileSetIndex: fields[4] as int,
      glassIndex: fields[5] as int,
      blindIndex: fields[6] as int?,
      mechanismIndex: fields[7] as int?,
      accessoryIndex: fields[8] as int?,
      openings: fields[9] as int,
      photoPath: fields[10] as String?,
      photoBytes: fields[23] as Uint8List?,
      manualPrice: fields[11] as double?,
      manualBasePrice: fields[25] as double?,
      extra1Price: fields[12] as double?,
      extra2Price: fields[13] as double?,
      extra1Desc: fields[14] as String?,
      extra2Desc: fields[15] as String?,
      notes: fields[24] as String?,
      verticalSections: fields[16] as int,
      horizontalSections: fields[17] as int,
      fixedSectors: (fields[18] as List?)?.cast<bool>(),
      sectionWidths: (fields[19] as List?)?.cast<int>(),
      sectionHeights: (fields[20] as List?)?.cast<int>(),
      verticalAdapters: (fields[21] as List?)?.cast<bool>(),
      horizontalAdapters: (fields[22] as List?)?.cast<bool>(),
      perRowVerticalSections: (fields[26] as List?)?.cast<int>(),
      perRowSectionWidths: (fields[27] as List?)
          ?.map<List<int>>((dynamic row) => (row as List).cast<int>())
          .toList(),
      perRowFixedSectors: (fields[28] as List?)
          ?.map<List<bool>>((dynamic row) => (row as List).cast<bool>())
          .toList(),
      perRowVerticalAdapters: (fields[29] as List?)
          ?.map<List<bool>>((dynamic row) => (row as List).cast<bool>())
          .toList(),
    );
  }

  @override
  void write(BinaryWriter writer, WindowDoorItem obj) {
    writer
      ..writeByte(30)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.width)
      ..writeByte(2)
      ..write(obj.height)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.profileSetIndex)
      ..writeByte(5)
      ..write(obj.glassIndex)
      ..writeByte(6)
      ..write(obj.blindIndex)
      ..writeByte(7)
      ..write(obj.mechanismIndex)
      ..writeByte(8)
      ..write(obj.accessoryIndex)
      ..writeByte(9)
      ..write(obj.openings)
      ..writeByte(10)
      ..write(obj.photoPath)
      ..writeByte(11)
      ..write(obj.manualPrice)
      ..writeByte(25)
      ..write(obj.manualBasePrice)
      ..writeByte(12)
      ..write(obj.extra1Price)
      ..writeByte(13)
      ..write(obj.extra2Price)
      ..writeByte(14)
      ..write(obj.extra1Desc)
      ..writeByte(15)
      ..write(obj.extra2Desc)
      ..writeByte(16)
      ..write(obj.verticalSections)
      ..writeByte(17)
      ..write(obj.horizontalSections)
      ..writeByte(18)
      ..write(obj.fixedSectors)
      ..writeByte(19)
      ..write(obj.sectionWidths)
      ..writeByte(20)
      ..write(obj.sectionHeights)
      ..writeByte(21)
      ..write(obj.verticalAdapters)
      ..writeByte(22)
      ..write(obj.horizontalAdapters)
      ..writeByte(23)
      ..write(obj.photoBytes)
      ..writeByte(24)
      ..write(obj.notes)
      ..writeByte(26)
      ..write(obj.perRowVerticalSections)
      ..writeByte(27)
      ..write(obj.perRowSectionWidths)
      ..writeByte(28)
      ..write(obj.perRowFixedSectors)
      ..writeByte(29)
      ..write(obj.perRowVerticalAdapters);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WindowDoorItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OfferAdapter extends TypeAdapter<Offer> {
  @override
  final int typeId = 7;

  @override
  Offer read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Offer(
      id: fields[0] as String,
      customerIndex: fields[1] as int,
      date: fields[2] as DateTime,
      items:
          fields[3] == null ? [] : (fields[3] as List).cast<WindowDoorItem>(),
      profitPercent: fields[4] == null ? 0 : fields[4] as double,
      extraCharges:
          fields[5] == null ? [] : (fields[5] as List?)?.cast<ExtraCharge>(),
      discountPercent: fields[6] == null ? 0 : fields[6] as double,
      discountAmount: fields[7] == null ? 0 : fields[7] as double,
      notes: fields[8] == null ? '' : fields[8] as String,
      lastEdited: fields[9] as DateTime?,
      defaultProfileSetIndex: fields[10] == null ? 0 : fields[10] as int,
      defaultGlassIndex: fields[11] == null ? 0 : fields[11] as int,
      versions:
          fields[12] == null ? [] : (fields[12] as List).cast<OfferVersion>(),
      offerNumber: fields[13] == null ? 0 : fields[13] as int,
      defaultBlindIndex: fields[14] == null ? -1 : fields[14] as int,
      status: fields[15] == null ? OfferStatus.draft : fields[15] as String,
      statusChangedAt: fields[16] as DateTime?,
      acceptedAt: fields[17] as DateTime?,
      acceptedBy: fields[18] == null ? '' : fields[18] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Offer obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerIndex)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.items)
      ..writeByte(4)
      ..write(obj.profitPercent)
      ..writeByte(5)
      ..write(obj.extraCharges)
      ..writeByte(6)
      ..write(obj.discountPercent)
      ..writeByte(7)
      ..write(obj.discountAmount)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.lastEdited)
      ..writeByte(10)
      ..write(obj.defaultProfileSetIndex)
      ..writeByte(11)
      ..write(obj.defaultGlassIndex)
      ..writeByte(12)
      ..write(obj.versions)
      ..writeByte(13)
      ..write(obj.offerNumber)
      ..writeByte(14)
      ..write(obj.defaultBlindIndex)
      ..writeByte(15)
      ..write(obj.status)
      ..writeByte(16)
      ..write(obj.statusChangedAt)
      ..writeByte(17)
      ..write(obj.acceptedAt)
      ..writeByte(18)
      ..write(obj.acceptedBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfferAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OfferVersionAdapter extends TypeAdapter<OfferVersion> {
  @override
  final int typeId = 9;

  @override
  OfferVersion read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfferVersion(
      name: fields[0] as String,
      createdAt: fields[1] as DateTime?,
      items:
          fields[2] == null ? [] : (fields[2] as List).cast<WindowDoorItem>(),
      profitPercent: fields[3] == null ? 0 : fields[3] as double,
      extraCharges:
          fields[4] == null ? [] : (fields[4] as List).cast<ExtraCharge>(),
      discountPercent: fields[5] == null ? 0 : fields[5] as double,
      discountAmount: fields[6] == null ? 0 : fields[6] as double,
      notes: fields[7] == null ? '' : fields[7] as String,
      defaultProfileSetIndex: fields[8] == null ? 0 : fields[8] as int,
      defaultGlassIndex: fields[9] == null ? 0 : fields[9] as int,
      defaultBlindIndex: fields[10] == null ? -1 : fields[10] as int,
      customerIndex: fields[11] == null ? 0 : fields[11] as int,
      status: fields[12] == null ? OfferStatus.draft : fields[12] as String,
      note: fields[13] == null ? '' : fields[13] as String,
      createdBy: fields[14] == null ? '' : fields[14] as String,
    );
  }

  @override
  void write(BinaryWriter writer, OfferVersion obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.createdAt)
      ..writeByte(2)
      ..write(obj.items)
      ..writeByte(3)
      ..write(obj.profitPercent)
      ..writeByte(4)
      ..write(obj.extraCharges)
      ..writeByte(5)
      ..write(obj.discountPercent)
      ..writeByte(6)
      ..write(obj.discountAmount)
      ..writeByte(7)
      ..write(obj.notes)
      ..writeByte(8)
      ..write(obj.defaultProfileSetIndex)
      ..writeByte(9)
      ..write(obj.defaultGlassIndex)
      ..writeByte(10)
      ..write(obj.defaultBlindIndex)
      ..writeByte(11)
      ..write(obj.customerIndex)
      ..writeByte(12)
      ..write(obj.status)
      ..writeByte(13)
      ..write(obj.note)
      ..writeByte(14)
      ..write(obj.createdBy);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfferVersionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
