import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  group('MessageModel serialization', () {
    test('fromJson(toJson()) round-trip preserves all fields', () {
      final original = MessageModel(
        id: 'msg_001',
        chatId: 'chat_dk_aarav',
        senderId: 'member_001',
        receiverId: 'trainer_001',
        text: 'Hello trainer!',
        createdAt: DateTime(2024, 1, 15, 14, 30),
        status: MessageStatus.sent,
      );
      final json = original.toJson();
      final restored = MessageModel.fromJson(json);
      expect(restored, equals(original));
      expect(restored.id, equals('msg_001'));
      expect(restored.text, equals('Hello trainer!'));
      expect(restored.status, equals(MessageStatus.sent));
    });
    
    test('MessageStatus enum serializes correctly', () {
      for (final status in MessageStatus.values) {
        final msg = MessageModel(
          id: 'test',
          chatId: 'chat',
          senderId: 's',
          receiverId: 'r',
          text: 'text',
          createdAt: DateTime.now(),
          status: status,
        );
        final json = msg.toJson();
        final restored = MessageModel.fromJson(json);
        expect(restored.status, equals(status));
      }
    });
    
    test('createdAt DateTime round-trip', () {
      final now = DateTime.utc(2024, 6, 15, 10, 30, 45);
      final msg = MessageModel(
        id: 'dt_test',
        chatId: 'chat',
        senderId: 's',
        receiverId: 'r',
        text: 'dt test',
        createdAt: now,
        status: MessageStatus.read,
      );
      final restored = MessageModel.fromJson(msg.toJson());
      expect(restored.createdAt, equals(now));
    });
  });
}
