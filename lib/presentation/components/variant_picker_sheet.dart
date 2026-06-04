import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/doh_cache_manager.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/common/pricing_utils.dart';
import 'package:minimumz/cubits/locale/locale_cubit.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';

import '../screens/cart/bloc/cart/cart_bloc.dart';
import '../screens/cart/bloc/line_item/line_item_bloc.dart';

/// Optimistically adds [variant] of [product] to the cart and dispatches the
/// real add to the server. Shared by the product card's quick-add button and
/// the [VariantPickerSheet] so both paths stay in sync.
///
/// Bloc/messenger instances are passed in (rather than read from a context) so
/// the call is safe even when invoked from a modal route's context.
void addVariantToCart({
  required CartBloc cartBloc,
  required LineItemBloc lineItemBloc,
  required ScaffoldMessengerState messenger,
  required String addedToCartText,
  required Product product,
  required ProductVariant variant,
}) {
  final cartId = PreferenceRepository.instance.cartId;
  if (cartId == null || variant.id == null) return;

  // Optimistic banner — immediate feedback.
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(addedToCartText),
      duration: const Duration(seconds: 2),
    ));

  // Optimistic cart badge update — the dashboard-level BlocListener guarantees
  // the real server cart always overwrites this.
  cartBloc.state.whenOrNull(loaded: (cart) {
    final items = cart.items ?? <LineItem>[];
    final List<LineItem> updated;
    final existing = items.where((e) => e.variantId == variant.id);
    if (existing.isNotEmpty) {
      updated = items.map((item) {
        if (item.variantId != variant.id) return item;
        final qty = (item.quantity ?? 0) + 1;
        final total = (item.unitPrice ?? 0) * qty;
        return item.copyWith(quantity: qty, total: total, subtotal: total);
      }).toList();
    } else {
      final locale = LocaleCubit.instance.state.languageCode;
      final code = PreferenceRepository.currencyCode.toUpperCase();
      final variantPrices = variant.prices ?? <MoneyAmount>[];
      final effectiveCode = variantPrices.effectiveCurrency(code);
      final unitPrice = variantPrices.minPrice(effectiveCode) ?? 0;
      updated = [
        ...items,
        LineItem(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          variantId: variant.id,
          title: product.localizedTitle(locale),
          description: variant.title,
          unitPrice: unitPrice,
          quantity: 1,
          total: unitPrice,
          subtotal: unitPrice,
          thumbnail: variant.thumbnail ?? product.thumbnail,
        ),
      ];
    }
    cartBloc.add(CartEvent.refreshCart(cart.copyWith(items: updated).recalculate()));
  });

  lineItemBloc.add(LineItemEvent.add(cartId, variant.id!, 1));
}

/// Bottom sheet that lets the user pick a specific variant of a multi-variation
/// [product] before adding it to the cart.
class VariantPickerSheet {
  const VariantPickerSheet._();

  static Future<void> show(BuildContext context, Product product) {
    // Capture bloc/messenger from the caller's context so the add still works
    // after the sheet's own context is torn down on pop.
    final cartBloc = context.read<CartBloc>();
    final lineItemBloc = context.read<LineItemBloc>();
    final messenger = ScaffoldMessenger.of(context);
    final addedText = context.l10n.addedToCart;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VariantPickerBody(
        product: product,
        cartBloc: cartBloc,
        lineItemBloc: lineItemBloc,
        messenger: messenger,
        addedText: addedText,
      ),
    );
  }
}

class _VariantPickerBody extends StatefulWidget {
  const _VariantPickerBody({
    required this.product,
    required this.cartBloc,
    required this.lineItemBloc,
    required this.messenger,
    required this.addedText,
  });

  final Product product;
  final CartBloc cartBloc;
  final LineItemBloc lineItemBloc;
  final ScaffoldMessengerState messenger;
  final String addedText;

  @override
  State<_VariantPickerBody> createState() => _VariantPickerBodyState();
}

class _VariantPickerBodyState extends State<_VariantPickerBody> {
  /// Map of option.id -> selected value.
  final Map<String, String> _selected = {};

  Product get _product => widget.product;

  @override
  void initState() {
    super.initState();
    // Pre-select when a single variant trivially resolves.
    final options = _product.options ?? [];
    if (options.length == 1 &&
        (options.first.values?.length ?? 0) == 1 &&
        _product.variants?.length == 1) {
      _selected[options.first.id!] = options.first.values!.first.value!;
    }
  }

  /// The variant matching the current selection, or null if incomplete.
  ProductVariant? get _selectedVariant {
    final options = _product.options ?? [];
    if (_selected.length != options.length) return null;
    final values = _selected.values.map((e) => e.trim()).toSet();
    for (final v in _product.variants ?? <ProductVariant>[]) {
      final titleParts =
          v.title?.split('/').map((e) => e.trim()).toSet();
      if (titleParts != null && titleParts.containsAll(values)) return v;
    }
    return null;
  }

  void _onAdd() {
    final variant = _selectedVariant;
    if (variant == null || !(variant.purchasable ?? false)) return;
    addVariantToCart(
      cartBloc: widget.cartBloc,
      lineItemBloc: widget.lineItemBloc,
      messenger: widget.messenger,
      addedToCartText: widget.addedText,
      product: _product,
      variant: variant,
    );
    Navigator.of(context).pop();
  }

  String _priceLabel(String locale) {
    final code = PreferenceRepository.currencyCode.toUpperCase();
    final amounts = _selectedVariant?.prices ??
        (_product.variants ?? [])
            .expand((v) => v.prices ?? <MoneyAmount>[])
            .toList();
    final effective = amounts.effectiveCurrency(code);
    final p = amounts.minPrice(effective);
    return p == null ? '' : p.formatAsPrice(effective, locale: locale);
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleCubit>().state.languageCode;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final variant = _selectedVariant;
    final purchasable = variant?.purchasable ?? false;
    final thumbnail = variant?.thumbnail ?? _product.thumbnail;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ───────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ColorConstant.manatee.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // ── Header: thumbnail + title + price ─────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: thumbnail == null
                        ? Container(
                            color: ColorConstant.beige,
                            child: const Icon(
                                Icons.image_not_supported_outlined,
                                size: 24,
                                color: Colors.grey),
                          )
                        : CachedNetworkImage(
                            cacheManager: DohCacheManager.instance,
                            imageUrl: thumbnail,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Container(
                              color: ColorConstant.beige,
                              child: const Icon(Icons.broken_image_outlined,
                                  size: 24, color: Colors.grey),
                            ),
                          ),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _product.localizedTitle(locale) ?? '',
                        style: context.bodyMediumW600,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(6),
                      Text(
                        _priceLabel(locale),
                        style: context.bodyLargeW600?.copyWith(
                          color: ColorConstant.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── Option groups ─────────────────────────────────────────
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _product.options?.length ?? 0,
              separatorBuilder: (_, __) => const Gap(16),
              itemBuilder: (context, index) {
                final option = _product.options![index];
                // Distinct values, keeping the first occurrence so we retain its
                // metadata (e.g. the color swatch hex).
                final seen = <String>{};
                final values = <ProductOptionValue>[];
                for (final ov in option.values ?? <ProductOptionValue>[]) {
                  final v = ov.value;
                  if (v != null && seen.add(v)) values.add(ov);
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(option.title ?? '',
                          style: context.bodyLargeW600),
                    ),
                    const Gap(10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: values.map((ov) {
                          final value = ov.value!;
                          final isSelected = _selected[option.id] == value;
                          final swatch = hexToColor(ov.metadata?['color']);
                          return GestureDetector(
                            onTap: () => setState(
                                () => _selected[option.id!] = value),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              height: 44,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? ColorConstant.primary
                                    : context.theme.cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? ColorConstant.primary
                                      : ColorConstant.beige,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (swatch != null) ...[
                                    Container(
                                      width: 16,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: swatch,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.white
                                              : ColorConstant.manatee
                                                  .withValues(alpha: 0.4),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                    const Gap(8),
                                  ],
                                  Text(
                                    value,
                                    style: context.bodyMediumW500?.copyWith(
                                      color: isSelected ? Colors.white : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const Divider(height: 1),
          // ── Add-to-cart button ────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad + 16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: (variant != null && purchasable) ? _onAdd : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstant.primary,
                  disabledBackgroundColor:
                      ColorConstant.primary.withValues(alpha: 0.4),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  variant != null && !purchasable
                      ? context.l10n.outOfStock
                      : variant == null
                          ? context.l10n.selectOptions
                          : context.l10n.addToCart,
                  style: context.bodyLargeW600?.copyWith(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
