import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:minimumz/common/doh_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:minimumz/cubits/locale/locale_cubit.dart';
import 'package:minimumz/cubits/wishlist/wishlist_cubit.dart';
import 'package:minimumz/data/data.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../common/colors.dart';
import '../../../../domain/repository/preference_repository.dart';
import '../../../routes/app_router.dart';
import '../../cart/bloc/cart/cart_bloc.dart';
import '../../cart/bloc/line_item/line_item_bloc.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.shimmer = false,
  });

  final Product product;
  final bool shimmer;

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleCubit>().state.languageCode;
    final currencyCode = PreferenceRepository.currencyCode.toUpperCase();
    final allMoneyAmounts = (product.variants ?? [])
        .expand((v) => v.prices ?? <MoneyAmount>[])
        .where((p) => p.amount != null)
        .toList();

    // Prefer user's currency; fall back to any available price so product never shows blank
    final currencyMatches = allMoneyAmounts.where((p) => p.currencyCode?.toUpperCase() == currencyCode).toList();
    final allPrices       = currencyMatches.isNotEmpty ? currencyMatches : allMoneyAmounts;
    final effectiveCurrency = currencyMatches.isNotEmpty
        ? currencyCode
        : (allMoneyAmounts.firstOrNull?.currencyCode?.toUpperCase() ?? currencyCode);

    final price = allPrices.isEmpty
        ? null
        : allPrices.map((p) => p.amount!).reduce((a, b) => a < b ? a : b);

    final compareAt = allPrices.isEmpty
        ? null
        : allPrices
            .where((p) => p.compareAtAmount != null)
            .map((p) => p.compareAtAmount!)
            .fold<int?>(null, (best, v) => best == null || v > best ? v : best);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: context.theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.router.push(ProductDetailsRoute(product: product)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Image ──────────────────────────────────────────────
              AspectRatio(
                aspectRatio: 1.0,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ProductImage(product: product, shimmer: shimmer),
                    if (!shimmer)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _WishlistButton(product: product),
                      ),
                  ],
                ),
              ),
              // ── Info ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      product.localizedTitle(locale) ?? '',
                      style: context.bodyExtraSmallW500?.copyWith(
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(10),
                    // ── Price + Button ────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                price.formatAsPrice(effectiveCurrency),
                                style: context.bodySmallW500?.copyWith(
                                  color: ColorConstant.brownDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (compareAt != null)
                                Text(
                                  compareAt.formatAsPrice(effectiveCurrency),
                                  style: context.bodyExtraSmall?.copyWith(
                                    color: ColorConstant.manatee,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        if (!shimmer) ...[
                          const SizedBox(width: 8),
                          _QuickAddButton(product: product),
                        ],
                      ],
                    ),
                    // ── Views + Rating ────────────────────────────────
                    if (product.viewsCount > 0 || product.avgRating > 0) ...[
                      const Gap(6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          if (product.viewsCount > 0) ...[
                            Icon(Icons.remove_red_eye_outlined,
                                size: 11, color: ColorConstant.manatee),
                            const SizedBox(width: 2),
                            Text(
                              product.viewsCount.toString(),
                              style: context.bodyExtraSmall
                                  ?.copyWith(color: ColorConstant.manatee),
                            ),
                          ],
                          if (product.viewsCount > 0 && product.avgRating > 0)
                            const SizedBox(width: 6),
                          if (product.avgRating > 0) ...[
                            const Icon(Icons.star_rounded,
                                color: Colors.amber, size: 11),
                            const SizedBox(width: 2),
                            Text(
                              product.avgRating.toStringAsFixed(1),
                              style: context.bodyExtraSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product, required this.shimmer});
  final Product product;
  final bool shimmer;

  @override
  Widget build(BuildContext context) {
    if (shimmer && product.thumbnail == null) {
      return const Bone.square(size: double.infinity);
    }
    if (product.thumbnail == null) {
      return Container(
        color: ColorConstant.beige,
        child: const Center(
          child: Icon(Icons.image_not_supported_outlined,
              size: 40, color: Colors.grey),
        ),
      );
    }
    return CachedNetworkImage(
          cacheManager: DohCacheManager.instance,
      imageUrl: product.thumbnail!,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        color: ColorConstant.beige,
        child: Center(
          child: LoadingAnimationWidget.threeArchedCircle(
              color: ColorConstant.primary, size: 22),
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        color: ColorConstant.beige,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey),
        ),
      ),
    );
  }
}

class _WishlistButton extends StatelessWidget {
  const _WishlistButton({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WishlistCubit, List<Product>>(
      builder: (context, wishlist) {
        final isWishlisted = wishlist.any((p) => p.id == product.id);
        return GestureDetector(
          onTap: () => context.read<WishlistCubit>().toggle(product),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isWishlisted ? Icons.favorite : Icons.favorite_border,
              color: isWishlisted ? Colors.red : ColorConstant.manatee,
              size: 15,
            ),
          ),
        );
      },
    );
  }
}

// ── Quick-add button ──────────────────────────────────────────────────────────

class _QuickAddButton extends StatefulWidget {
  const _QuickAddButton({required this.product});
  final Product product;

  @override
  State<_QuickAddButton> createState() => _QuickAddButtonState();
}

class _QuickAddButtonState extends State<_QuickAddButton> {
  bool _busy = false;

  ProductVariant? get _autoVariant {
    final opts = widget.product.options;
    final variants = widget.product.variants;
    if (opts == null || opts.isEmpty) return variants?.firstOrNull;
    if (opts.length == 1 &&
        (opts.first.values?.length ?? 0) == 1 &&
        variants?.length == 1) return variants!.first;
    return null;
  }

  void _onTap(BuildContext context) {
    final variant = _autoVariant;
    final purchasable = variant == null ? true : (variant.purchasable ?? false);

    if (variant == null || !purchasable) {
      context.router.push(ProductDetailsRoute(product: widget.product));
      return;
    }

    final cartId = PreferenceRepository.instance.cartId;
    if (cartId == null || variant.id == null) return;

    setState(() => _busy = true);

    // Optimistic banner — immediate feedback.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(context.l10n.addedToCart),
        duration: const Duration(seconds: 2),
      ));

    // Optimistic cart badge update — dashboard-level BlocListener guarantees
    // the real server cart always overwrites this, even if this widget scrolls away.
    final cartBloc = context.read<CartBloc>();
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
        final unitPrice = (variant.prices ?? [])
            .where((p) => p.currencyCode?.toUpperCase() == code && p.amount != null)
            .map((p) => p.amount!)
            .fold<num>(0, (a, b) => a < b ? a : b)
            .toInt();
        updated = [
          ...items,
          LineItem(
            id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
            variantId: variant.id,
            title: widget.product.localizedTitle(locale),
            unitPrice: unitPrice,
            quantity: 1,
            total: unitPrice,
            subtotal: unitPrice,
            thumbnail: widget.product.thumbnail,
          ),
        ];
      }
      cartBloc.add(CartEvent.refreshCart(cart.copyWith(items: updated).recalculate()));
    });

    context.read<LineItemBloc>().add(LineItemEvent.add(cartId, variant.id!, 1));
  }

  @override
  Widget build(BuildContext context) {
    final variant = _autoVariant;
    final purchasable = variant == null ? true : (variant.purchasable ?? false);

    return BlocListener<LineItemBloc, LineItemState>(
      listenWhen: (_, s) => s.maybeWhen(
        success: (_) => true,
        failure: (_, lineItemId) => lineItemId == variant?.id,
        orElse: () => false,
      ),
      listener: (context, state) {
        // Cart update is handled at dashboard level. Only manage local busy state here.
        if (!mounted) return;
        state.whenOrNull(
          success: (_) => setState(() => _busy = false),
          failure: (_, __) {
            setState(() => _busy = false);
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(context.l10n.errorAddingItem)));
          },
        );
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () { if (!_busy) _onTap(context); },
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: ColorConstant.primary.withValues(alpha: purchasable ? 1.0 : 0.45),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}
