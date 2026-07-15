import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/common/pricing_utils.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';
import 'package:minimumz/presentation/screens/home/home_screen.dart' show Headline;
import 'package:minimumz/presentation/screens/home/widgets/product_card.dart';
import 'package:minimumz/services/reco_event_tracker.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Personalized "For You" feed — replaces the home New Arrivals section.
///
/// Logged-in users get server-ranked recommendations (session-snapshot
/// pagination). Guests fall back to newest products (the feed endpoint is
/// authenticated). Each visible card fires a viewport impression; taps fire a
/// view event — both batched by [RecoEventTracker].
class ForYouFeed extends StatefulWidget {
  const ForYouFeed({super.key});

  @override
  State<ForYouFeed> createState() => _ForYouFeedState();
}

class _ForYouFeedState extends State<ForYouFeed> {
  static const _pageSize = 20;

  final PagingController<int, Product> _pagingController =
      PagingController(firstPageKey: 0);
  String? _session;                    // server session for this feed instance
  int _loadedCount = 0;

  bool get _isGuest => getIt<PreferenceRepository>().isGuest;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(_fetchPage);
  }

  @override
  void dispose() {
    RecoEventTracker.instance.flushNow();   // don't lose buffered impressions
    _pagingController.dispose();
    super.dispose();
  }

  Future<void> _fetchPage(int offset) async {
    try {
      final countryId = PreferenceRepository.instance.country?.id;
      List<Product> products;
      bool isLast;

      if (_isGuest) {
        // Guests: newest products (feed needs auth).
        final res = await getIt<DataStore>().products.list(queryParams: {
          'offset': offset,
          'limit': _pageSize,
          'sort': 'created_at',
          if (countryId != null) 'country_id': countryId,
        });
        products = filterPricedProducts(res?.products ?? []);
        isLast = products.length < _pageSize;
        _loadedCount += products.length;
        isLast
            ? _pagingController.appendLastPage(products)
            : _pagingController.appendPage(products, _loadedCount);
      } else {
        final page = await getIt<DataStore>().feed.fetch(
              session: _session,
              offset: offset,
              limit: _pageSize,
              countryId: countryId,
            );
        // Adopt the server session on the first page.
        if (_session == null && page?.session != null) {
          _session = page!.session;
          RecoEventTracker.instance.setSession(_session);
        }
        products = filterPricedProducts(page?.products ?? []);
        isLast = !(page?.hasMore ?? false);
        _loadedCount += products.length;
        isLast
            ? _pagingController.appendLastPage(products)
            : _pagingController.appendPage(products, page!.nextOffset);
      }

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) _pagingController.error = e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isGuest ? context.l10n.newArrival : context.l10n.forYou;
    final label = _loadedCount != 0 ? '$title ($_loadedCount)' : title;

    return MultiSliver(children: [
      SliverToBoxAdapter(child: Headline(headline: label, onViewAllTap: null)),
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
            itemBuilder: (_, product, __) => _TrackedCard(product: product),
            firstPageProgressIndicatorBuilder: (_) => _skeleton(),
          ),
        ),
      ),
    ]);
  }

  Widget _skeleton() {
    const product = Product(title: 'Medusa Product');
    const card = SizedBox(height: 320, child: ProductCard(product: product, shimmer: true));
    return const Skeletonizer(
      enabled: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [Expanded(child: card), SizedBox(width: 8), Expanded(child: card)]),
          SizedBox(height: 8),
          Row(children: [Expanded(child: card), SizedBox(width: 8), Expanded(child: card)]),
        ],
      ),
    );
  }
}

/// A product card that reports a viewport impression once it is ≥50% visible.
/// (The "view details" event is fired by the product details screen, so it
/// captures opens from anywhere — not just the feed.)
class _TrackedCard extends StatefulWidget {
  const _TrackedCard({required this.product});
  final Product product;

  @override
  State<_TrackedCard> createState() => _TrackedCardState();
}

class _TrackedCardState extends State<_TrackedCard> {
  bool _reported = false;

  @override
  Widget build(BuildContext context) {
    final pid = int.tryParse(widget.product.id ?? '');
    if (pid == null) return ProductCard(product: widget.product);

    return VisibilityDetector(
      key: Key('foryou_$pid'),
      onVisibilityChanged: (info) {
        if (!_reported && info.visibleFraction >= 0.5 && mounted) {
          _reported = true;
          RecoEventTracker.instance.impression(pid);
        }
      },
      child: ProductCard(product: widget.product),
    );
  }
}
