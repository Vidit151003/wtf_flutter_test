import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared/shared.dart';

class TrainerAuthProvider extends ChangeNotifier {
  static const String _boxName = 'prefs_box';
  static const String _userKey = 'current_user';

  final AuthService _authService;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  TrainerAuthProvider(this._authService) {
    _restoreSession();
  }

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _restoreSession() {
    try {
      final box = Hive.box(_boxName);
      final stored = box.get(_userKey);
      if (stored is UserModel) {
        _currentUser = stored;
        AppLogger.write(LogTag.auth, 'Trainer session restored: ${stored.email}');
        notifyListeners();
      }
    } catch (e) {
      AppLogger.write(LogTag.auth, 'Trainer restore session error: $e');
    }
  }

  /// Login accepts any email for demo; always returns the seed trainer (Aarav).
  Future<void> login(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Always log in as the trainer seed user for demo purposes
      final user = await _authService.login('aarav@wtf.com');
      if (user != null) {
        _currentUser = user;
        try {
          final box = Hive.box(_boxName);
          await box.put(_userKey, user);
        } catch (_) {}
        AppLogger.write(LogTag.auth, 'Trainer login success: ${user.id}');
      } else {
        _error = 'Login failed. Please try again.';
      }
    } catch (e) {
      _error = 'An error occurred: $e';
      AppLogger.write(LogTag.auth, 'Trainer login error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authService.logout();
      _currentUser = null;
      try {
        final box = Hive.box(_boxName);
        await box.delete(_userKey);
      } catch (_) {}
      AppLogger.write(LogTag.auth, 'Trainer logged out');
    } catch (e) {
      AppLogger.write(LogTag.auth, 'Trainer logout error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
