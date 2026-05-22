import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/presentation/components/index.dart';

@RoutePage()
class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({super.key});

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  List<Address> _addresses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await getIt<DataStore>().customers.listShippingAddresses();
      if (mounted) setState(() { _addresses = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Failed to load addresses'; _loading = false; });
    }
  }

  Future<void> _delete(Address address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete address?'),
        content: Text('${address.firstName ?? ''} ${address.lastName ?? ''}\n${address.address1 ?? ''}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await getIt<DataStore>().customers.deleteShippingAddress(addressId: address.id!);
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to delete address')),
        );
      }
    }
  }

  Future<void> _showForm({Address? existing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.theme.scaffoldBackgroundColor,
      builder: (_) => _AddressFormSheet(existing: existing),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = context.bottomViewPadding == 0.0 ? 30.0 : context.bottomViewPadding;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.theme.appBarTheme.systemOverlayStyle!,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Address Book',
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _showForm(),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  )
                : _addresses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.location_off_outlined, size: 56, color: ColorConstant.manatee),
                            const Gap(12),
                            Text('No saved addresses yet', style: context.bodyMedium?.copyWith(color: ColorConstant.manatee)),
                            const Gap(16),
                            FilledButton.icon(
                              onPressed: () => _showForm(),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Address'),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
                        separatorBuilder: (_, __) => const Divider(height: 24),
                        itemCount: _addresses.length,
                        itemBuilder: (context, index) {
                          final addr = _addresses[index];
                          return _AddressCard(
                            address: addr,
                            onEdit: () => _showForm(existing: addr),
                            onDelete: () => _delete(addr),
                          );
                        },
                      ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onEdit,
    required this.onDelete,
  });

  final Address address;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final name = '${address.firstName ?? ''} ${address.lastName ?? ''}'.trim();
    final line2 = [address.address2, address.city, address.province, address.postalCode, address.countryCode]
        .where((v) => v != null && v.isNotEmpty)
        .join(', ');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.location_on_outlined, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (name.isNotEmpty) Text(name, style: context.bodyMediumW500),
              if (address.address1 != null) Text(address.address1!, style: context.bodyMedium),
              if (line2.isNotEmpty)
                Text(line2, style: context.bodySmall?.copyWith(color: ColorConstant.manatee)),
            ],
          ),
        ),
        IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: onEdit, visualDensity: VisualDensity.compact),
        IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red), onPressed: onDelete, visualDensity: VisualDensity.compact),
      ],
    );
  }
}

class _AddressFormSheet extends StatefulWidget {
  const _AddressFormSheet({this.existing});
  final Address? existing;

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _address1;
  late final TextEditingController _address2;
  late final TextEditingController _city;
  late final TextEditingController _countryCode;
  late final TextEditingController _province;
  late final TextEditingController _postalCode;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _firstName   = TextEditingController(text: a?.firstName ?? '');
    _lastName    = TextEditingController(text: a?.lastName ?? '');
    _address1    = TextEditingController(text: a?.address1 ?? '');
    _address2    = TextEditingController(text: a?.address2 ?? '');
    _city        = TextEditingController(text: a?.city ?? '');
    _countryCode = TextEditingController(text: a?.countryCode ?? '');
    _province    = TextEditingController(text: a?.province ?? '');
    _postalCode  = TextEditingController(text: a?.postalCode ?? '');
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _address1.dispose();
    _address2.dispose();
    _city.dispose();
    _countryCode.dispose();
    _province.dispose();
    _postalCode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final address = Address(
      firstName:   _firstName.text.trim(),
      lastName:    _lastName.text.trim(),
      address1:    _address1.text.trim(),
      address2:    _address2.text.trim().isEmpty ? null : _address2.text.trim(),
      city:        _city.text.trim(),
      countryCode: _countryCode.text.trim().toUpperCase(),
      province:    _province.text.trim().isEmpty ? null : _province.text.trim(),
      postalCode:  _postalCode.text.trim().isEmpty ? null : _postalCode.text.trim(),
    );

    try {
      if (widget.existing?.id != null) {
        await getIt<DataStore>().customers.updateShippingAddress(
          addressId: widget.existing!.id!,
          address: address,
        );
      } else {
        await getIt<DataStore>().customers.addShippingAddress(address: address);
      }
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save address. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10.0)),
      borderSide: BorderSide(width: 0, color: Colors.transparent),
    );

    InputDecoration field(String hint, {bool required = false}) => InputDecoration(
      filled: true,
      isDense: true,
      hintText: required ? '$hint *' : hint,
      border: inputBorder,
      enabledBorder: inputBorder,
      focusedBorder: inputBorder,
      hintStyle: TextStyle(color: ColorConstant.manatee),
      fillColor: context.theme.cardColor,
    );

    String? req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              automaticallyImplyLeading: false,
              title: Text(widget.existing != null ? 'Edit Address' : 'Add Address'),
              actions: [
                _loading
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : TextButton(onPressed: _submit, child: const Text('Save')),
              ],
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _firstName,
                          textInputAction: TextInputAction.next,
                          decoration: field('First Name', required: true),
                          validator: req,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _lastName,
                          textInputAction: TextInputAction.next,
                          decoration: field('Last Name', required: true),
                          validator: req,
                        ),
                      ),
                    ],
                  ),
                  const Gap(10),
                  TextFormField(
                    controller: _address1,
                    textInputAction: TextInputAction.next,
                    decoration: field('Address Line 1', required: true),
                    validator: req,
                  ),
                  const Gap(10),
                  TextFormField(
                    controller: _address2,
                    textInputAction: TextInputAction.next,
                    decoration: field('Address Line 2 (optional)'),
                  ),
                  const Gap(10),
                  TextFormField(
                    controller: _city,
                    textInputAction: TextInputAction.next,
                    decoration: field('City', required: true),
                    validator: req,
                  ),
                  const Gap(10),
                  Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: TextFormField(
                          controller: _countryCode,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.characters,
                          maxLength: 2,
                          decoration: field('Country', required: true).copyWith(counterText: ''),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            if (v.trim().length != 2) return '2 chars';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _province,
                          textInputAction: TextInputAction.next,
                          decoration: field('Province/State'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _postalCode,
                          textInputAction: TextInputAction.done,
                          decoration: field('Postal Code'),
                          onFieldSubmitted: (_) => _submit(),
                        ),
                      ),
                    ],
                  ),
                  const Gap(10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
