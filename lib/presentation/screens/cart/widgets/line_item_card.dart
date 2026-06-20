import 'dart:async';

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
  Timer? _qtyDebounce;

  @override
  void initState() {
    super.initState();
    _qty = widget.lineItem.quantity ?? 1;
  }

  @override
  void didUpdateWidget(LineItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Accept server quantity once cart refreshes (only when not mid-operation).
    // Skip if there's a pending debounced update — the user is still tapping.
    if (_qtyDebounce == null &&
        widget.lineItem.quantity != null &&
        widget.lineItem.quantity != oldWidget.lineItem.quantity) {
      setState(() => _qty = widget.lineItem.quantity!);
    }
  }

  @override
  void dispose() {
    _qtyDebounce?.cancel();
    super.dispose();
  }

  void _scheduleUpdate(BuildContext context) {
    _qtyDebounce?.cancel();
    _qtyDebounce = Timer(const Duration(milliseconds: 600), () {
      _qtyDebounce = null;
      context.read<LineItemBloc>().add(
          LineItemEvent.update(widget.cartId, widget.lineItem.id!, _qty));
    });
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
      _qtyDebounce?.cancel();
      _qtyDebounce = null;
      setState(() => _hidden = true);
      context
          .read<LineItemBloc>()
          .add(LineItemEvent.delete(widget.cartId, widget.lineItem.id!));
    } else {
      setState(() => --_qty);
      _optimisticUpdate(_qty);
      _scheduleUpdate(context);
    }
  }

  void _increment(BuildContext context) {
    setState(() => ++_qty);
    _optimisticUpdate(_qty);
    _scheduleUpdate(context);
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

  /// The variation label to show under the title. The API returns it in the
  /// line item's `description` (e.g. "Small / Red"); simple products send the
  /// placeholder "Default", which we hide.
  String? get _variation {
    final v = (widget.lineItem.description ?? widget.lineItem.variant?.title)
        ?.trim();
    if (v == null || v.isEmpty || v == 'Default') return null;
    return v;
  }

  /// Color swatches for the variant's color-type options, parsed from the
  /// line item's `colors` hex list.
  List<Color> get _swatches => (widget.lineItem.colors ?? const [])
      .map(hexToColor)
      .whereType<Color>()
      .toList();

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
                      if (_variation != null) ...[
                        const Gap(6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.theme.scaffoldBackgroundColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ..._swatches.map((c) => Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                        end: 5),
                                    child: Container(
                                      width: 13,
                                      height: 13,
                                      decoration: BoxDecoration(
                                        color: c,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: ColorConstant.manatee
                                              .withValues(alpha: 0.35),
                                          width: 1,
                                        ),
                                      ),
                                    ),
                                  )),
                              ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 150),
                                child: Text(
                                  _variation!,
                                  style: context.bodyExtraSmallW500?.copyWith(
                                      color: ColorConstant.brownDark),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Gap(8),
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
                      // ── Quantity stepper ──────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: context.theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: ColorConstant.beige),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _StepButton(
                              icon: Icons.remove_rounded,
                              onTap: () => _decrement(context),
                            ),
                            ConstrainedBox(
                              constraints: const BoxConstraints(minWidth: 26),
                              child: Center(
                                child: Text(
                                  _qty.toString(),
                                  style: context.bodySmallW500
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            _StepButton(
                              icon: Icons.add_rounded,
                              emphasized: true,
                              onTap:
                                  canAdd ? () => _increment(context) : null,
                            ),
                          ],
                        ),
                      ),
                      // ── Delete ────────────────────────────────────
                      _RoundIconButton(
                        icon: minimumzIcons.delete,
                        onTap: () => _delete(context),
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
        style: context.bodySmallW500?.copyWith(
          color: ColorConstant.brownDark,
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
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
          style: context.bodySmallW500?.copyWith(
            color: Colors.green,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

/// A +/- control used inside the quantity stepper pill. The "+" is
/// [emphasized] with the primary color; a null [onTap] renders it muted.
class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, this.onTap, this.emphasized = false});
  final IconData icon;
  final VoidCallback? onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = !enabled
        ? ColorConstant.manatee.withValues(alpha: 0.35)
        : emphasized
            ? ColorConstant.primary
            : ColorConstant.brownDark;
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}

/// A standalone circular icon action. Defaults to a light red "delete" look.
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 15, color: Colors.red.shade400),
        ),
      ),
    );
  }
}
