import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/cubits/wishlist/wishlist_cubit.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';

import '../../common/colors.dart';
import '../components/index.dart';
import '../routes/app_router.dart';
import 'home/widgets/product_card.dart';

@RoutePage()
class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  static const _pageSize = 20;

  // Source of truth — kept in sync with the cubit
  List<Product> _allProducts = [];

  // IDs returned by the country-filtered API refresh; null = no filter applied yet
  Set<String>? _availableIds;

  List<Product> get _visibleProducts => _availableIds != null
      ? _allProducts.where((p) => _availableIds!.contains(p.id)).toList()
      : _allProducts;

  final PagingController<int, Product> _pagingController =
      PagingController(firstPageKey: 0);

  @override
  void initState() {
    super.initState();
    _allProducts = List<Product>.from(context.read<WishlistCubit>().state);
    _pagingController.addPageRequestListener(_loadPage);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshPrices());
  }

  Future<void> _refreshPrices() async {
    final ids = context.read<WishlistCubit>().state
        .map((p) => p.id)
        .whereType<String>()
        .toList();
    if (ids.isEmpty) return;
    final countryId = PreferenceRepository.instance.country?.id;
    try {
      final result = await getIt<DataStore>().products.list(queryParams: {
        'id[]': ids,
        'limit': ids.length,
        if (countryId != null) 'country_id': countryId,
      });
      final refreshed = result?.products ?? [];
      if (!mounted) return;
      if (refreshed.isNotEmpty) {
        context.read<WishlistCubit>().refreshPrices(refreshed);
      }
      // If a country is selected, only show products the API returned for it
      if (countryId != null) {
        setState(() {
          _availableIds = refreshed.map((p) => p.id).whereType<String>().toSet();
        });
        _pagingController.refresh();
      }
    } catch (_) {}
  }

  void _loadPage(int pageKey) {
    final source = _visibleProducts;
    final page = source.skip(pageKey).take(_pageSize).toList();
    final isLastPage = pageKey + page.length >= source.length;
    if (isLastPage) {
      _pagingController.appendLastPage(page);
    } else {
      _pagingController.appendPage(page, pageKey + page.length);
    }
  }

  // Called by BlocConsumer listener whenever the wishlist changes
  void _onWishlistChanged(List<Product> products) {
    _allProducts = List<Product>.from(products);
    _pagingController.refresh();
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.clearWishlist),
        content: Text(ctx.l10n.removeAllFromWishlist),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.l10n.clear)),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      for (final p in List<Product>.from(_allProducts)) {
        await context.read<WishlistCubit>().toggle(p);
      }
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.theme.appBarTheme.systemOverlayStyle!,
      child: Scaffold(
        appBar: CustomAppBar(
          title: context.l10n.wishlist,
          actions: const [CartBadgeButton()],
        ),
        body: SafeArea(
          child: BlocConsumer<WishlistCubit, List<Product>>(
            listener: (context, products) => _onWishlistChanged(products),
            builder: (context, products) {
              final visible = _visibleProducts;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${visible.length} ${context.l10n.items}',
                                style: context.bodyLargeW500),
                            const SizedBox(height: 3),
                            Text(context.l10n.inWishlist,
                                style: context.bodyMedium
                                    ?.copyWith(color: ColorConstant.manatee)),
                          ],
                        ),
                        if (visible.isNotEmpty)
                          InkWell(
                            onTap: _clearAll,
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10)),
                            child: Ink(
                              decoration: BoxDecoration(
                                borderRadius:
                                    const BorderRadius.all(Radius.circular(10)),
                                color: context.theme.cardColor,
                              ),
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  Icon(minimumzIcons.edit,
                                      size: 14,
                                      color: context.bodyMediumW500?.color),
                                  const SizedBox(width: 5),
                                  Text(context.l10n.clear, style: context.bodyMediumW500),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Gap(12),
                  // ── Grid ───────────────────────────────────────────
                  if (visible.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(minimumzIcons.heart,
                                size: 64, color: ColorConstant.manatee),
                            const SizedBox(height: 16),
                            Text(context.l10n.yourWishlistIsEmpty,
                                style: context.bodyLargeW500),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: PagedGridView<int, Product>(
                        pagingController: _pagingController,
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
                          newPageProgressIndicatorBuilder: (_) => const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                                child: CircularProgressIndicator.adaptive()),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
