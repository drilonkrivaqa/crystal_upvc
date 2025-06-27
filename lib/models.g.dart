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
      email: fields[3] as String,
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
    );
  }

  @override
  void write(BinaryWriter writer, ProfileSet obj) {
    writer
      ..writeByte(6)
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
      ..write(obj.priceLlajsne);
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
    );
  }

  @override
  void write(BinaryWriter writer, Glass obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.pricePerM2);
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
    );
  }

  @override
  void write(BinaryWriter writer, Blind obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.pricePerM2);
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
    );
  }

  @override
  void write(BinaryWriter writer, Mechanism obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.price);
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
    );
  }

  @override
  void write(BinaryWriter writer, Accessory obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.price);
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
      manualPrice: fields[11] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, WindowDoorItem obj) {
    writer
      ..writeByte(12)
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
      ..write(obj.manualPrice);
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
      items: (fields[3] as List).cast<WindowDoorItem>(),
      profitPercent: fields[4] as double,
    );
  }

  @override
  void write(BinaryWriter writer, Offer obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.customerIndex)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.items)
      ..writeByte(4)
      ..write(obj.profitPercent);
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
