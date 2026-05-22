import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'session_log_model.g.dart';

@HiveType(typeId: 3)
class SessionLogModel extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String memberId;
  @HiveField(2)
  final String trainerId;
  @HiveField(3)
  final DateTime startedAt;
  @HiveField(4)
  final DateTime endedAt;
  @HiveField(5)
  final int durationSec;
  @HiveField(6)
  final int? rating;
  @HiveField(7)
  final String? trainerNotes;
  @HiveField(8)
  final String? memberNotes;

  const SessionLogModel({
    required this.id,
    required this.memberId,
    required this.trainerId,
    required this.startedAt,
    required this.endedAt,
    required this.durationSec,
    this.rating,
    this.trainerNotes,
    this.memberNotes,
  });

  factory SessionLogModel.fromJson(Map<String, dynamic> json) =>
      SessionLogModel(
        id: json['id'] as String,
        memberId: json['memberId'] as String,
        trainerId: json['trainerId'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        endedAt: DateTime.parse(json['endedAt'] as String),
        durationSec: json['durationSec'] as int,
        rating: json['rating'] as int?,
        trainerNotes: json['trainerNotes'] as String?,
        memberNotes: json['memberNotes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'trainerId': trainerId,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt.toIso8601String(),
        'durationSec': durationSec,
        'rating': rating,
        'trainerNotes': trainerNotes,
        'memberNotes': memberNotes,
      };

  SessionLogModel copyWith({
    String? id,
    String? memberId,
    String? trainerId,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationSec,
    int? rating,
    String? trainerNotes,
    String? memberNotes,
  }) =>
      SessionLogModel(
        id: id ?? this.id,
        memberId: memberId ?? this.memberId,
        trainerId: trainerId ?? this.trainerId,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt ?? this.endedAt,
        durationSec: durationSec ?? this.durationSec,
        rating: rating ?? this.rating,
        trainerNotes: trainerNotes ?? this.trainerNotes,
        memberNotes: memberNotes ?? this.memberNotes,
      );

  @override
  List<Object?> get props => [
        id,
        memberId,
        trainerId,
        startedAt,
        endedAt,
        durationSec,
        rating,
        trainerNotes,
        memberNotes,
      ];
}
