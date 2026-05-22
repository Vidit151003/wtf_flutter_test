import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 10)
enum UserRole {
  @HiveField(0)
  trainer,
  @HiveField(1)
  member,
}

@HiveType(typeId: 0)
class UserModel extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String email;
  @HiveField(3)
  final UserRole role;
  @HiveField(4)
  final String? avatarUrl;
  @HiveField(5)
  final String? assignedTrainerId;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.assignedTrainerId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: UserRole.values.firstWhere((e) => e.name == json['role']),
        avatarUrl: json['avatarUrl'] as String?,
        assignedTrainerId: json['assignedTrainerId'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'avatarUrl': avatarUrl,
        'assignedTrainerId': assignedTrainerId,
      };

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? avatarUrl,
    String? assignedTrainerId,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        role: role ?? this.role,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        assignedTrainerId: assignedTrainerId ?? this.assignedTrainerId,
      );

  @override
  List<Object?> get props =>
      [id, name, email, role, avatarUrl, assignedTrainerId];
}
