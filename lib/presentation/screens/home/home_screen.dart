import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:minimumz/common/doh_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/presentation/screens/cart/bloc/cart/cart_bloc.dart';
import 'package:minimumz/presentation/screens/home/widgets/index.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../../common/colors.dart';
import '../../components/index.dart';
import '../../routes/app_router.dart';
import '../dashboard_screen.dart';
import 'bloc/collections/collections_bloc.dart';
import 'bloc/products/products_bloc.dart';

@RoutePage()
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 5),
            sliver: SliverAppBar(
              shadowColor: Colors.transparent,
              snap: true,
              floating: true,
              leadingWidth: 45,
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
                        fillColor: context.theme.cardColor,
                        prefixIcon: Icon(minimumzIcons.search,
                            color: ColorConstant.manatee)),
                  ),
                ),
              ),
              leading: Hero(
                tag: 'search_back',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.all(Radius.circular(50)),
                    onTap: () {
                      dashboardScaffoldKey.currentState?.openDrawer();
                    },
                    child: Ink(
                      width: 45,
                      height: 45,
                      decoration: ShapeDecoration(
                        color: context.theme.cardColor,
                        shape: const CircleBorder(),
                      ),
                      child: Icon(
                        minimumzIcons.menu_horizontal,
                        size: 13,
                        color: context.theme.iconTheme.color,
                      ),
                    ),
                  ),
                ),
              ),
              actions: const [
                CartBadgeButton(),
              ],
            ),
          ),
          const SliverGap(10),
          _CategoriesSection(),
          const SliverGap(10),
          const _BrandsSection(),
          const SliverGap(10),
          const NewArrival(),
        ],
      )),
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
  @override
  State<_CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<_CategoriesSection> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;
  bool _autoPlayStarted = false;

  // Each CategoryTile is width 72 + separator gap 12 = 84 logical pixels.
  static const double _itemStride = 84.0;
  static const Duration _interval = Duration(seconds: 3);
  static const Duration _animDuration = Duration(milliseconds: 500);

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CollectionsBloc, CollectionsState>(
      builder: (context, state) {
        return state.map(
          loading: (_) => SliverToBoxAdapter(
            child: Skeletonizer(
              enabled: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Headline(headline: context.l10n.categories, onViewAllTap: null),
                  const Gap(10),
                  SizedBox(
                    height: 90,
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
          ),
          loaded: (data) {
            if (data.collections.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

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
                    onViewAllTap: () => _showAllCategories(context, data.collections),
                  ),
                  const Gap(10),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      separatorBuilder: (_, __) => const Gap(12),
                      itemCount: data.collections.length,
                      itemBuilder: (_, i) => CategoryTile(collection: data.collections[i]),
                    ),
                  ),
                ],
              ),
            );
          },
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
    return GestureDetector(
      onTap: onTap ?? () => context.router.push(CollectionRoute(collection: collection)),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: ColorConstant.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ColorConstant.primary.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: collection.logo != null
                    ? CachedNetworkImage(
          cacheManager: DohCacheManager.instance,
                        imageUrl: collection.logo!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Icon(
                          Icons.category_outlined,
                          color: ColorConstant.primary,
                          size: 26,
                        ),
                      )
                    : Icon(
                        Icons.category_outlined,
                        color: ColorConstant.primary,
                        size: 26,
                      ),
              ),
            ),
            const Gap(6),
            Text(
              collection.title ?? '',
              style: context.bodyExtraSmall?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 2,
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

// ── Brands section ────────────────────────────────────────────────────────────

class _BrandsSection extends StatefulWidget {
  const _BrandsSection();

  @override
  State<_BrandsSection> createState() => _BrandsSectionState();
}

class _BrandsSectionState extends State<_BrandsSection> {
  List<BrandItem>? _brands;
  bool _loading = true;
  final ScrollController _scrollController = ScrollController();
  Timer? _timer;

  static const double _itemStride = 100.0;
  static const Duration _interval = Duration(seconds: 3);
  static const Duration _animDuration = Duration(milliseconds: 500);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final brands = await getIt<DataStore>().brands.list(limit: 20);
      if (mounted) {
        setState(() { _brands = brands; _loading = false; });
        if (brands.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoPlay());
        }
      }
    } catch (_) {
      if (mounted) setState(() { _brands = []; _loading = false; });
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
                ? () => _showAllBrands(context, _brands!)
                : null,
          ),
          const Gap(10),
          SizedBox(
            height: 44,
            child: _loading
                ? Skeletonizer(
                    enabled: true,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      separatorBuilder: (_, __) => const Gap(8),
                      itemCount: 5,
                      itemBuilder: (_, __) => _BrandChip(brand: BrandItem(name: 'Loading')),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    scrollDirection: Axis.horizontal,
                    separatorBuilder: (_, __) => const Gap(8),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: ColorConstant.primary.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (brand.logo != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
          cacheManager: DohCacheManager.instance,
                  imageUrl: brand.logo!,
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.storefront_outlined, size: 16),
                ),
              ),
              const Gap(6),
            ],
            Text(brand.name ?? '', style: context.bodySmallW500),
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
  late ProductsBloc productsBloc;
  int loadedProductsCount = 0;

  @override
  void initState() {
    productsBloc = context.read<ProductsBloc>();
    _pagingController.addPageRequestListener((pageKey) {
      productsBloc.add(ProductsEvent.loadProducts(queryParameters: {
        'offset': pageKey,
        'limit': _pageSize,
      }));
    });
    super.initState();
  }

  void _loaded(List<Product> products, int? limit, int? count, int? offset) {
    loadedProductsCount += products.length;
    final isLastPage = products.length < _pageSize;
    if (isLastPage) {
      _pagingController.appendLastPage(products);
    } else {
      _pagingController.appendPage(products, loadedProductsCount);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProductsBloc, ProductsState>(
      listener: (context, state) {
        state.whenOrNull(
          loading: () {
            loadedProductsCount = 0;
            _pagingController.refresh();
          },
          loaded: _loaded,
          error: (error) => _pagingController.error = error,
        );
      },
      builder: (context, state) {
        final label = loadedProductsCount != 0
            ? '${context.l10n.newArrival} ($loadedProductsCount)'
            : context.l10n.newArrival;
        return MultiSliver(
          children: [
            SliverToBoxAdapter(
                child: Headline(headline: label, onViewAllTap: null)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              sliver: PagedSliverGrid(
                pagingController: _pagingController,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 280,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                ),
                builderDelegate: PagedChildBuilderDelegate<Product>(
                  itemBuilder: (_, product, __) => ProductCard(product: product),
                  firstPageProgressIndicatorBuilder: (_) {
                    const product = Product(title: 'Medusa Product');
                    return const Skeletonizer(
                      enabled: true,
                      child: Wrap(
                        spacing: 4,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          ProductCard(product: product, shimmer: true),
                          ProductCard(product: product, shimmer: true),
                          ProductCard(product: product, shimmer: true),
                          ProductCard(product: product, shimmer: true),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
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
