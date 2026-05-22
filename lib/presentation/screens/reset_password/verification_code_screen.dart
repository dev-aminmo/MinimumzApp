import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import 'package:flutter_svg/svg.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/presentation/components/index.dart';
import 'package:minimumz/presentation/routes/app_router.dart';

import '../../../common/colors.dart';

@RoutePage()
class VerificationCodeScreen extends StatefulWidget {
  const VerificationCodeScreen({super.key, required this.email});

  final String email;

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  String _code = '';
  bool _loading = false;

  Future<void> _submit() async {
    if (_code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 4-digit code.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await getIt<DataStore>().auth.verifyResetCode(
            email: widget.email,
            code: _code,
          );
      if (mounted) {
        context.router.push(NewPasswordRoute(email: widget.email, code: _code));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid or expired code. Please try again.')),
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
          appBar: const CustomAppBar(),
          bottomNavigationBar: BottomNavButton(
            label: _loading ? 'Verifying...' : 'Confirm Code',
            onTap: _loading ? () {} : _submit,
          ),
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: Center(
                        child: Text('Verification Code', style: context.headlineMedium),
                      ),
                    ),
                    SvgPicture.asset('assets/images/forgot_password.svg'),
                    const SizedBox(height: 20),
                    OtpTextField(
                      numberOfFields: 4,
                      fieldWidth: 77,
                      borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                      showFieldAsBox: true,
                      onCodeChanged: (code) => setState(() => _code = code),
                      onSubmit: (code) {
                        setState(() => _code = code);
                        _submit();
                      },
                    ),
                  ],
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      child: Text(
                        'A 4-digit code was sent to ${widget.email}',
                        style: context.bodySmall?.copyWith(color: ColorConstant.manatee),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
