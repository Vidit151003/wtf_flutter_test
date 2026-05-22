import 'dart:async';

import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../models/user_model.dart';
import '../utils/app_logger.dart';

// ─── Abstract interface ───────────────────────────────────────────────────────

abstract class AuthService {
  /// Attempts to log in using the given [email].
  /// Returns the matching [UserModel] or null if no match is found.
  Future<UserModel?> login(String email);

  /// Creates and persists a new user profile.
  Future<UserModel> createProfile({
    required String name,
    required UserRole role,
    String? assignedTrainerId,
  });

  /// Logs out the current user.
  Future<void> logout();

  /// The currently authenticated user, or null if unauthenticated.
  UserModel? get currentUser;

  /// A stream that emits the current user whenever auth state changes.
  Stream<UserModel?> get authStateChanges;
}

// ─── Seed data ────────────────────────────────────────────────────────────────

const _seedUsers = [
  {
    'id': 'trainer_001',
    'name': 'Aarav',
    'email': 'aarav@wtf.com',
    'role': 'trainer',
    'avatarUrl': null,
    'assignedTrainerId': null,
  },
  {
    'id': 'member_001',
    'name': 'DK',
    'email': 'dk@wtf.com',
    'role': 'member',
    'avatarUrl': null,
    'assignedTrainerId': 'trainer_001',
  },
];

// ─── Mock implementation ──────────────────────────────────────────────────────

class MockAuthService implements AuthService {
  static const String _boxName = 'prefs_box';
  static const String _userKey = 'current_user';

  final _uuid = const Uuid();
  final _controller = StreamController<UserModel?>.broadcast();

  UserModel? _currentUser;

  MockAuthService() {
    _restoreSession();
  }

  // Restores user from Hive on app restart.
  void _restoreSession() {
    try {
      final box = Hive.box(_boxName);
      final stored = box.get(_userKey);
      if (stored is UserModel) {
        _currentUser = stored;
        _controller.add(_currentUser);
        AppLogger.write(LogTag.auth, 'Session restored: ${stored.email}');
      }
    } catch (_) {
      // Box may not be open yet; caller should open it before constructing.
    }
  }

  @override
  Future<UserModel?> login(String email) async {
    AppLogger.write(LogTag.auth, 'login attempt: $email');
    final normalised = email.trim().toLowerCase();

    // Check seed data first.
    for (final seed in _seedUsers) {
      if ((seed['email'] as String).toLowerCase() == normalised) {
        final user = UserModel.fromJson(Map<String, dynamic>.from(seed));
        await _persist(user);
        AppLogger.write(LogTag.auth, 'login success (seed): ${user.id}');
        return user;
      }
    }

    // Check Hive for previously created profiles.
    try {
      final box = Hive.box(_boxName);
      for (final key in box.keys) {
        final value = box.get(key);
        if (value is UserModel &&
            value.email.toLowerCase() == normalised) {
          await _persist(value);
          AppLogger.write(
              LogTag.auth, 'login success (hive): ${value.id}');
          return value;
        }
      }
    } catch (_) {}

    AppLogger.write(LogTag.auth, 'login failed: no user for $email');
    return null;
  }

  @override
  Future<UserModel> createProfile({
    required String name,
    required UserRole role,
    String? assignedTrainerId,
  }) async {
    AppLogger.write(LogTag.auth, 'createProfile: $name ($role)');
    final user = UserModel(
      id: _uuid.v4(),
      name: name,
      email: '${name.toLowerCase().replaceAll(' ', '_')}@wtf.com',
      role: role,
      assignedTrainerId: assignedTrainerId,
    );
    await _persist(user);
    AppLogger.write(LogTag.auth, 'profile created: ${user.id}');
    return user;
  }

  @override
  Future<void> logout() async {
    AppLogger.write(LogTag.auth, 'logout: ${_currentUser?.id}');
    _currentUser = null;
    try {
      final box = Hive.box(_boxName);
      await box.delete(_userKey);
    } catch (_) {}
    _controller.add(null);
  }

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Stream<UserModel?> get authStateChanges => _controller.stream;

  Future<void> _persist(UserModel user) async {
    _currentUser = user;
    try {
      final box = Hive.box(_boxName);
      await box.put(_userKey, user);
    } catch (_) {}
    _controller.add(_currentUser);
  }

  /// Dispose the stream controller when no longer needed.
  Future<void> dispose() async {
    await _controller.close();
  }
}
