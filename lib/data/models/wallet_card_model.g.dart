// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_card_model.dart';

class WalletCardModelAdapter extends TypeAdapter<WalletCardModel> {
  @override
  final int typeId = 3;

  @override
  WalletCardModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WalletCardModel(
      id: fields[0] as String,
      name: fields[1] as String,
      nickname: fields[2] as String?,
      cardTypeIndex: fields[3] as int,
      frontImagePath: fields[4] as String,
      backImagePath: fields[5] as String?,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
      extractedData: (fields[8] as Map?)?.cast<String, dynamic>(),
      notes: fields[9] as String?,
      displayOrder: fields[10] as int,
      categoryIndex: (fields[11] as int?) ?? 0,
      displayFormatIndex: (fields[12] as int?) ?? 0,
      hasBarcode: fields[13] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, WalletCardModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.nickname)
      ..writeByte(3)
      ..write(obj.cardTypeIndex)
      ..writeByte(4)
      ..write(obj.frontImagePath)
      ..writeByte(5)
      ..write(obj.backImagePath)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.extractedData)
      ..writeByte(9)
      ..write(obj.notes)
      ..writeByte(10)
      ..write(obj.displayOrder)
      ..writeByte(11)
      ..write(obj.categoryIndex)
      ..writeByte(12)
      ..write(obj.displayFormatIndex)
      ..writeByte(13)
      ..write(obj.hasBarcode);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletCardModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
