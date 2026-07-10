import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:image_picker/image_picker.dart';
import 'package:minimumz/common/doh_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/image_url.dart';
import 'package:minimumz/common/pricing_utils.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';
import 'package:minimumz/domain/model/product_filter.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/presentation/routes/app_router.dart';
import 'package:minimumz/presentation/screens/home/widgets/product_card.dart';

import '../components/index.dart';

class _SuggestionItem {
  final String id;
  final String name;
  final String? imageUrl;
  const _SuggestionItem({required this.id, required this.name, this.imageUrl});
}

// ── Screen ────────────────────────────────────────────────────────────────────

@RoutePage()
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _pageSize = 20;

  final _controller = TextEditingController();
  final _focusNode  = FocusNode();
  Timer? _debounce;
  String _currentQuery = '';

  List<_SuggestionItem> _suggestionItems = [];
  bool _loadingSuggestions = false;
  bool _showSuggestions    = false;
  bool _fieldFocused       = false;
  List<String> _history    = [];
  ProductFilter _filter    = ProductFilter.empty;

  // Image (visual) search: when active, results come from a picked photo via the
  // vision service instead of a title query. _imagePath is the resized file.
  bool _imageMode    = false;
  String? _imagePath;

  final PagingController<int, Product> _pagingController =
      PagingController(firstPageKey: 0);

  bool get _showOverlay =>
      _showSuggestions ||
      (_fieldFocused && _currentQuery.isEmpty && _history.isNotEmpty);

  @override
  void initState() {
    super.initState();
    _history = PreferenceRepository.instance.searchHistory;
    _pagingController.addPageRequestListener(_fetchPage);
    _focusNode.addListener(() {
      setState(() {
        _fieldFocused = _focusNode.hasFocus;
        if (!_focusNode.hasFocus) _showSuggestions = false;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    _pagingController.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    // Typing returns to text search, leaving image-search mode.
    if (_imageMode) {
      setState(() { _imageMode = false; _imagePath = null; });
    }
    if (trimmed.isEmpty) {
      setState(() {
        _currentQuery      = '';
        _showSuggestions   = false;
        _suggestionItems   = [];
      });
      return;
    }
    setState(() { _showSuggestions = true; _loadingSuggestions = true; });
    _debounce = Timer(const Duration(milliseconds: 400), () => _fetchSuggestions(trimmed));
  }

  /// Opens a Camera/Gallery sheet, then runs an image search with the picked photo.
  Future<void> _onCameraTap() async {
    FocusScope.of(context).unfocus();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(context.l10n.searchByImage,
                  style: context.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(context.l10n.camera),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(context.l10n.gallery),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _pickAndSearch(source);
  }

  Future<void> _pickAndSearch(ImageSource source) async {
    // Resize/compress client-side to keep the upload small (CLIP needs only a
    // small image anyway).
    final XFile? file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (file == null || !mounted) return;

    _focusNode.unfocus();
    _controller.clear();
    setState(() {
      _imageMode       = true;
      _imagePath       = file.path;
      _currentQuery    = '';
      _showSuggestions = false;
      _suggestionItems = [];
    });
    _pagingController.refresh();
  }

  List<String> get _viewedIds   => PreferenceRepository.instance.recentlyViewedIds;
  List<String> get _wishlistIds => PreferenceRepository.instance.wishlistProducts
      .map((p) => p.id).whereType<String>().toList();

  Future<void> _fetchSuggestions(String query) async {
    try {
      // Omit viewed_ids from the inline suggestions dropdown — it can be a long
      // comma-separated list that bloats every-keystroke requests unnecessarily.
      final data = await getIt<DataStore>().products.suggestions(
        query,
        wishlistIds: _wishlistIds,
      );
      if (!mounted) return;
      final raw = (data?['products'] as List? ?? []);
      final products = raw.map((e) {
        final m = e as Map<String, dynamic>;
        final img = (m['base_image'] as Map<String, dynamic>?)?['path'] as String?;
        return _SuggestionItem(
          id: m['id']?.toString() ?? '',
          name: (m['name'] as String? ?? '').replaceAll(RegExp(r'<[^>]*>'), ''),
          imageUrl: fixImageUrl(img),
        );
      }).toList();
      setState(() {
        _suggestionItems    = products;
        _loadingSuggestions = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingSuggestions = false);
    }
  }

  void _commitQuery(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    _controller.text = trimmed;
    _focusNode.unfocus();
    setState(() {
      _currentQuery    = trimmed;
      _showSuggestions = false;
      _imageMode       = false;
      _imagePath       = null;
    });
    _pagingController.refresh();
    PreferenceRepository.instance.addSearchHistory(trimmed).then((_) {
      if (mounted) setState(() => _history = PreferenceRepository.instance.searchHistory);
    });
  }

  /// A product suggestion identifies a specific product, so open it directly by
  /// id instead of re-running a fragile title search. Falls back to the title
  /// search if the id is missing or the fetch fails.
  Future<void> _openProduct(_SuggestionItem item) async {
    if (item.id.isEmpty) {
      _commitQuery(item.name);
      return;
    }

    _focusNode.unfocus();
    EasyLoading.show();
    try {
      final countryId = PreferenceRepository.instance.country?.id;
      final res = await getIt<DataStore>().products.retrieve(
        item.id,
        queryParams: {if (countryId != null) 'country_id': countryId},
      );
      if (!mounted) return;
      EasyLoading.dismiss();
      final product = res?.product;
      if (product != null) {
        context.router.push(ProductDetailsRoute(product: product));
      } else {
        _commitQuery(item.name);
      }
    } catch (_) {
      if (!mounted) return;
      EasyLoading.dismiss();
      _commitQuery(item.name);
    }
  }

  void _removeHistory(String query) {
    PreferenceRepository.instance.removeSearchHistory(query).then((_) {
      if (mounted) setState(() => _history = PreferenceRepository.instance.searchHistory);
    });
  }

  void _clearHistory() {
    PreferenceRepository.instance.clearSearchHistory().then((_) {
      if (mounted) setState(() => _history = []);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    // Image-search mode: the vision service returns a single ranked top-N list,
    // so we append it as one (last) page.
    if (_imageMode) {
      if (_imagePath == null) return;
      try {
        final countryId = PreferenceRepository.instance.country?.id;
        final res = await getIt<DataStore>().products.imageSearch(
          imagePath: _imagePath!,
          countryId: countryId,
          limit: 50,
        );
        if (!mounted) return;
        _pagingController.appendLastPage(filterPricedProducts(res?.products ?? []));
      } catch (e) {
        if (mounted) _pagingController.error = e;
      }
      return;
    }

    if (_currentQuery.isEmpty) return;
    try {
      final countryId = PreferenceRepository.instance.country?.id;
      final viewed   = _viewedIds;
      final wishlist = _wishlistIds;
      final res = await getIt<DataStore>().products.list(
        queryParams: {
          'title':  _currentQuery,
          'offset': pageKey,
          'limit':  _pageSize,
          if (countryId != null)    'country_id':   countryId,
          if (viewed.isNotEmpty)    'viewed_ids':   viewed.join(','),
          if (wishlist.isNotEmpty)  'wishlist_ids': wishlist.join(','),
          ..._filter.toQueryParams(),
        },
      );
      if (!mounted) return;
      final products   = filterPricedProducts(res?.products ?? []);
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
        controller:   _controller,
        focusNode:    _focusNode,
        onChanged:    _onChanged,
        onSubmitted:  _commitQuery,
        onCameraTap:  _onCameraTap,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            _buildResults(context, bottomPadding),
            if (_showOverlay)
              Positioned.fill(child: _buildOverlayPanel(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(BuildContext context, double bottomPadding) {
    if (_currentQuery.isEmpty && !_imageMode) {
      return Center(
        child: Text(
          context.l10n.searchThroughStore,
          style: context.bodyLarge?.copyWith(color: ColorConstant.manatee),
        ),
      );
    }

    return Column(
      children: [
        // Title-based sort/filter only apply to text search; in image mode show a
        // chip indicating the active visual search instead.
        if (_imageMode)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Chip(
                  avatar: const Icon(Icons.image_search_outlined, size: 18),
                  label: Text(context.l10n.searchByImage),
                  onDeleted: () {
                    setState(() { _imageMode = false; _imagePath = null; });
                  },
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final result = await ProductSortSheet.show(context, _filter.sortBy);
                    if (result != null && mounted) {
                      setState(() => _filter = _filter.copyWith(sortBy: result.isEmpty ? null : result));
                      _pagingController.refresh();
                    }
                  },
                  icon: Icon(Icons.sort_rounded, size: 18,
                      color: _filter.sortBy != null ? ColorConstant.primary : null),
                  label: Text(
                    context.l10n.sortBy,
                    style: TextStyle(
                      color: _filter.sortBy != null ? ColorConstant.primary : null,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final result = await ProductFilterSheet.show(context, _filter);
                    if (result != null && mounted) {
                      setState(() => _filter = result);
                      _pagingController.refresh();
                    }
                  },
                  icon: Icon(Icons.tune_outlined, size: 18,
                      color: _filter.activeCount > 0 ? ColorConstant.primary : null),
                  label: Text(
                    _filter.activeCount > 0
                        ? context.l10n.activeFilters(_filter.activeCount)
                        : context.l10n.filters,
                    style: TextStyle(
                      color: _filter.activeCount > 0 ? ColorConstant.primary : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: PagedGridView<int, Product>(
      pagingController: _pagingController,
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 301,
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
            context.l10n.noResultsFound,
            style: context.bodyMedium?.copyWith(color: ColorConstant.manatee),
          ),
        ),
        firstPageErrorIndicatorBuilder: (_) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _imageMode
                    ? context.l10n.imageSearchUnavailable
                    : (_pagingController.error?.toString() ?? context.l10n.searchFailed),
                style: context.bodyMedium?.copyWith(color: ColorConstant.manatee),
              ),
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
  }

  Widget _buildOverlayPanel(BuildContext context) {
    return Material(
      elevation: 4,
      color: context.theme.scaffoldBackgroundColor,
      child: _showSuggestions
          ? _buildSuggestionsList(context)
          : _buildHistoryList(context),
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.l10n.recentSearches,
                  style: context.bodySmallW500
                      ?.copyWith(color: ColorConstant.manatee)),
              GestureDetector(
                onTap: _clearHistory,
                child: Text(context.l10n.clearAll,
                    style: context.bodySmall
                        ?.copyWith(color: ColorConstant.primary)),
              ),
            ],
          ),
        ),
        ..._history.map((q) => ListTile(
              leading: Icon(Icons.history,
                  color: ColorConstant.manatee, size: 20),
              title: Text(q, style: context.bodyMedium),
              trailing: IconButton(
                icon: Icon(Icons.close,
                    size: 16, color: ColorConstant.manatee),
                onPressed: () => _removeHistory(q),
              ),
              dense: true,
              onTap: () => _commitQuery(q),
            )),
        const Gap(8),
      ],
    );
  }

  Widget _buildSuggestionsList(BuildContext context) {
    final bool empty = _suggestionItems.isEmpty;
    if (_loadingSuggestions && empty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    if (empty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(context.l10n.noResultsFound,
            style: context.bodyMedium?.copyWith(color: ColorConstant.manatee)),
      );
    }
    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(context.l10n.products,
              style: context.bodySmallW500
                  ?.copyWith(color: ColorConstant.manatee)),
        ),
        ..._suggestionItems.map((p) {
          final imageUrl = p.imageUrl;
          final name = p.name;
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      cacheManager: DohCacheManager.instance,
                      imageUrl: imageUrl,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _imageFallback(),
                    )
                  : _imageFallback(),
            ),
            title: Text(name,
                style: context.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            onTap: () => _openProduct(p),
          );
        }),
        const Gap(8),
      ],
    );
  }

  Widget _imageFallback() => Container(
        width: 48,
        height: 48,
        color: ColorConstant.beige,
        child: const Icon(Icons.image_not_supported_outlined,
            size: 20, color: Colors.grey),
      );
}

// ── App bar ───────────────────────────────────────────────────────────────────

class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SearchAppBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onCameraTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onCameraTap;

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
                    controller:      controller,
                    focusNode:       focusNode,
                    onChanged:       onChanged,
                    onSubmitted:     onSubmitted,
                    autofocus:       true,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      filled: true,
                      hintText: context.l10n.searchHint,
                      contentPadding: EdgeInsets.zero,
                      border:        inputBorder,
                      enabledBorder: inputBorder,
                      focusedBorder: inputBorder,
                      hintStyle:  TextStyle(color: ColorConstant.manatee),
                      fillColor:  context.theme.cardColor.withAlpha(50),
                      prefixIcon: Icon(minimumzIcons.search,
                          color: ColorConstant.manatee),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.photo_camera_outlined,
                            color: ColorConstant.manatee),
                        tooltip: context.l10n.searchByImage,
                        onPressed: onCameraTap,
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
