import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../router/app_router.dart';

/// Handles FCM token registration and push notification display.
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  String? _currentToken;

  /// Initialize Firebase and request notification permissions.
  /// Call this once after Firebase.initializeApp() in main().
  Future<void> init() async {
    try {
      debugPrint('[fcm] Starting notification service init...');

      // Request permission (iOS requires this; Android auto-grants)
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('[fcm] Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('[fcm] Notifications denied by user');
        return;
      }

      // Get the FCM token
      debugPrint('[fcm] Requesting FCM token...');
      _currentToken = await _messaging.getToken();
      debugPrint('[fcm] Token: ${_currentToken ?? "NULL — check Google Play Services"}');

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _currentToken = newToken;
        debugPrint('[fcm] Token refreshed: $newToken');
        _registerTokenWithBackend(newToken);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle background/terminated message taps
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);

      // Check if app was opened from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageTap(initialMessage);
      }

      debugPrint('[fcm] Notification service init complete');
    } catch (e, stack) {
      debugPrint('[fcm] ERROR during init: $e');
      debugPrint('[fcm] Stack: $stack');
    }
  }

  /// Register the current FCM token with the backend.
  /// Call this after the user logs in.
  Future<void> registerToken() async {
    if (_currentToken == null) {
      debugPrint('[fcm] No token available to register');
      return;
    }
    await _registerTokenWithBackend(_currentToken!);
  }

  /// Clear the FCM token on the backend (call on logout).
  Future<void> clearToken() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // Find contractor by auth user id and clear FCM token
      await supabase
          .from('contractors')
          .update({'fcm_token': null})
          .eq('contact_email', user.email ?? '');

      debugPrint('[fcm] Token cleared on backend');
    } catch (e) {
      debugPrint('[fcm] Failed to clear token: $e');
    }
  }

  /// Get the current FCM token (for debugging).
  String? get currentToken => _currentToken;

  // ---------------------------------------------------------------------------
  // Private
  // ---------------------------------------------------------------------------

  Future<void> _registerTokenWithBackend(String token) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      if (user == null) {
        debugPrint('[fcm] No authenticated user, skipping token registration');
        return;
      }

      // Update the contractor's FCM token directly via Supabase
      await supabase
          .from('contractors')
          .update({'fcm_token': token})
          .eq('contact_email', user.email ?? '');

      debugPrint('[fcm] Token registered with backend');
    } catch (e) {
      debugPrint('[fcm] Failed to register token: $e');
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final isUrgent = message.data['priority'] == 'high';
    debugPrint('[fcm] Foreground message: ${message.notification?.title} (urgent=$isUrgent)');

    if (isUrgent) {
      // Urgent notifications: Android will use the 'urgent_leads' channel
      // which has alarm-volume sound and bypasses DND.
      // The notification banner will show automatically with the loud sound.
      debugPrint('[fcm] 🚨 URGENT notification — alarm channel will ring loudly');
    }
    // All notifications show automatically on Android via the FCM channel config.
  }

  void _handleMessageTap(RemoteMessage message) {
    debugPrint('[fcm] Message tap: ${message.data}');
    // Navigate to the lead detail screen if leadId is in the payload.
    final leadId = message.data['leadId'];
    if (leadId != null) {
      debugPrint('[fcm] Navigating to lead: $leadId');
      // Use the global navigator key to push without needing a BuildContext.
      final context = rootNavigatorKey.currentContext;
      if (context != null) {
        GoRouter.of(context).push('/leads/$leadId');
      } else {
        debugPrint('[fcm] No navigator context available for deep link');
      }
    }
  }
}

/// Top-level handler for background messages (required by Firebase).
/// Must be a top-level function, not a class method.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[fcm] Background message: ${message.messageId}');
}
