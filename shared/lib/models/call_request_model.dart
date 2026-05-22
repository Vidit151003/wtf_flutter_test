import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'call_request_model.g.dart';

@HiveType(typeId: 12)
enum CallStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  approved,
  @HiveField(2)
  declined,
  @HiveField(3)
  cancelled,
}

@HiveType(typeId: 2)
class CallRequestModel extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String memberId;
  @HiveField(2)
  final String trainerId;
  @HiveField(3)
  final DateTime requestedAt;
  @HiveField(4)
  final DateTime scheduledFor;
  @HiveField(5)
  final String note;
  @HiveField(6)
  final CallStatus status;
  @HiveField(7)
  final bool isInstant;

  const CallRequestModel({
    required this.id,
    required this.memberId,
    required this.trainerId,
    required this.requestedAt,
    required this.scheduledFor,
    required this.note,
    required this.status,
    this.isInstant = false,
  });

  factory CallRequestModel.fromJson(Map<String, dynamic> json) =>
      CallRequestModel(
        id: json['id'] as String,
        memberId: json['memberId'] as String,
        trainerId: json['trainerId'] as String,
        requestedAt: DateTime.parse(json['requestedAt'] as String),
        scheduledFor: DateTime.parse(json['scheduledFor'] as String),
        note: json['note'] as String,
        status: CallStatus.values
            .firstWhere((e) => e.name == json['status']),
        isInstant: (json['isInstant'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'trainerId': trainerId,
        'requestedAt': requestedAt.toIso8601String(),
        'scheduledFor': scheduledFor.toIso8601String(),
        'note': note,
        'status': status.name,
        'isInstant': isInstant,
      };

  CallRequestModel copyWith({
    String? id,
    String? memberId,
    String? trainerId,
    DateTime? requestedAt,
    DateTime? scheduledFor,
    String? note,
    CallStatus? status,
    bool? isInstant,
  }) =>
      CallRequestModel(
        id: id ?? this.id,
        memberId: memberId ?? this.memberId,
        trainerId: trainerId ?? this.trainerId,
        requestedAt: requestedAt ?? this.requestedAt,
        scheduledFor: scheduledFor ?? this.scheduledFor,
        note: note ?? this.note,
        status: status ?? this.status,
        isInstant: isInstant ?? this.isInstant,
      );

  @override
  List<Object?> get props =>
      [id, memberId, trainerId, requestedAt, scheduledFor, note, status, isInstant];
}
