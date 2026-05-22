// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_request_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CallRequestModelAdapter extends TypeAdapter<CallRequestModel> {
  @override
  final int typeId = 2;

  @override
  CallRequestModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CallRequestModel(
      id: fields[0] as String,
      memberId: fields[1] as String,
      trainerId: fields[2] as String,
      requestedAt: fields[3] as DateTime,
      scheduledFor: fields[4] as DateTime,
      note: fields[5] as String,
      status: fields[6] as CallStatus,
      isInstant: fields[7] == null ? false : fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, CallRequestModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.memberId)
      ..writeByte(2)
      ..write(obj.trainerId)
      ..writeByte(3)
      ..write(obj.requestedAt)
      ..writeByte(4)
      ..write(obj.scheduledFor)
      ..writeByte(5)
      ..write(obj.note)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.isInstant);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallRequestModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CallStatusAdapter extends TypeAdapter<CallStatus> {
  @override
  final int typeId = 12;

  @override
  CallStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return CallStatus.pending;
      case 1:
        return CallStatus.approved;
      case 2:
        return CallStatus.declined;
      case 3:
        return CallStatus.cancelled;
      default:
        return CallStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, CallStatus obj) {
    switch (obj) {
      case CallStatus.pending:
        writer.writeByte(0);
        break;
      case CallStatus.approved:
        writer.writeByte(1);
        break;
      case CallStatus.declined:
        writer.writeByte(2);
        break;
      case CallStatus.cancelled:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CallStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
