import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/services/notification_service.dart';
import '../routes/app_router.dart';

/// Circle icon button with a live unread-notification badge.
/// Tapping it opens [NotificationsRoute] (which marks everything read).
class NotificationBellButton extends StatefulWidget {
  const NotificationBellButton({super.key});

  @override
  State<NotificationBellButton> createState() => _NotificationBellButtonState();
}

class _NotificationBellButtonState extends State<NotificationBellButton>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Reflect notifications saved by the background isolate.
    NotificationService.instance.refreshUnreadCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationService.instance.refreshUnreadCount();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: NotificationService.instance.unreadCount,
      builder: (context, count, _) {
        return InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(50)),
          onTap: () => context.router.push(const NotificationsRoute()),
          child: Ink(
            width: 45,
            height: 45,
            decoration: ShapeDecoration(
              color: context.theme.cardColor,
              shape: const CircleBorder(),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Icon(Icons.notifications_outlined,
                      size: 24, color: context.theme.iconTheme.color),
                ),
                if (count > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: ColorConstant.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
