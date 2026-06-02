import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:minimumz/common/doh_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/data/data.dart';
import '../components/index.dart';
import '../routes/app_router.dart';

@RoutePage()
class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({
    super.key,
    required this.productId,
    this.productTitle,
  });

  final String productId;
  final String? productTitle;

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  static const _pageSize = 15;

  final PagingController<int, ReviewItem> _pagingController =
      PagingController(firstPageKey: 0);

  int _count = 0;
  double _avgRating = 0.0;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(_fetchPage);
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final result = await getIt<DataStore>().reviews.list(
            productId: widget.productId,
            limit: _pageSize,
            offset: pageKey,
          );
      if (!mounted) return;

      // Always sync header stats from the latest response
      setState(() {
        _count = result.count;
        _avgRating = result.avgRating;
      });

      final isLastPage = result.reviews.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(result.reviews);
      } else {
        _pagingController.appendPage(
            result.reviews, pageKey + result.reviews.length);
      }
    } catch (e) {
      if (mounted) _pagingController.error = e;
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        context.bottomViewPadding == 0.0 ? 30.0 : context.bottomViewPadding;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.theme.appBarTheme.systemOverlayStyle!,
      child: Scaffold(
        appBar: CustomAppBar(
          title: widget.productTitle != null
              ? '${context.l10n.reviews} · ${widget.productTitle}'
              : context.l10n.reviews,
        ),
        body: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _Header(
                  count: _count,
                  avgRating: _avgRating,
                  productId: widget.productId,
                  onReviewAdded: _pagingController.refresh,
                ),
              ),
            ),

            // ── Reviews list ─────────────────────────────────────────
            PagedSliverList<int, ReviewItem>(
              pagingController: _pagingController,
              builderDelegate: PagedChildBuilderDelegate<ReviewItem>(
                itemBuilder: (_, review, __) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _ReviewCard(review: review),
                ),
                firstPageProgressIndicatorBuilder: (_) => const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator.adaptive()),
                ),
                newPageProgressIndicatorBuilder: (_) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator.adaptive()),
                ),
                noItemsFoundIndicatorBuilder: (context) => Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(child: Text(context.l10n.noReviewsYet)),
                ),
                firstPageErrorIndicatorBuilder: (context) => Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _pagingController.error?.toString() ??
                              context.l10n.failedToLoadReviews,
                        ),
                        const SizedBox(height: 12),
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

            SliverPadding(padding: EdgeInsets.only(bottom: bottomPadding)),
          ],
        ),
      ),
    );
  }
}

// ── Header ───────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.count,
    required this.avgRating,
    required this.productId,
    required this.onReviewAdded,
  });

  final int count;
  final double avgRating;
  final String productId;
  final VoidCallback onReviewAdded;

  @override
  Widget build(BuildContext context) {
    final fullStars = avgRating.floor();
    final halfStar = (avgRating - fullStars) >= 0.5;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$count ${context.l10n.reviews}',
                style: context.bodyMediumW500),
            const SizedBox(height: 5),
            Row(
              children: [
                Text(avgRating.toStringAsFixed(1), style: context.bodySmall),
                const SizedBox(width: 4),
                Row(
                  children: List.generate(5, (i) {
                    if (i < fullStars) {
                      return const Icon( CupertinoIcons.star_fill,
                          size: 14, color: Color(0xffFFCF04 ));
                    } else if (i == fullStars && halfStar) {
                      return const Icon( CupertinoIcons.star_lefthalf_fill,
                          size: 14, color: Color(0xffFFCF04 ));
                    }
                    return Icon( CupertinoIcons.star,
                        size: 14, color: ColorConstant.manatee);
                  }),
                ),
              ],
            ),
          ],
        ),
        FilledButton(
          style: ButtonStyle(
            padding: WidgetStateProperty.all<EdgeInsets>(
                const EdgeInsets.symmetric(horizontal: 10)),
            shape: WidgetStateProperty.all<RoundedRectangleBorder>(
              const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(5))),
            ),
          ),
          onPressed: () async {
            await context.router.push(AddReviewRoute(productId: productId));
            onReviewAdded();
          },
          child: Row(
            children: [
              const Icon(minimumzIcons.edit_square, size: 18),
              const SizedBox(width: 5),
              Text(context.l10n.addReview),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Review card ───────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
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
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.reviewerName, style: context.bodyMediumW500),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(minimumzIcons.clock,
                            color: ColorConstant.manatee, size: 18),
                        const SizedBox(width: 5),
                        Text(date,
                            style: context.bodyExtraSmall
                                ?.copyWith(color: ColorConstant.manatee)),
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
                const SizedBox(height: 5),
                Row(
                  children: List.generate(5, (i) {
                    return Icon(
                      i < fullStars ?  CupertinoIcons.star_fill :  CupertinoIcons.star,
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
        const SizedBox(height: 10),
        Text(review.comment, style: context.bodyMedium),
        if (review.images.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: review.images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => _showImageViewer(context, review.images, i),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    cacheManager: DohCacheManager.instance,
                    imageUrl: review.images[i],
                    width: 80,
                    height: 80,
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

void _showImageViewer(BuildContext context, List<String> images, int initial) {
  showDialog(
    context: context,
    builder: (_) => _ImageViewerDialog(images: images, initialIndex: initial),
  );
}

class _ImageViewerDialog extends StatefulWidget {
  const _ImageViewerDialog({required this.images, required this.initialIndex});
  final List<String> images;
  final int initialIndex;

  @override
  State<_ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<_ImageViewerDialog> {
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
