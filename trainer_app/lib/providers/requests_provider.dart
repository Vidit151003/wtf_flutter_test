import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared/shared.dart';
import 'package:uuid/uuid.dart';

class RequestsProvider extends ChangeNotifier {
  final CallService _callService;
  final ChatService _chatService;
  final String _trainerId;

  final _uuid = const Uuid();

  List<CallRequestModel> _allRequests = [];
  bool _isLoading = false;
  String? _error;

  StreamSubscription<List<CallRequestModel>>? _requestsSub;

  RequestsProvider({
    required CallService callService,
    required ChatService chatService,
    required String trainerId,
  })  : _callService = callService,
        _chatService = chatService,
        _trainerId = trainerId {
    _init();
  }

  List<CallRequestModel> get allRequests => List.unmodifiable(_allRequests);

  List<CallRequestModel> get pendingRequests => _allRequests
      .where((r) => r.status == CallStatus.pending && r.trainerId == _trainerId)
      .toList();

  int get pendingCount => pendingRequests.length;

  bool get isLoading => _isLoading;
  String? get error => _error;

  void _init() {
    AppLogger.write(LogTag.schedule, 'RequestsProvider init: trainer=$_trainerId');
    _requestsSub = _callService.watchRequests(_trainerId).listen(
      (requests) {
        _allRequests = requests;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> approve(String requestId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final request = _allRequests.firstWhere((r) => r.id == requestId);

      final roomMeta = RoomMetaModel(
        id: _uuid.v4(),
        callRequestId: requestId,
        hmsRoomId: 'dev-room-001',
        hmsRoleMember: 'viewer',
        hmsRoleTrainer: 'host',
      );

      await _callService.approveRequest(requestId, roomMeta);

      // Send system chat message
      final chatId = 'chat_${request.memberId}_${request.trainerId}';
      final formattedDate =
          DateFormat('dd MMM yyyy').format(request.scheduledFor);
      final formattedTime = DateFormat('h:mm a').format(request.scheduledFor);
      final systemMsg = MessageModel(
        id: _uuid.v4(),
        chatId: chatId,
        senderId: _trainerId,
        receiverId: request.memberId,
        text: 'Call approved for $formattedDate $formattedTime.',
        createdAt: DateTime.now(),
        status: MessageStatus.sent,
      );
      await _chatService.sendMessage(systemMsg);

      AppLogger.write(LogTag.schedule, 'Request approved: $requestId');
    } catch (e) {
      _error = e.toString();
      AppLogger.write(LogTag.schedule, 'approve error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> decline(String requestId, String reason) async {
    _isLoading = true;
    notifyListeners();

    try {
      final request = _allRequests.firstWhere((r) => r.id == requestId);

      await _callService.declineRequest(requestId, reason);

      // Send system chat message
      final chatId = 'chat_${request.memberId}_${request.trainerId}';
      final systemMsg = MessageModel(
        id: _uuid.v4(),
        chatId: chatId,
        senderId: _trainerId,
        receiverId: request.memberId,
        text: 'Call request declined. Reason: $reason.',
        createdAt: DateTime.now(),
        status: MessageStatus.sent,
      );
      await _chatService.sendMessage(systemMsg);

      AppLogger.write(LogTag.schedule, 'Request declined: $requestId');
    } catch (e) {
      _error = e.toString();
      AppLogger.write(LogTag.schedule, 'decline error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _requestsSub?.cancel();
    super.dispose();
  }
}
