import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/presentation/routes/app_router.dart';
import 'package:minimumz/presentation/screens/home/widgets/product_card.dart';

import '../components/index.dart';

@RoutePage()
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _pageSize = 20;

  final _controller = TextEditingController();
  Timer? _debounce;
  String _currentQuery = '';

  final PagingController<int, Product> _pagingController =
      PagingController(firstPageKey: 0);

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(_fetchPage);
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    _pagingController.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() => _currentQuery = '');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _currentQuery = trimmed;
      // refresh resets to firstPageKey and triggers _fetchPage(0)
      _pagingController.refresh();
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    if (_currentQuery.isEmpty) return;
    try {
      final res = await getIt<DataStore>().products.list(
        queryParams: {
          'title': _currentQuery,
          'offset': pageKey,
          'limit': _pageSize,
        },
      );
      if (!mounted) return;
      final products = res?.products ?? [];
      final isLastPage = products.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(products);
      } else {
        _pagingController.appendPage(products, pageKey + products.length);
      }
    } catch (e) {
      if (mounted) _pagingController.error = e;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        context.bottomViewPadding == 0.0 ? 30.0 : context.bottomViewPadding;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: SearchAppBar(
        controller: _controller,
        onChanged: _onChanged,
      ),
      body: SafeArea(child: _buildBody(context, bottomPadding)),
    );
  }

  Widget _buildBody(BuildContext context, double bottomPadding) {
    if (_currentQuery.isEmpty) {
      return Center(
        child: Text(
          'Search through the store',
          style: context.bodyLarge?.copyWith(color: ColorConstant.manatee),
        ),
      );
    }

    return PagedGridView<int, Product>(
      pagingController: _pagingController,
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 280,
      ),
      builderDelegate: PagedChildBuilderDelegate<Product>(
        itemBuilder: (_, product, __) => ProductCard(product: product),
        firstPageProgressIndicatorBuilder: (_) =>
            const Center(child: CircularProgressIndicator.adaptive()),
        newPageProgressIndicatorBuilder: (_) => const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
        noItemsFoundIndicatorBuilder: (_) => Center(
          child: Text(
            'No results found',
            style: context.bodyMedium?.copyWith(color: ColorConstant.manatee),
          ),
        ),
        firstPageErrorIndicatorBuilder: (_) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _pagingController.error?.toString() ?? 'Search failed',
                style: context.bodyMedium?.copyWith(color: ColorConstant.manatee),
              ),
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
  }
}

class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SearchAppBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  bool get canPop => getIt<AppRouter>().canPop();

  @override
  Widget build(BuildContext context) {
    const inputBorder = OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10.0)),
        borderSide: BorderSide(width: 0, color: Colors.transparent));
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.theme.appBarTheme.systemOverlayStyle!,
      child: Container(
        alignment: Alignment.bottomCenter,
        padding: EdgeInsets.fromLTRB(20, context.viewPadding.top, 20, 0),
        child: Row(
          children: [
            if (canPop) ...[
              Hero(
                tag: 'search_back',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
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
                ),
              ),
              const Gap(15),
            ],
            Expanded(
              child: Hero(
                tag: 'search',
                child: Material(
                  color: Colors.transparent,
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    autofocus: true,
                    decoration: InputDecoration(
                      filled: true,
                      hintText: 'Search ...',
                      contentPadding: EdgeInsets.zero,
                      border: inputBorder,
                      enabledBorder: inputBorder,
                      focusedBorder: inputBorder,
                      hintStyle: TextStyle(color: ColorConstant.manatee),
                      fillColor: context.theme.cardColor,
                      prefixIcon: Icon(
                        minimumzIcons.search,
                        color: ColorConstant.manatee,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
