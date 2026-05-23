import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/presentation/routes/app_router.dart';

import '../../../common/colors.dart';
import '../../components/index.dart';

@RoutePage()
class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({
    super.key,
    required this.email,
    required this.code,
  });

  final String email;
  final String code;

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await getIt<DataStore>().auth.confirmPasswordReset(
            email: widget.email,
            code: widget.code,
            password: _passwordCtrl.text,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.passwordResetSuccess)),
        );
        context.router.replaceAll([const SignInRoute()]);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.passwordResetFailed)),
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
          bottomNavigationBar: BottomNavButton(
            label: _loading ? context.l10n.resetting : context.l10n.resetPassword,
            onTap: _loading ? () {} : _submit,
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: Center(
                          child: Text(context.l10n.newPassword, style: context.headlineMedium),
                        ),
                      ),
                      SvgPicture.asset('assets/images/forgot_password.svg'),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: !_showPassword,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: context.l10n.newPassword,
                                suffixIcon: IconButton(
                                  icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _showPassword = !_showPassword),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return context.l10n.required;
                                if (v.length < 6) return context.l10n.atLeast6Characters;
                                return null;
                              },
                            ),
                            const Gap(10),
                            TextFormField(
                              controller: _confirmCtrl,
                              obscureText: !_showConfirm,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              decoration: InputDecoration(
                                labelText: context.l10n.confirmPassword,
                                suffixIcon: IconButton(
                                  icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return context.l10n.required;
                                if (v != _passwordCtrl.text) return context.l10n.passwordsDoNotMatch;
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Text(
                        context.l10n.writeNewPassword,
                        style: context.bodySmall?.copyWith(color: ColorConstant.manatee),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
