import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:minimumz/blocs/auth/authentication_bloc.dart';
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
    _firstNameCtrl =
        TextEditingController(text: customer?.firstName ?? '');
    _lastNameCtrl =
        TextEditingController(text: customer?.lastName ?? '');
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
          const SnackBar(content: Text('Information updated')),
        );
      },
      (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.message.isEmpty ? 'Update failed' : error.message)),
      ),
    );
  }

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
            AppBar(
              automaticallyImplyLeading: false,
              title: const Text('Update Information'),
              actions: [
                _loading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : TextButton(
                        onPressed: _save,
                        child: const Text('Save'),
                      ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20)
                  .copyWith(bottom: 20),
              child: Column(
                children: [
                  TextFormField(
                    controller: _firstNameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration:
                        const InputDecoration(hintText: 'First Name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const Gap(10.0),
                  TextFormField(
                    controller: _lastNameCtrl,
                    textInputAction: TextInputAction.next,
                    decoration:
                        const InputDecoration(hintText: 'Last Name'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const Gap(10.0),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _save(),
                    decoration:
                        const InputDecoration(hintText: 'Phone (optional)'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
