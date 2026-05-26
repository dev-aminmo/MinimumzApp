import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:minimumz/common/doh_cache_manager.dart';
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
    final currencyCode = PreferenceRepository.currencyCode.toUpperCase();
    final allPrices = (product.variants ?? [])
        .expand((v) => v.prices ?? <MoneyAmount>[])
        .where((p) => p.currencyCode?.toUpperCase() == currencyCode && p.amount != null)
        .toList();

    final price = allPrices.isEmpty
        ? null
        : allPrices.map((p) => p.amount!).reduce((a, b) => a < b ? a : b);

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
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    Flexible(
                      child: Text(
                        product.title ?? '',
                        style: context.bodyExtraSmallW500?.copyWith(
                          fontSize: 18,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Gap(4),
                    Row(
                      children: [
                        if (product.avgRating > 0) ...[

                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            product.avgRating.toStringAsFixed(1),
                            style: context.bodyExtraSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if(product.avgRating > 0)
                        Spacer(),
                        if (product.viewsCount > 0) ...[
                          Icon(Icons.remove_red_eye_outlined,
                              size: 11, color: ColorConstant.manatee),
                          const SizedBox(width: 2),
                          Text(
                            product.viewsCount.toString(),
                            style: context.bodyExtraSmall
                                ?.copyWith(color: ColorConstant.manatee),
                          ),
                          SizedBox(width: 16,),
                        ],
                      ],
                    ),
                    const Gap(3),
                    Text(
                      price.formatAsPrice(currencyCode),
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
