import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';

import '../../blocs/auth/authentication_bloc.dart';
import '../../common/colors.dart';
import '../components/index.dart';
import 'home/widgets/product_card.dart';

@RoutePage()
class RecentlyViewedScreen extends StatefulWidget {
  const RecentlyViewedScreen({super.key});

  @override
  State<RecentlyViewedScreen> createState() => _RecentlyViewedScreenState();
}

class _RecentlyViewedScreenState extends State<RecentlyViewedScreen> {
  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final isLoggedIn = context.read<AuthenticationBloc>().state
        .maybeMap(loggedIn: (_) => true, orElse: () => false);

    try {
      if (isLoggedIn) {
        final countryId = PreferenceRepository.instance.country?.id;
        final products = await getIt<DataStore>().products
            .fetchRecentlyViewed(countryId: countryId);
        if (mounted) setState(() { _products = products; _loading = false; });
        return;
      }

      // Guest: fetch all recently viewed products in one request
      final ids = PreferenceRepository.instance.recentlyViewedIds;
      if (ids.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final countryId = PreferenceRepository.instance.country?.id;
      final result = await getIt<DataStore>().products.list(queryParams: {
        'id[]': ids,
        'limit': ids.length,
        if (countryId != null) 'country_id': countryId,
      });
      // Preserve local order (server may return in any order)
      final byId = {for (final p in result?.products ?? <Product>[]) p.id: p};
      final products = ids
          .map((id) => byId[id])
          .whereType<Product>()
          .toList();
      if (mounted) setState(() { _products = products; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.theme.appBarTheme.systemOverlayStyle!,
      child: Scaffold(
        appBar: CustomAppBar(
          title: context.l10n.recentlyViewed,
          actions: const [CartBadgeButton()],
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator.adaptive())
              : _products.isEmpty
                  ? _buildEmpty()
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisExtent: 301,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _products.length,
                      itemBuilder: (_, i) => ProductCard(product: _products[i]),
                    ),
        ),
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(minimumzIcons.clock, size: 48, color: ColorConstant.manatee),
            const SizedBox(height: 16),
            Text(context.l10n.recentlyViewed, style: context.bodyLargeW500),
            const SizedBox(height: 8),
            Text(
              context.l10n.noProducts,
              style:
                  context.bodyMedium?.copyWith(color: ColorConstant.manatee),
            ),
          ],
        ),
      );
}
