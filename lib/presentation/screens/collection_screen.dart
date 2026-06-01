import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:minimumz/common/doh_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/cubits/locale/locale_cubit.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/model/product_filter.dart';
import 'package:minimumz/presentation/screens/home/bloc/products/products_bloc.dart';
import 'package:minimumz/data/data.dart';
import '../components/index.dart';
import '../routes/app_router.dart';
import 'home/widgets/product_card.dart';

@RoutePage()
class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key, required this.collection});
  final ProductCollection collection;

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  static const _pageSize = 10;
  static const _minHeight = kToolbarHeight;

  final PagingController<int, Product> _pagingController =
      PagingController(firstPageKey: 0);
  late final ProductsBloc _bloc;
  int _loadedCount = 0;
  ProductFilter _filter = ProductFilter.empty;

  bool get _hasBanner => widget.collection.banner != null;
  bool get _hasLogo => widget.collection.logo != null;
  bool get _hasVisual => _hasBanner || _hasLogo;

  double get _expandedHeight {
    if (_hasBanner) return 240.0;
    if (_hasLogo) return 200.0;
    return 90.0;
  }

  @override
  void initState() {
    super.initState();
    _bloc = getIt<ProductsBloc>();
    _pagingController.addPageRequestListener(_requestPage);
  }

  void _requestPage(int pageKey) {
    _bloc.add(ProductsEvent.loadProducts(queryParameters: {
      widget.collection.filterParam: widget.collection.id,
      'offset': pageKey,
      'limit': _pageSize,
      ..._filter.toQueryParams(),
    }));
  }

  void _onLoaded(List<Product> products, int? limit, int? count, int? offset) {
    _loadedCount += products.length;
    final isLastPage = products.length < _pageSize;
    if (isLastPage) {
      _pagingController.appendLastPage(products);
    } else {
      _pagingController.appendPage(products, _loadedCount);
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Widget _buildFlexibleSpace(BuildContext context) {
    final locale = context.read<LocaleCubit>().state.languageCode;
    final canPop = context.router.canPop();
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final maxH = _expandedHeight + _minHeight;
        final expandRatio =
            ((constraints.maxHeight - _minHeight) / (maxH - _minHeight))
                .clamp(0.0, 1.0);
        final collapsedOpacity = (1.0 - expandRatio * 2).clamp(0.0, 1.0);
        final expandedOpacity = ((expandRatio - 0.5) * 2).clamp(0.0, 1.0);

        return Stack(
          fit: StackFit.expand,
          children: [
            // ── Banner: full-bleed background ──────────────────────────────
            if (_hasBanner)
              Opacity(
                opacity: expandedOpacity,
                child: CachedNetworkImage(
          cacheManager: DohCacheManager.instance,
                  imageUrl: widget.collection.banner!,
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),

            // ── Gradient overlay so text stays readable on banner ──────────
            if (_hasBanner)
              Opacity(
                opacity: expandedOpacity,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x88000000)],
                    ),
                  ),
                ),
              ),

            // ── Expanded content: logo + title ─────────────────────────────
            if (_hasVisual)
              Opacity(
                opacity: expandedOpacity,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_hasLogo) ...[
                          ClipRRect(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(12)),
                            child: CachedNetworkImage(
          cacheManager: DohCacheManager.instance,
                              imageUrl: widget.collection.logo!,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Icon(
                                Icons.category_outlined,
                                size: 40,
                                color: _hasBanner
                                    ? Colors.white70
                                    : Theme.of(ctx)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.4),
                              ),
                            ),
                          ),
                          const Gap(10),
                        ],
                        Text(
                          widget.collection.localizedTitle(locale),
                          style: context.bodyMediumW500?.copyWith(
                            fontSize: 18,
                            color: _hasBanner ? Colors.white : null,
                            shadows: _hasBanner
                                ? [
                                    const Shadow(
                                      blurRadius: 4,
                                      color: Colors.black45,
                                    )
                                  ]
                                : null,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ── Collapsed state: pill with logo + title ────────────────────
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: 8,
                  left: canPop ? 64 : 20,
                  right: 64,
                ),
                child: Opacity(
                  opacity: collapsedOpacity,
                  child: Container(
                    height: 40,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: context.theme.cardColor,
                      borderRadius:
                          const BorderRadius.all(Radius.circular(10.0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_hasLogo) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
          cacheManager: DohCacheManager.instance,
                              imageUrl: widget.collection.logo!,
                              width: 24,
                              height: 24,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.collection.localizedTitle(locale),
                          style: context.bodyMediumW500,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleCubit>(); // rebuild when locale changes so _buildFlexibleSpace re-reads
    final canPop = context.router.canPop();
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        body: BlocConsumer<ProductsBloc, ProductsState>(
          listener: (context, state) {
            state.whenOrNull(
              loaded: _onLoaded,
              error: (error) => _pagingController.error = error,
            );
          },
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: _expandedHeight,
                  automaticallyImplyLeading: false,
                  // Make the appBar itself transparent so the banner shows through
                  backgroundColor: _hasBanner
                      ? Colors.transparent
                      : context.theme.scaffoldBackgroundColor,
                  leading: canPop
                      ? Padding(
                          padding: const EdgeInsets.all(8),
                          child: InkWell(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(50)),
                            onTap: () => context.router.maybePop(),
                            child: Ink(
                              decoration: ShapeDecoration(
                                color: context.theme.cardColor,
                                shape: const CircleBorder(),
                              ),
                              child: const Icon(Icons.arrow_back_outlined),
                            ),
                          ),
                        )
                      : null,
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 6, left: 8,right: 8),
                      child: InkWell(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(50)),
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
                        child: Ink(
                          width: 40,
                          height: 40,
                          decoration: ShapeDecoration(
                            color: context.theme.cardColor,
                            shape: const CircleBorder(),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(Icons.sort_rounded,
                                  color: _filter.sortBy != null
                                      ? Theme.of(context).colorScheme.primary
                                      : null),
                              if (_filter.sortBy != null)
                                Positioned(
                                  top: 6,
                                  right: 6,
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
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 6, left: 4),
                      child: InkWell(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(50)),
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
                        child: Ink(
                          width: 40,
                          height: 40,
                          decoration: ShapeDecoration(
                            color: context.theme.cardColor,
                            shape: const CircleBorder(),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(Icons.tune_outlined),
                              if (_filter.activeCount > 0)
                                Positioned(
                                  top: 6,
                                  right: 6,
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
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          right: 8, top: 6, bottom: 6, left: 8),
                      child: InkWell(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(50)),
                        onTap: () =>
                            context.router.push(const CartRoute()),
                        child: Ink(
                          width: 40,
                          height: 40,
                          decoration: ShapeDecoration(
                            color: context.theme.cardColor,
                            shape: const CircleBorder(),
                          ),
                          child: const Icon(minimumzIcons.bag),
                        ),
                      ),
                    ),
                  ],
                  flexibleSpace: _buildFlexibleSpace(context),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  sliver: PagedSliverGrid<int, Product>(
                    pagingController: _pagingController,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisExtent: 301,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    builderDelegate: PagedChildBuilderDelegate<Product>(
                      itemBuilder: (_, product, __) =>
                          ProductCard(product: product),
                      firstPageProgressIndicatorBuilder: (_) => const Center(
                          child: CircularProgressIndicator.adaptive()),
                      newPageProgressIndicatorBuilder: (_) => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                            child: CircularProgressIndicator.adaptive()),
                      ),
                      noItemsFoundIndicatorBuilder: (context) => Center(
                        child: Text(context.l10n.noProductsInCategory),
                      ),
                      firstPageErrorIndicatorBuilder: (context) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_pagingController.error?.toString() ??
                                context.l10n.errorLoadingProducts),
                            const Gap(12),
                            ElevatedButton(
                              onPressed: _pagingController.refresh,
                              child: Text(context.l10n.retry),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
