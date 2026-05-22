import 'package:auto_route/auto_route.dart';
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
    final cartId = getIt<PreferenceRepository>().cartId;
    if (cartId == null) return;
    setState(() => _shippingLoading = true);
    try {
      final res = await getIt<DataStore>().shippingOptions.listCartOptions(cartId: cartId);
      if (mounted) {
        setState(() {
          _shippingOptions = res?.shippingOptions ?? [];
          if (_shippingOptions.isNotEmpty) _selectedShipping = _shippingOptions.first;
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

    if (cart.shippingAddress == null) {
      _showAddressSheet(context, cart);
      return;
    }

    EasyLoading.show(status: context.l10n.placingOrder);
    try {
      if (_selectedShipping?.id != null) {
        await getIt<DataStore>().carts.addShippingMethod(
              cartId: cartId,
              req: StorePostCartsCartShippingMethodReq(optionId: _selectedShipping!.id!),
            );
      }

      await getIt<DataStore>().carts.createPaymentSessions(cartId: cartId);

      final sessions = (await getIt<DataStore>().carts.retrieve(cartId: cartId))?.cart?.paymentSessions;
      final codSession = sessions?.firstWhere(
        (s) => s.providerId == 'manual',
        orElse: () => sessions!.first,
      );
      if (codSession != null) {
        await getIt<DataStore>().carts.setPaymentSession(
              cartId: cartId,
              req: StorePostCartsCartPaymentSessionReq(providerId: codSession.providerId ?? 'manual'),
            );
      }

      final result = await getIt<DataStore>().carts.complete(cartId: cartId);
      if (result?.type == 'order' && result?.order != null) {
        await getIt<PreferenceRepository>().clearCartId();
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

  void _showAddressSheet(BuildContext context, Cart cart) {
    showModalBottomSheet(
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
            body: state.map(
              loaded: (s) => s.cart.items?.isEmpty ?? true
                  ? _EmptyCart()
                  : _CartBody(
                      cart: s.cart,
                      shippingOptions: _shippingOptions,
                      selectedShipping: _selectedShipping,
                      shippingLoading: _shippingLoading,
                      onShippingSelected: (opt) => setState(() => _selectedShipping = opt),
                      onEditAddress: () => _showAddressSheet(context, s.cart),
                    ),
              loading: (_) => Center(
                  child: LoadingAnimationWidget.threeArchedCircle(
                      color: ColorConstant.primary, size: 40)),
              initial: (_) => Center(
                  child: LoadingAnimationWidget.threeArchedCircle(
                      color: ColorConstant.primary, size: 40)),
              error: (e) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(e.message ?? context.l10n.errorLoadingCart),
                    const Gap(12),
                    ElevatedButton(
                        onPressed: () =>
                            context.read<CartBloc>().add(const CartEvent.loadCart()),
                        child: Text(context.l10n.retry)),
                  ],
                ),
              ),
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
                  return LineItemCard(lineItem: items[i ~/ 2], cartId: cart.id!);
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
                              ? opt.amount!.formatAsPrice(currencyCode)
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
                    cart.subTotal.formatAsPrice(currencyCode), context),
                const Gap(8),
                _SummaryRow(context.l10n.shipping,
                    cart.shippingTotal.formatAsPrice(currencyCode), context),
                if ((cart.taxTotal ?? 0) > 0) ...[
                  const Gap(8),
                  _SummaryRow(
                      context.l10n.tax, cart.taxTotal.formatAsPrice(currencyCode), context),
                ],
                if ((cart.discountTotal ?? 0) > 0) ...[
                  const Gap(8),
                  _SummaryRow(context.l10n.discount,
                      '- ${cart.discountTotal.formatAsPrice(currencyCode)}', context,
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
                    Text(cart.total.formatAsPrice(currencyCode),
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
        Text(label, style: context.bodySmall?.copyWith(color: ColorConstant.manatee)),
        Text(value,
            style: context.bodySmall?.copyWith(
              color: color ?? context.theme.textTheme.bodySmall?.color,
              fontWeight: FontWeight.w500,
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

class _AddressSheet extends StatefulWidget {
  const _AddressSheet({required this.cart});
  final Cart cart;

  @override
  State<_AddressSheet> createState() => _AddressSheetState();
}

class _AddressSheetState extends State<_AddressSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _firstNameCtrl =
      TextEditingController(text: widget.cart.shippingAddress?.firstName ?? '');
  late final _lastNameCtrl =
      TextEditingController(text: widget.cart.shippingAddress?.lastName ?? '');
  late final _address1Ctrl =
      TextEditingController(text: widget.cart.shippingAddress?.address1 ?? '');
  late final _cityCtrl =
      TextEditingController(text: widget.cart.shippingAddress?.city ?? '');
  late final _provinceCtrl =
      TextEditingController(text: widget.cart.shippingAddress?.province ?? '');
  late final _postalCodeCtrl =
      TextEditingController(text: widget.cart.shippingAddress?.postalCode ?? '');
  late final _phoneCtrl =
      TextEditingController(text: widget.cart.shippingAddress?.phone ?? '');
  bool _saving = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _address1Ctrl.dispose();
    _cityCtrl.dispose();
    _provinceCtrl.dispose();
    _postalCodeCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final cartId = widget.cart.id;
    if (cartId == null) return;

    setState(() => _saving = true);
    try {
      final countryCode =
          getIt<PreferenceRepository>().country?.iso2?.toLowerCase() ?? 'sa';
      final req = StorePostCartsCartReq(
        shippingAddress: {
          'first_name': _firstNameCtrl.text.trim(),
          'last_name': _lastNameCtrl.text.trim(),
          'address_1': _address1Ctrl.text.trim(),
          'city': _cityCtrl.text.trim(),
          'province': _provinceCtrl.text.trim(),
          'postal_code': _postalCodeCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'country_code': countryCode,
        },
      );
      context.read<CartBloc>().add(CartEvent.updateCart(cartId: cartId, req: req));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.failedToSaveAddress)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final country = getIt<PreferenceRepository>().country;

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
                  Text(context.l10n.addressTitle, style: context.bodyLargeW600),
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
                    _ReadOnlyField(
                      label: context.l10n.country,
                      value: country?.name ?? '',
                      icon: Icons.flag_outlined,
                    ),
                    const Gap(14),
                    // First name + Last name
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
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: _AddressField(
                            controller: _postalCodeCtrl,
                            label: context.l10n.postalCode,
                            keyboardType: TextInputType.number,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorConstant.manatee.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorConstant.manatee.withValues(alpha: 0.3)),
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
          ? (v) => (v == null || v.trim().isEmpty) ? requiredMsg ?? 'Required' : null
          : null,
    );
  }
}
