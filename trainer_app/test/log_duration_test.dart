import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  group('SessionLogModel duration', () {
    test('durationSec calculated correctly', () {
      final start = DateTime(2024, 1, 15, 9, 0, 0);
      final end = DateTime(2024, 1, 15, 9, 45, 0);
      final log = SessionLogModel(
        id: 'log_001',
        memberId: 'member_001',
        trainerId: 'trainer_001',
        startedAt: start,
        endedAt: end,
        durationSec: end.difference(start).inSeconds,
      );
      expect(log.durationSec, equals(2700)); // 45 minutes
    });
  });
  
  group('int.toFormattedDuration()', () {
    test('2700 seconds returns 45:00', () {
      expect(2700.toFormattedDuration(), equals('45:00'));
    });
    
    test('zero returns 00:00', () {
      expect(0.toFormattedDuration(), equals('00:00'));
    });
    
    test('90 seconds returns 01:30', () {
      expect(90.toFormattedDuration(), equals('01:30'));
    });
  });
}
