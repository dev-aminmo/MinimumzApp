import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';
import 'package:minimumz/presentation/components/index.dart';
import 'package:minimumz/presentation/screens/orders/bloc/orders/orders_bloc.dart';
import 'package:minimumz/data/data.dart';
import '../../routes/app_router.dart';

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

  // Cache-first: show page 1 from prefs instantly; flip to false once fresh
  // data arrives and has been seeded into the PagingController.
  List<Order>? _cachedPage1;
  bool _freshDataReceived = false;

  @override
  void initState() {
    super.initState();
    _bloc = getIt<OrdersBloc>();
    _cachedPage1 = PreferenceRepository.instance.cachedOrdersList?.cast<Order>();

    if (_cachedPage1 != null && _cachedPage1!.isNotEmpty) {
      // Cache exists — trigger a background refresh manually since the
      // PagingController's ListView won't build (and fire its listener) until
      // _freshDataReceived is true.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _bloc.add(OrdersEvent.loadOrders(queryParameters: {
          'offset': 0,
          'limit': _pageSize,
        }));
      });
    }

    _pagingController.addPageRequestListener((pageKey) {
      _bloc.add(OrdersEvent.loadOrders(queryParameters: {
        'offset': pageKey,
        'limit': _pageSize,
      }));
    });
  }

  void _onLoaded(List<Order> orders) {
    if (!_freshDataReceived && _loadedCount == 0) {
      // First page of fresh data: cache it and switch out of cache-display mode.
      PreferenceRepository.instance.setCachedOrdersList(orders);
      setState(() => _freshDataReceived = true);
    }
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
                error: (message) => _pagingController.error = message,
              );
            },
            builder: (context, state) {
              // Show cached page 1 instantly while fresh data loads in background.
              if (!_freshDataReceived &&
                  _cachedPage1 != null &&
                  _cachedPage1!.isNotEmpty) {
                return _CachedOrdersList(orders: _cachedPage1!);
              }

              return PagedListView<int, Order>(
                pagingController: _pagingController,
                builderDelegate: PagedChildBuilderDelegate<Order>(
                  itemBuilder: (context, order, index) =>
                      _OrderTile(order: order),
                  firstPageProgressIndicatorBuilder: (_) => const Center(
                      child: CircularProgressIndicator.adaptive()),
                  newPageProgressIndicatorBuilder: (_) => const Padding(
                    padding: EdgeInsets.all(16),
                    child:
                        Center(child: CircularProgressIndicator.adaptive()),
                  ),
                  noItemsFoundIndicatorBuilder: (ctx) =>
                      Center(child: Text(ctx.l10n.noOrdersYet)),
                  firstPageErrorIndicatorBuilder: (ctx) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _pagingController.error?.toString() ??
                              ctx.l10n.errorLoadingOrders,
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

// Renders the cached page-1 orders while fresh data loads in background.
// Shown only until _freshDataReceived flips — no spinner, instant display.
class _CachedOrdersList extends StatelessWidget {
  const _CachedOrdersList({required this.orders});
  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (_, i) => _OrderTile(order: orders[i]),
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
      onTap: () => context.router
          .push(OrderDetailsRoute(orderId: order.id ?? '', order: order)),
      title: Text('${context.l10n.order} #${order.displayId ?? order.id ?? ''}'),
      subtitle:
          Text('${context.l10n.placedOn} ${order.createdAt?.formatDate() ?? ''}'),
      trailing: OrderStatusChip(order.status.value),
    );
  }
}
