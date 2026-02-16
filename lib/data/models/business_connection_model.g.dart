// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_connection_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BusinessConnectionModelAdapter
    extends TypeAdapter<BusinessConnectionModel> {
  @override
  final int typeId = 4;

  @override
  BusinessConnectionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BusinessConnectionModel(
      id: fields[0] as String,
      providerName: fields[1] as String,
      issuerUrl: fields[2] as String?,
      clientId: fields[3] as String,
      discoveryUrl: fields[4] as String?,
      authEndpoint: fields[5] as String?,
      tokenEndpoint: fields[6] as String?,
      badgeApiEndpoint: fields[7] as String,
      accessToken: fields[8] as String?,
      refreshToken: fields[9] as String?,
      tokenExpiry: fields[10] as DateTime?,
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime,
      logoUrl: fields[13] as String?,
      scopes: (fields[14] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, BusinessConnectionModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.providerName)
      ..writeByte(2)
      ..write(obj.issuerUrl)
      ..writeByte(3)
      ..write(obj.clientId)
      ..writeByte(4)
      ..write(obj.discoveryUrl)
      ..writeByte(5)
      ..write(obj.authEndpoint)
      ..writeByte(6)
      ..write(obj.tokenEndpoint)
      ..writeByte(7)
      ..write(obj.badgeApiEndpoint)
      ..writeByte(8)
      ..write(obj.accessToken)
      ..writeByte(9)
      ..write(obj.refreshToken)
      ..writeByte(10)
      ..write(obj.tokenExpiry)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.logoUrl)
      ..writeByte(14)
      ..write(obj.scopes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BusinessConnectionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
