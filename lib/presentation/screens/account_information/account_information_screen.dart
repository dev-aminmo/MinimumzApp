import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:minimumz/blocs/auth/authentication_bloc.dart';
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/presentation/components/custom_appbar.dart';
import 'package:minimumz/presentation/routes/app_router.dart';

import 'widgets/index.dart';

@RoutePage()
class AccountInformationScreen extends StatelessWidget {
  const AccountInformationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: context.l10n.accountInformation),
      body: BlocBuilder<AuthenticationBloc, AuthenticationState>(
        builder: (context, authState) {
          final customer = authState.maybeMap(
            loggedIn: (s) => s.customer,
            orElse: () => null,
          );
          final name =
              '${customer?.firstName ?? ''} ${customer?.lastName ?? ''}'.trim();
          final email = customer?.email ?? '';
          final initials = _initials(name);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
            children: [
              // ── Profile card ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor:
                          ColorConstant.primary.withValues(alpha: 0.15),
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: ColorConstant.primary,
                        ),
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (name.isNotEmpty)
                            Text(name, style: context.bodyLargeW600),
                          if (email.isNotEmpty)
                            const Gap(2),
                          if (email.isNotEmpty)
                            Text(
                              email,
                              style: context.bodySmall
                                  ?.copyWith(color: ColorConstant.manatee),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(28),

              // ── Section label ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  context.l10n.settings,
                  style: context.bodyExtraSmall?.copyWith(
                    color: ColorConstant.manatee,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              // ── Action tiles ──────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: context.theme.cardColor,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    _ActionTile(
                      icon: Icons.person_outline_rounded,
                      title: context.l10n.updateInformation,
                      isFirst: true,
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: context.theme.scaffoldBackgroundColor,
                        builder: (_) => const UpdateInformation(),
                      ),
                    ),
                    Divider(
                      height: 0,
                      indent: 66,
                      color: ColorConstant.manatee.withValues(alpha: 0.15),
                    ),
                    _ActionTile(
                      icon: Icons.location_on_outlined,
                      title: context.l10n.addressBook,
                      onTap: () =>
                          context.router.push(const AddressBookRoute()),
                    ),
                    Divider(
                      height: 0,
                      indent: 66,
                      color: ColorConstant.manatee.withValues(alpha: 0.15),
                    ),
                    _ActionTile(
                      icon: Icons.lock_outline_rounded,
                      title: context.l10n.changePassword,
                      isLast: true,
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: context.theme.scaffoldBackgroundColor,
                        builder: (_) => _PasswordSheet(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _initials(String name) {
  final parts =
      name.trim().split(' ').where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.vertical(
      top: isFirst ? const Radius.circular(18) : Radius.zero,
      bottom: isLast ? const Radius.circular(18) : Radius.zero,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: radius,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: ColorConstant.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, size: 19, color: ColorConstant.primary),
            ),
            const Gap(14),
            Expanded(
              child: Text(title, style: context.bodyMediumW500),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: ColorConstant.manatee.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Password sheet ────────────────────────────────────────────────────────────

class _PasswordSheet extends StatefulWidget {
  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await getIt<DataStore>().customers.changePassword(
            currentPassword: _currentCtrl.text,
            newPassword: _newCtrl.text,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.passwordUpdated)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.currentPasswordIncorrect)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  InputDecoration _field(String label, {required Widget suffix}) =>
      InputDecoration(
        labelText: label,
        filled: true,
        fillColor: context.theme.cardColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        suffixIcon: suffix,
        border: _border(ColorConstant.manatee.withValues(alpha: 0.3)),
        enabledBorder: _border(ColorConstant.manatee.withValues(alpha: 0.3)),
        focusedBorder: _border(ColorConstant.primary, width: 1.5),
        errorBorder: _border(Colors.redAccent),
        focusedErrorBorder: _border(Colors.redAccent, width: 1.5),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ───────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ColorConstant.manatee.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // ── Header ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ColorConstant.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_outline_rounded,
                        color: ColorConstant.primary, size: 22),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(context.l10n.changePassword,
                        style: context.bodyLargeW600),
                  ),
                ],
              ),
            ),
            const Divider(height: 0),
            // ── Fields ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                children: [
                  TextFormField(
                    controller: _currentCtrl,
                    obscureText: !_showCurrent,
                    textInputAction: TextInputAction.next,
                    decoration: _field(
                      context.l10n.currentPassword,
                      suffix: IconButton(
                        icon: Icon(_showCurrent
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _showCurrent = !_showCurrent),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? context.l10n.required : null,
                  ),
                  const Gap(14),
                  TextFormField(
                    controller: _newCtrl,
                    obscureText: !_showNew,
                    textInputAction: TextInputAction.next,
                    decoration: _field(
                      context.l10n.newPassword,
                      suffix: IconButton(
                        icon: Icon(_showNew
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _showNew = !_showNew),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return context.l10n.required;
                      if (v.length < 6) return context.l10n.atLeast6Characters;
                      return null;
                    },
                  ),
                  const Gap(14),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: !_showConfirm,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: _field(
                      context.l10n.confirmNewPassword,
                      suffix: IconButton(
                        icon: Icon(_showConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _showConfirm = !_showConfirm),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return context.l10n.required;
                      if (v != _newCtrl.text) return context.l10n.passwordsDoNotMatch;
                      return null;
                    },
                  ),
                ],
              ),
            ),
            // ── Save button ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: ColorConstant.brownDark,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          context.l10n.save,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
