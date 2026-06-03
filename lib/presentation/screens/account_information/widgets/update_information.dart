import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:minimumz/blocs/auth/authentication_bloc.dart';
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/domain/usecase/account_information_usecase.dart';

class UpdateInformation extends StatefulWidget {
  const UpdateInformation({super.key});

  @override
  State<UpdateInformation> createState() => _UpdateInformationState();
}

class _UpdateInformationState extends State<UpdateInformation> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthenticationBloc>().state;
    final customer = authState.maybeMap(
      loggedIn: (s) => s.customer,
      orElse: () => null,
    );
    _firstNameCtrl = TextEditingController(text: customer?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: customer?.lastName ?? '');
    _phoneCtrl = TextEditingController(text: customer?.phone ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final result = await AccountInformationUsecase.instance.updateInformation(
      StorePostCustomersCustomerReq(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      (_) {
        context
            .read<AuthenticationBloc>()
            .add(const AuthenticationEvent.init());
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.informationUpdated)),
        );
      },
      (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.message.isEmpty
                ? context.l10n.failedToUpdate
                : error.message)),
      ),
    );
  }

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  InputDecoration _field(String label, {IconData? icon}) => InputDecoration(
        labelText: label,
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: ColorConstant.manatee)
            : null,
        filled: true,
        fillColor: context.theme.cardColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
                    child: Icon(Icons.person_outline_rounded,
                        color: ColorConstant.primary, size: 22),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(context.l10n.updateInformation,
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
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstNameCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: _field(context.l10n.firstName,
                              icon: Icons.person_outline),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? context.l10n.required
                              : null,
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: TextFormField(
                          controller: _lastNameCtrl,
                          textInputAction: TextInputAction.next,
                          decoration: _field(context.l10n.lastName),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? context.l10n.required
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const Gap(14),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _save(),
                    decoration: _field(context.l10n.phoneOptional,
                        icon: Icons.phone_outlined),
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
                  onPressed: _loading ? null : _save,
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
