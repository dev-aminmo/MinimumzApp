import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:minimumz/common/doh_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/cubits/locale/locale_cubit.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';
import 'package:minimumz/presentation/components/index.dart';
import 'package:minimumz/presentation/screens/orders/bloc/orders/orders_bloc.dart';
import 'package:minimumz/data/data.dart';

@RoutePage()
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  static const _pageSize = 20;

  final PagingController<int, Order> _pagingController =
      PagingController(firstPageKey: 0);
  late final OrdersBloc _bloc;
  int _loadedCount = 0;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<OrdersBloc>();
    _pagingController.addPageRequestListener((pageKey) {
      _bloc.add(OrdersEvent.loadOrders(queryParameters: {
        'offset': pageKey,
        'limit': _pageSize,
      }));
    });
  }

  void _onLoaded(List<Order> orders) {
    _loadedCount += orders.length;
    final isLastPage = orders.length < _pageSize;
    if (isLastPage) {
      _pagingController.appendLastPage(orders);
    } else {
      _pagingController.appendPage(orders, _loadedCount);
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
        appBar: CustomAppBar(title: context.l10n.orders),
        body: SafeArea(
          child: BlocConsumer<OrdersBloc, OrdersState>(
            listener: (context, state) {
              state.whenOrNull(
                loaded: _onLoaded,
                error: (message) =>
                    _pagingController.error = message,
              );
            },
            builder: (context, state) {
              return PagedListView<int, Order>(
                pagingController: _pagingController,
                builderDelegate: PagedChildBuilderDelegate<Order>(
                  itemBuilder: (context, order, index) => _OrderTile(order: order),
                  firstPageProgressIndicatorBuilder: (_) =>
                      const Center(child: CircularProgressIndicator.adaptive()),
                  newPageProgressIndicatorBuilder: (_) => const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator.adaptive()),
                  ),
                  noItemsFoundIndicatorBuilder: (ctx) => Center(
                    child: Text(ctx.l10n.noOrdersYet),
                  ),
                  firstPageErrorIndicatorBuilder: (ctx) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _pagingController.error?.toString() ?? ctx.l10n.errorLoadingOrders,
                        ),
                        const Gap(12),
                        ElevatedButton(
                          onPressed: _pagingController.refresh,
                          child: Text(ctx.l10n.retry),
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

// ── Order list tile ──────────────────────────────────────────────────────────

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});
  final Order order;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.theme.scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => _OrderDetailSheet(order: order),
      ),
      title: Text('${context.l10n.order} #${order.displayId ?? order.id ?? ''}'),
      subtitle: Text('${context.l10n.placedOn} ${order.createdAt?.formatDate() ?? ''}'),
      trailing: _StatusChip(order.status.name),
    );
  }
}

// ── Status chip ──────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.label);
  final String label;

  Color _color() {
    switch (label.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'canceled':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label[0].toUpperCase() + label.substring(1),
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Order detail sheet ───────────────────────────────────────────────────────

class _OrderDetailSheet extends StatelessWidget {
  const _OrderDetailSheet({required this.order});
  final Order order;

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('d MMM yyyy, HH:mm').format(dt.toLocal());
  }

  String _formatPrice(num? amount, String? code, String locale) =>
      amount.formatAsPrice(code, locale: locale);

  @override
  Widget build(BuildContext context) {
    final currencyCode = order.currencyCode?.toUpperCase() ??
        PreferenceRepository.currencyCode;
    final locale = context.read<LocaleCubit>().state.languageCode;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom == 0
        ? 24.0
        : MediaQuery.of(context).viewPadding.bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => ListView(
        controller: scrollCtrl,
        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${context.l10n.order} #${order.displayId ?? order.id ?? ''}',
                  style: context.bodyLargeW600),
              _StatusChip(order.status.name),
            ],
          ),
          const Gap(4),
          Text(_formatDate(order.createdAt),
              style: context.bodySmall?.copyWith(color: ColorConstant.manatee)),
          const Gap(16),
          const Divider(height: 0),
          const Gap(16),
          if (order.items?.isNotEmpty ?? false) ...[
            Text(context.l10n.items, style: context.bodyMediumW500),
            const Gap(10),
            ...order.items!
                .map((item) => _LineItemRow(item: item, currencyCode: currencyCode, locale: locale)),
            const Gap(16),
            const Divider(height: 0),
            const Gap(16),
          ],
          _totalRow(context.l10n.subtotal, _formatPrice(order.subTotal, currencyCode, locale), context),
          if ((order.shippingTotal ?? 0) > 0)
            _totalRow(context.l10n.shipping, _formatPrice(order.shippingTotal, currencyCode, locale), context),
          if ((order.taxTotal ?? 0) > 0)
            _totalRow(context.l10n.tax, _formatPrice(order.taxTotal, currencyCode, locale), context),
          if ((order.discountTotal ?? 0) > 0)
            _totalRow(context.l10n.discount, '− ${_formatPrice(order.discountTotal, currencyCode, locale)}', context),
          const Divider(height: 16),
          _totalRow(context.l10n.total, _formatPrice(order.total, currencyCode, locale), context, bold: true),
          const Gap(16),
          Row(children: [
            Text('${context.l10n.fulfillment}: ', style: context.bodySmall),
            _StatusChip(order.fulfillmentStatus.name),
          ]),
          const Gap(6),
          Row(children: [
            Text('${context.l10n.payment}: ', style: context.bodySmall),
            _StatusChip(order.paymentStatus.name),
          ]),
        ],
      ),
    );
  }

  Widget _totalRow(String label, String value, BuildContext context,
      {bool bold = false}) {
    final style = bold ? context.bodyMediumW500 : context.bodySmall;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

// ── Line item row ────────────────────────────────────────────────────────────

class _LineItemRow extends StatelessWidget {
  const _LineItemRow({required this.item, required this.currencyCode, required this.locale});
  final LineItem item;
  final String currencyCode;
  final String locale;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (item.thumbnail != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
          cacheManager: DohCacheManager.instance,
                imageUrl: item.thumbnail!,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported_outlined,
                      color: Colors.grey),
                ),
              ),
            )
          else
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.image_not_supported_outlined,
                  color: Colors.grey),
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
                if (item.variant?.title != null)
                  Text(item.variant!.title!,
                      style: context.bodyExtraSmall
                          ?.copyWith(color: ColorConstant.manatee)),
                Text('${context.l10n.qty}: ${item.quantity ?? 1}',
                    style: context.bodyExtraSmall
                        ?.copyWith(color: ColorConstant.manatee)),
              ],
            ),
          ),
          Text(
            item.total.formatAsPrice(currencyCode, locale: locale),
            style: context.bodySmallW500,
          ),
        ],
      ),
    );
  }
}
