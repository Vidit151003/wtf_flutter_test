import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'room_meta_model.g.dart';

@HiveType(typeId: 4)
class RoomMetaModel extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String callRequestId;
  @HiveField(2)
  final String hmsRoomId;
  @HiveField(3)
  final String hmsRoleMember;
  @HiveField(4)
  final String hmsRoleTrainer;

  const RoomMetaModel({
    required this.id,
    required this.callRequestId,
    required this.hmsRoomId,
    required this.hmsRoleMember,
    required this.hmsRoleTrainer,
  });

  factory RoomMetaModel.fromJson(Map<String, dynamic> json) => RoomMetaModel(
        id: json['id'] as String,
        callRequestId: json['callRequestId'] as String,
        hmsRoomId: json['hmsRoomId'] as String,
        hmsRoleMember: json['hmsRoleMember'] as String,
        hmsRoleTrainer: json['hmsRoleTrainer'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'callRequestId': callRequestId,
        'hmsRoomId': hmsRoomId,
        'hmsRoleMember': hmsRoleMember,
        'hmsRoleTrainer': hmsRoleTrainer,
      };

  RoomMetaModel copyWith({
    String? id,
    String? callRequestId,
    String? hmsRoomId,
    String? hmsRoleMember,
    String? hmsRoleTrainer,
  }) =>
      RoomMetaModel(
        id: id ?? this.id,
        callRequestId: callRequestId ?? this.callRequestId,
        hmsRoomId: hmsRoomId ?? this.hmsRoomId,
        hmsRoleMember: hmsRoleMember ?? this.hmsRoleMember,
        hmsRoleTrainer: hmsRoleTrainer ?? this.hmsRoleTrainer,
      );

  @override
  List<Object?> get props =>
      [id, callRequestId, hmsRoomId, hmsRoleMember, hmsRoleTrainer];
}
