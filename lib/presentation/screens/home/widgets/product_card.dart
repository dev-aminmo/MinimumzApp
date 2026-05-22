import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:minimumz/cubits/wishlist/wishlist_cubit.dart';
import 'package:minimumz/data/data.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../common/colors.dart';
import '../../../../domain/repository/preference_repository.dart';
import '../../../routes/app_router.dart';

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
    final currencyCode = PreferenceRepository.currencyCode;
    num? price;
    String effectiveCurrency = currencyCode;

    // Prefer current-currency prices; fall back to any available price for
    // old products that only have a single default-currency price.
    final matchingPrices = <num>[];
    MoneyAmount? firstFallback;
    product.variants?.forEach((variant) {
      variant.prices?.forEach((p) {
        if (p.amount == null) return;
        if (p.currencyCode?.toUpperCase() == currencyCode) {
          matchingPrices.add(p.amount!);
        } else {
          firstFallback ??= p;
        }
      });
    });
    if (matchingPrices.isNotEmpty) {
      price = matchingPrices.reduce((a, b) => a < b ? a : b);
    } else if (firstFallback != null) {
      price = firstFallback!.amount;
      // Keep effectiveCurrency as the user's selected currency (same as ProductDetails behavior)
    }

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
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title ?? '',
                      style: context.bodyExtraSmallW500,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Gap(5),
                    Text(
                      price.formatAsPrice(effectiveCurrency),
                      style: context.bodySmallW500?.copyWith(
                        color: ColorConstant.brownDark,
                      ),
                    ),
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
