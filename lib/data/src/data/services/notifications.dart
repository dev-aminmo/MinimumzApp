import 'dart:developer';
import 'base.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.orderId,
    required this.status,
    required this.readAt,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return AppNotification(
      id:        json['id'] as String? ?? '',
      type:      json['type'] as String? ?? '',
      title:     data['title'] as String? ?? '',
      body:      data['body'] as String? ?? '',
      orderId:   data['order_id'] as String? ?? '',
      status:    data['status'] as String? ?? '',
      readAt:    json['read_at'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  final String  id;
  final String  type;
  final String  title;
  final String  body;
  final String  orderId;
  final String  status;
  final String? readAt;
  final String  createdAt;

  bool get isRead => readAt != null;
}

class NotificationsResource extends BaseResource {
  NotificationsResource(super.client);

  Future<({List<AppNotification> items, int unreadCount, bool hasMore})> list({int page = 1}) async {
    try {
      final response = await client.get('/store/me/notifications', queryParameters: {'page': page});
      if (response.statusCode == 200) {
        final json = response.data as Map<String, dynamic>;
        final items = (json['notifications'] as List? ?? [])
            .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
            .toList();
        return (
          items:       items,
          unreadCount: json['unread_count'] as int? ?? 0,
          hasMore:     json['has_more'] as bool? ?? false,
        );
      }
    } catch (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
    }
    return (items: <AppNotification>[], unreadCount: 0, hasMore: false);
  }

  /// Mark specific notifications read. Pass null to mark all.
  Future<int> markRead({List<String>? ids}) async {
    try {
      final body = ids != null ? {'ids': ids} : <String, dynamic>{};
      final response = await client.post('/store/me/notifications/read', data: body);
      if (response.statusCode == 200) {
        return (response.data as Map<String, dynamic>)['unread_count'] as int? ?? 0;
      }
    } catch (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
    }
    return 0;
  }
}
