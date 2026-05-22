import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';

void main() {
  group('Validators.validateScheduleTime', () {
    test('past datetime returns error string', () {
      final past = DateTime.now().subtract(const Duration(hours: 1));
      final result = Validators.validateScheduleTime(past);
      expect(result, isNotNull);
      expect(result, contains('future'));
    });
    
    test('future datetime returns null (valid)', () {
      final future = DateTime.now().add(const Duration(hours: 2));
      final result = Validators.validateScheduleTime(future);
      expect(result, isNull);
    });
    
    test('exact current time is invalid (boundary)', () {
      // DateTime.now() is in the past by the time we call validate
      final boundary = DateTime.now().subtract(const Duration(milliseconds: 1));
      final result = Validators.validateScheduleTime(boundary);
      expect(result, isNotNull);
    });
  });
}
