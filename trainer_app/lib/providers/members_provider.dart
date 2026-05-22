import 'package:flutter/foundation.dart';
import 'package:shared/shared.dart';

class MembersProvider extends ChangeNotifier {
  /// Hardcoded seed members for demo purposes.
  final List<UserModel> _members = const [
    UserModel(
      id: 'member_001',
      name: 'DK',
      email: 'dk@wtf.com',
      role: UserRole.member,
      assignedTrainerId: 'trainer_001',
    ),
  ];

  List<UserModel> get members => List.unmodifiable(_members);

  int get memberCount => _members.length;

  UserModel? getMember(String id) {
    try {
      return _members.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}
