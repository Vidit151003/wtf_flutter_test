import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared/shared.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider(this._authService);

  UserModel? get currentUser => _authService.currentUser;

  bool get isOnboarded {
    try {
      final box = Hive.box<dynamic>('app_prefs');
      return box.get('onboarded', defaultValue: false) == true;
    } catch (_) {
      return false;
    }
  }

  Future<void> createDKProfile(String trainerId) async {
    AppLogger.write(LogTag.auth,
        'createDKProfile called with trainerId=$trainerId');
    await _authService.createProfile(
      name: 'DK',
      role: UserRole.member,
      assignedTrainerId: trainerId,
    );
    notifyListeners();
  }

  Future<void> setOnboarded() async {
    try {
      final box = Hive.box<dynamic>('app_prefs');
      await box.put('onboarded', true);
    } catch (e) {
      AppLogger.write(LogTag.auth, 'setOnboarded error: $e');
    }
    notifyListeners();
  }

  Future<void> logout() async {
    AppLogger.write(LogTag.auth, 'logout called');
    await _authService.logout();
    try {
      final box = Hive.box<dynamic>('app_prefs');
      await box.delete('onboarded');
    } catch (_) {}
    notifyListeners();
  }
}
