// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SessionLogModelAdapter extends TypeAdapter<SessionLogModel> {
  @override
  final int typeId = 3;

  @override
  SessionLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SessionLogModel(
      id: fields[0] as String,
      memberId: fields[1] as String,
      trainerId: fields[2] as String,
      startedAt: fields[3] as DateTime,
      endedAt: fields[4] as DateTime,
      durationSec: fields[5] as int,
      rating: fields[6] as int?,
      trainerNotes: fields[7] as String?,
      memberNotes: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SessionLogModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.memberId)
      ..writeByte(2)
      ..write(obj.trainerId)
      ..writeByte(3)
      ..write(obj.startedAt)
      ..writeByte(4)
      ..write(obj.endedAt)
      ..writeByte(5)
      ..write(obj.durationSec)
      ..writeByte(6)
      ..write(obj.rating)
      ..writeByte(7)
      ..write(obj.trainerNotes)
      ..writeByte(8)
      ..write(obj.memberNotes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
