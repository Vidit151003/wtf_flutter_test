import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:shared/shared.dart';
import 'package:uuid/uuid.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _chatService;
  final AuthService _authService;
  final _uuid = const Uuid();

  List<MessageModel> _messages = [];
  bool _isTyping = false;
  String? _activeChatId;
  StreamSubscription<List<MessageModel>>? _messagesSub;
  String? _errorMessage;

  List<MessageModel> get messages => List.unmodifiable(_messages);
  bool get isTyping => _isTyping;
  String? get activeChatId => _activeChatId;
  String? get errorMessage => _errorMessage;

  ChatProvider(this._chatService, this._authService);

  void setActiveChat(String chatId) {
    _activeChatId = chatId;
    _messagesSub?.cancel();
    _messagesSub = _chatService.watchMessages(chatId).listen((msgs) {
      // Merge: keep any optimistic (sending) messages not yet in the stream
      final streamIds = msgs.map((m) => m.id).toSet();
      final optimistic = _messages
          .where((m) =>
              m.status == MessageStatus.sending && !streamIds.contains(m.id))
          .toList();
      _messages = [...msgs, ...optimistic];
      _messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      notifyListeners();
    });
    AppLogger.write(LogTag.chat, 'setActiveChat: $chatId');
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _activeChatId == null) return;
    final user = _authService.currentUser;
    if (user == null) return;

    _errorMessage = null;

    // Optimistic add
    final msg = MessageModel(
      id: _uuid.v4(),
      chatId: _activeChatId!,
      senderId: user.id,
      receiverId: user.assignedTrainerId ?? 'trainer_001',
      text: trimmed,
      createdAt: DateTime.now(),
      status: MessageStatus.sending,
    );

    _messages = [..._messages, msg];
    notifyListeners();

    try {
      await _chatService.sendMessage(msg);
      // Update to sent
      final sentMsg = msg.copyWith(status: MessageStatus.sent);
      _messages = _messages
          .map((m) => m.id == msg.id ? sentMsg : m)
          .toList();
      notifyListeners();
      AppLogger.write(LogTag.chat, 'sendMessage success: ${msg.id}');
    } catch (e) {
      _errorMessage = 'Failed to send message.';
      AppLogger.write(LogTag.chat, 'sendMessage error: $e');
      notifyListeners();
    }
  }

  void _simulateReply(
      String chatId, String trainerId, String memberId) async {
    final delayMs = 400 + Random().nextInt(401); // 400–800ms
    await Future.delayed(Duration(milliseconds: delayMs));
    if (!_isTyping) {
      _isTyping = true;
      notifyListeners();
    }
    await Future.delayed(const Duration(milliseconds: 800));
    _isTyping = false;
    notifyListeners();

    final replyMsg = MessageModel(
      id: _uuid.v4(),
      chatId: chatId,
      senderId: trainerId,
      receiverId: memberId,
      text: "Thanks for your message! I'll get back to you shortly.",
      createdAt: DateTime.now(),
      status: MessageStatus.sent,
    );
    await _chatService.sendMessage(replyMsg);
    AppLogger.write(LogTag.chat, 'auto-reply sent: ${replyMsg.id}');
  }

  void markRead() {
    final user = _authService.currentUser;
    if (_activeChatId == null || user == null) return;
    _chatService.markAsRead(_activeChatId!, user.id);
    AppLogger.write(LogTag.chat, 'markRead: $_activeChatId');
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    super.dispose();
  }
}
