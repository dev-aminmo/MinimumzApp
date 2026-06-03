import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:dio/dio.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';
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
    // Show cached data immediately, then refresh in background
    final cached = PreferenceRepository.instance.cachedAddresses;
    if (cached != null) {
      _addresses = cached;
      _loading = false;
    }
    _load(silent: cached != null);
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = _addresses.isEmpty;
        _error = null;
      });
    }
    try {
      final list = await getIt<DataStore>().customers.listShippingAddresses();
      await PreferenceRepository.instance.setCachedAddresses(list);
      if (mounted) setState(() { _addresses = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() {
        if (_addresses.isEmpty) _error = 'load_failed';
        _loading = false;
      });
    }
  }

  Future<void> _delete(Address address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.deleteAddressTitle),
        content: Text('${address.firstName ?? ''} ${address.lastName ?? ''}\n${address.address1 ?? ''}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ctx.l10n.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    // Optimistic remove
    final index = _addresses.indexOf(address);
    setState(() => _addresses = List.of(_addresses)..remove(address));
    try {
      await getIt<DataStore>().customers.deleteShippingAddress(addressId: address.id!);
    } catch (_) {
      // Revert on failure
      if (mounted) {
        setState(() => _addresses = List.of(_addresses)..insert(index, address));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.failedToDeleteAddress)),
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
    _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = context.bottomViewPadding == 0.0 ? 30.0 : context.bottomViewPadding;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.theme.appBarTheme.systemOverlayStyle!,
      child: Scaffold(
        appBar: CustomAppBar(
          title: context.l10n.addressBook,
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
                        Text(context.l10n.failedToLoadAddresses),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _load, child: Text(context.l10n.retry)),
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
                            Text(context.l10n.noSavedAddresses, style: context.bodyMedium?.copyWith(color: ColorConstant.manatee)),
                            const Gap(16),
                            FilledButton.icon(
                              onPressed: () => _showForm(),
                              icon: const Icon(Icons.add),
                              label: Text(context.l10n.addAddress),
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
  late final TextEditingController _phone;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    // For edits: preserve the address's own country.
    // For new addresses: default to the currently selected country.
    final prefCountry = PreferenceRepository.instance.country?.iso2?.toUpperCase();
    final initialCountry = (a?.countryCode?.isNotEmpty == true)
        ? a!.countryCode!.toUpperCase()
        : (prefCountry ?? '');
    _firstName   = TextEditingController(text: a?.firstName ?? '');
    _lastName    = TextEditingController(text: a?.lastName ?? '');
    _address1    = TextEditingController(text: a?.address1 ?? '');
    _address2    = TextEditingController(text: a?.address2 ?? '');
    _city        = TextEditingController(text: a?.city ?? '');
    _countryCode = TextEditingController(text: initialCountry);
    _province    = TextEditingController(text: a?.province ?? '');
    _postalCode  = TextEditingController(text: a?.postalCode ?? '');
    _phone       = TextEditingController(text: a?.phone ?? '');
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
    _phone.dispose();
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
      province:    _province.text.trim(),
      postalCode:  _postalCode.text.trim(),
      phone:       _phone.text.trim().isEmpty ? null : _phone.text.trim(),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_apiError(e, context.l10n.failedToSaveAddressRetry))),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  OutlineInputBorder _border(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  InputDecoration _field(
    BuildContext context,
    String label, {
    IconData? icon,
    bool req = false,
  }) =>
      InputDecoration(
        labelText: req ? '$label *' : label,
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: ColorConstant.manatee)
            : null,
        filled: true,
        fillColor: context.theme.cardColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: _border(ColorConstant.manatee.withValues(alpha: 0.3)),
        enabledBorder: _border(ColorConstant.manatee.withValues(alpha: 0.3)),
        focusedBorder: _border(ColorConstant.primary, width: 1.5),
        errorBorder: _border(Colors.redAccent),
        focusedErrorBorder: _border(Colors.redAccent, width: 1.5),
      );

  String _countryDisplayName(String code) {
    if (code.isEmpty) return '';
    final regions = PreferenceRepository.instance.cachedRegions ?? [];
    for (final region in regions) {
      for (final c in region.countries ?? []) {
        if (c.iso2?.toUpperCase() == code.toUpperCase()) {
          return c.displayName ?? c.name ?? code.toUpperCase();
        }
      }
    }
    // Fallback: if the code matches the preference country, use its name.
    final pref = PreferenceRepository.instance.country;
    if (pref?.iso2?.toUpperCase() == code.toUpperCase()) {
      return pref?.name ?? code.toUpperCase();
    }
    return code.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    String? reqValidator(String? v) =>
        (v == null || v.trim().isEmpty) ? context.l10n.required : null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                    child: Icon(Icons.location_on_outlined,
                        color: ColorConstant.primary, size: 22),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      widget.existing != null
                          ? context.l10n.editAddress
                          : context.l10n.addAddress,
                      style: context.bodyLargeW600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 0),
            // ── Fields ────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  children: [
                    // Country (read-only)
                    _ReadOnlyAddressField(
                      label: context.l10n.country,
                      value: _countryDisplayName(_countryCode.text),
                      icon: Icons.flag_outlined,
                    ),
                    const Gap(14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstName,
                            textInputAction: TextInputAction.next,
                            decoration: _field(context, context.l10n.firstName,
                                icon: Icons.person_outline, req: true),
                            validator: reqValidator,
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastName,
                            textInputAction: TextInputAction.next,
                            decoration: _field(context, context.l10n.lastName, req: true),
                            validator: reqValidator,
                          ),
                        ),
                      ],
                    ),
                    const Gap(14),
                    TextFormField(
                      controller: _address1,
                      textInputAction: TextInputAction.next,
                      decoration: _field(context, context.l10n.addressLine1,
                          icon: Icons.home_outlined, req: true),
                      validator: reqValidator,
                    ),
                    const Gap(14),
                    TextFormField(
                      controller: _address2,
                      textInputAction: TextInputAction.next,
                      decoration: _field(context, context.l10n.addressLine2Optional),
                    ),
                    const Gap(14),
                    TextFormField(
                      controller: _city,
                      textInputAction: TextInputAction.next,
                      decoration: _field(context, context.l10n.city,
                          icon: Icons.location_city_outlined, req: true),
                      validator: reqValidator,
                    ),
                    const Gap(14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _province,
                            textInputAction: TextInputAction.next,
                            decoration: _field(context, context.l10n.provinceState, req: true),
                            validator: reqValidator,
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: TextFormField(
                            controller: _postalCode,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.number,
                            decoration: _field(context, context.l10n.postalCode, req: true),
                            validator: reqValidator,
                          ),
                        ),
                      ],
                    ),
                    const Gap(14),
                    TextFormField(
                      controller: _phone,
                      textInputAction: TextInputAction.done,
                      keyboardType: TextInputType.phone,
                      decoration: _field(context, context.l10n.phone,
                          icon: Icons.phone_outlined),
                      onFieldSubmitted: (_) => _submit(),
                    ),
                  ],
                ),
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
                  onPressed: _loading ? null : _submit,
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

class _ReadOnlyAddressField extends StatelessWidget {
  const _ReadOnlyAddressField({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: ColorConstant.manatee.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorConstant.manatee.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: ColorConstant.manatee),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: context.bodyExtraSmall
                        ?.copyWith(color: ColorConstant.manatee)),
                const Gap(2),
                Text(value, style: context.bodySmallW500),
              ],
            ),
          ),
          Icon(Icons.lock_outline,
              size: 14, color: ColorConstant.manatee.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}

String _apiError(Object e, String fallback) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    }
  }
  return fallback;
}
