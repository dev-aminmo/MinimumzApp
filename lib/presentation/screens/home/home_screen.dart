import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:minimumz/common/doh_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/common/pricing_utils.dart';
import 'package:minimumz/common/cta_handler.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';
import 'package:minimumz/domain/model/product_filter.dart';
import 'package:minimumz/presentation/screens/home/widgets/index.dart';
import 'package:minimumz/presentation/screens/home/widgets/for_you_feed.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../../common/colors.dart';
import '../../components/index.dart';
import '../../routes/app_router.dart';
import '../../../cubits/locale/locale_cubit.dart';
import 'bloc/collections/collections_bloc.dart';
import '../../../common/network_log.dart';
import '../../../common/country_change_notifier.dart';

@RoutePage()
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _resetKey = 0;
  HomeBundle? _bundle;

  @override
  void initState() {
    super.initState();
    CountryChangeNotifier.instance.addListener(_onCountryChange);
    _fetchBundle();
  }

  @override
  void dispose() {
    CountryChangeNotifier.instance.removeListener(_onCountryChange);
    super.dispose();
  }

  void _onCountryChange() {
    setState(() => _resetKey++);
    _fetchBundle();
  }

  Future<void> _fetchBundle() async {
    try {
      final bundle = await getIt<DataStore>().home.fetch(
        countryId: PreferenceRepository.instance.country?.id,
      );
      if (!mounted) return;
      PreferenceRepository.instance.setCachedSlider(bundle.slides);
      PreferenceRepository.instance.setCachedCollections(bundle.collections);
      PreferenceRepository.instance.setCachedBrands(bundle.brands);
      PreferenceRepository.instance.setCachedBestSellers(
          filterPricedProducts(bundle.bestSellers));
      setState(() => _bundle = bundle);
    } catch (_) {
      // Bundle failed — sections fall back to their own individual calls.
    }
  }

  @override
  Widget build(BuildContext context) {
    const inputBorder = OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
        borderSide: BorderSide(width: 0, color: Colors.transparent));
    return Scaffold(
      body: SafeArea(
          child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 5),

            sliver: SliverAppBar(
              shadowColor: Colors.transparent,
              snap: true,
              floating: true,
              leadingWidth: 65,
              actionsPadding: EdgeInsetsDirectional.only(end: 20),
              title: Hero(
                tag: 'search',
                child: Material(
                  color: Colors.transparent,
                  child: TextField(
                    onTap: () => context.router.push(const SearchRoute()),
                    readOnly: true,
                    decoration: InputDecoration(
                        filled: true,
                        hintText: context.l10n.searchHint,
                        contentPadding: EdgeInsets.zero,
                        border: inputBorder,
                        enabledBorder: inputBorder,
                        focusedBorder: inputBorder,
                        hintStyle: TextStyle(color: ColorConstant.manatee),
                        fillColor:  context.theme.cardColor.withAlpha(50),
                        prefixIcon: Icon(minimumzIcons.search,
                            color: ColorConstant.manatee)),
                  ),
                ),
              ),
              // leading: Padding(
              //   padding: const EdgeInsetsDirectional.only(start: 20),
              //   child: Hero(
              //     tag: 'search_back',
              //     child: Material(
              //       color: Colors.transparent,
              //       child: InkWell(
              //         borderRadius: const BorderRadius.all(Radius.circular(50)),
              //         onTap: () {
              //           // Profile moved from a drawer to the last bottom-nav tab.
              //           context.tabsRouter.setActiveIndex(3);
              //         },
              //         child: Ink(
              //           width: 45,
              //           height: 45,
              //
              //           decoration: ShapeDecoration(
              //             color: context.theme.cardColor,
              //             shape: const CircleBorder(),
              //           ),
              //           child: Icon(
              //             minimumzIcons.menu_horizontal,
              //             size: 13,
              //             color: context.theme.iconTheme.color,
              //           ),
              //         ),
              //       ),
              //
              //     ),
              //   ),
              // ),
              actions: const [
                NotificationBellButton(),
                SizedBox(width: 10),
                CartBadgeButton(),
              ],
            ),
          ),
          const SliverGap(10),
          const _ApiPingBanner(),
          const SliverGap(10),
          _SliderSection(prefetched: _bundle?.slides),
          const SliverGap(10),
          _CategoriesSection(prefetched: _bundle?.collections),
          const SliverGap(10),
          _BestSellersSection(
              key: ValueKey('bs_$_resetKey'),
              prefetched: _bundle?.bestSellers),
          const SliverGap(10),
          _BrandsSection(prefetched: _bundle?.brands),
          const SliverGap(10),
          ForYouFeed(key: ValueKey('fy_$_resetKey')),
        ],
      )),
    );
  }
}

// ── Slider / hero carousel ────────────────────────────────────────────────────

class _SliderSection extends StatefulWidget {
  const _SliderSection({this.prefetched});
  final List<SliderSlide>? prefetched;

  @override
  State<_SliderSection> createState() => _SliderSectionState();
}

class _SliderSectionState extends State<_SliderSection> with WidgetsBindingObserver {
  List<SliderSlide> _slides = [];
  int _currentPage = 0;
  final PageController _pageController = PageController();
  Timer? _timer;
  bool _bundleReceived = false;

  static const Duration _interval = Duration(seconds: 3);
  static const Duration _animDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCache();
    // Give the home bundle 700ms to arrive before falling back to own call.
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted && !_bundleReceived) _fetchFromNetwork();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      if (_slides.length > 1 && (_timer == null || !_timer!.isActive)) {
        _startAutoPlay();
      }
    }
  }

  @override
  void didUpdateWidget(_SliderSection old) {
    super.didUpdateWidget(old);
    final slides = widget.prefetched;
    if (slides != null && slides != old.prefetched) {
      _bundleReceived = true;
      setState(() => _slides = slides);
      if (_timer == null || !_timer!.isActive) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoPlay());
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _loadCache() {
    final cached = PreferenceRepository.instance.cachedSlider;
    if (cached != null && cached.isNotEmpty) {
      _slides = cached;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoPlay());
    }
  }

  Future<void> _fetchFromNetwork() async {
    try {
      final slides = await getIt<DataStore>().slider.fetch();
      if (!mounted) return;
      PreferenceRepository.instance.setCachedSlider(slides);
      setState(() => _slides = slides);
      if (_timer == null || !_timer!.isActive) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoPlay());
      }
    } catch (_) {}
  }

  void _startAutoPlay() {
    if (_slides.length <= 1) return;
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) {
      if (!_pageController.hasClients) return;
      final next = (_currentPage + 1) % _slides.length;
      _pageController.animateToPage(next,
          duration: _animDuration, curve: Curves.easeInOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_slides.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: AspectRatio(
        aspectRatio: 16 / 7,
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (_, i) => _SliderTile(slide: _slides[i]),
            ),
            if (_slides.length > 1)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_slides.length, (i) {
                    final active = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SliderTile extends StatelessWidget {
  const _SliderTile({required this.slide});
  final SliderSlide slide;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => handleCtaUrl(context, slide.callToActionUrl),
      child: ClipRRect(
        borderRadius: BorderRadius.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (slide.image != null)
              CachedNetworkImage(
                cacheManager: DohCacheManager.instance,
                imageUrl: slide.image!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: ColorConstant.primary.withValues(alpha: 0.1),
                ),
              )
            else
              Container(color: ColorConstant.primary.withValues(alpha: 0.1)),
            if (slide.caption1 != null || slide.caption2 != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 20, 14, 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (slide.caption1 != null)
                        Text(
                          slide.caption1!,
                          style: context.bodySmallW500
                              ?.copyWith(color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (slide.caption2 != null)
                        Text(
                          slide.caption2!,
                          style: context.bodyExtraSmall
                              ?.copyWith(color: Colors.white70),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Categories section ────────────────────────────────────────────────────────

void _showAllCategories(BuildContext context, List<ProductCollection> collections) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.theme.scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, ctrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.l10n.allCategories, style: context.bodyLargeW600),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(_),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: GridView.builder(
              controller: ctrl,
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisExtent: 100,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: collections.length,
              itemBuilder: (_, i) => CategoryTile(collection: collections[i]),
            ),
          ),
        ],
      ),
    ),
  );
}

void _showAllBrands(BuildContext context, List<BrandItem> brands) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.theme.scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (ctx, ctrl) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.l10n.allBrands, style: context.bodyLargeW600),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
          const Divider(height: 0),
          Expanded(
            child: ListView.builder(
              controller: ctrl,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: brands.length,
              itemBuilder: (_, i) {
                final brand = brands[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(ctx);
                    context.router.push(CollectionRoute(
                      collection: ProductCollection(id: brand.id, title: brand.name, filterParam: 'type_id', logo: brand.logo, banner: brand.banner),
                    ));
                  },
                  leading: brand.logo != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: CachedNetworkImage(
          cacheManager: DohCacheManager.instance,
                            imageUrl: brand.logo!,
                            width: 36,
                            height: 36,
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => const Icon(Icons.storefront_outlined, size: 22),
                          ),
                        )
                      : const Icon(Icons.storefront_outlined, size: 22),
                  title: Text(brand.name ?? ''),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

class _CategoriesSection extends StatefulWidget {
  const _CategoriesSection({this.prefetched});
  final List<ProductCollection>? prefetched;

  @override
  State<_CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<_CategoriesSection> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  bool _autoPlayStarted = false;

  // Each CategoryTile is width 80 + separator gap 12 = 92 logical pixels.
  static const double _itemStride = 92.0;
  static const Duration _interval = Duration(seconds: 3);
  static const Duration _animDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      if (_autoPlayStarted && (_timer == null || !_timer!.isActive)) {
        _startAutoPlay();
      }
    }
  }

  @override
  void didUpdateWidget(_CategoriesSection old) {
    super.didUpdateWidget(old);
    if (widget.prefetched != null && old.prefetched == null && !_autoPlayStarted) {
      _autoPlayStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoPlay());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      final next = _scrollController.offset + _itemStride;
      if (next >= max) {
        _scrollController.animateTo(0,
            duration: _animDuration, curve: Curves.easeInOut);
      } else {
        _scrollController.animateTo(next,
            duration: _animDuration, curve: Curves.easeInOut);
      }
    });
  }

  Widget _buildLoaded(List<ProductCollection> collections) {
    if (collections.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    if (!_autoPlayStarted) {
      _autoPlayStarted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoPlay());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Headline(
            headline: context.l10n.categories,
            onViewAllTap: () => _showAllCategories(context, collections),
          ),
          const Gap(10),
          SizedBox(
            height: 108,
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              separatorBuilder: (_, __) => const Gap(12),
              itemCount: collections.length,
              itemBuilder: (_, i) => CategoryTile(collection: collections[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return SliverToBoxAdapter(
      child: Skeletonizer(
        enabled: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Headline(headline: context.l10n.categories, onViewAllTap: null),
            const Gap(10),
            SizedBox(
              height: 108,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                separatorBuilder: (_, __) => const Gap(12),
                itemCount: 5,
                itemBuilder: (_, __) => const _CategorySkeletonTile(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // When the home bundle has provided collections, use them directly.
    if (widget.prefetched != null) {
      return _buildLoaded(widget.prefetched!);
    }

    // Fall back to the CollectionsBloc (populated at app startup).
    return BlocBuilder<CollectionsBloc, CollectionsState>(
      builder: (context, state) {
        return state.map(
          loading: (_) => _buildLoading(),
          loaded: (data) => _buildLoaded(data.collections),
          error: (_) => const SliverToBoxAdapter(child: SizedBox.shrink()),
        );
      },
    );
  }
}

class CategoryTile extends StatelessWidget {
  const CategoryTile({super.key, required this.collection, this.onTap});
  final ProductCollection collection;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleCubit>().state.languageCode;
    return GestureDetector(
      onTap: onTap ?? () => context.router.push(CollectionRoute(collection: collection)),
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
              ),
              child: collection.logo != null
                  ? CachedNetworkImage(
                      cacheManager: DohCacheManager.instance,
                      imageUrl: collection.logo!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Icon(
                        Icons.category_outlined,
                        color: ColorConstant.primary,
                        size: 28,
                      ),
                    )
                  : Icon(
                      Icons.category_outlined,
                      color: ColorConstant.primary,
                      size: 28,
                    ),
            ),
            const Gap(6),
            Text(
              collection.localizedTitle(locale),
              style: context.bodyExtraSmall?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySkeletonTile extends StatelessWidget {
  const _CategorySkeletonTile();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: ColorConstant.manatee.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const Gap(6),
          Container(height: 10, width: 50, color: ColorConstant.manatee.withValues(alpha: 0.1)),
        ],
      ),
    );
  }
}

// ── Best sellers ──────────────────────────────────────────────────────────────

class _BestSellersSection extends StatefulWidget {
  const _BestSellersSection({super.key, this.prefetched});
  final List<Product>? prefetched;

  @override
  State<_BestSellersSection> createState() => _BestSellersSectionState();
}

class _BestSellersSectionState extends State<_BestSellersSection> with WidgetsBindingObserver {
  List<Product>? _products;
  bool _loading = true;
  bool _bundleReceived = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

  // card width 160 + separator 12
  static const double _itemStride = 172.0;
  static const Duration _interval = Duration(seconds: 3);
  static const Duration _animDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCache();
    // Give the home bundle 700ms to arrive before falling back to own call.
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted && !_bundleReceived) _fetchFromNetwork();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      if ((_products?.length ?? 0) > 1 && (_timer == null || !_timer!.isActive)) {
        _startAutoPlay();
      }
    }
  }

  @override
  void didUpdateWidget(_BestSellersSection old) {
    super.didUpdateWidget(old);
    final incoming = widget.prefetched;
    if (incoming != null && incoming != old.prefetched) {
      _bundleReceived = true;
      final products = filterPricedProducts(incoming);
      _timer?.cancel();
      setState(() { _products = products; _loading = false; });
      if (products.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoPlay());
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    if ((_products?.length ?? 0) <= 1) return;
    _timer = Timer.periodic(_interval, (_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      final next = _scrollController.offset + _itemStride;
      _scrollController.animateTo(
        next >= max ? 0 : next,
        duration: _animDuration,
        curve: Curves.easeInOut,
      );
    });
  }

  void _loadCache() {
    final cached = PreferenceRepository.instance.cachedBestSellers;
    if (cached != null) {
      setState(() { _products = cached; _loading = false; });
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoPlay());
    }
  }

  Future<void> _fetchFromNetwork() async {
    final countryId = PreferenceRepository.instance.country?.id;
    if (_products == null && mounted) setState(() => _loading = true);
    try {
      final res = await getIt<DataStore>().products.list(queryParams: {
        'sort': 'best_sellers',
        'limit': 12,
        if (countryId != null) 'country_id': countryId,
      });
      final products = filterPricedProducts(res?.products ?? []);
      if (!mounted) return;
      PreferenceRepository.instance.setCachedBestSellers(products);
      _timer?.cancel();
      setState(() { _products = products; _loading = false; });
      if (products.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoPlay());
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && (_products?.isEmpty ?? true)) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Headline(headline: context.l10n.bestSellers, onViewAllTap: null),
          const Gap(10),
          SizedBox(
            height: 281,
            child: _loading
                ? Skeletonizer(
                    enabled: true,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      separatorBuilder: (_, __) => const Gap(12),
                      itemCount: 4,
                      itemBuilder: (_, __) => const SizedBox(
                        width: 160,
                        child: ProductCard(
                          product: Product(title: 'Best Seller'),
                          shimmer: true,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    separatorBuilder: (_, __) => const Gap(12),
                    itemCount: _products!.length,
                    itemBuilder: (_, i) => SizedBox(
                      width: 160,
                      child: ProductCard(product: _products![i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Brands section ────────────────────────────────────────────────────────────

class _BrandsSection extends StatefulWidget {
  const _BrandsSection({this.prefetched});
  final List<BrandItem>? prefetched;

  @override
  State<_BrandsSection> createState() => _BrandsSectionState();
}

class _BrandsSectionState extends State<_BrandsSection> with WidgetsBindingObserver {
  List<BrandItem>? _brands;
  bool _loading = true;
  bool _bundleReceived = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

  static const double _itemStride = 100.0;
  static const Duration _interval = Duration(seconds: 3);
  static const Duration _animDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadCache();
    // Give the home bundle 700ms to arrive before falling back to own call.
    Future.delayed(const Duration(milliseconds: 700), () {
      if (mounted && !_bundleReceived) _load();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      if ((_brands?.length ?? 0) > 1 && (_timer == null || !_timer!.isActive)) {
        _startAutoPlay();
      }
    }
  }

  @override
  void didUpdateWidget(_BrandsSection old) {
    super.didUpdateWidget(old);
    final incoming = widget.prefetched;
    if (incoming != null && incoming != old.prefetched) {
      _bundleReceived = true;
      setState(() { _brands = incoming; _loading = false; });
      if (incoming.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoPlay());
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadCache() {
    final cached = PreferenceRepository.instance.cachedBrands;
    if (cached != null) {
      setState(() { _brands = cached; _loading = false; });
      if (cached.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoPlay());
      }
    }
  }

  Future<void> _load() async {
    try {
      final brands = await getIt<DataStore>().brands.list(limit: 20);
      if (mounted) {
        PreferenceRepository.instance.setCachedBrands(brands);
        setState(() { _brands = brands; _loading = false; });
        if (brands.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoPlay());
        }
      }
    } catch (_) {
      if (mounted) setState(() { _brands = _brands ?? []; _loading = false; });
    }
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      final next = _scrollController.offset + _itemStride;
      if (next >= max) {
        _scrollController.animateTo(0,
            duration: _animDuration, curve: Curves.easeInOut);
      } else {
        _scrollController.animateTo(next,
            duration: _animDuration, curve: Curves.easeInOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && (_brands?.isEmpty ?? true)) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Headline(
            headline: context.l10n.brands,
            onViewAllTap: _brands?.isNotEmpty == true
                ? () async {
                    // The home row is a prefetched subset — fetch ALL brands for
                    // the "view all" sheet.
                    List<BrandItem> all = _brands!;
                    try {
                      final fetched = await getIt<DataStore>().brands.list(limit: 200);
                      if (fetched.isNotEmpty) all = fetched;
                    } catch (_) {}
                    if (context.mounted) _showAllBrands(context, all);
                  }
                : null,
          ),
          const Gap(10),
          SizedBox(
            height: 108,
            child: _loading
                ? Skeletonizer(
                    enabled: true,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      separatorBuilder: (_, __) => const Gap(12),
                      itemCount: 5,
                      itemBuilder: (_, __) => _BrandChip(brand: BrandItem(name: 'Loading')),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    separatorBuilder: (_, __) => const Gap(12),
                    itemCount: _brands!.length,
                    itemBuilder: (_, i) => _BrandChip(brand: _brands![i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BrandChip extends StatelessWidget {
  const _BrandChip({required this.brand});
  final BrandItem brand;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to collection screen filtered by brand
        context.router.push(CollectionRoute(
          collection: ProductCollection(id: brand.id, title: brand.name, filterParam: 'type_id', logo: brand.logo, banner: brand.banner),
        ));
      },
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.07),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: brand.logo != null
                    ? CachedNetworkImage(
                        cacheManager: DohCacheManager.instance,
                        imageUrl: brand.logo!,
                        fit: BoxFit.contain,
                        errorWidget: (_, __, ___) =>
                            Icon(Icons.storefront_outlined, size: 28, color: ColorConstant.primary),
                      )
                    : Icon(Icons.storefront_outlined, size: 28, color: ColorConstant.primary),
              ),
            ),
            const Gap(6),
            Text(
              brand.name ?? '',
              style: context.bodyExtraSmall?.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── New Arrivals ──────────────────────────────────────────────────────────────

class NewArrival extends StatefulWidget {
  const NewArrival({super.key});

  @override
  State<NewArrival> createState() => _NewArrivalState();
}

class _NewArrivalState extends State<NewArrival> {
  static const _pageSize = 10;

  final PagingController<int, Product> _pagingController =
      PagingController(firstPageKey: 0);
  int _loadedCount = 0;
  ProductFilter _filter = ProductFilter.empty;

  // Pre-fetches the first page independently of the PagingController lifecycle.
  // Returning users get cached data instantly (zero wait); first-timers wait
  // for the staggered network fetch. _fetchPage(0) just awaits this future.
  Future<List<Product>?>? _firstPagePrefetch;

  @override
  void initState() {
    super.initState();
    _firstPagePrefetch = _prefetchFirstPage();
    _pagingController.addPageRequestListener(_fetchPage);
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Future<List<Product>?> _fetchNetworkPage(int offset) async {
    final countryId = PreferenceRepository.instance.country?.id;
    final res = await getIt<DataStore>().products.list(queryParams: {
      'offset': offset,
      'limit': _pageSize,
      'sort': 'created_at',
      if (countryId != null) 'country_id': countryId,
      ..._filter.toQueryParams(),
    });
    final raw = res?.products;
    return raw == null ? null : filterPricedProducts(raw);
  }

  Future<List<Product>?> _prefetchFirstPage() async {
    // Serve cache immediately — returning users see data with zero delay.
    final cached = PreferenceRepository.instance.cachedNewArrivals;
    if (cached != null && cached.isNotEmpty) {
      _backgroundRefreshCache(); // silently update cache for next session
      return cached;
    }
    // No cache: stagger behind slider (T+0) and best-sellers (T+400ms).
    await Future.delayed(const Duration(milliseconds: 900));
    try {
      final products = await _fetchNetworkPage(0);
      if (products != null && products.isNotEmpty) {
        PreferenceRepository.instance.setCachedNewArrivals(products);
      }
      return products;
    } catch (_) {
      return null; // _fetchPage falls through to a direct retry
    }
  }

  Future<void> _backgroundRefreshCache() async {
    await Future.delayed(const Duration(milliseconds: 900));
    try {
      final products = await _fetchNetworkPage(0);
      if (products == null || products.isEmpty) return;
      await PreferenceRepository.instance.setCachedNewArrivals(products);

      // Apply the fresh data to the visible list too — not just the cache for
      // next session. Without this, a returning user keeps seeing the stale
      // cached list until the app is restarted.
      if (!mounted || !_firstPageDiffers(products)) return;
      _loadedCount = products.length;
      _pagingController.value = PagingState<int, Product>(
        itemList: products,
        nextPageKey: products.length < _pageSize ? null : products.length,
        error: null,
      );
      if (mounted) setState(() {});
    } catch (_) {}
  }

  /// True if the fresh first page differs from what's currently displayed
  /// (by product id/length), so we only repaint when something actually changed.
  bool _firstPageDiffers(List<Product> fresh) {
    final current = _pagingController.itemList;
    if (current == null || current.isEmpty) return true;
    final n = fresh.length < current.length ? fresh.length : current.length;
    for (var i = 0; i < n; i++) {
      if (current[i].id != fresh[i].id) return true;
    }
    return current.length != fresh.length;
  }

  Future<void> _fetchPage(int offset) async {
    try {
      List<Product> products;

      if (offset == 0 && _firstPagePrefetch != null) {
        final prefetched = await _firstPagePrefetch;
        _firstPagePrefetch = null;

        if (prefetched != null) {
          products = prefetched;
        } else {
          // Pre-fetch failed — direct retry, then cache the result.
          final fetched = await _fetchNetworkPage(0);
          products = fetched ?? [];
          if (products.isNotEmpty) {
            PreferenceRepository.instance.setCachedNewArrivals(products);
          }
        }
      } else {
        products = await _fetchNetworkPage(offset) ?? [];
      }

      if (!mounted) return;
      _loadedCount += products.length;
      final isLast = products.length < _pageSize;
      if (isLast) {
        _pagingController.appendLastPage(products);
      } else {
        _pagingController.appendPage(products, _loadedCount);
      }
      if (mounted) setState(() {}); // update _loadedCount label
    } catch (e) {
      if (mounted) _pagingController.error = e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = _loadedCount != 0
        ? '${context.l10n.newArrival} ($_loadedCount)'
        : context.l10n.newArrival;
    return MultiSliver(
        children: [
            SliverToBoxAdapter(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: Headline(headline: label, onViewAllTap: null)),
                  GestureDetector(
                    onTap: () async {
                      final result = await ProductSortSheet.show(context, _filter.sortBy);
                      if (result != null && mounted) {
                        setState(() {
                          _filter = _filter.copyWith(sortBy: result.isEmpty ? null : result);
                          _loadedCount = 0;
                        });
                        _pagingController.refresh();
                      }
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.sort_rounded,
                            color: _filter.sortBy != null
                                ? Theme.of(context).colorScheme.primary
                                : null),
                        if (_filter.sortBy != null)
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16, left: 8),
                    child: GestureDetector(
                      onTap: () async {
                        final result = await ProductFilterSheet.show(context, _filter);
                        if (result != null && mounted) {
                          setState(() {
                            _filter = result;
                            _loadedCount = 0;
                          });
                          _pagingController.refresh();
                        }
                      },
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(Icons.tune_outlined,
                              color: _filter.activeCount > 0
                                  ? Theme.of(context).colorScheme.primary
                                  : null),
                          if (_filter.activeCount > 0)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10),
              sliver: PagedSliverGrid(
                pagingController: _pagingController,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 320,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                ),
                builderDelegate: PagedChildBuilderDelegate<Product>(
                  itemBuilder: (_, product, __) => ProductCard(product: product),
                  firstPageProgressIndicatorBuilder: (_) {
                    const product = Product(title: 'Medusa Product');
                    const card = SizedBox(
                      height: 320,
                      child: ProductCard(product: product, shimmer: true),
                    );
                    return const Skeletonizer(
                      enabled: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(children: [
                            Expanded(child: card),
                            SizedBox(width: 8),
                            Expanded(child: card),
                          ]),
                          SizedBox(height: 8),
                          Row(children: [
                            Expanded(child: card),
                            SizedBox(width: 8),
                            Expanded(child: card),
                          ]),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
    );
  }
}

// ── Shared Headline ───────────────────────────────────────────────────────────

class Headline extends StatelessWidget {
  const Headline({super.key, required this.headline, this.onViewAllTap});
  final String headline;
  final void Function()? onViewAllTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              Text(headline, style: context.bodyLargeW600),
            ],
          ),
          if (onViewAllTap != null)
            GestureDetector(
              onTap: onViewAllTap,
              child: Text(
                context.l10n.viewAll,
                style: context.bodySmall?.copyWith(color: ColorConstant.manatee),
              ),
            ),
        ],
      ),
    );
  }
}

// CollectionTile kept for backward compat if used elsewhere
class CollectionTile extends StatelessWidget {
  const CollectionTile({super.key, required this.collection, this.onTap});
  final ProductCollection collection;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) => CategoryTile(collection: collection, onTap: onTap);
}

// ── API Ping Banner ───────────────────────────────────────────────────────────

enum _PingStatus { loading, success, fail }

class _ApiPingBanner extends StatefulWidget {
  const _ApiPingBanner();

  @override
  State<_ApiPingBanner> createState() => _ApiPingBannerState();
}

class _ApiPingBannerState extends State<_ApiPingBanner> {
  _PingStatus _status = _PingStatus.loading;
  int? _statusCode;
  Map<String, dynamic>? _body;
  String? _errorMessage;
  List<String> _trace = [];
  int _durationMs = 0;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    // Defer so the ping doesn't compete with Slider + Collections at T+0.
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _ping();
    });
  }

  Future<void> _ping() async {
    setState(() {
      _status = _PingStatus.loading;
      _body = null;
      _errorMessage = null;
      _trace = [];
    });

    final result = await getIt<DataStore>().ping();
    if (!mounted) return;
    setState(() {
      _status = result.success ? _PingStatus.success : _PingStatus.fail;
      _statusCode = result.statusCode;
      _body = result.body;
      _errorMessage = result.error;
      _trace = result.trace.toList();
      _durationMs = result.durationMs;
    });
  }

  Future<void> _copy(Color color) async {
    final text = const JsonEncoder.withIndent('  ').convert(_body);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _copyError() async {
    final buf = StringBuffer();
    buf.writeln('API Health Check — FAIL');
    buf.writeln('Status : ${_statusCode ?? '—'}');
    if (_errorMessage != null) buf.writeln('Error  : $_errorMessage');
    if (_trace.isNotEmpty) {
      buf.writeln('Trace  :');
      for (final line in _trace) buf.writeln('  $line');
    }
    if (_body != null) {
      buf.writeln('Body   :');
      buf.writeln(const JsonEncoder.withIndent('  ').convert(_body));
    }
    await Clipboard.setData(ClipboardData(text: buf.toString().trim()));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Widget _buildBodyBox({
    required Color color,
    required Color bgColor,
    required double maxHeight,
    required EdgeInsets margin,
    required TextStyle textStyle,
  }) {
    final text = const JsonEncoder.withIndent('  ').convert(_body);
    return Stack(
      children: [
        Container(
          width: double.infinity,
          constraints: BoxConstraints(maxHeight: maxHeight),
          margin: margin,
          padding: const EdgeInsets.fromLTRB(10, 10, 36, 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            child: Text(text, style: textStyle),
          ),
        ),
        Positioned(
          top: margin.top + 4,
          right: margin.right + 4,
          child: GestureDetector(
            onTap: () => _copy(color),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _copied
                  ? Icon(Icons.check_rounded, key: const ValueKey('ok'), size: 16, color: color)
                  : Icon(Icons.copy_rounded, key: const ValueKey('copy'), size: 16, color: color.withValues(alpha: 0.5)),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = _status == _PingStatus.success;
    final isLoading = _status == _PingStatus.loading;

    final color = isLoading
        ? Colors.grey
        : isSuccess
            ? const Color(0xFF2E7D32)
            : const Color(0xFFC62828);
    final bgColor = isLoading
        ? Colors.grey.withValues(alpha: 0.08)
        : isSuccess
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFFFEBEE);

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              GestureDetector(
                onTap: () => _showNetworkLog(context),
                child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                child: Row(
                  children: [
                    Icon(
                      isLoading
                          ? Icons.circle_outlined
                          : isSuccess
                              ? Icons.check_circle_rounded
                              : Icons.error_rounded,
                      color: color,
                      size: 18,
                    ),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        'API Health Check',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                    if (!isLoading) ...[
                      Text(
                        '$_durationMs ms',
                        style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7)),
                      ),
                      const Gap(8),
                    ],
                    if (_status == _PingStatus.fail) ...[
                      GestureDetector(
                        onTap: _copyError,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _copied
                              ? Icon(Icons.check_rounded, key: const ValueKey('ok'), size: 18, color: color)
                              : Icon(Icons.copy_rounded, key: const ValueKey('copy'), size: 18, color: color.withValues(alpha: 0.6)),
                        ),
                      ),
                      const Gap(8),
                    ],
                    GestureDetector(
                      onTap: isLoading ? null : _ping,
                      child: Icon(
                        isLoading ? Icons.hourglass_empty_rounded : Icons.refresh_rounded,
                        color: color.withValues(alpha: 0.7),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
              ),

              if (isLoading)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey.shade500),
                      ),
                      const Gap(10),
                      Text('Pinging API…', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),

              if (_status == _PingStatus.success) ...[
                Container(height: 1, color: color.withValues(alpha: 0.15)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                  child: Row(
                    children: [
                      Text(
                        '$_statusCode',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: color),
                      ),
                      const Gap(12),
                      Text('OK — API is reachable', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
                    ],
                  ),
                ),
                if (_body != null)
                  _buildBodyBox(
                    color: color,
                    bgColor: Colors.white.withValues(alpha: 0.6),
                    maxHeight: 220,
                    margin: const EdgeInsets.fromLTRB(14, 6, 14, 14),
                    textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.5),
                  ),
              ],

              if (_status == _PingStatus.fail) ...[
                Container(height: 1, color: color.withValues(alpha: 0.15)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_statusCode ?? '—'}',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: color),
                      ),
                      const Gap(12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Gap(6),
                            Text(
                              _errorMessage ?? 'Unknown error',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color),
                            ),
                            if ((_statusCode ?? 0) > 0)
                              Text(
                                'HTTP $_statusCode',
                                style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_trace.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STACK TRACE',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color.withValues(alpha: 0.7), letterSpacing: 0.5),
                        ),
                        const Gap(4),
                        ...List.generate(_trace.length, (i) => Text(
                          '${i + 1}. ${_trace[i]}',
                          style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: color.withValues(alpha: 0.85), height: 1.6),
                        )),
                      ],
                    ),
                  ),
                if (_body != null)
                  _buildBodyBox(
                    color: color,
                    bgColor: Colors.white.withValues(alpha: 0.5),
                    maxHeight: 160,
                    margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                    textStyle: TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.5, color: color.withValues(alpha: 0.9)),
                  ),
                const Gap(14),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

void _showNetworkLog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _NetworkLogSheet(),
  );
}

class _NetworkLogSheet extends StatefulWidget {
  const _NetworkLogSheet();

  @override
  State<_NetworkLogSheet> createState() => _NetworkLogSheetState();
}

class _NetworkLogSheetState extends State<_NetworkLogSheet> {
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    NetworkLog.instance.addListener(_onUpdate);
  }

  @override
  void dispose() {
    NetworkLog.instance.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() => setState(() {});

  String _buildText() {
    final entries = NetworkLog.instance.entries;
    if (entries.isEmpty) return 'No requests recorded yet.';
    final buf = StringBuffer();
    for (final e in entries) {
      final t = e.timestamp;
      final time =
          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
      buf.writeln('── ${e.method} ${e.statusCode ?? '---'} ${e.durationMs}ms $time ──');
      buf.writeln('URL: ${e.url}');
      if (e.error != null) buf.writeln('ERROR: ${e.error}');
      if (e.requestBody != null) {
        buf.writeln('REQUEST:');
        buf.writeln(_fmt(e.requestBody));
      }
      if (e.responseBody != null) {
        buf.writeln('RESPONSE:');
        buf.writeln(_fmt(e.responseBody));
      }
      buf.writeln();
    }
    return buf.toString().trimRight();
  }

  String _fmt(dynamic v) {
    try {
      return const JsonEncoder.withIndent('  ').convert(v);
    } catch (_) {
      return v.toString();
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _buildText()));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = _buildText();
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 12, 10),
              child: Row(
                children: [
                  const Text(
                    'Network Log',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      NetworkLog.instance.clear();
                    },
                    child: const Icon(Icons.delete_outline,
                        color: Colors.white54, size: 20),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _copy,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _copied
                          ? const Icon(Icons.check_rounded,
                              key: ValueKey('ok'),
                              color: Colors.greenAccent,
                              size: 20)
                          : const Icon(Icons.copy_rounded,
                              key: ValueKey('copy'),
                              color: Colors.white54,
                              size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.white10),
            // Scrollable log text
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.all(14),
                child: SelectableText(
                  text,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: Colors.white70,
                    height: 1.55,
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
