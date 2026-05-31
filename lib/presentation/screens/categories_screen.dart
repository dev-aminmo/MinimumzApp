import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:minimumz/common/doh_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/data/data.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../routes/app_router.dart';
import 'package:minimumz/cubits/locale/locale_cubit.dart';
import 'home/bloc/collections/collections_bloc.dart';

@RoutePage()
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<CollectionsBloc, CollectionsState>(
          builder: (context, state) {
            return state.map(
              loading: (_) => _buildSkeleton(context),
              loaded: (data) => _buildGrid(context, data.collections),
              error: (e) => _buildError(context, e.message),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisExtent: 100,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 9,
        itemBuilder: (_, __) => _CategoryCard(
          collection: ProductCollection(id: '', title: 'Placeholder'),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<ProductCollection> collections) {
    if (collections.isEmpty) {
      return Center(child: Text(context.l10n.noProductsInCategory));
    }
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          sliver: SliverToBoxAdapter(
            child: Text(context.l10n.categories, style: context.bodyLargeW600),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (_, i) => _CategoryCard(collection: collections[i]),
              childCount: collections.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisExtent: 100,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError(BuildContext context, String? message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(message ?? context.l10n.errorLoadingProducts),
          const Gap(12),
          ElevatedButton(
            onPressed: () => context
                .read<CollectionsBloc>()
                .add(const CollectionsEvent.retrieveCollections()),
            child: Text(context.l10n.retry),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.collection});
  final ProductCollection collection;

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleCubit>().state.languageCode;
    return GestureDetector(
      onTap: () => context.router
          .push(CollectionRoute(collection: collection)),
      child: Container(
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: ColorConstant.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: ColorConstant.primary.withValues(alpha: 0.15),
                ),
              ),
              child: ClipOval(
                child: collection.logo != null
                    ? CachedNetworkImage(
                        cacheManager: DohCacheManager.instance,
                        imageUrl: collection.logo!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Icon(
                          Icons.category_outlined,
                          color: ColorConstant.primary,
                          size: 24,
                        ),
                      )
                    : Icon(
                        Icons.category_outlined,
                        color: ColorConstant.primary,
                        size: 24,
                      ),
              ),
            ),
            const Gap(8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                collection.localizedTitle(locale),
                style: context.bodyExtraSmall
                    ?.copyWith(fontWeight: FontWeight.w500),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
