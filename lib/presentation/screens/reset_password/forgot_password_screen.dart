import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/presentation/components/index.dart';
import 'package:minimumz/presentation/routes/app_router.dart';

import '../../../common/colors.dart';

@RoutePage()
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await getIt<DataStore>().auth.requestPasswordReset(
            email: _emailCtrl.text.trim(),
          );
      if (mounted) {
        context.router.push(VerificationCodeRoute(email: _emailCtrl.text.trim()));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.failedToSendResetCode)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.theme.appBarTheme.systemOverlayStyle!,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: const CustomAppBar(),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Gap(8),

                    // ── Heading ──────────────────────────────────────
                    Text(context.l10n.forgotPasswordTitle,
                        style: context.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const Gap(4),
                    Text(context.l10n.enterEmailToReset,
                        style: context.bodyMedium
                            ?.copyWith(color: ColorConstant.manatee)),

                    const Spacer(),

                    // ── Illustration ──────────────────────────────────
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: ColorConstant.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: ColorConstant.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_reset_rounded,
                              size: 36,
                              color: ColorConstant.primary,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const Spacer(),

                    // ── Email field ───────────────────────────────────
                    CustomTextField(
                      controller: _emailCtrl,
                      labelText: context.l10n.emailAddress,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return context.l10n.emailRequired;
                        if (!v.contains('@')) return context.l10n.enterValidEmail;
                        return null;
                      },
                    ),
                    const Gap(24),

                    // ── Submit ────────────────────────────────────────
                    SizedBox(
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
                            : Text(context.l10n.sendResetCode,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const Gap(20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
