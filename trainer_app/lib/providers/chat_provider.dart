import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared/shared.dart';
import 'package:uuid/uuid.dart';

class TrainerChatProvider extends ChangeNotifier {
  final ChatService _chatService;
  final String _chatId;
  final String _trainerId;
  final String _memberId;

  final _uuid = const Uuid();

  List<MessageModel> _messages = [];
  bool _isTyping = false;
  bool _isLoading = false;
  bool _memberTyping = false;
  String? _error;

  StreamSubscription<List<MessageModel>>? _messagesSub;
  StreamSubscription<bool>? _typingSub;

  TrainerChatProvider({
    required ChatService chatService,
    required String chatId,
    required String trainerId,
    required String memberId,
  })  : _chatService = chatService,
        _chatId = chatId,
        _trainerId = trainerId,
        _memberId = memberId {
    _init();
  }

  List<MessageModel> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  bool get memberTyping => _memberTyping;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _init() {
    _messagesSub = _chatService.watchMessages(_chatId).listen(
      (msgs) {
        _messages = msgs;
        _error = null;
        notifyListeners();
      },
      onError: (Object e) {
        _error = e.toString();
        notifyListeners();
      },
    );

    // Watch member typing indicator
    _typingSub = _chatService.watchTyping(_chatId, _memberId).listen(
      (typing) {
        _memberTyping = typing;
        notifyListeners();
      },
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _isLoading = true;
    notifyListeners();

    final message = MessageModel(
      id: _uuid.v4(),
      chatId: _chatId,
      senderId: _trainerId,
      receiverId: _memberId,
      text: text.trim(),
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
    );

    try {
      await _chatService.sendMessage(message);
      await _chatService.setTyping(_chatId, _trainerId, false);
      _isTyping = false;
      AppLogger.write(LogTag.chat, 'Trainer sent message: ${message.id}');
    } catch (e) {
      _error = e.toString();
      AppLogger.write(LogTag.chat, 'Trainer sendMessage error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setTyping(bool typing) async {
    if (_isTyping == typing) return;
    _isTyping = typing;
    await _chatService.setTyping(_chatId, _trainerId, typing);
  }

  Future<void> markAsRead() async {
    try {
      await _chatService.markAsRead(_chatId, _trainerId);
    } catch (e) {
      AppLogger.write(LogTag.chat, 'markAsRead error: $e');
    }
  }

  Future<void> refresh() async {
    // Re-subscribe
    await _messagesSub?.cancel();
    _messagesSub = _chatService.watchMessages(_chatId).listen(
      (msgs) {
        _messages = msgs;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _typingSub?.cancel();
    super.dispose();
  }
}
