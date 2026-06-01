import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:minimumz/common/doh_cache_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gap/gap.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/cubits/locale/locale_cubit.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';

import '../../../../common/colors.dart';
import '../../../../domain/repository/preference_repository.dart';
import '../../../components/minimumz_icons.dart';
import '../../../routes/app_router.dart';
import '../bloc/cart/cart_bloc.dart';
import '../bloc/line_item/line_item_bloc.dart';

class LineItemCard extends StatefulWidget {
  const LineItemCard({super.key, required this.lineItem, required this.cartId});
  final LineItem lineItem;
  final String cartId;

  @override
  State<LineItemCard> createState() => _LineItemCardState();
}

class _LineItemCardState extends State<LineItemCard> {
  late int _qty;
  bool _hidden = false;

  @override
  void initState() {
    super.initState();
    _qty = widget.lineItem.quantity ?? 1;
  }

  @override
  void didUpdateWidget(LineItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Accept server quantity once cart refreshes (only when not mid-operation)
    if (widget.lineItem.quantity != null &&
        widget.lineItem.quantity != oldWidget.lineItem.quantity) {
      setState(() => _qty = widget.lineItem.quantity!);
    }
  }

  void _optimisticUpdate(int newQty) {
    final cartBloc = context.read<CartBloc>();
    final currentState = cartBloc.state;

    currentState.whenOrNull(loaded: (cart) {
      if (cart.items == null) return;

      final updatedItems = cart.items!.map((item) {
        if (item.id == widget.lineItem.id) {
          final int newTotal = (item.unitPrice ?? 0) * newQty;
          return item.copyWith(
            quantity: newQty,
            total: newTotal,
            subtotal: newTotal,
          );
        }
        return item;
      }).toList();

      final updatedCart = cart.copyWith(items: updatedItems).recalculate();
      cartBloc.add(CartEvent.refreshCart(updatedCart));
    });
  }

  void _decrement(BuildContext context) {
    if (_qty <= 1) {
      setState(() => _hidden = true);
      context
          .read<LineItemBloc>()
          .add(LineItemEvent.delete(widget.cartId, widget.lineItem.id!));
    } else {
      setState(() => --_qty);
      _optimisticUpdate(_qty);
      context.read<LineItemBloc>().add(
          LineItemEvent.update(widget.cartId, widget.lineItem.id!, _qty));
    }
  }

  void _increment(BuildContext context) {
    setState(() => ++_qty);
    _optimisticUpdate(_qty);
    context.read<LineItemBloc>().add(
        LineItemEvent.update(widget.cartId, widget.lineItem.id!, _qty));
  }

  void _delete(BuildContext context) {
    setState(() => _hidden = true);

    final cartBloc = context.read<CartBloc>();
    final currentState = cartBloc.state;
    currentState.whenOrNull(loaded: (cart) {
      if (cart.items == null) return;
      final updatedItems = cart.items!.where((item) => item.id != widget.lineItem.id).toList();
      final updatedCart = cart.copyWith(items: updatedItems).recalculate();
      cartBloc.add(CartEvent.refreshCart(updatedCart));
    });

    context
        .read<LineItemBloc>()
        .add(LineItemEvent.delete(widget.cartId, widget.lineItem.id!));
  }

  void _revert() {
    setState(() {
      _qty = widget.lineItem.quantity ?? 1;
      _hidden = false;
    });
  }

  Future<void> _navigateToProduct(BuildContext context) async {
    final productId = widget.lineItem.productId;
    if (productId == null) return;
    try {
      final countryId = PreferenceRepository.instance.country?.id;
      final result = await getIt<DataStore>().products.list(queryParams: {
        'id[]': [productId],
        'limit': 1,
        if (countryId != null) 'country_id': countryId,
      });
      final products = result?.products ?? [];
      final product = products.isNotEmpty ? products.first : null;
      if (product != null && context.mounted) {
        context.router.push(ProductDetailsRoute(product: product));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final variant = widget.lineItem.variant;
    final invQuantity = variant?.inventoryQuantity;
    final manageInventory = variant?.manageInventory ?? true;
    final allowBackorder = variant?.allowBackorder ?? false;

    final canAdd = !manageInventory || allowBackorder || invQuantity == null || invQuantity > _qty;
    final currencyCode = PreferenceRepository.currencyCode;

    return BlocListener<LineItemBloc, LineItemState>(
      // Keep listening even when hidden so failures can revert the delete.
      listenWhen: (_, s) => s.maybeWhen(
        success: (_) => true,
        failure: (_, lineItemId) => lineItemId == widget.lineItem.id,
        orElse: () => false,
      ),
      listener: (context, state) {
        state.whenOrNull(
          success: (cart) =>
              context.read<CartBloc>().add(CartEvent.refreshCart(cart)),
          failure: (message, lineItemId) {
            if (lineItemId == widget.lineItem.id) {
              _revert();
              if (message.isNotEmpty) Fluttertoast.showToast(msg: message);
            }
          },
        );
      },
      child: _hidden ? const SizedBox.shrink() : GestureDetector(
        onTap: () => _navigateToProduct(context),
        child: Container(
        height: 160,
        padding: const EdgeInsets.all(6.0),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: const BorderRadius.all(Radius.circular(10.0)),
        ),
        child: Row(
          children: [
            if (widget.lineItem.thumbnail != null)
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                    color: context.theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.all(Radius.circular(10.0)),
                    image: DecorationImage(
                        image: CachedNetworkImageProvider(
                            widget.lineItem.thumbnail!,
                            cacheManager: DohCacheManager.instance),
                        fit: BoxFit.fitWidth)),
              ),
            const Gap(10),
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.lineItem.title ?? '',
                        style: context.bodySmallW500,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const Gap(5),
                      Text(
                        widget.lineItem.variant?.title ?? '',
                        style: context.bodySmallW500,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const Gap(5),
                      _PriceRow(
                        lineItem: widget.lineItem,
                        qty: _qty,
                        currencyCode: currencyCode,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _CircleButton(
                            onTap: () => _decrement(context),
                            child: const Icon(Icons.arrow_drop_down),
                          ),
                          const Gap(15),
                          Text(_qty.toString(), style: context.bodySmallW500),
                          const Gap(15),
                          _CircleButton(
                            onTap: canAdd ? () => _increment(context) : null,
                            child: Icon(Icons.arrow_drop_up,
                                color: canAdd ? null : ColorConstant.manatee),
                          ),
                        ],
                      ),
                      _CircleButton(
                        onTap: () => _delete(context),
                        child: const Icon(minimumzIcons.delete, size: 14.0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.lineItem,
    required this.qty,
    required this.currencyCode,
  });
  final LineItem lineItem;
  final int qty;
  final String? currencyCode;

  @override
  Widget build(BuildContext context) {
    final unitPrice = lineItem.unitPrice ?? 0;
    final originalTotal = lineItem.originalTotal;
    final quantity = lineItem.quantity ?? 1;
    final locale = context.read<LocaleCubit>().state.languageCode;

    final hasDiscount = originalTotal != null &&
        originalTotal > (lineItem.total ?? 0) &&
        quantity > 0;

    final currentPrice = (unitPrice * qty).formatAsPrice(currencyCode, locale: locale);

    if (!hasDiscount) {
      return Text(
        currentPrice,
        style: context.bodySmallW500?.copyWith(color: ColorConstant.manatee),
        overflow: TextOverflow.ellipsis,
      );
    }

    final originalUnitPrice = (originalTotal / quantity).round();
    final originalPrice = (originalUnitPrice * qty).formatAsPrice(currencyCode, locale: locale);

    return Row(
      children: [
        Text(
          originalPrice,
          style: context.bodySmallW500?.copyWith(
            color: ColorConstant.manatee,
            decoration: TextDecoration.lineThrough,
          ),
        ),
        const Gap(6),
        Text(
          currentPrice,
          style: context.bodySmallW500?.copyWith(color: Colors.green),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(50)),
        onTap: onTap,
        child: Ink(
          width: 30,
          height: 30,
          decoration: ShapeDecoration(
            color: context.theme.scaffoldBackgroundColor,
            shape: const CircleBorder(),
          ),
          child: child,
        ),
      ),
    );
  }
}
