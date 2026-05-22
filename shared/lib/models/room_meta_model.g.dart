// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'room_meta_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RoomMetaModelAdapter extends TypeAdapter<RoomMetaModel> {
  @override
  final int typeId = 4;

  @override
  RoomMetaModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RoomMetaModel(
      id: fields[0] as String,
      callRequestId: fields[1] as String,
      hmsRoomId: fields[2] as String,
      hmsRoleMember: fields[3] as String,
      hmsRoleTrainer: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RoomMetaModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.callRequestId)
      ..writeByte(2)
      ..write(obj.hmsRoomId)
      ..writeByte(3)
      ..write(obj.hmsRoleMember)
      ..writeByte(4)
      ..write(obj.hmsRoleTrainer);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RoomMetaModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
