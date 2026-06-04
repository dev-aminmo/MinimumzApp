import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/doh_cache_manager.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/cubits/locale/locale_cubit.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';
import '../../components/index.dart';
import '../../routes/app_router.dart';

@RoutePage()
class OrderDetailsScreen extends StatefulWidget {
  const OrderDetailsScreen({super.key, required this.orderId, this.order});

  /// The order id to display. Used to fetch when [order] isn't provided
  /// (e.g. when opened from a push notification).
  final String orderId;

  /// Pre-loaded order (e.g. from the orders list) to render immediately.
  final Order? order;

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  Order? _order;
  bool _loading = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    if (_order != null) {
      _cache(_order!);
      return;
    }
    // Cache-first: render the last cached copy instantly, then refresh.
    final cached = getIt<PreferenceRepository>().cachedOrderDetail(widget.orderId);
    if (cached != null) {
      try {
        _order = Order.fromJson(cached);
      } catch (_) {}
    }
    _fetch();
  }

  void _cache(Order order) {
    getIt<PreferenceRepository>()
        .setCachedOrderDetail(widget.orderId, order.toJson());
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = _order == null; // only block the UI when there's nothing cached
      _error = false;
    });
    try {
      final order = await getIt<DataStore>().customers.getOrder(widget.orderId);
      if (!mounted) return;
      if (order != null) _cache(order);
      setState(() {
        _order = order ?? _order;
        _error = order == null && _order == null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = _order == null; // keep showing cached data on refresh failure
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.theme.appBarTheme.systemOverlayStyle!,
      child: Scaffold(
        appBar: CustomAppBar(
          title: '${context.l10n.order} #${_order?.displayId ?? widget.orderId}',
        ),
        body: _loading
            ? Center(
                child: LoadingAnimationWidget.threeArchedCircle(
                    color: ColorConstant.primary, size: 40))
            : _error || _order == null
                ? _errorView(context)
                : _OrderBody(order: _order!),
      ),
    );
  }

  Widget _errorView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 56, color: ColorConstant.manatee.withValues(alpha: 0.6)),
          const Gap(12),
          Text(context.l10n.errorLoadingCart,
              style: context.bodyMedium?.copyWith(color: ColorConstant.manatee)),
          const Gap(16),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ColorConstant.primary),
            onPressed: _fetch,
            child: Text(context.l10n.retry),
          ),
        ],
      ),
    );
  }
}

class _OrderBody extends StatelessWidget {
  const _OrderBody({required this.order});
  final Order order;

  String _formatDate(DateTime? dt) =>
      dt == null ? '' : DateFormat('d MMM yyyy, HH:mm').format(dt.toLocal());

  @override
  Widget build(BuildContext context) {
    final currencyCode =
        order.currencyCode?.toUpperCase() ?? PreferenceRepository.currencyCode;
    final locale = context.read<LocaleCubit>().state.languageCode;
    final addr = order.shippingAddress;

    String price(num? a) => a.formatAsPrice(currencyCode, locale: locale);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.l10n.order} #${order.displayId ?? order.id ?? ''}',
                  style: context.bodyLargeW600
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const Gap(4),
                Text(_formatDate(order.createdAt),
                    style:
                        context.bodySmall?.copyWith(color: ColorConstant.manatee)),
              ],
            ),
            OrderStatusChip(order.status.value),
          ],
        ),
        const Gap(16),
        const Divider(height: 0),
        const Gap(16),
        if (order.items?.isNotEmpty ?? false) ...[
          Text(context.l10n.items, style: context.bodyMediumW500),
          const Gap(10),
          ...order.items!.map((item) => _LineItemRow(
              item: item, currencyCode: currencyCode, locale: locale)),
          const Gap(16),
          const Divider(height: 0),
          const Gap(16),
        ],
        _totalRow(context, context.l10n.subtotal, price(order.subTotal)),
        if ((order.shippingTotal ?? 0) > 0)
          _totalRow(context, context.l10n.shipping, price(order.shippingTotal)),
        if ((order.discountTotal ?? 0) > 0)
          _totalRow(context, context.l10n.discount,
              '− ${price(order.discountTotal)}',
              valueColor: Colors.green),
        const Divider(height: 16),
        _totalRow(context, context.l10n.total, price(order.total), bold: true),
        if ((order.trackingReference ?? '').isNotEmpty) ...[
          const Gap(20),
          Text(context.l10n.trackingNumber, style: context.bodyMediumW500),
          const Gap(6),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  order.trackingReference!,
                  style: context.bodySmall?.copyWith(
                      color: ColorConstant.brownDark,
                      fontWeight: FontWeight.w600),
                ),
              ),
              const Gap(8),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: order.trackingReference!));
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      content: Text(context.l10n.copiedToClipboard),
                      duration: const Duration(seconds: 2),
                    ));
                },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.copy_rounded,
                      size: 18, color: ColorConstant.primary),
                ),
              ),
            ],
          ),
        ],
        if (addr != null) ...[
          const Gap(20),
          Text(context.l10n.deliveryAddress, style: context.bodyMediumW500),
          const Gap(8),
          Text(
            [
              '${addr.firstName ?? ''} ${addr.lastName ?? ''}'.trim(),
              addr.address1 ?? '',
              [addr.city, addr.province, addr.postalCode]
                  .where((e) => (e ?? '').isNotEmpty)
                  .join(', '),
              addr.phone ?? '',
            ].where((e) => e.isNotEmpty).join('\n'),
            style: context.bodySmall?.copyWith(color: ColorConstant.manatee),
          ),
        ],
      ],
    );
  }

  Widget _totalRow(BuildContext context, String label, String value,
      {bool bold = false, Color? valueColor}) {
    final labelStyle = bold ? context.bodyMediumW500 : context.bodySmall;
    final valueStyle = bold
        ? context.bodyLargeW600?.copyWith(
            fontWeight: FontWeight.w800, color: ColorConstant.brownDark)
        : context.bodySmall
            ?.copyWith(fontWeight: FontWeight.w600, color: valueColor);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: labelStyle),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}

class _LineItemRow extends StatelessWidget {
  const _LineItemRow(
      {required this.item, required this.currencyCode, required this.locale});
  final LineItem item;
  final String currencyCode;
  final String locale;

  /// Opens the product page for this line item by looking it up by id.
  Future<void> _openProduct(BuildContext context) async {
    final productId = item.productId;
    if (productId == null || productId.isEmpty) return;
    try {
      final countryId = PreferenceRepository.instance.country?.id;
      final result = await getIt<DataStore>().products.list(queryParams: {
        'id[]': [productId],
        'limit': 1,
        if (countryId != null) 'country_id': countryId,
      });
      final products = result?.products ?? [];
      if (products.isNotEmpty && context.mounted) {
        context.router.push(ProductDetailsRoute(product: products.first));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final clickable = (item.productId ?? '').isNotEmpty;
    return InkWell(
      onTap: clickable ? () => _openProduct(context) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: item.thumbnail != null
                  ? CachedNetworkImage(
                      cacheManager: DohCacheManager.instance,
                      imageUrl: item.thumbnail!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title ?? '',
                      style: context.bodySmallW500,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  Text('${context.l10n.qty}: ${item.quantity ?? 1}',
                      style: context.bodyExtraSmall
                          ?.copyWith(color: ColorConstant.manatee)),
                ],
              ),
            ),
            if (clickable) ...[
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: ColorConstant.manatee.withValues(alpha: 0.7)),
              const Gap(2),
            ],
            Text(item.total.formatAsPrice(currencyCode, locale: locale),
                style: context.bodySmallW500
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 56,
        height: 56,
        color: Colors.grey.shade200,
        child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
      );
}
