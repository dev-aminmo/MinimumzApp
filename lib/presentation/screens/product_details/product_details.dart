import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:minimumz/common/doh_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:minimumz/cubits/locale/locale_cubit.dart';
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
import 'package:minimumz/common/pricing_utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'widgets/bottom_nav_button.dart';
import 'dart:async';

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
  double _avgRating = 0.0;
  late int _viewsCount;
  List<Product> _relatedProducts = [];

  // Stable list of all unique image URLs (product gallery + variant thumbnails)
  late List<String> _allImages;
  late PageController _pageController;
  int _mediaPage = 0;
  Timer? _autoSlideTimer;

  String? get _videoUrl => widget.product.videoUrl;
  bool get _hasVideo => _videoUrl != null && _videoUrl!.isNotEmpty;
  bool get _videoSelected => _hasVideo && _mediaPage == 0;

  int get _totalMediaCount => (_hasVideo ? 1 : 0) + _allImages.length;

  List<String> _buildAllImages() {
    final seen = <String>{};
    final result = <String>[];
    for (final img in widget.product.images ?? []) {
      if (img.url != null && seen.add(img.url!)) result.add(img.url!);
    }
    for (final v in widget.product.variants ?? []) {
      if (v.thumbnail != null && seen.add(v.thumbnail!)) result.add(v.thumbnail!);
    }
    if (result.isEmpty && widget.product.thumbnail != null) {
      result.add(widget.product.thumbnail!);
    }
    return result;
  }

  // Page indices that belong to main product images only (no variant thumbnails, no video).
  List<int> get _autoSlidePages {
    final variantThumbs = (widget.product.variants ?? [])
        .where((v) => v.thumbnail != null)
        .map((v) => v.thumbnail!)
        .toSet();
    final pages = <int>[];
    for (int i = 0; i < _allImages.length; i++) {
      if (!variantThumbs.contains(_allImages[i])) {
        pages.add(_hasVideo ? i + 1 : i);
      }
    }
    return pages;
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    final pages = _autoSlidePages;
    if (pages.length < 2) return;

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final currentIdx = pages.indexOf(_mediaPage);
      final nextIdx = (currentIdx < 0 ? 0 : (currentIdx + 1)) % pages.length;
      _pageController.animateToPage(pages[nextIdx],
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    });
  }

  void _onPageChanged(int page) {
    // Restart timer so a manual swipe gets a full 3 s before next auto-advance
    _startAutoSlide();
    setState(() {
      _mediaPage = page;
      if (!(_hasVideo && page == 0)) {
        final imgIdx = _hasVideo ? page - 1 : page;
        if (imgIdx >= 0 && imgIdx < _allImages.length) {
          selectedImage = _allImages[imgIdx];
          _trySelectVariantForImage(selectedImage!);
        }
      }
    });
  }

  void _trySelectVariantForImage(String url) {
    for (final v in widget.product.variants ?? []) {
      if (v.thumbnail == url && v.id != selectedVariant?.id) {
        selectedVariant = v;
        _syncOptionsForVariant(v);
        break;
      }
    }
  }

  void _syncOptionsForVariant(ProductVariant v) {
    if (v.title == null || (widget.product.options?.isEmpty ?? true)) return;
    final parts = v.title!.split('/').map((e) => e.trim()).toList();
    final options = widget.product.options ?? [];
    if (parts.length == options.length) {
      for (int i = 0; i < options.length; i++) {
        final opt = options[i];
        if (opt.id != null && i < parts.length) {
          optionsSelected[opt.id!] = parts[i];
        }
      }
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _viewsCount = widget.product.viewsCount;
    _allImages = _buildAllImages();
    selectedImage = _allImages.isNotEmpty ? _allImages[0] : widget.product.thumbnail;
    _mediaPage = 0;
    _pageController = PageController(initialPage: 0);
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
    _startAutoSlide();
    _loadReviews();
    _loadRelated();
    _recordView();
  }

  Future<void> _loadRelated() async {
    final categoryId = widget.product.collectionId;
    if (categoryId == null) return;
    try {
      final countryId = PreferenceRepository.instance.country?.id;
      final result = await getIt<DataStore>().products.list(
        queryParams: {
          'category_id[]': categoryId,
          'limit': 10,
          if (countryId != null) 'country_id': countryId,
        },
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
          _avgRating = result.avgRating;
        });
      }
    } catch (_) {}
  }

  Future<void> _recordView() async {
    final id = widget.product.id;
    if (id == null) return;
    PreferenceRepository.instance.addRecentlyViewed(
      id: id,
      title: widget.product.title ?? '',
      thumbnail: widget.product.thumbnail,
    );
    try {
      final updated = await getIt<DataStore>().reviews.recordView(
            productId: id,
            sessionId: PreferenceRepository.sessionId,
          );
      if (mounted) setState(() => _viewsCount = updated);
    } catch (_) {}
  }

  void selectVariant() {
    if (optionsSelected.length != (widget.product.options?.length ?? 0)) return;
    final values = optionsSelected.values.toList();
    for (final variant in widget.product.variants ?? []) {
      final titleList = variant.title?.split('/').map((e) => e.trim()).toList();
      if (titleList != null && titleList.toSet().containsAll(values.toSet())) {
        setState(() {
          selectedVariant = variant;
          selectedImage = variant.thumbnail ?? widget.product.thumbnail;
        });
        // Scroll PageView to this variant's image
        if (variant.thumbnail != null) {
          final idx = _allImages.indexOf(variant.thumbnail!);
          if (idx >= 0) {
            final page = _hasVideo ? idx + 1 : idx;
            _pageController.animateToPage(page,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut);
          }
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final locale = context.watch<LocaleCubit>().state.languageCode;
    final bottomPadding =
        context.bottomViewPadding == 0.0 ? 30.0 : context.bottomViewPadding;
    final currencyCode = PreferenceRepository.currencyCode;

    List<MoneyAmount> allAmounts() => (product.variants ?? [])
        .expand((v) => v.prices ?? <MoneyAmount>[])
        .toList();

    List<MoneyAmount> selectedAmounts() =>
        selectedVariant != null ? (selectedVariant!.prices ?? []) : allAmounts();

    String variantPrice() {
      final code = currencyCode.toUpperCase();
      final amounts = selectedAmounts();
      final effective = amounts.effectiveCurrency(code);
      final p = amounts.minPrice(effective);
      return p == null ? '' : p.formatAsPrice(effective, locale: locale);
    }

    String? variantCompareAt() {
      final code = currencyCode.toUpperCase();
      final amounts = selectedAmounts();
      final effective = amounts.effectiveCurrency(code);
      final p = amounts.minPrice(effective);
      if (p == null) return null;
      final ca = amounts.maxCompareAt(effective, p);
      return ca == null ? null : ca.formatAsPrice(effective, locale: locale);
    }

    int? variantDiscountPercent() {
      final code = currencyCode.toUpperCase();
      final amounts = selectedAmounts();
      final effective = amounts.effectiveCurrency(code);
      final p = amounts.minPrice(effective);
      if (p == null) return null;
      final ca = amounts.maxCompareAt(effective, p);
      if (ca == null) return null;
      return (((ca - p) / ca) * 100).round();
    }

    return Scaffold(
      backgroundColor: Colors.white,
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
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 20.0, start: 10.0),
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
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            expandedHeight: 400,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      physics: const ClampingScrollPhysics(),
                      itemCount: _totalMediaCount,
                      itemBuilder: (context, index) {
                        if (_hasVideo && index == 0) {
                          return _ProductVideoPlayer(
                            videoUrl: _videoUrl!,
                            thumbnail: widget.product.thumbnail,
                          );
                        }
                        final imgIdx = _hasVideo ? index - 1 : index;
                        final url = _allImages[imgIdx];
                        return CachedNetworkImage(
                          cacheManager: DohCacheManager.instance,
                          imageUrl: url,
                          fit: BoxFit.fitHeight,
                        );
                      },
                    ),
                    // Gradient fade at bottom
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
                              Colors.white.withValues(alpha: 0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            systemOverlayStyle:
                context.theme.appBarTheme.systemOverlayStyle!.copyWith(
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
            ),
          ),
          // ── Media dot indicators ──────────────────────────────────
          if (_totalMediaCount > 1)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_totalMediaCount, (i) {
                    final active = i == _mediaPage;
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.collection?.title != null || product.type?.value != null) ...[
                    Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      children: [
                        if (product.type?.value != null)
                          _TopChip(
                            label: product.type!.value!,
                            icon: Icons.storefront_outlined,
                            logoUrl: product.type!.logo,
                            color:ColorConstant.manatee,
                            onTap: () => context.router.push(
                              CollectionRoute(
                                collection: ProductCollection(
                                  id: product.type!.id,
                                  title: product.type!.value,
                                  filterParam: 'type_id',
                                  logo: product.type!.logo,
                                  banner: product.type!.banner,
                                ),
                              ),
                            ),
                          ),
                        if (product.collection?.title != null)
                          _TopChip(
                            label: product.collection!.localizedTitle(locale),
                            icon: Icons.category_outlined,
                            color: ColorConstant.manatee,
                            onTap: () => context.router.push(
                              CollectionRoute(collection: product.collection!),
                            ),
                          ),

                      ],
                    ),
                    const Gap(8.0),
                  ],
                  Text(product.localizedTitle(locale) ?? '', style: context.headlineSmall),
                  if (product.variants?.isNotEmpty ?? false) ...[
                    const Gap(8),
                    Text(
                      selectedVariant == null ? context.l10n.startsFrom : '',//context.l10n.price,
                      style: context.bodySmall!.copyWith(fontWeight: FontWeight.w500,fontSize: 16),
                    ),
                    const Gap(4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              variantPrice(),
                              style: context.headlineSmall,
                            ),
                            if (variantCompareAt() != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                variantCompareAt()!,
                                style: context.bodySmall?.copyWith(
                                  color: ColorConstant.manatee,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '-${variantDiscountPercent()}%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        BlocBuilder<WishlistCubit, List<Product>>(
                          builder: (context, wishlist) {
                            final isWishlisted =
                                wishlist.any((p) => p.id == product.id);
                            return InkWell(
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(50)),
                              onTap: () =>
                                  context.read<WishlistCubit>().toggle(product),
                              child: Ink(
                                width: 44,
                                height: 44,
                                decoration: ShapeDecoration(
                                  color: AppTheme.lightTheme.cardColor,
                                  shape: const CircleBorder(),
                                ),
                                child: Icon(
                                  isWishlisted
                                      ? Icons.favorite
                                      : minimumzIcons.heart,
                                  color: isWishlisted ? Colors.red : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SliverGap(6),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                children: [
                  if (_avgRating > 0) ...[
                    ...List.generate(5, (i) {
                      final full = i < _avgRating.floor();
                      final half = !full && i < _avgRating && (_avgRating % 1) >= 0.5;
                      return Icon(
                        full ?  CupertinoIcons.star_fill: half ?  CupertinoIcons.star_lefthalf_fill :  CupertinoIcons.star,
                        color: (full || half) ? Color(0xffFFCF04 ) : ColorConstant.manatee.withValues(alpha: 0.4),
                        size: 13,
                      );
                    }),
                    const SizedBox(width: 5),
                    Text(_avgRating.toStringAsFixed(1), style: context.bodySmallW500),
                    if (_reviewCount > 0) ...[
                      const SizedBox(width: 3),
                      Text('($_reviewCount)',
                          style: context.bodyExtraSmall
                              ?.copyWith(color: ColorConstant.manatee)),
                    ],
                    const SizedBox(width: 12),
                  ],
                  if (_viewsCount > 0) ...[
                    Icon(Icons.remove_red_eye_outlined,
                        size: 14, color: ColorConstant.manatee),
                    const SizedBox(width: 3),
                    Text(_viewsCount.toString(),
                        style: context.bodyExtraSmall
                            ?.copyWith(color: ColorConstant.manatee)),
                  ],
                ],
              ),
            ),
          ),
          const SliverGap(6),
          if (product.localizedDescription(locale) != null) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Divider(height: 32),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Text(context.l10n.description, style: context.bodyLargeW600),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Html(
                      data: product.localizedDescription(locale)!,
                      style: {
                        'body': Style(
                          margin: Margins.zero,
                          padding: HtmlPaddings.zero,
                          fontSize: FontSize(16),
                          color: const Color(0xFF555555),
                        ),
                        'p': Style(
                          margin: Margins.only(bottom: 8),
                          padding: HtmlPaddings.zero,
                        ),
                      },
                    ),
                    const Gap(16),
                  ],
                ),
              ),
            ),
          ],
          // ── Physical specs (weight, dimensions, age range) ───────
          if (_hasSpecs(product))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _SpecsCard(product: product),
              ),
            ),
          // ── Tags ─────────────────────────────────────────────────
          if (product.tags?.isNotEmpty ?? false)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...?(product.tags?.map((tag) => _InfoChip(label: tag.value ?? ''))),
                  ],
                ),
              ),
            ),
          if (_totalMediaCount > 0)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 90,
                width: double.infinity,
                child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      // Video thumbnail is always first
                      if (_hasVideo && index == 0) {
                        final isActive = _videoSelected;
                        return GestureDetector(
                          onTap: () => _pageController.animateToPage(0,
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeInOut),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 80,
                            width: 80,
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive ? ColorConstant.primary : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (widget.product.thumbnail != null)
                                    CachedNetworkImage(
                                      cacheManager: DohCacheManager.instance,
                                      imageUrl: widget.product.thumbnail!,
                                      fit: BoxFit.cover,
                                      color: Colors.black45,
                                      colorBlendMode: BlendMode.darken,
                                    ),
                                  const Center(
                                    child: Icon(Icons.play_circle_fill_rounded,
                                        color: Colors.white, size: 28),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                      final imgIndex = _hasVideo ? index - 1 : index;
                      final url = _allImages[imgIndex];
                      final isActive = !_videoSelected && selectedImage == url;
                      return GestureDetector(
                        onTap: () => _pageController.animateToPage(index,
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeInOut),
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
                              cacheManager: DohCacheManager.instance,
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
                    itemCount: _totalMediaCount),
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
                            ? '${context.l10n.reviews} ($_reviewCount)'
                            : context.l10n.reviews,
                        style: context.bodyLargeW600,
                      ),
                      TextButton(
                          onPressed: () => context.pushRoute(ReviewsRoute(
                                productId: product.id ?? '',
                                productTitle: product.localizedTitle(locale),
                              )),
                          child: Text(context.l10n.viewAll)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: _firstReview != null
                      ? _ReviewCardItem(review: _firstReview!)
                      : Text(
                          context.l10n.noReviewsYet,
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
                        Text(context.l10n.moreLikeThis, style: context.bodyLargeW600),
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

bool _hasSpecs(Product p) =>
    p.weight != null ||
    p.height != null ||
    p.width != null ||
    p.length != null ||
    p.ageMin != null ||
    p.ageMax != null;

class _SpecsCard extends StatelessWidget {
  const _SpecsCard({required this.product});
  final Product product;

  String _fmtAge(BuildContext context, int months) {
    if (months < 12) return context.l10n.ageMonths(months);
    final y = months ~/ 12;
    final m = months % 12;
    return m == 0 ? context.l10n.ageYears(y) : context.l10n.ageYearsMonths(y, m);
  }

  @override
  Widget build(BuildContext context) {
    final specs = <_SpecRow>[];

    if (product.weight != null) {
      specs.add(_SpecRow(
        icon: Icons.scale_outlined,
        label: context.l10n.specWeight,
        value: '${product.weight} ${context.l10n.kgUnit}',
      ));
    }
    if (product.height != null || product.width != null || product.length != null) {
      final parts = <String>[];
      if (product.height != null) parts.add('${context.l10n.dimHeight} ${product.height}');
      if (product.width != null)  parts.add('${context.l10n.dimWidth} ${product.width}');
      if (product.length != null) parts.add('${context.l10n.dimLength} ${product.length}');
      specs.add(_SpecRow(
        icon: Icons.straighten_outlined,
        label: context.l10n.specDimensions,
        value: '${parts.join(' × ')} ${context.l10n.cmUnit}',
      ));
    }
    if (product.ageMin != null || product.ageMax != null) {
      final String ageText;
      if (product.ageMin != null && product.ageMax != null) {
        ageText = context.l10n.specAgeBetween(
          _fmtAge(context, product.ageMin!),
          _fmtAge(context, product.ageMax!),
        );
      } else if (product.ageMin != null) {
        ageText = context.l10n.specAgeFrom(_fmtAge(context, product.ageMin!));
      } else {
        ageText = context.l10n.specUpTo(_fmtAge(context, product.ageMax!));
      }
      specs.add(_SpecRow(
        icon: Icons.child_care_outlined,
        label: context.l10n.specAgeRange,
        value: ageText,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: ColorConstant.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(8),
            Text(context.l10n.specifications, style: context.bodyLargeW600),
          ],
        ),
        const Gap(12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: specs.map((s) => _SpecChip(spec: s)).toList(),
        ),
      ],
    );
  }
}

class _SpecChip extends StatelessWidget {
  const _SpecChip({required this.spec});
  final _SpecRow spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: ColorConstant.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: ColorConstant.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(spec.icon, size: 15, color: ColorConstant.primary),
          const Gap(6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                spec.label,
                style: context.bodyExtraSmall?.copyWith(color: ColorConstant.primary.withValues(alpha: 0.7)),
              ),
              Text(
                spec.value,
                style: context.bodySmallW500,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpecRow {
  const _SpecRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
}

class _TopChip extends StatelessWidget {
  const _TopChip({
    required this.label,
    required this.color,
    this.icon,
    this.logoUrl,
    this.onTap,
  });
  final String label;
  final Color color;
  final IconData? icon;
  final String? logoUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.05),
              boxShadow: [

                BoxShadow(
                  color: color.withValues(alpha: (logoUrl!=null)?0.30:0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: logoUrl != null
                  ? CachedNetworkImage(
                      cacheManager: DohCacheManager.instance,
                      imageUrl: logoUrl!,
                      width: 42,
                      height: 42,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Icon(
                        icon ?? Icons.storefront_outlined,
                        size: 17,
                        color: color,
                      ),
                    )
                  : Icon(icon ?? Icons.storefront_outlined, size: 17, color: color),
            ),
          ),
          const Gap(8),
          Text(
            label,
            style: context.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, this.icon, this.imageUrl, this.color, this.onTap, this.logoSize = 16, this.fontSize = 12});
  final String label;
  final IconData? icon;
  final String? imageUrl;
  final Color? color;
  final VoidCallback? onTap;
  final double logoSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? ColorConstant.manatee;
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imageUrl != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: CachedNetworkImage(
          cacheManager: DohCacheManager.instance,
                imageUrl: imageUrl!,
                width: logoSize,
                height: logoSize,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) =>
                    Icon(Icons.storefront_outlined, size: logoSize - 3, color: chipColor),
              ),
            ),
            const Gap(6),
          ] else if (icon != null) ...[
            Icon(icon, size: fontSize + 1, color: chipColor),
            const Gap(4),
          ],
          Text(label,
              style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: chipColor)),
        ],
      ),
    ),
    );
  }
}

class ProductDetailsRelatedCard extends StatelessWidget {
  const ProductDetailsRelatedCard({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleCubit>().state.languageCode;
    final currencyCode = PreferenceRepository.currencyCode.toUpperCase();
    final allAmounts = (product.variants ?? [])
        .expand((v) => v.prices ?? <MoneyAmount>[])
        .toList();
    final effective = allAmounts.effectiveCurrency(currencyCode);
    final price     = allAmounts.minPrice(effective);

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
          cacheManager: DohCacheManager.instance,
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
                    product.localizedTitle(locale) ?? '',
                    style: context.bodyExtraSmallW500,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),
                  if (price != null)
                    Text(
                      price.formatAsPrice(effective, locale: locale),
                      style: context.bodyExtraSmall
                          ?.copyWith(color: Colors.black, fontWeight: FontWeight.w600),
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
                    Text(' ${context.l10n.ratingLabel}',
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
        if (review.images.isNotEmpty) ...[
          const Gap(10),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: review.images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => _showReviewImageViewer(context, review.images, i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    cacheManager: DohCacheManager.instance,
                    imageUrl: review.images[i],
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

void _showReviewImageViewer(BuildContext context, List<String> images, int initial) {
  showDialog(
    context: context,
    builder: (_) => _ReviewImageViewerDialog(images: images, initialIndex: initial),
  );
}

class _ReviewImageViewerDialog extends StatefulWidget {
  const _ReviewImageViewerDialog({required this.images, required this.initialIndex});
  final List<String> images;
  final int initialIndex;

  @override
  State<_ReviewImageViewerDialog> createState() => _ReviewImageViewerDialogState();
}

class _ReviewImageViewerDialogState extends State<_ReviewImageViewerDialog> {
  late int _current;
  late PageController _ctrl;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    _ctrl = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          PageView.builder(
            controller: _ctrl,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) => InteractiveViewer(
              child: Center(
                child: CachedNetworkImage(
                  cacheManager: DohCacheManager.instance,
                  imageUrl: widget.images[i],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                    color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
          if (widget.images.length > 1)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.images.length, (i) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _current ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _current ? Colors.white : Colors.white38,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Video player widget ───────────────────────────────────────────────────────

class _ProductVideoPlayer extends StatefulWidget {
  const _ProductVideoPlayer({required this.videoUrl, this.thumbnail});
  final String videoUrl;
  final String? thumbnail;

  @override
  State<_ProductVideoPlayer> createState() => _ProductVideoPlayerState();
}

class _ProductVideoPlayerState extends State<_ProductVideoPlayer> {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _isExternal = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _isExternal = _isExternalUrl(widget.videoUrl);
    if (!_isExternal) {
      _initPlayer();
    }
  }

  bool _isExternalUrl(String url) {
    return url.contains('youtube.com') ||
        url.contains('youtu.be') ||
        url.contains('vimeo.com');
  }

  Future<void> _initPlayer() async {
    try {
      final file = await DohCacheManager.instance.getSingleFile(widget.videoUrl);
      _controller = VideoPlayerController.file(file);
      await _controller!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: true,
        looping: false,
        aspectRatio: _controller!.value.aspectRatio,
        allowFullScreen: true,
        showControlsOnInitialize: false,
      );
      if (mounted) setState(() => _initialized = true);
    } catch (_) {
      if (mounted) setState(() => _isExternal = true);
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _launchExternal() async {
    try {
      await launchUrl(Uri.parse(widget.videoUrl), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isExternal) {
      return GestureDetector(
        onTap: _launchExternal,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.thumbnail != null)
              CachedNetworkImage(
                cacheManager: DohCacheManager.instance,
                imageUrl: widget.thumbnail!,
                fit: BoxFit.cover,
                color: Colors.black38,
                colorBlendMode: BlendMode.darken,
              )
            else
              Container(color: Colors.black),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 42),
              ),
            ),
            Positioned(
              bottom: 90,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    context.l10n.tapToOpenVideo,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!_initialized) {
      return Stack(
        fit: StackFit.expand,
        children: [
          if (widget.thumbnail != null)
            CachedNetworkImage(
              cacheManager: DohCacheManager.instance,
              imageUrl: widget.thumbnail!,
              fit: BoxFit.cover,
              color: Colors.black26,
              colorBlendMode: BlendMode.darken,
            )
          else
            Container(color: Colors.black),
          Center(
            child: LoadingAnimationWidget.threeArchedCircle(
                color: Colors.white, size: 32),
          ),
        ],
      );
    }

    return Chewie(controller: _chewieController!);
  }
}
