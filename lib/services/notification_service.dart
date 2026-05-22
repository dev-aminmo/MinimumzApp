import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId   = 'minimumz_channel';
  static const _channelName = 'MiniMumz Notifications';
  static const _storedKey   = 'stored_notifications';

  Future<void> init() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
      playSound: true,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const iosSettings     = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<AuthorizationStatus> getPermissionStatus() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  Future<String?> getToken() => _messaging.getToken();

  /// Call after login — registers the FCM token with the backend.
  Future<void> registerToken() async {
    try {
      final prefs = getIt<PreferenceRepository>();
      if (!prefs.notificationsEnabled) return;
      final token = await _messaging.getToken();
      if (token == null) return;
      await getIt<DataStore>().customers.updateFcmToken(token);
    } catch (_) {}
  }

  /// Clears the FCM token in the backend when the user disables notifications.
  Future<void> clearToken() async {
    try {
      await getIt<DataStore>().customers.updateFcmToken(null);
    } catch (_) {}
  }

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _saveNotification(notification.title, notification.body);

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/launcher_icon',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  void _saveNotification(String? title, String? body) async {
    if (title == null && body == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw  = prefs.getString(_storedKey);
    final list = raw != null ? List<Map<String, dynamic>>.from(jsonDecode(raw)) : <Map<String, dynamic>>[];
    list.insert(0, {
      'title': title ?? '',
      'body': body ?? '',
      'time': DateTime.now().toIso8601String(),
    });
    if (list.length > 50) list.removeLast();
    await prefs.setString(_storedKey, jsonEncode(list));
  }

  Future<List<Map<String, dynamic>>> getStoredNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storedKey);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  Future<void> clearStoredNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storedKey);
  }
}
