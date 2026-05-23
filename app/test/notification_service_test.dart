import 'package:flutter_test/flutter_test.dart';
import 'package:missed_lead_recovery/services/notification_service.dart';

/// Tests for NotificationService that don't require Firebase initialization.
/// These verify the service structure and singleton behavior.
void main() {
  group('NotificationService', () {
    test('is a singleton', () {
      final a = NotificationService();
      final b = NotificationService();
      expect(identical(a, b), isTrue);
    });

    test('currentToken is null before init', () {
      final service = NotificationService();
      expect(service.currentToken, isNull);
    });
  });
}
