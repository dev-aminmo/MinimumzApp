import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:gap/gap.dart';
import 'package:minimumz/blocs/auth/authentication_bloc.dart';
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import '../../di/di.dart';
import '../../domain/repository/preference_repository.dart';
import '../components/index.dart';
import '../routes/app_router.dart';

@RoutePage()
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthenticationBloc>().add(AuthenticationEvent.signUpCustomer(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
        firstName: _nameCtrl.text.trim(),
        lastName: ''));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        state.maybeMap(
          loading: (_) => EasyLoading.show(maskType: EasyLoadingMaskType.black),
          loggedIn: (_) {
            getIt<PreferenceRepository>().setGuest(value: false);
            EasyLoading.dismiss();
            context.router.replaceAll([const DashboardRoute()]);
          },
          orElse: () => EasyLoading.dismiss(),
        );
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
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

                      // ── Heading ─────────────────────────────────
                      Text(context.l10n.createAccount,
                          style: context.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const Gap(4),
                      Text(context.l10n.fillDetails,
                          style: context.bodyMedium
                              ?.copyWith(color: ColorConstant.manatee)),
                      const Gap(32),

                      // ── Fields ───────────────────────────────────
                      CustomTextField(
                        controller: _nameCtrl,
                        labelText: context.l10n.fullName,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        validator: (val) =>
                            (val == null || val.trim().isEmpty) ? context.l10n.required : null,
                      ),
                      const Gap(12),
                      CustomTextField(
                        controller: _emailCtrl,
                        labelText: context.l10n.emailAddress,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (val) {
                          if (val == null || val.isEmpty) return context.l10n.required;
                          if (!val.contains('@')) return context.l10n.enterValidEmail;
                          return null;
                        },
                      ),
                      const Gap(12),
                      CustomTextField(
                        controller: _passwordCtrl,
                        labelText: context.l10n.password,
                        keyboardType: TextInputType.text,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            size: 20,
                            color: ColorConstant.manatee,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (val) {
                          if (val == null || val.isEmpty) return context.l10n.required;
                          if (val.length < 8) return context.l10n.minimum8Characters;
                          return null;
                        },
                      ),

                      const Spacer(),

                      // ── Submit ───────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: ColorConstant.brownDark,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _submit,
                          child: Text(context.l10n.createAccount,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      const Gap(16),

                      // ── Sign in link ─────────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: () => context.router.maybePop(),
                          child: Text.rich(
                            TextSpan(
                              text: '${context.l10n.alreadyHaveAccount} ',
                              style: context.bodySmall
                                  ?.copyWith(color: ColorConstant.manatee),
                              children: [
                                TextSpan(
                                  text: context.l10n.signIn,
                                  style: context.bodySmallW500?.copyWith(
                                      color: ColorConstant.brownDark),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Gap(12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
