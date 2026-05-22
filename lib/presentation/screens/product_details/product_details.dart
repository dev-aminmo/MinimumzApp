import 'package:animated_digit/animated_digit.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:minimumz/cubits/wishlist/wishlist_cubit.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';
import 'package:minimumz/presentation/routes/app_router.dart';
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/presentation/components/index.dart';
import 'package:minimumz/presentation/theme/theme.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:minimumz/data/data.dart';
import 'widgets/bottom_nav_button.dart';

@RoutePage()
class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});
  final Product product;

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late String? selectedImage;
  late num? price;
  Map<String, String> optionsSelected = {};
  ProductVariant? selectedVariant;
  ReviewItem? _firstReview;
  int _reviewCount = 0;
  List<Product> _relatedProducts = [];

  List<String> get _imageUrls {
    final productUrls = (widget.product.images ?? [])
        .where((img) => img.url != null)
        .map((img) => img.url!)
        .toList();
    final variantThumb = selectedVariant?.thumbnail;
    if (variantThumb != null && !productUrls.contains(variantThumb)) {
      return [variantThumb, ...productUrls];
    }
    return productUrls;
  }

  @override
  void initState() {
    selectedImage = widget.product.thumbnail;
    if (widget.product.options?.length == 1 &&
        widget.product.options?.first.values?.length == 1 &&
        widget.product.variants?.length == 1) {
      optionsSelected.addAll({
        widget.product.options!.first.id!:
            widget.product.options!.first.values!.first.value!
      });
      selectedVariant = widget.product.variants?.first;
    } else if (widget.product.options?.isEmpty ?? true) {
      selectedVariant = widget.product.variants?.firstOrNull;
    }

    super.initState();
    _loadReviews();
    _loadRelated();
  }

  Future<void> _loadRelated() async {
    final categoryId = widget.product.collectionId;
    if (categoryId == null) return;
    try {
      final result = await getIt<DataStore>().products.list(
        queryParams: {'category_id[]': categoryId, 'limit': 10},
      );
      final others = (result?.products ?? [])
          .where((p) => p.id != widget.product.id)
          .toList();
      if (mounted) setState(() => _relatedProducts = others);
    } catch (_) {}
  }

  Future<void> _loadReviews() async {
    final id = widget.product.id;
    if (id == null) return;
    try {
      final result = await getIt<DataStore>().reviews.list(productId: id, limit: 1);
      if (mounted) {
        setState(() {
          _firstReview = result.reviews.isNotEmpty ? result.reviews.first : null;
          _reviewCount = result.count;
        });
      }
    } catch (_) {}
  }

  void selectVariant() {
    if (optionsSelected.length != (widget.product.options?.length ?? 0)) {
      return;
    }
    final values = optionsSelected.values.toList();
    widget.product.variants?.forEach((variant) {
      List<String>? titleList = variant.title
          ?.split('/')
          .toList()
          .map((e) => e.trim())
          .toList();
      if (titleList != null && titleList.toSet().containsAll(values.toSet())) {
        setState(() {
          selectedVariant = variant;
          selectedImage = variant.thumbnail ?? widget.product.thumbnail;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final bottomPadding =
        context.bottomViewPadding == 0.0 ? 30.0 : context.bottomViewPadding;
    final currencyCode = PreferenceRepository.currencyCode;

    num variantPrice() {
      // in case the customer didn't select any variant then show the lowest price of the product
      // aka starts from price
      if (selectedVariant == null) {
        List<MoneyAmount> prices = [];
        product.variants?.forEach((variant) {
          variant.prices?.forEach((price) {
            if (price.currencyCode?.toUpperCase() == currencyCode) {
              prices.add(price);
            }
          });
        });
        // Fall back to first available price if none match current currency
        if (prices.isEmpty) {
          product.variants?.forEach((variant) {
            variant.prices?.forEach((p) { if (prices.isEmpty && p.amount != null) prices.add(p); });
          });
        }
        if (prices.isEmpty) return 0;
        final startFromPrice = prices
            .map((e) => e.amount ?? 0)
            .reduce((current, next) => current < next ? current : next);
        return startFromPrice.formatAsPriceNum(currencyCode);
      }
      final amount = selectedVariant?.prices
          ?.where((price) => price.currencyCode?.toUpperCase() == currencyCode)
          .firstOrNull
          ?.amount
          ?? selectedVariant?.prices?.firstOrNull?.amount;
      return amount.formatAsPriceNum(currencyCode);
    }

    return Scaffold(
      bottomNavigationBar: ProductDetailsBottomNavButton(
        selectedVariant: selectedVariant,
        product: widget.product,
        optionsSelected: optionsSelected,
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            leadingWidth: 0,
            leading: const SizedBox.shrink(),
            title: InkWell(
              borderRadius: BorderRadius.circular(56),
              radius: 56,
              onTap: () => context.router.pop(),
              child: Ink(
                width: 45,
                height: 45,
                decoration: ShapeDecoration(
                  color: AppTheme.lightTheme.cardColor,
                  shape: const CircleBorder(),
                ),
                child: const Icon(Icons.arrow_back_outlined),
              ),
            ),
            centerTitle: false,
            pinned: true,
            actions: [
              BlocBuilder<WishlistCubit, List<Product>>(
                builder: (context, wishlist) {
                  final isWishlisted =
                      wishlist.any((p) => p.id == product.id);
                  return InkWell(
                    borderRadius: const BorderRadius.all(Radius.circular(50)),
                    onTap: () =>
                        context.read<WishlistCubit>().toggle(product),
                    child: Ink(
                      width: 45,
                      height: 45,
                      decoration: ShapeDecoration(
                        color: AppTheme.lightTheme.cardColor,
                        shape: const CircleBorder(),
                      ),
                      child: Icon(
                        isWishlisted ? Icons.favorite : minimumzIcons.heart,
                        color: isWishlisted ? Colors.red : null,
                      ),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 20.0, left: 10.0),
                child: InkWell(
                  borderRadius: const BorderRadius.all(Radius.circular(50)),
                  onTap: () => context.router.push(const CartRoute()),
                  child: Ink(
                    width: 45,
                    height: 45,
                    decoration: ShapeDecoration(
                      color: AppTheme.lightTheme.cardColor,
                      shape: const CircleBorder(),
                    ),
                    child: const Icon(minimumzIcons.bag),
                  ),
                ),
              ),
            ],
            foregroundColor: ColorConstant.primary,
            backgroundColor: ColorConstant.cream,
            surfaceTintColor: Colors.transparent,
            expandedHeight: 400,
            flexibleSpace: FlexibleSpaceBar(
              background: selectedImage != null
                  ? SafeArea(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                              imageUrl: selectedImage!, fit: BoxFit.fitHeight),
                          // Gradient fade at bottom for smooth transition
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    ColorConstant.cream.withValues(alpha: 0.7),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : null,
            ),
            systemOverlayStyle:
                context.theme.appBarTheme.systemOverlayStyle!.copyWith(
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
          ),
          // ── Image dot indicators ──────────────────────────────────
          if (_imageUrls.length > 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_imageUrls.length, (i) {
                    final active = selectedImage == _imageUrls[i];
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 20 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active
                            ? ColorConstant.primary
                            : ColorConstant.beige,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
            ),
          const SliverGap(12),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.collection?.title != null)
                          Text(product.collection!.title!,
                              style: context.bodySmall),
                        if (product.collection?.title != null) const Gap(5.0),
                        Text(product.title ?? '', style: context.headlineSmall),
                      ],
                    ),
                  ),
                  if (product.variants?.isNotEmpty ?? false)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(selectedVariant == null ? 'Starts From' : 'Price',
                            style: context.bodySmall),
                        const Gap(5.0),
                        AnimatedDigitWidget(
                            value: variantPrice(),
                            prefix: '$currencyCode ',
                            textStyle: context.headlineSmall,
                            fractionDigits: 2),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SliverGap(10),
          if (product.description != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Html(
                      data: product.description!,
                      style: {
                        '*': Style(
                          fontSize: FontSize(
                              context.bodyMedium?.fontSize ?? 14),
                          color: ColorConstant.manatee,
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                        ),
                      },
                    ),
                    const Gap(16),
                  ],
                ),
              ),
            ),
          // ── Brand + Tags ─────────────────────────────────────────
          if (product.type?.value != null || (product.tags?.isNotEmpty ?? false))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (product.type?.value != null)
                      _InfoChip(
                        label: product.type!.value!,
                        icon: Icons.storefront_outlined,
                        color: ColorConstant.brownDark,
                      ),
                    ...?(product.tags?.map((tag) => _InfoChip(label: tag.value ?? ''))),
                  ],
                ),
              ),
            ),
          if (_imageUrls.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 90,
                width: double.infinity,
                child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final url = _imageUrls[index];
                      final isActive = selectedImage == url;
                      return GestureDetector(
                        onTap: () => setState(() => selectedImage = url),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isActive
                                  ? ColorConstant.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: ColorConstant.beige,
                                child: Center(
                                  child: LoadingAnimationWidget.threeArchedCircle(
                                      color: ColorConstant.primary, size: 18),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: ColorConstant.beige,
                                child: const Icon(Icons.broken_image_outlined,
                                    size: 24, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 10.0),
                    itemCount: _imageUrls.length),
              ),
            ),
          const SliverGap(5),
          // ============================================================
          // Options
          if (product.options?.isNotEmpty ?? false)
            SliverToBoxAdapter(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: product.options!.length,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, __) => const Gap(10),
                itemBuilder: (context, index) {
                  final productOption = product.options![index];
                  // final values = options.values.;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(productOption.title ?? '',
                            style: context.bodyLargeW600),
                      ),
                      const Gap(10),
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: ListView.separated(
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8.0),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20.0),
                            physics: const BouncingScrollPhysics(),
                            scrollDirection: Axis.horizontal,
                            itemCount: productOption.values!
                                .map((e) => e.value)
                                .toSet()
                                .toList()
                                .length,
                            itemBuilder: (context, index) {
                              final productOptionValue = productOption.values!
                                  .map((e) => e.value)
                                  .toSet()
                                  .toList()[index];
                              final bool isSelected = optionsSelected
                                      .containsKey(productOption.id) &&
                                  optionsSelected
                                      .containsValue(productOptionValue);

                              return GestureDetector(
                                onTap: () {
                                  setState(() => optionsSelected.addAll({
                                        productOption.id!: productOptionValue!
                                      }));
                                  selectVariant();
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 20),
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
                                  child: Center(
                                    child: Text(
                                      productOptionValue ?? '',
                                      style: context.bodyMediumW500?.copyWith(
                                        color: isSelected
                                            ? Colors.white
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                      )
                    ],
                  );
                },
              ),
            ),
          const SliverGap(20),
          // ============================================================
          // Reviews
          SliverToBoxAdapter(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _reviewCount > 0
                            ? 'Reviews ($_reviewCount)'
                            : 'Reviews',
                        style: context.bodyLargeW600,
                      ),
                      TextButton(
                          onPressed: () => context.pushRoute(ReviewsRoute(
                                productId: product.id ?? '',
                                productTitle: product.title,
                              )),
                          child: const Text('View All')),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: _firstReview != null
                      ? _ReviewCardItem(review: _firstReview!)
                      : Text(
                          'No reviews yet.',
                          style: context.bodyMedium
                              ?.copyWith(color: ColorConstant.manatee),
                        ),
                ),
              ],
            ),
          ),

          // ── Related products ──────────────────────────────────────
          if (_relatedProducts.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Gap(20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 3, height: 18,
                          decoration: BoxDecoration(
                            color: ColorConstant.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const Gap(8),
                        Text('More like this', style: context.bodyLargeW600),
                      ],
                    ),
                  ),
                  const Gap(12),
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _relatedProducts.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final related = _relatedProducts[index];
                        return SizedBox(
                          width: 150,
                          child: ProductDetailsRelatedCard(product: related),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // ── Bottom padding ────────────────────────────────────────
          SliverGap(bottomPadding),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, this.icon, this.color});
  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? ColorConstant.manatee;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: chipColor),
            const Gap(4),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: chipColor)),
        ],
      ),
    );
  }
}

class ProductDetailsRelatedCard extends StatelessWidget {
  const ProductDetailsRelatedCard({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final currencyCode = PreferenceRepository.currencyCode;
    final matchingPrices = <num>[];
    num? fallbackAmount;
    product.variants?.forEach((v) {
      v.prices?.forEach((p) {
        if (p.amount == null) return;
        if (p.currencyCode?.toUpperCase() == currencyCode) {
          matchingPrices.add(p.amount!);
        } else {
          fallbackAmount ??= p.amount;
        }
      });
    });
    final price = matchingPrices.isNotEmpty
        ? matchingPrices.reduce((a, b) => a < b ? a : b)
        : fallbackAmount;

    return GestureDetector(
      onTap: () => context.router.push(ProductDetailsRoute(product: product)),
      child: Container(
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: product.thumbnail != null
                    ? CachedNetworkImage(
                        imageUrl: product.thumbnail!,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: ColorConstant.beige,
                          child: const Icon(Icons.broken_image_outlined,
                              color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: ColorConstant.beige,
                        child: const Icon(Icons.image_not_supported_outlined,
                            color: Colors.grey),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title ?? '',
                    style: context.bodyExtraSmallW500,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),
                  Text(
                    price.formatAsPrice(currencyCode),
                    style: context.bodyExtraSmall
                        ?.copyWith(color: ColorConstant.brownDark, fontWeight: FontWeight.w600),
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

class _ReviewCardItem extends StatelessWidget {
  const _ReviewCardItem({required this.review});

  final ReviewItem review;

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      return DateFormat('d MMM, yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = _formatDate(review.createdAt);
    final fullStars = review.rating.round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(
                    review.reviewerName.isNotEmpty
                        ? review.reviewerName[0].toUpperCase()
                        : '?',
                    style: context.bodyMediumW500,
                  ),
                ),
                const Gap(10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.reviewerName, style: context.bodyMediumW500),
                    const Gap(5),
                    Row(
                      children: [
                        Icon(minimumzIcons.clock,
                            color: ColorConstant.manatee, size: 18),
                        const Gap(5),
                        Text(
                          date,
                          style: context.bodyExtraSmall
                              ?.copyWith(color: ColorConstant.manatee),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text(review.rating.toStringAsFixed(1),
                        style: context.bodyMediumW500),
                    Text(' rating',
                        style: context.bodyExtraSmall
                            ?.copyWith(color: ColorConstant.manatee)),
                  ],
                ),
                const Gap(5),
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < fullStars ? Icons.star : Icons.star_border,
                      size: 14,
                      color: i < fullStars
                          ? const Color(0xffFF981F)
                          : ColorConstant.manatee,
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
        const Gap(10),
        Text(review.comment, style: context.bodyMedium),
      ],
    );
  }
}
