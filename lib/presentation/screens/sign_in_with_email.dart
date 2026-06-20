import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:gap/gap.dart';
import 'package:minimumz/blocs/auth/authentication_bloc.dart';
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/cubits/wishlist/wishlist_cubit.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';
import 'package:minimumz/domain/services/user_data_sync_service.dart';
import '../components/index.dart';
import '../routes/app_router.dart';

@RoutePage()
class SignInWithEmailScreen extends StatefulWidget {
  const SignInWithEmailScreen({super.key});

  @override
  State<SignInWithEmailScreen> createState() => _SignInWithEmailScreenState();
}

class _SignInWithEmailScreenState extends State<SignInWithEmailScreen> {
  bool _obscurePassword = true;
  bool _submitted = false;
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitted) return;
    if (!_formKey.currentState!.validate()) return;
    _submitted = true;
    context.read<AuthenticationBloc>().add(
          AuthenticationEvent.loginCustomer(
              email: _emailCtrl.text, password: _passwordCtrl.text),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        state.maybeMap(
          loading: (_) => EasyLoading.show(maskType: EasyLoadingMaskType.black),
          loggedIn: (_) async {
            PreferenceRepository.instance.setGuest(value: false);
            final cartId = PreferenceRepository.instance.cartId;
            if (cartId != null) {
              try {
                final result = await getIt<DataStore>().carts.transferToCustomer(cartId: cartId);
                // Backend may return a different cart ID if merge happened (user had existing cart).
                final returnedId = result?.cart?.id;
                if (returnedId != null && returnedId != cartId) {
                  await PreferenceRepository.instance.setCartId(returnedId);
                  if (result?.cart != null) {
                    await PreferenceRepository.instance.setCachedCart(result!.cart!);
                  }
                }
              } catch (_) {}
            }
            if (context.mounted) {
              await syncUserDataOnLogin(context.read<WishlistCubit>());
            }
            EasyLoading.dismiss();
            if (context.mounted) context.router.replaceAll([const DashboardRoute()]);
          },
          orElse: () {
            _submitted = false;
            EasyLoading.dismiss();
          },
        );
      },
      builder: (context, state) {
        final error = state.mapOrNull(
          error: (_) => _.failure.message,
          loggedInAsGuest: (_) => _.failure?.message,
          loggedOut: (_) => _.failure?.message,
        );

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

                        // ── Heading ─────────────────────────────────
                        Text(context.l10n.welcomeBack,
                            style: context.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        const Gap(4),
                        Text(context.l10n.signInToAccount,
                            style: context.bodyMedium
                                ?.copyWith(color: ColorConstant.manatee)),
                        const Gap(32),

                        // ── Error banner ─────────────────────────────
                        AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          child: error != null
                              ? Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 20),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffFFE9E9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          color: Colors.redAccent, size: 18),
                                      const Gap(8),
                                      Expanded(
                                        child: Text(error,
                                            style: context.bodySmall?.copyWith(
                                                color: Colors.redAccent)),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),

                        // ── Fields ───────────────────────────────────
                        CustomTextField(
                          controller: _emailCtrl,
                          labelText: context.l10n.emailAddress,
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) => (val == null || val.isEmpty)
                              ? context.l10n.required
                              : null,
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
                          validator: (val) {
                            if (val == null || val.isEmpty) return context.l10n.required;
                            if (val.length < 8) {
                              return context.l10n.minimum8Characters;
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                        ),

                        // ── Forgot password ──────────────────────────
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: TextButton(
                            onPressed: () => context.router
                                .push(const ForgotPasswordRoute()),
                            child: Text(context.l10n.forgotPassword,
                                style: context.bodySmall?.copyWith(
                                    color: ColorConstant.brownDark)),
                          ),
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
                            child: Text(context.l10n.signIn,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const Gap(16),

                        // ── Sign up link ─────────────────────────────
                        Center(
                          child: GestureDetector(
                            onTap: () =>
                                context.router.push(const SignUpRoute()),
                            child: Text.rich(
                              TextSpan(
                                text: '${context.l10n.dontHaveAccount} ',
                                style: context.bodySmall
                                    ?.copyWith(color: ColorConstant.manatee),
                                children: [
                                  TextSpan(
                                    text: context.l10n.signUp,
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
        );
      },
    );
  }
}
