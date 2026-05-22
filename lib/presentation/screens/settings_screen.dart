import 'dart:io';
import 'package:auto_route/auto_route.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/cubits/locale/locale_cubit.dart';
import 'package:minimumz/cubits/notifications/notification_cubit.dart';
import 'package:minimumz/cubits/theme/theme_cubit.dart';
import 'package:minimumz/services/notification_service.dart';
import '../components/index.dart';

@RoutePage()
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.theme.appBarTheme.systemOverlayStyle!,
      child: Scaffold(
        appBar: CustomAppBar(title: context.l10n.settings),
        body: SafeArea(
          child: ListView(
            children: [
              const Gap(12),

              // ── Language ─────────────────────────────────────────
              _SectionHeader(title: context.l10n.language),
              BlocBuilder<LocaleCubit, Locale>(
                builder: (context, locale) {
                  return Column(
                    children: [
                      _LanguageTile(
                        label: 'English',
                        subtitle: context.l10n.english,
                        locale: const Locale('en'),
                        selected: locale.languageCode == 'en',
                        onTap: () =>
                            context.read<LocaleCubit>().setLocale(const Locale('en')),
                      ),
                      _LanguageTile(
                        label: 'العربية',
                        subtitle: context.l10n.arabic,
                        locale: const Locale('ar'),
                        selected: locale.languageCode == 'ar',
                        onTap: () =>
                            context.read<LocaleCubit>().setLocale(const Locale('ar')),
                      ),
                    ],
                  );
                },
              ),

              const Gap(20),

              // ── Appearance ───────────────────────────────────────
              _SectionHeader(title: context.l10n.appearance),
              BlocBuilder<ThemeCubit, ThemeState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      _AppearanceTile(
                        label: context.l10n.systemDefault,
                        icon: Icons.brightness_auto_outlined,
                        selected: state.themeMode == ThemeMode.system,
                        onTap: () =>
                            context.read<ThemeCubit>().updateTheme(ThemeMode.system),
                      ),
                      _AppearanceTile(
                        label: context.l10n.light,
                        icon: Icons.wb_sunny_outlined,
                        selected: state.themeMode == ThemeMode.light,
                        onTap: () =>
                            context.read<ThemeCubit>().updateTheme(ThemeMode.light),
                      ),
                      _AppearanceTile(
                        label: context.l10n.dark,
                        icon: Icons.dark_mode_outlined,
                        selected: state.themeMode == ThemeMode.dark,
                        onTap: () =>
                            context.read<ThemeCubit>().updateTheme(ThemeMode.dark),
                      ),
                    ],
                  );
                },
              ),

              const Gap(20),

              // ── Notifications ───────────────────────────────────
              _SectionHeader(title: context.l10n.notifications),
              BlocBuilder<NotificationCubit, bool>(
                builder: (context, enabled) {
                  return SwitchListTile.adaptive(
                    activeColor: Platform.isIOS ? ColorConstant.primary : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                    title: Text(context.l10n.pushNotifications),
                    subtitle: Text(context.l10n.orderUpdatesAndPromotions,
                        style: context.bodyExtraSmall?.copyWith(color: ColorConstant.manatee)),
                    value: enabled,
                    onChanged: (value) async {
                      if (value) {
                        final status = await NotificationService.instance.getPermissionStatus();
                        if (status == AuthorizationStatus.denied) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(context.l10n.notificationsPermissionDenied)),
                            );
                          }
                          return;
                        }
                      }
                      if (context.mounted) {
                        context.read<NotificationCubit>().setEnabled(value);
                      }
                    },
                  );
                },
              ),

              const Gap(20),

              // ── About ────────────────────────────────────────────
              _SectionHeader(title: context.l10n.about),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                title: Text(context.l10n.version),
                trailing: Text('1.0.0',
                    style: context.bodySmall?.copyWith(color: ColorConstant.manatee)),
              ),
              const Gap(16),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Text(
        title,
        style: context.bodyExtraSmall?.copyWith(
          color: ColorConstant.manatee,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.label,
    required this.subtitle,
    required this.locale,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final Locale locale;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      onTap: onTap,
      title: Text(label),
      subtitle: Text(subtitle,
          style: context.bodyExtraSmall?.copyWith(color: ColorConstant.manatee)),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: ColorConstant.primary)
          : Icon(Icons.circle_outlined, color: ColorConstant.manatee),
    );
  }
}

class _AppearanceTile extends StatelessWidget {
  const _AppearanceTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      onTap: onTap,
      leading: Icon(icon, color: selected ? ColorConstant.primary : null),
      title: Text(label, style: TextStyle(color: selected ? ColorConstant.primary : null)),
      trailing: selected ? Icon(Icons.check_circle_rounded, color: ColorConstant.primary) : null,
    );
  }
}
