import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
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
      appBar: const CustomAppBar(title: 'Account Information'),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        children: [
          const Gap(20.0),
          ListTile(
            leading: const Icon(Icons.account_box_rounded),
            onTap: () async {
              await showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: context.theme.scaffoldBackgroundColor,
                  builder: (context) {
                    return const UpdateInformation();
                  });
            },
            title: const Text('Update Information'),
          ),
          const Divider(height: 0),
          ListTile(
            onTap: () => context.router.push(const AddressBookRoute()),
            leading: const Icon(Icons.location_history),
            title: const Text('Address Book'),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.security),
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: context.theme.scaffoldBackgroundColor,
              builder: (_) => _PasswordSheet(),
            ),
            title: const Text('Change Password'),
          ),
        ],
      ),
    );
  }
}

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
          const SnackBar(content: Text('Password updated successfully')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Current password is incorrect')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
              title: const Text('Change Password'),
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
                        onPressed: _submit,
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
                    controller: _currentCtrl,
                    obscureText: !_showCurrent,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: 'Current Password',
                      suffixIcon: IconButton(
                        icon: Icon(_showCurrent
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _showCurrent = !_showCurrent),
                      ),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const Gap(10),
                  TextFormField(
                    controller: _newCtrl,
                    obscureText: !_showNew,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      hintText: 'New Password',
                      suffixIcon: IconButton(
                        icon: Icon(_showNew
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _showNew = !_showNew),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 6) return 'At least 6 characters';
                      return null;
                    },
                  ),
                  const Gap(10),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                        hintText: 'Confirm New Password'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v != _newCtrl.text) return 'Passwords do not match';
                      return null;
                    },
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
