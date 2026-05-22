import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Returns a stream that emits the latest message for [chatId], or null if none.
  Stream<MessageModel?> watchLastMessage(String chatId);
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

  // ─── watchLastMessage ──────────────────────────────────────────────────────

  @override
  Stream<MessageModel?> watchLastMessage(String chatId) {
    final controller = _messageControllers.putIfAbsent(
      chatId,
      () => StreamController<List<MessageModel>>.broadcast(),
    );
    _emitMessages(chatId, controller);
    return controller.stream.map((msgs) => msgs.isNotEmpty ? msgs.last : null);
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

class FirebaseChatService implements ChatService {
  FirebaseChatService({FirebaseFirestore? firestore}) : _firestore = firestore;

  static const String _boxName = 'messages_box';

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _db => _firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<MessageModel>> watchMessages(String chatId) async* {
    AppLogger.write(LogTag.chat, 'watchMessages(firebase): chatId=$chatId');
    yield _cachedMessages(chatId);

    try {
      final query = _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt');

      await for (final snapshot in query.snapshots()) {
        final messages = snapshot.docs
            .map((doc) => MessageModel.fromJson(doc.data()))
            .toList();
        await _cacheMessages(messages);
        AppLogger.write(
          LogTag.chat,
          'watchMessages(firebase): ${messages.length} messages',
        );
        yield messages;
      }
    } catch (e) {
      AppLogger.write(
        LogTag.chat,
        'watchMessages(firebase) error; using cache: $e',
      );
      yield _cachedMessages(chatId);
    }
  }

  @override
  Future<void> sendMessage(MessageModel message) async {
    AppLogger.write(
      LogTag.chat,
      'sendMessage(firebase): id=${message.id} chatId=${message.chatId}',
    );
    await _cacheMessage(message);
    try {
      await _db
          .collection('chats')
          .doc(message.chatId)
          .collection('messages')
          .doc(message.id)
          .set(message.toJson());
      AppLogger.write(LogTag.chat, 'sendMessage(firebase) synced');
    } catch (e) {
      AppLogger.write(LogTag.chat, 'sendMessage(firebase) offline: $e');
    }
  }

  // ─── watchLastMessage ──────────────────────────────────────────────────────

  @override
  Stream<MessageModel?> watchLastMessage(String chatId) async* {
    final cached = _cachedMessages(chatId);
    yield cached.isNotEmpty ? cached.last : null;
    try {
      final query = _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .limit(1);
      await for (final snapshot in query.snapshots()) {
        if (snapshot.docs.isEmpty) {
          yield null;
        } else {
          final msg = MessageModel.fromJson(snapshot.docs.first.data());
          await _cacheMessage(msg);
          yield msg;
        }
      }
    } catch (e) {
      AppLogger.write(LogTag.chat, 'watchLastMessage(firebase) error: $e');
      final c = _cachedMessages(chatId);
      yield c.isNotEmpty ? c.last : null;
    }
  }

  @override
  Future<void> markAsRead(String chatId, String userId) async {
    AppLogger.write(
      LogTag.chat,
      'markAsRead(firebase): chatId=$chatId userId=$userId',
    );
    final messages = _cachedMessages(chatId)
        .where((m) => m.receiverId == userId && m.status != MessageStatus.read)
        .toList();

    for (final message in messages) {
      await _cacheMessage(message.copyWith(status: MessageStatus.read));
    }

    try {
      final snapshot = await _db
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .get();
      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'status': MessageStatus.read.name});
      }
      await batch.commit();
    } catch (e) {
      AppLogger.write(LogTag.chat, 'markAsRead(firebase) offline: $e');
    }
  }

  @override
  Stream<bool> watchTyping(String chatId, String senderId) async* {
    AppLogger.write(
      LogTag.chat,
      'watchTyping(firebase): chatId=$chatId senderId=$senderId',
    );
    try {
      await for (final snapshot in _db
          .collection('chats')
          .doc(chatId)
          .collection('typing')
          .doc(senderId)
          .snapshots()) {
        yield (snapshot.data()?['isTyping'] as bool?) ?? false;
      }
    } catch (e) {
      AppLogger.write(LogTag.chat, 'watchTyping(firebase) offline: $e');
      yield false;
    }
  }

  @override
  Future<void> setTyping(String chatId, String userId, bool isTyping) async {
    AppLogger.write(
      LogTag.chat,
      'setTyping(firebase): chatId=$chatId userId=$userId val=$isTyping',
    );
    try {
      await _db
          .collection('chats')
          .doc(chatId)
          .collection('typing')
          .doc(userId)
          .set({
        'isTyping': isTyping,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.write(LogTag.chat, 'setTyping(firebase) offline: $e');
    }
  }

  List<MessageModel> _cachedMessages(String chatId) {
    try {
      final box = Hive.box<MessageModel>(_boxName);
      return box.values.where((m) => m.chatId == chatId).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } catch (_) {
      return [];
    }
  }

  Future<void> _cacheMessages(List<MessageModel> messages) async {
    for (final message in messages) {
      await _cacheMessage(message);
    }
  }

  Future<void> _cacheMessage(MessageModel message) async {
    try {
      final box = Hive.box<MessageModel>(_boxName);
      await box.put(message.id, message);
    } catch (_) {}
  }
}
