import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:uuid/uuid.dart';

class ScheduleProvider extends ChangeNotifier {
  final CallService _callService;
  final AuthService _authService;
  final _uuid = const Uuid();

  List<CallRequestModel> _allRequests = [];
  DateTime? _selectedDate;
  DateTime? _selectedSlot;
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<CallRequestModel>>? _requestsSub;

  List<CallRequestModel> get myRequests {
    final user = _authService.currentUser;
    if (user == null) return [];
    return _allRequests.where((r) => r.memberId == user.id).toList();
  }

  List<CallRequestModel> get pendingRequests =>
      myRequests.where((r) => r.status == CallStatus.pending).toList();

  DateTime? get selectedDate => _selectedDate;
  DateTime? get selectedSlot => _selectedSlot;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ScheduleProvider(this._callService, this._authService) {
    _init();
  }

  void _init() {
    final trainerId = _authService.currentUser?.assignedTrainerId ?? 'trainer_001';
    _requestsSub = _callService.watchRequests(trainerId).listen((requests) {
      _allRequests = requests;
      notifyListeners();
    });
    AppLogger.write(LogTag.schedule, 'ScheduleProvider init: watching $trainerId');
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    _selectedSlot = null;
    notifyListeners();
  }

  void selectSlot(DateTime slot) {
    _selectedSlot = slot;
    notifyListeners();
  }

  Future<void> requestCall({
    required DateTime slot,
    required String note,
  }) async {
    final validationError = Validators.validateScheduleTime(slot);
    if (validationError != null) {
      _errorMessage = validationError;
      notifyListeners();
      return;
    }

    final noteError = Validators.validateNote(note);
    if (noteError != null) {
      _errorMessage = noteError;
      notifyListeners();
      return;
    }

    final user = _authService.currentUser;
    if (user == null) {
      _errorMessage = 'You must be logged in to schedule a call.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = CallRequestModel(
        id: _uuid.v4(),
        memberId: user.id,
        trainerId: user.assignedTrainerId ?? 'trainer_001',
        requestedAt: DateTime.now(),
        scheduledFor: slot,
        note: note,
        status: CallStatus.pending,
      );
      await _callService.createCallRequest(request);
      AppLogger.write(LogTag.schedule, 'requestCall success: ${request.id}');
    } catch (e) {
      _errorMessage = 'Failed to request call. Please try again.';
      AppLogger.write(LogTag.schedule, 'requestCall error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates an instant call request and returns the request ID so the caller
  /// can watch for trainer acceptance. Returns null on failure.
  Future<String?> instantCall() async {
    final user = _authService.currentUser;
    if (user == null) {
      _errorMessage = 'You must be logged in to start a call.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = CallRequestModel(
        id: _uuid.v4(),
        memberId: user.id,
        trainerId: user.assignedTrainerId ?? 'trainer_001',
        requestedAt: DateTime.now(),
        scheduledFor: DateTime.now(),
        note: 'Instant call request',
        status: CallStatus.pending,
        isInstant: true,
      );
      await _callService.createCallRequest(request);
      AppLogger.write(LogTag.schedule, 'instantCall created: ${request.id}');
      return request.id;
    } catch (e) {
      _errorMessage = 'Failed to start instant call. Please try again.';
      AppLogger.write(LogTag.schedule, 'instantCall error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Stream<CallRequestModel?> watchRequest(String requestId) =>
      _callService.watchRequest(requestId);

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _requestsSub?.cancel();
    super.dispose();
  }
}
