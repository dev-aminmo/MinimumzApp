import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:minimumz/blocs/auth/authentication_bloc.dart';
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import '../../di/di.dart';
import '../../domain/repository/preference_repository.dart';
import '../routes/app_router.dart';

@RoutePage()
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.theme.appBarTheme.systemOverlayStyle!,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Branding ─────────────────────────────────────────
                const Spacer(flex: 2),
                Image.asset('assets/images/logo_minimumz.png', height: 80),
                const Gap(20),
                Text(context.l10n.appName,
                    style: context.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Gap(8),
                Text(
                  context.l10n.tagline,
                  style: context.bodyMedium
                      ?.copyWith(color: ColorConstant.manatee),
                ),
                const Spacer(flex: 2),

                // ── Actions ───────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: ColorConstant.brownDark,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.mail_outline, size: 20),
                    label: Text(context.l10n.continueWithEmail,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                    onPressed: () =>
                        context.router.push(const SignInWithEmailRoute()),
                  ),
                ),
                const Gap(14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: ColorConstant.primary.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () =>
                        context.router.push(const SignUpRoute()),
                    child: Text(context.l10n.createAnAccount,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: ColorConstant.brownDark)),
                  ),
                ),

                // ── Guest ─────────────────────────────────────────────
                if (!getIt<PreferenceRepository>().isGuest) ...[
                  const Gap(24),
                  GestureDetector(
                    onTap: () {
                      context
                          .read<AuthenticationBloc>()
                          .add(const AuthenticationEvent.loginAsGuest());
                      context.router.replaceAll([const DashboardRoute()]);
                    },
                    child: Text(
                      context.l10n.continueAsGuest,
                      style: context.bodySmall?.copyWith(
                        color: ColorConstant.manatee,
                        decoration: TextDecoration.underline,
                        decorationColor: ColorConstant.manatee,
                      ),
                    ),
                  ),
                ],

                // ── Commented social buttons (kept for future use) ────
                // const Gap(10),
                // SizedBox(width: double.infinity, height: 50,
                //   child: SignInButton(Buttons.googleDark, onPressed: () {})),
                // const Gap(10),
                // SizedBox(width: double.infinity, height: 50,
                //   child: SignInButton(Buttons.facebook, onPressed: () {})),
                // const Gap(10),
                // SizedBox(width: double.infinity, height: 50,
                //   child: SignInButton(Buttons.twitter, onPressed: () {})),

                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
