import 'dart:async';

import 'package:hive/hive.dart';

import '../models/message_model.dart';
import '../utils/app_logger.dart';

// ─── Abstract interface ───────────────────────────────────────────────────────

abstract class ChatService {
  /// Returns a stream of messages for the given [chatId], sorted ascending.
  Stream<List<MessageModel>> watchMessages(String chatId);

  /// Persists [message] and emits it on the corresponding stream.
  Future<void> sendMessage(MessageModel message);

  /// Marks all messages in [chatId] addressed to [userId] as [MessageStatus.read].
  Future<void> markAsRead(String chatId, String userId);

  /// Returns a stream that emits true while [senderId] is typing in [chatId].
  Stream<bool> watchTyping(String chatId, String senderId);

  /// Updates the typing indicator for [userId] in [chatId].
  Future<void> setTyping(String chatId, String userId, bool isTyping);
}

// ─── Mock implementation ──────────────────────────────────────────────────────

class MockChatService implements ChatService {
  static const String _boxName = 'messages_box';

  /// Per-chatId stream controllers for message lists.
  final Map<String, StreamController<List<MessageModel>>> _messageControllers =
      {};

  /// Per-(chatId+senderId) typing controllers.
  final Map<String, StreamController<bool>> _typingControllers = {};

  /// In-memory typing state.
  final Map<String, bool> _typingState = {};

  // ─── watchMessages ─────────────────────────────────────────────────────────

  @override
  Stream<List<MessageModel>> watchMessages(String chatId) {
    AppLogger.write(LogTag.chat, 'watchMessages: chatId=$chatId');
    final controller = _messageControllers.putIfAbsent(
      chatId,
      () => StreamController<List<MessageModel>>.broadcast(),
    );
    // Emit current snapshot immediately.
    _emitMessages(chatId, controller);
    return controller.stream;
  }

  // ─── sendMessage ───────────────────────────────────────────────────────────

  @override
  Future<void> sendMessage(MessageModel message) async {
    AppLogger.write(
        LogTag.chat, 'sendMessage: id=${message.id} chatId=${message.chatId}');
    try {
      final box = Hive.box<MessageModel>(_boxName);
      await box.put(message.id, message);
    } catch (e) {
      AppLogger.write(LogTag.chat, 'sendMessage error: $e');
    }
    _emitMessages(
      message.chatId,
      _messageControllers[message.chatId],
    );
  }

  // ─── markAsRead ────────────────────────────────────────────────────────────

  @override
  Future<void> markAsRead(String chatId, String userId) async {
    AppLogger.write(
        LogTag.chat, 'markAsRead: chatId=$chatId userId=$userId');
    try {
      final box = Hive.box<MessageModel>(_boxName);
      final toUpdate = box.values
          .where((m) =>
              m.chatId == chatId &&
              m.receiverId == userId &&
              m.status != MessageStatus.read)
          .toList();

      for (final msg in toUpdate) {
        await box.put(msg.id, msg.copyWith(status: MessageStatus.read));
      }
    } catch (e) {
      AppLogger.write(LogTag.chat, 'markAsRead error: $e');
    }
    _emitMessages(chatId, _messageControllers[chatId]);
  }

  // ─── watchTyping ───────────────────────────────────────────────────────────

  @override
  Stream<bool> watchTyping(String chatId, String senderId) {
    AppLogger.write(
        LogTag.chat, 'watchTyping: chatId=$chatId senderId=$senderId');
    final key = '$chatId:$senderId';
    final controller = _typingControllers.putIfAbsent(
      key,
      () => StreamController<bool>.broadcast(),
    );
    return controller.stream;
  }

  // ─── setTyping ─────────────────────────────────────────────────────────────

  @override
  Future<void> setTyping(
      String chatId, String userId, bool isTyping) async {
    AppLogger.write(
        LogTag.chat, 'setTyping: chatId=$chatId userId=$userId val=$isTyping');
    final key = '$chatId:$userId';
    _typingState[key] = isTyping;
    _typingControllers[key]?.add(isTyping);
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  void _emitMessages(
    String chatId,
    StreamController<List<MessageModel>>? controller,
  ) {
    if (controller == null || controller.isClosed) return;
    try {
      final box = Hive.box<MessageModel>(_boxName);
      final messages = box.values
          .where((m) => m.chatId == chatId)
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      controller.add(messages);
    } catch (_) {
      controller.add([]);
    }
  }

  /// Dispose all stream controllers.
  Future<void> dispose() async {
    for (final c in _messageControllers.values) {
      await c.close();
    }
    for (final c in _typingControllers.values) {
      await c.close();
    }
    _messageControllers.clear();
    _typingControllers.clear();
  }
}
