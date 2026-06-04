import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';
import 'package:minimumz/presentation/routes/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _storedKey = 'stored_notifications';
const _maxStored = 50;

/// Persists an incoming message to local storage and returns its generated id.
/// Top-level so the background isolate (no [NotificationService] instance) can
/// call it. Stores the backend-localized title/body plus structured fields
/// (type/order_id/status) used for deep-linking and per-item read state.
Future<String?> _persistMessage(RemoteMessage message) async {
  final n = message.notification;
  final data = message.data;
  final title = n?.title ?? data['title'] as String?;
  final body = n?.body ?? data['body'] as String?;
  if ((title == null || title.isEmpty) && (body == null || body.isEmpty)) {
    return null;
  }

  final id = DateTime.now().microsecondsSinceEpoch.toString();
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_storedKey);
  final list = raw != null
      ? List<Map<String, dynamic>>.from(jsonDecode(raw))
      : <Map<String, dynamic>>[];
  list.insert(0, {
    'id': id,
    'type': data['type'] ?? '',
    'order_id': data['order_id'] ?? '',
    'status': data['status'] ?? '',
    'title': title ?? '',
    'body': body ?? '',
    'time': DateTime.now().toIso8601String(),
    'read': false,
  });
  if (list.length > _maxStored) list.removeRange(_maxStored, list.length);
  await prefs.setString(_storedKey, jsonEncode(list));
  return id;
}

Future<int> _computeUnread() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(_storedKey);
  if (raw == null) return 0;
  final list = List<Map<String, dynamic>>.from(jsonDecode(raw));
  return list.where((n) => n['read'] != true).length;
}

/// Handles messages delivered while the app is backgrounded or terminated.
/// Runs in its own isolate, so it only persists — the badge is recomputed when
/// the app next resumes (see [NotificationService.refreshUnreadCount]).
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await _persistMessage(message);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId   = 'minimumz_channel';
  static const _channelName = 'MiniMumz Notifications';

  /// Reactive unread badge count. UI listens via [ValueListenableBuilder].
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  /// Bumped whenever a new notification is stored, so an open notifications
  /// screen can refresh its list live. (markAllRead does NOT bump this, to
  /// avoid a reload loop.)
  final ValueNotifier<int> notificationsRevision = ValueNotifier<int>(0);

  /// Order id from a notification that launched the app from a terminated
  /// state. Consumed by the splash flow once the dashboard is in place, so the
  /// order page opens with Home beneath it (and can be popped back to).
  String? pendingOrderId;

  /// Returns and clears [pendingOrderId].
  String? consumePendingOrder() {
    final id = pendingOrderId;
    pendingOrderId = null;
    return id;
  }

  Future<void> init() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

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
      onDidReceiveNotificationResponse: (resp) => _handlePayloadTap(resp.payload),
    );

    // Background / terminated delivery.
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    // Foreground delivery.
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    // App opened by tapping a notification while backgrounded.
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTap);
    // Re-register with the backend whenever FCM rotates the token.
    _messaging.onTokenRefresh.listen((_) => registerToken());

    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // App launched from a terminated state by tapping a notification. Don't
    // navigate here — the splash flow opens it after the dashboard is in the
    // stack, so the order page can be popped back to Home.
    final initial = await _messaging.getInitialMessage();
    pendingOrderId = initial?.data['order_id'] as String?;

    await refreshUnreadCount();
  }

  Future<AuthorizationStatus> getPermissionStatus() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus;
  }

  Future<String?> getToken() => _messaging.getToken();

  /// Syncs the device's FCM token with the backend. Called on app open, login,
  /// and signup. Compares against the last-registered token cached locally and
  /// only hits the backend when it changed, so repeated calls are cheap no-ops.
  Future<void> registerToken() async {
    try {
      final prefs = getIt<PreferenceRepository>();
      if (!prefs.notificationsEnabled) return;
      final token = await _messaging.getToken();
      if (token == null) return;
      if (prefs.registeredFcmToken == token) return; // already in sync
      await getIt<DataStore>().customers.updateFcmToken(token);
      await prefs.setRegisteredFcmToken(token);
    } catch (_) {}
  }

  /// Clears the FCM token in the backend (logout / notifications disabled), and
  /// always drops the cached token so a later login re-registers — important
  /// when a different account signs in on the same device.
  Future<void> clearToken() async {
    try {
      await getIt<DataStore>().customers.updateFcmToken(null);
    } catch (_) {}
    await getIt<PreferenceRepository>().setRegisteredFcmToken(null);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final id = await _persistMessage(message);
    await refreshUnreadCount();
    notificationsRevision.value++; // let an open list refresh live

    final payload = jsonEncode({
      'id': id,
      'order_id': message.data['order_id'],
    });

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          // Small status-bar icon must be a transparent silhouette.
          icon: 'ic_launcher_foreground',
          // Full-color app logo shown in the notification body.
          largeIcon: DrawableResourceAndroidBitmap('ic_launcher_foreground'),
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  // ── Tap handling ──────────────────────────────────────────────────────────

  /// Tap on a locally-shown (foreground) notification — payload carries our
  /// stored id + order id.
  void _handlePayloadTap(String? payload) {
    if (payload == null) {
      _openOrder(null);
      return;
    }
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _markReadById(data['id'] as String?);
      _openOrder(data['order_id'] as String?);
    } catch (_) {
      _openOrder(null);
    }
  }

  /// Tap on an OS-tray notification (backgrounded/terminated) — identified by
  /// the FCM data payload.
  void _handleMessageTap(RemoteMessage message) {
    final orderId = message.data['order_id'] as String?;
    _markReadByOrder(orderId);
    _openOrder(orderId);
  }

  /// Opens the order details page (or the notifications list as a fallback).
  /// Guarded because the router singleton may not be registered very early.
  void _openOrder(String? orderId) {
    if (!getIt.isRegistered<AppRouter>()) return;
    final router = getIt<AppRouter>();
    if (orderId != null && orderId.isNotEmpty) {
      router.push(OrderDetailsRoute(orderId: orderId));
    } else {
      router.push(const NotificationsRoute());
    }
  }

  // ── Read state / badge ──────────────────────────────────────────────────

  Future<void> _markReadById(String? id) async {
    if (id == null) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storedKey);
    if (raw == null) return;
    final list = List<Map<String, dynamic>>.from(jsonDecode(raw));
    for (final n in list) {
      if (n['id'] == id) n['read'] = true;
    }
    await prefs.setString(_storedKey, jsonEncode(list));
    await refreshUnreadCount();
  }

  /// Marks the most recent unread notification for [orderId] as read.
  Future<void> _markReadByOrder(String? orderId) async {
    if (orderId == null || orderId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storedKey);
    if (raw == null) return;
    final list = List<Map<String, dynamic>>.from(jsonDecode(raw));
    for (final n in list) {
      if (n['order_id'] == orderId && n['read'] != true) {
        n['read'] = true;
        break;
      }
    }
    await prefs.setString(_storedKey, jsonEncode(list));
    await refreshUnreadCount();
  }

  /// Recomputes the unread badge from storage. Call on resume so notifications
  /// saved by the background isolate are reflected.
  Future<void> refreshUnreadCount() async {
    unreadCount.value = await _computeUnread();
  }

  Future<List<Map<String, dynamic>>> getStoredNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storedKey);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw));
  }

  /// Marks all stored notifications read and clears the badge.
  Future<void> markAllRead() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storedKey);
    if (raw != null) {
      final list = List<Map<String, dynamic>>.from(jsonDecode(raw));
      for (final n in list) {
        n['read'] = true;
      }
      await prefs.setString(_storedKey, jsonEncode(list));
    }
    unreadCount.value = 0;
  }

  /// Dismisses notifications shown in the system tray / notification center.
  Future<void> clearSystemTray() async {
    await _localNotifications.cancelAll();
  }

  Future<void> clearStoredNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storedKey);
    unreadCount.value = 0;
  }
}
