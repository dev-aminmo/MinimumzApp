import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/di/di.dart';
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

  final PagingController<int, Product> _pagingController =
      PagingController(firstPageKey: 0);
  late final ProductsBloc _bloc;
  int _loadedCount = 0;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<ProductsBloc>();
    _pagingController.addPageRequestListener((pageKey) {
      _bloc.add(ProductsEvent.loadProducts(queryParameters: {
        widget.collection.filterParam: widget.collection.id,
        'offset': pageKey,
        'limit': _pageSize,
      }));
    });
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

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        appBar: CollectionAppBar(
          collection: widget.collection,
          actions: [
            InkWell(
              borderRadius: const BorderRadius.all(Radius.circular(50)),
              onTap: () => context.router.push(const CartRoute()),
              child: Ink(
                width: 45,
                height: 45,
                decoration: ShapeDecoration(
                  color: context.theme.cardColor,
                  shape: const CircleBorder(),
                ),
                child: const Icon(minimumzIcons.bag),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: BlocConsumer<ProductsBloc, ProductsState>(
            listener: (context, state) {
              state.whenOrNull(
                loaded: _onLoaded,
                error: (error) => _pagingController.error = error,
              );
            },
            builder: (context, state) {
              return PagedGridView<int, Product>(
                pagingController: _pagingController,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisExtent: 280,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                builderDelegate: PagedChildBuilderDelegate<Product>(
                  itemBuilder: (_, product, __) => ProductCard(product: product),
                  firstPageProgressIndicatorBuilder: (_) =>
                      const Center(child: CircularProgressIndicator.adaptive()),
                  newPageProgressIndicatorBuilder: (_) => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  ),
                  noItemsFoundIndicatorBuilder: (_) => const Center(
                    child: Text('No products in this category'),
                  ),
                  firstPageErrorIndicatorBuilder: (context) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_pagingController.error?.toString() ??
                            'Error loading products'),
                        const Gap(12),
                        ElevatedButton(
                          onPressed: _pagingController.refresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class CollectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CollectionAppBar({super.key, required this.collection, this.actions});
  final ProductCollection collection;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final canPop = context.router.canPop();
    return Container(
      height: kToolbarHeight,
      margin: EdgeInsets.only(top: context.viewPadding.top),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: canPop || actions != null
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.center,
          children: [
            if (canPop)
              InkWell(
                borderRadius: const BorderRadius.all(Radius.circular(50)),
                onTap: () => context.router.maybePop(),
                child: Ink(
                  width: 45,
                  height: 45,
                  decoration: ShapeDecoration(
                    color: context.theme.cardColor,
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons.arrow_back_outlined),
                ),
              ),
            if (!canPop && actions != null)
              const SizedBox(height: 45, width: 45),
            Container(
              height: 40,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: context.theme.cardColor,
                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
              ),
              child: Text(collection.title ?? '',
                  style: context.bodyMediumW500),
            ),
            if (canPop && actions == null)
              const SizedBox(height: 45, width: 45),
            if (actions != null)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: actions!,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
