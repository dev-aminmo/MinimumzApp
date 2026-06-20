import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:gap/gap.dart';
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';
import 'package:minimumz/presentation/components/index.dart';
import 'package:minimumz/presentation/screens/cart/widgets/line_item_card.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:minimumz/cubits/locale/locale_cubit.dart';
import 'package:minimumz/data/data.dart';
import 'bloc/cart/cart_bloc.dart';
import '../../routes/app_router.dart';

@RoutePage()
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  ShippingOption? _selectedShipping;
  List<ShippingOption> _shippingOptions = [];
  bool _shippingLoading = false;

  @override
  void initState() {
    super.initState();
    _loadShippingOptions();
  }

  Future<void> _loadShippingOptions() async {
    final prefs = getIt<PreferenceRepository>();
    final cartId = prefs.cartId;
    if (cartId == null) return;

    // Show cached options instantly if available for this cart.
    final cached = prefs.cachedShippingOptions(cartId);
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _shippingOptions = cached;
        _selectedShipping = cached.first;
        _shippingLoading = false;
      });
      return; // Options are stable per cart — no need to re-fetch.
    }

    setState(() => _shippingLoading = true);
    try {
      final res = await getIt<DataStore>().shippingOptions.listCartOptions(cartId: cartId);
      if (mounted) {
        final options = res?.shippingOptions ?? [];
        prefs.setCachedShippingOptions(cartId, options);
        setState(() {
          _shippingOptions = options;
          if (options.isNotEmpty) _selectedShipping = options.first;
          _shippingLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _shippingLoading = false);
    }
  }

  Future<void> _checkout(BuildContext context, Cart cart) async {
    final cartId = cart.id;
    if (cartId == null) return;

    // Guest users must log in before checking out
    if (getIt<PreferenceRepository>().isGuest) {
      await context.router.push(const SignInRoute());
      // After returning, the auth bloc will reload the cart if login succeeded
      return;
    }

    if (cart.shippingAddress == null) {
      _showAddressSheet(context, cart);
      return;
    }

    EasyLoading.show(status: context.l10n.placingOrder);
    try {
      final result = await getIt<DataStore>().carts.complete(cartId: cartId);
      if (result?.type == 'order' && result?.order != null) {
        final prefs = getIt<PreferenceRepository>();
        await Future.wait([prefs.clearCartId(), prefs.clearCachedCart(), prefs.clearCachedOrdersList(), prefs.clearCachedShippingOptions()]);
        EasyLoading.dismiss();
        if (context.mounted) {
          context.read<CartBloc>().add(const CartEvent.loadCart());
          await context.router.push(OrderConfirmedRoute(order: result!.order!));
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.l10n.checkoutFailed)),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.checkoutFailed} ${e.toString()}')),
        );
      }
    } finally {
      EasyLoading.dismiss();
    }
  }

  Future<void> _showAddressSheet(BuildContext context, Cart cart) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<CartBloc>(),
        child: _AddressSheet(cart: cart),
      ),
    );
    // Address may have changed — reload shipping options (cache cleared on selection).
    if (mounted) _loadShippingOptions();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.theme.appBarTheme.systemOverlayStyle!,
      child: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          final cart = state.whenOrNull(loaded: (c) => c);
          final hasItems = cart?.items?.isNotEmpty ?? false;

          return Scaffold(
            appBar: CustomAppBar(title: context.l10n.cart),
            bottomNavigationBar: hasItems
                ? SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: SizedBox(
                        height: 52,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: ColorConstant.brownDark,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: cart != null ? () => _checkout(context, cart) : null,
                          child: Text(context.l10n.checkout,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ),
                  )
                : null,
            body: state.maybeWhen(
              loaded: (s) => s.items?.isEmpty ?? true
                  ? _EmptyCart()
                  : _CartBody(
                      cart: s,
                      shippingOptions: _shippingOptions,
                      selectedShipping: _selectedShipping,
                      shippingLoading: _shippingLoading,
                      onShippingSelected: (opt) => setState(() => _selectedShipping = opt),
                      onEditAddress: () => _showAddressSheet(context, s),
                    ),
              loading: () => cart != null 
                  ? _CartBody(
                      cart: cart,
                      shippingOptions: _shippingOptions,
                      selectedShipping: _selectedShipping,
                      shippingLoading: _shippingLoading,
                      onShippingSelected: (opt) => setState(() => _selectedShipping = opt),
                      onEditAddress: () => _showAddressSheet(context, cart),
                    )
                  : Center(
                      child: LoadingAnimationWidget.threeArchedCircle(
                          color: ColorConstant.primary, size: 40)),
              error: (message) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(message ?? context.l10n.errorLoadingCart),
                    const Gap(12),
                    ElevatedButton(
                        onPressed: () =>
                            context.read<CartBloc>().add(const CartEvent.loadCart()),
                        child: Text(context.l10n.retry)),
                  ],
                ),
              ),
              orElse: () => Center(
                  child: LoadingAnimationWidget.threeArchedCircle(
                      color: ColorConstant.primary, size: 40)),
            ),
          );
        },
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined,
              size: 72, color: ColorConstant.manatee.withValues(alpha: 0.4)),
          const Gap(16),
          Text(context.l10n.cartEmpty,
              style: context.bodyLargeW600?.copyWith(color: ColorConstant.manatee)),
          const Gap(8),
          Text(context.l10n.cartEmptySubtitle,
              style: context.bodySmall?.copyWith(color: ColorConstant.manatee)),
        ],
      ),
    );
  }
}

// ── Cart body ─────────────────────────────────────────────────────────────────

class _CartBody extends StatelessWidget {
  const _CartBody({
    required this.cart,
    required this.shippingOptions,
    required this.selectedShipping,
    required this.shippingLoading,
    required this.onShippingSelected,
    required this.onEditAddress,
  });

  final Cart cart;
  final List<ShippingOption> shippingOptions;
  final ShippingOption? selectedShipping;
  final bool shippingLoading;
  final ValueChanged<ShippingOption> onShippingSelected;
  final VoidCallback onEditAddress;

  @override
  Widget build(BuildContext context) {
    final currencyCode = PreferenceRepository.currencyCode;
    final locale = context.read<LocaleCubit>().state.languageCode;

    return CustomScrollView(
      slivers: [
        // ── Items ────────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                final items = cart.items!;
                if (i.isEven) {
                  final item = items[i ~/ 2];
                  // Stable key per line item: without it, Flutter reassociates a
                  // deleted card's State (its `_hidden`/`_qty`) with a surviving
                  // item by position, hiding items that are still in the cart and
                  // counted in the badge/total.
                  return LineItemCard(
                      key: ValueKey(item.id), lineItem: item, cartId: cart.id!);
                }
                return const Gap(10);
              },
              childCount: cart.items!.length * 2 - 1,
            ),
          ),
        ),

        // ── Delivery address ─────────────────────────────────────
        SliverToBoxAdapter(
          child: _Section(
            title: context.l10n.deliveryAddress,
            trailing: TextButton(
              onPressed: onEditAddress,
              child: Text(
                  cart.shippingAddress != null
                      ? context.l10n.change
                      : context.l10n.add,
                  style: TextStyle(color: ColorConstant.brownDark)),
            ),
            child: cart.shippingAddress == null
                ? _EmptyAddress(onTap: onEditAddress)
                : _AddressCard(address: cart.shippingAddress!),
          ),
        ),

        // ── Shipping method ───────────────────────────────────────
        SliverToBoxAdapter(
          child: _Section(
            title: context.l10n.shippingMethod,
            child: shippingLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  )
                : shippingOptions.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(context.l10n.noShippingOptions,
                            style:
                                context.bodySmall?.copyWith(color: ColorConstant.manatee)),
                      )
                    : Column(
                        children: shippingOptions.map((opt) {
                          final selected = selectedShipping?.id == opt.id;
                          final price = opt.amount != null
                              ? opt.amount!.formatAsPrice(currencyCode, locale: locale)
                              : context.l10n.free;
                          return _ShippingOptionTile(
                            option: opt,
                            price: price,
                            selected: selected,
                            onTap: () => onShippingSelected(opt),
                          );
                        }).toList(),
                      ),
          ),
        ),

        // ── Payment method ────────────────────────────────────────
        SliverToBoxAdapter(
          child: _Section(
            title: context.l10n.paymentMethod,
            child: const _PaymentMethodTile(),
          ),
        ),

        // ── Order summary ─────────────────────────────────────────
        SliverToBoxAdapter(
          child: _Section(
            title: context.l10n.orderSummary,
            child: Column(
              children: [
                _SummaryRow(context.l10n.subtotal,
                    cart.subTotal.formatAsPrice(currencyCode, locale: locale), context),
                const Gap(8),
                _SummaryRow(context.l10n.shipping,
                    cart.shippingTotal.formatAsPrice(currencyCode, locale: locale), context),
                if ((cart.taxTotal ?? 0) > 0) ...[
                  const Gap(8),
                  _SummaryRow(
                      context.l10n.tax, cart.taxTotal.formatAsPrice(currencyCode, locale: locale), context),
                ],
                if ((cart.discountTotal ?? 0) > 0) ...[
                  const Gap(8),
                  _SummaryRow(context.l10n.discount,
                      '- ${cart.discountTotal.formatAsPrice(currencyCode, locale: locale)}', context,
                      color: Colors.green),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 0),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.l10n.total, style: context.bodyMediumW500),
                    Text(cart.total.formatAsPrice(currencyCode, locale: locale),
                        style: context.bodyLargeW600
                            ?.copyWith(color: ColorConstant.brownDark)),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SliverGap(24),
      ],
    );
  }

  Widget _SummaryRow(String label, String value, BuildContext context, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: context.bodyMedium?.copyWith(color: ColorConstant.manatee)),
        Text(value,
            style: context.bodyMediumW500?.copyWith(
              color: color ?? context.theme.textTheme.bodyMedium?.color,
            )),
      ],
    );
  }
}

// ── Section wrapper ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: context.bodyMediumW500),
              if (trailing != null) trailing!,
            ],
          ),
          const Gap(12),
          child,
        ],
      ),
    );
  }
}

// ── Address widgets ───────────────────────────────────────────────────────────

class _EmptyAddress extends StatelessWidget {
  const _EmptyAddress({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: ColorConstant.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: ColorConstant.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_location_alt_outlined, color: ColorConstant.primary),
              const Gap(8),
              Text(context.l10n.addDeliveryAddress,
                  style: TextStyle(color: ColorConstant.primary, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address});
  final Address address;

  @override
  Widget build(BuildContext context) {
    final lines = [
      [address.firstName, address.lastName].where((e) => e?.isNotEmpty ?? false).join(' '),
      address.address1,
      [address.city, address.province].where((e) => e?.isNotEmpty ?? false).join(', '),
      address.phone,
    ].where((e) => e?.isNotEmpty ?? false).cast<String>().toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ColorConstant.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.location_on_outlined, color: ColorConstant.primary, size: 20),
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines
                .map((l) => Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(l, style: context.bodySmall),
                    ))
                .toList(),
          ),
        ),
        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
      ],
    );
  }
}

// ── Shipping option tile ──────────────────────────────────────────────────────

class _ShippingOptionTile extends StatelessWidget {
  const _ShippingOptionTile({
    required this.option,
    required this.price,
    required this.selected,
    required this.onTap,
  });

  final ShippingOption option;
  final String price;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? ColorConstant.primary
                : ColorConstant.manatee.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
          color: selected ? ColorConstant.primary.withValues(alpha: 0.05) : null,
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? ColorConstant.primary : ColorConstant.manatee,
              size: 20,
            ),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(option.name ?? context.l10n.standardShipping,
                      style: context.bodySmallW500),
                  if (option.providerId != null)
                    Text(
                        option.providerId == 'manual'
                            ? context.l10n.cashOnDelivery
                            : option.providerId!,
                        style: context.bodyExtraSmall
                            ?.copyWith(color: ColorConstant.manatee)),
                ],
              ),
            ),
            Text(price,
                style: context.bodySmallW500?.copyWith(color: ColorConstant.brownDark)),
          ],
        ),
      ),
    );
  }
}

// ── Payment method tile ───────────────────────────────────────────────────────

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ColorConstant.primary, width: 1.5),
        color: ColorConstant.primary.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: ColorConstant.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.payments_outlined, color: ColorConstant.primary, size: 20),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.cashOnDelivery, style: context.bodySmallW500),
                Text(context.l10n.payWhenArrives,
                    style: context.bodyExtraSmall?.copyWith(color: ColorConstant.manatee)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
        ],
      ),
    );
  }
}

// ── Address bottom sheet ──────────────────────────────────────────────────────

enum _AddrMode { select, form }

class _AddressSheet extends StatefulWidget {
  const _AddressSheet({required this.cart});
  final Cart cart;

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  _AddrMode _mode = _AddrMode.select;
  Address? _editingAddress;

  // Saved addresses (filtered to current country)
  List<Address> _addresses = [];
  bool _fetchingAddresses = false;

  // Form
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _address1Ctrl;
  late TextEditingController _address2Ctrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _provinceCtrl;
  late TextEditingController _postalCodeCtrl;
  late TextEditingController _phoneCtrl;
  bool _saving = false;

  String get _currentCountryCode =>
      getIt<PreferenceRepository>().country?.iso2?.toLowerCase() ?? '';

  @override
  void initState() {
    super.initState();
    _initFormWith(widget.cart.shippingAddress);
    _bootAddresses();
  }

  void _bootAddresses() {
    final code = _currentCountryCode;
    final cached = PreferenceRepository.instance.cachedAddresses ?? [];
    final filtered =
        cached.where((a) => a.countryCode?.toLowerCase() == code).toList();
    setState(() {
      _addresses = filtered;
      if (_addresses.isEmpty) _mode = _AddrMode.form;
    });
    _fetchAddresses(code);
  }

  Future<void> _fetchAddresses(String code) async {
    setState(() => _fetchingAddresses = true);
    try {
      final list =
          await getIt<DataStore>().customers.listShippingAddresses();
      await PreferenceRepository.instance.setCachedAddresses(list);
      final filtered =
          list.where((a) => a.countryCode?.toLowerCase() == code).toList();
      if (mounted) {
        setState(() {
          _addresses = filtered;
          _fetchingAddresses = false;
          if (_addresses.isEmpty && _mode == _AddrMode.select) {
            _mode = _AddrMode.form;
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _fetchingAddresses = false);
    }
  }

  void _initFormWith(Address? src) {
    _firstNameCtrl = TextEditingController(text: src?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: src?.lastName ?? '');
    _address1Ctrl = TextEditingController(text: src?.address1 ?? '');
    _address2Ctrl = TextEditingController(text: src?.address2 ?? '');
    _cityCtrl = TextEditingController(text: src?.city ?? '');
    _provinceCtrl = TextEditingController(text: src?.province ?? '');
    _postalCodeCtrl = TextEditingController(text: src?.postalCode ?? '');
    _phoneCtrl = TextEditingController(text: src?.phone ?? '');
  }

  void _disposeFormControllers() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _address1Ctrl.dispose();
    _address2Ctrl.dispose();
    _cityCtrl.dispose();
    _provinceCtrl.dispose();
    _postalCodeCtrl.dispose();
    _phoneCtrl.dispose();
  }

  @override
  void dispose() {
    _disposeFormControllers();
    super.dispose();
  }

  void _enterForm({Address? prefill}) {
    _disposeFormControllers();
    _editingAddress = prefill;
    _initFormWith(prefill);
    setState(() => _mode = _AddrMode.form);
  }

  void _applyToCart(Address address) {
    final cartId = widget.cart.id;
    if (cartId == null) return;

    // Optimistic: reflect the new address in the UI immediately.
    final currentCart =
        context.read<CartBloc>().state.whenOrNull(loaded: (c) => c) ??
            widget.cart;
    context.read<CartBloc>().add(
      CartEvent.refreshCart(currentCart.copyWith(shippingAddress: address)),
    );

    // Clear shipping cache — a new address may have different available methods.
    getIt<PreferenceRepository>().clearCachedShippingOptions();

    if (mounted) Navigator.pop(context);

    // Background: persist to server (no loading spinner — state is already _Loaded).
    context.read<CartBloc>().add(
      CartEvent.updateCart(
        cartId: cartId,
        req: StorePostCartsCartReq(
          shippingAddress: {
            'first_name': address.firstName ?? '',
            'last_name': address.lastName ?? '',
            'address_1': address.address1 ?? '',
            'address_2': address.address2 ?? '',
            'city': address.city ?? '',
            'province': address.province ?? '',
            'postal_code': address.postalCode ?? '',
            'phone': address.phone ?? '',
            'country_code':
                address.countryCode?.toLowerCase() ?? _currentCountryCode,
          },
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final cartId = widget.cart.id;
    if (cartId == null) return;
    setState(() => _saving = true);

    final countryCode = _currentCountryCode.isEmpty ? 'sa' : _currentCountryCode;

    final address = Address(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      address1: _address1Ctrl.text.trim(),
      address2: _address2Ctrl.text.trim().isEmpty ? null : _address2Ctrl.text.trim(),
      city: _cityCtrl.text.trim(),
      province: _provinceCtrl.text.trim(),
      postalCode: _postalCodeCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      countryCode: countryCode,
    );

    try {
      // Persist to address book
      if (_editingAddress?.id != null) {
        await getIt<DataStore>().customers.updateShippingAddress(
          addressId: _editingAddress!.id!,
          address: address,
        );
      } else {
        await getIt<DataStore>().customers.addShippingAddress(address: address);
      }
      _applyToCart(address);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_apiError(e, context.l10n.failedToSaveAddress))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Shared header decoration ─────────────────────────────────────────────────

  Widget _dragHandle() => Center(
        child: Container(
          margin: const EdgeInsets.only(top: 12, bottom: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: ColorConstant.manatee.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return _mode == _AddrMode.select
        ? _buildSelectMode(context)
        : _buildFormMode(context);
  }

  // ── Select mode ──────────────────────────────────────────────────────────────

  Widget _buildSelectMode(BuildContext context) {
    final country = getIt<PreferenceRepository>().country;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _dragHandle(),
        // Header
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.l10n.addressTitle,
                        style: context.bodyLargeW600),
                    if (country != null)
                      Text(country.name ?? '',
                          style: context.bodyExtraSmall
                              ?.copyWith(color: ColorConstant.manatee)),
                  ],
                ),
              ),
              if (_fetchingAddresses)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: ColorConstant.manatee),
                ),
            ],
          ),
        ),
        const Divider(height: 0),
        // List
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            children: [
              ..._addresses.map((addr) => _AddressTile(
                    address: addr,
                    isSelected: _isCurrentCartAddress(addr),
                    onTap: () => _applyToCart(addr),
                    onEdit: () => _enterForm(prefill: addr),
                  )),
              const Gap(8),
              // Add new tile
              _AddNewTile(onTap: () => _enterForm()),
              const Gap(8),
            ],
          ),
        ),
      ],
    );
  }

  bool _isCurrentCartAddress(Address addr) {
    final s = widget.cart.shippingAddress;
    if (s == null) return false;
    return s.firstName == addr.firstName &&
        s.lastName == addr.lastName &&
        s.address1 == addr.address1 &&
        s.city == addr.city;
  }

  // ── Form mode ────────────────────────────────────────────────────────────────

  Widget _buildFormMode(BuildContext context) {
    final country = getIt<PreferenceRepository>().country;
    final isEdit = _editingAddress != null;
    final hasAddresses = _addresses.isNotEmpty;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dragHandle(),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 16),
              child: Row(
                children: [
                  if (hasAddresses)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18),
                      onPressed: () =>
                          setState(() => _mode = _AddrMode.select),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: ColorConstant.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.location_on_outlined,
                            color: ColorConstant.primary, size: 22),
                      ),
                    ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      isEdit
                          ? context.l10n.editAddress
                          : context.l10n.addAddress,
                      style: context.bodyLargeW600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 0),
            // Fields
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Column(
                  children: [
                    _ReadOnlyField(
                      label: context.l10n.country,
                      value: country?.name ?? '',
                      icon: Icons.flag_outlined,
                    ),
                    const Gap(14),
                    Row(
                      children: [
                        Expanded(
                          child: _AddressField(
                            controller: _firstNameCtrl,
                            label: context.l10n.firstName,
                            icon: Icons.person_outline,
                            required: true,
                            requiredMsg: context.l10n.required,
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: _AddressField(
                            controller: _lastNameCtrl,
                            label: context.l10n.lastName,
                            required: true,
                            requiredMsg: context.l10n.required,
                          ),
                        ),
                      ],
                    ),
                    const Gap(14),
                    _AddressField(
                      controller: _address1Ctrl,
                      label: context.l10n.addressLine1,
                      icon: Icons.home_outlined,
                      required: true,
                      requiredMsg: context.l10n.required,
                    ),
                    const Gap(14),
                    _AddressField(
                      controller: _address2Ctrl,
                      label: context.l10n.addressLine2Optional,
                    ),
                    const Gap(14),
                    _AddressField(
                      controller: _cityCtrl,
                      label: context.l10n.city,
                      icon: Icons.location_city_outlined,
                      required: true,
                      requiredMsg: context.l10n.required,
                    ),
                    const Gap(14),
                    Row(
                      children: [
                        Expanded(
                          child: _AddressField(
                            controller: _provinceCtrl,
                            label: context.l10n.provinceState,
                            required: true,
                            requiredMsg: context.l10n.required,
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: _AddressField(
                            controller: _postalCodeCtrl,
                            label: context.l10n.postalCode,
                            keyboardType: TextInputType.number,
                            required: true,
                            requiredMsg: context.l10n.required,
                          ),
                        ),
                      ],
                    ),
                    const Gap(14),
                    _AddressField(
                      controller: _phoneCtrl,
                      label: context.l10n.phone,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ),
            // Save button
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
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(context.l10n.save,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Saved address tile ────────────────────────────────────────────────────────

class _AddressTile extends StatelessWidget {
  const _AddressTile({
    required this.address,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
  });

  final Address address;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final name =
        '${address.firstName ?? ''} ${address.lastName ?? ''}'.trim();
    final line2 = [address.city, address.province]
        .where((v) => v?.isNotEmpty == true)
        .join(', ');

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorConstant.primary.withValues(alpha: 0.06)
              : context.theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? ColorConstant.primary
                : ColorConstant.manatee.withValues(alpha: 0.25),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.location_on_rounded
                  : Icons.location_on_outlined,
              color: isSelected ? ColorConstant.primary : ColorConstant.manatee,
              size: 22,
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (name.isNotEmpty)
                    Text(name, style: context.bodySmallW500),
                  if (address.address1?.isNotEmpty == true)
                    Text(address.address1!,
                        style: context.bodySmall
                            ?.copyWith(color: ColorConstant.manatee)),
                  if (line2.isNotEmpty)
                    Text(line2,
                        style: context.bodyExtraSmall
                            ?.copyWith(color: ColorConstant.manatee)),
                ],
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(Icons.check_circle_rounded,
                    color: ColorConstant.primary, size: 18),
              ),
            IconButton(
              icon: Icon(Icons.edit_outlined,
                  size: 18, color: ColorConstant.manatee),
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add new address tile ──────────────────────────────────────────────────────

class _AddNewTile extends StatelessWidget {
  const _AddNewTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: ColorConstant.primary.withValues(alpha: 0.4),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
          color: ColorConstant.primary.withValues(alpha: 0.04),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_location_alt_outlined,
                color: ColorConstant.primary, size: 20),
            const Gap(8),
            Text(
              context.l10n.addAddress,
              style: TextStyle(
                color: ColorConstant.primary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Read-only country field ───────────────────────────────────────────────────

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
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

// ── Address form field ────────────────────────────────────────────────────────

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.controller,
    required this.label,
    this.icon,
    this.required = false,
    this.requiredMsg,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool required;
  final String? requiredMsg;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: ColorConstant.manatee)
            : null,
        filled: true,
        fillColor: context.theme.cardColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: ColorConstant.manatee.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: ColorConstant.manatee.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorConstant.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
      validator: required
          ? (v) =>
              (v == null || v.trim().isEmpty) ? requiredMsg ?? 'Required' : null
          : null,
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
