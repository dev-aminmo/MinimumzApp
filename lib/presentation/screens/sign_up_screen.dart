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
import '../../di/di.dart';
import '../../domain/repository/preference_repository.dart';
import 'package:minimumz/domain/services/user_data_sync_service.dart';
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
  int _nameErrorCount = 0;
  bool _submitted = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_submitted) return;
    if (!_formKey.currentState!.validate()) return;
    _submitted = true;
    final parts = _nameCtrl.text.trim().split(RegExp(r'[,\s]+')).where((p) => p.isNotEmpty).toList();
    final firstName = parts.sublist(0, parts.length - 1).join(' ');
    final lastName = parts.last;
    context.read<AuthenticationBloc>().add(AuthenticationEvent.signUpCustomer(
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
        firstName: firstName,
        lastName: lastName));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      listener: (context, state) {
        state.maybeMap(
          loading: (_) => EasyLoading.show(),
          loggedIn: (_) async {
            getIt<PreferenceRepository>().setGuest(value: false);
            final cartId = getIt<PreferenceRepository>().cartId;
            if (cartId != null) {
              try {
                final result = await getIt<DataStore>().carts.transferToCustomer(cartId: cartId);
                // Backend may return a different cart ID if merge happened (user had existing cart).
                final returnedId = result?.cart?.id;
                if (returnedId != null && returnedId != cartId) {
                  await getIt<PreferenceRepository>().setCartId(returnedId);
                  if (result?.cart != null) {
                    await getIt<PreferenceRepository>().setCachedCart(result!.cart!);
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
                      Text(context.l10n.createAccount,
                          style: context.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const Gap(4),
                      Text(context.l10n.fillDetails,
                          style: context.bodyMedium
                              ?.copyWith(color: ColorConstant.manatee)),
                      const Gap(32),

                      // ── Error banner ─────────────────────────────
                      AnimatedSize(
                        duration: const Duration(milliseconds: 250),
                        child: (error != null && error.isNotEmpty)
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
                        controller: _nameCtrl,
                        labelText: context.l10n.fullName,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            _nameErrorCount = 0;
                            return context.l10n.required;
                          }
                          final parts = val.trim().split(RegExp(r'[,\s]+')).where((p) => p.isNotEmpty).toList();
                          if (parts.length < 2) {
                            _nameErrorCount++;
                            return _nameErrorCount == 1
                                ? context.l10n.enterFullName
                                : context.l10n.fullNameHelper;
                          }
                          _nameErrorCount = 0;
                          return null;
                        },
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
      );
      },
    );
  }
}
