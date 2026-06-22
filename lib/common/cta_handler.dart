import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';
import 'package:minimumz/presentation/routes/app_router.dart';

/// Handles a slide / banner call-to-action URL.
///
/// Admin-generated URLs are real storefront links carrying `cta_type` + `cta_id`
/// (+ optional `cta_title`) so we can navigate natively: brand/category → the
/// collection screen, product → its detail page. Anything else (a custom URL)
/// opens in the browser.
Future<void> handleCtaUrl(BuildContext context, String? url) async {
  final raw = url?.trim() ?? '';
  if (raw.isEmpty) return;

  final uri = Uri.tryParse(raw);
  final type = uri?.queryParameters['cta_type'];
  final id = uri?.queryParameters['cta_id'];
  final title = uri?.queryParameters['cta_title'] ?? '';

  if (type != null && id != null && id.isNotEmpty) {
    switch (type) {
      case 'brand':
        context.router.push(CollectionRoute(
          collection: ProductCollection(id: id, title: title, filterParam: 'type_id'),
        ));
        return;
      case 'category':
        context.router.push(CollectionRoute(
          collection: ProductCollection(id: id, title: title, filterParam: 'category_id'),
        ));
        return;
      case 'product':
        await _openProduct(context, id);
        return;
    }
  }

  // Fallback: open external/custom URLs in the browser.
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

Future<void> _openProduct(BuildContext context, String id) async {
  EasyLoading.show();
  try {
    final countryId = PreferenceRepository.instance.country?.id;
    final res = await getIt<DataStore>().products.retrieve(
      id,
      queryParams: {if (countryId != null) 'country_id': countryId},
    );
    if (!context.mounted) return;
    EasyLoading.dismiss();
    final product = res?.product;
    if (product != null) {
      context.router.push(ProductDetailsRoute(product: product));
    }
  } catch (_) {
    if (context.mounted) EasyLoading.dismiss();
  }
}
