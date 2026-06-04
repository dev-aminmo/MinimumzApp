import 'package:auto_route/auto_route.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/services/notification_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../components/index.dart';
import '../routes/app_router.dart';

@RoutePage()
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with WidgetsBindingObserver {
  List<Map<String, dynamic>> _notifications = [];
  AuthorizationStatus _permissionStatus = AuthorizationStatus.notDetermined;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Refresh the list live when a notification arrives while this screen is open.
    NotificationService.instance.notificationsRevision.addListener(_onRevision);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.instance.notificationsRevision
        .removeListener(_onRevision);
    super.dispose();
  }

  void _onRevision() => _load();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A notification may have been saved by the background isolate while away.
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final status = await NotificationService.instance.getPermissionStatus();
    final list = await NotificationService.instance.getStoredNotifications();
    if (!mounted) return;
    setState(() {
      _permissionStatus = status;
      _notifications = list;
      _loading = false;
    });
    // Mark everything read once viewed — clears the badge. The in-memory list
    // keeps its original flags so unread items stay highlighted this session.
    await NotificationService.instance.markAllRead();
    // Dismiss any notifications still sitting in the system tray.
    await NotificationService.instance.clearSystemTray();
  }

  Future<void> _clearAll() async {
    await NotificationService.instance.clearStoredNotifications();
    if (!mounted) return;
    setState(() => _notifications = []);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.theme.appBarTheme.systemOverlayStyle!,
      child: Scaffold(
        appBar: CustomAppBar(
          title: context.l10n.notifications,
          actions: _notifications.isEmpty
              ? null
              : [
                  TextButton(
                    onPressed: _clearAll,
                    child: Text(context.l10n.clearAll,
                        style: TextStyle(color: ColorConstant.primary)),
                  ),
                ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_permissionStatus == AuthorizationStatus.denied) {
      return _PermissionDeniedView(onReload: _load);
    }

    if (_notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_none_rounded,
                size: 64, color: ColorConstant.manatee.withValues(alpha: 0.5)),
            const Gap(16),
            Text(context.l10n.noNotificationsYet,
                style: context.bodyMedium?.copyWith(color: ColorConstant.manatee)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _notifications.length,
      separatorBuilder: (_, __) => const Divider(height: 0, indent: 20, endIndent: 20),
      itemBuilder: (context, i) {
        final n = _notifications[i];
        final time = DateTime.tryParse(n['time'] ?? '');
        final unread = n['read'] != true;
        final orderId = (n['order_id'] ?? '').toString();
        return ListTile(
          onTap: orderId.isEmpty
              ? null
              : () {
                  // Mark this tile seen immediately (clears its red dot) before
                  // navigating — storage is already read, this syncs the view.
                  if (unread) setState(() => n['read'] = true);
                  context.router.push(OrderDetailsRoute(orderId: orderId));
                },
          tileColor: unread
              ? ColorConstant.primary.withValues(alpha: 0.05)
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: ColorConstant.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.notifications_rounded,
                    color: ColorConstant.primary, size: 22),
              ),
              if (unread)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: context.theme.scaffoldBackgroundColor,
                          width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(n['title'] ?? '',
              style: context.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((n['body'] ?? '').isNotEmpty)
                Text(n['body'] ?? '',
                    style: context.bodyExtraSmall
                        ?.copyWith(color: ColorConstant.manatee)),
              if (time != null)
                Text(
                  timeago.format(time, locale: Localizations.localeOf(context).languageCode),
                  style: context.bodyExtraSmall
                      ?.copyWith(color: ColorConstant.manatee.withValues(alpha: 0.7)),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView({required this.onReload});
  final VoidCallback onReload;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_rounded,
                size: 64, color: ColorConstant.manatee.withValues(alpha: 0.5)),
            const Gap(16),
            Text(
              context.l10n.notificationsPermissionDenied,
              textAlign: TextAlign.center,
              style: context.bodyMedium?.copyWith(color: ColorConstant.manatee),
            ),
            const Gap(20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: ColorConstant.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onReload,
              child: Text(context.l10n.openSettings),
            ),
          ],
        ),
      ),
    );
  }
}
