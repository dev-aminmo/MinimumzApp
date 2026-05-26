import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';
import 'package:minimumz/presentation/components/index.dart';
import 'package:minimumz/presentation/routes/app_router.dart';
import 'package:minimumz/presentation/screens/cart/bloc/cart/cart_bloc.dart';
import 'package:minimumz/presentation/screens/cart/bloc/line_item/line_item_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:minimumz/data/data.dart';

class ProductDetailsBottomNavButton extends StatefulWidget {
  const ProductDetailsBottomNavButton(
      {super.key,
      required this.selectedVariant,
      required this.product,
      required this.optionsSelected});
  final ProductVariant? selectedVariant;
  final Product product;
  final Map<String, String> optionsSelected;

  @override
  State<ProductDetailsBottomNavButton> createState() =>
      _ProductDetailsBottomNavButtonState();
}

class _ProductDetailsBottomNavButtonState
    extends State<ProductDetailsBottomNavButton> {
  // Optimistic state for "add to cart": true while API is in-flight so the
  // button immediately switches to the "in cart" view without any spinner.
  bool _optimisticInCart = false;

  void _optimisticUpdate(int newQty) {
    final cartBloc = context.read<CartBloc>();
    final currentState = cartBloc.state;

    currentState.whenOrNull(loaded: (cart) {
      final items = cart.items ?? <LineItem>[];
      final exists = items.any((e) => e.variantId == widget.selectedVariant?.id);

      List<LineItem> updatedItems;
      if (exists) {
        updatedItems = items.map((item) {
          if (item.variantId == widget.selectedVariant?.id) {
            final int newTotal = (item.unitPrice ?? 0) * newQty;
            return item.copyWith(
              quantity: newQty,
              total: newTotal,
              subtotal: newTotal,
            );
          }
          return item;
        }).toList();
      } else {
        // Optimistic add: create a temporary line item
        final int unitPrice = (widget.selectedVariant?.prices?.firstOrNull?.amount ?? 0).toInt();
        final int total = unitPrice * newQty;
        final tempItem = LineItem(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          variantId: widget.selectedVariant?.id,
          title: widget.product.title,
          unitPrice: unitPrice,
          quantity: newQty,
          total: total,
          subtotal: total,
          thumbnail: widget.product.thumbnail,
        );
        updatedItems = [...items, tempItem];
      }

      final updatedCart = cart.copyWith(items: updatedItems).recalculate();
      cartBloc.add(CartEvent.refreshCart(updatedCart));
    });
  }

  @override
  Widget build(BuildContext context) {
    final String currencyCode = PreferenceRepository.currencyCode;

    return BlocListener<LineItemBloc, LineItemState>(
      listener: (context, lineState) {
        lineState.whenOrNull(
          success: (cart) {
            setState(() => _optimisticInCart = false);
            context.read<CartBloc>().add(CartEvent.refreshCart(cart));
          },
          failure: (message, lineItemId) {
            if (lineItemId == widget.selectedVariant?.id) {
              // Revert optimistic add
              setState(() => _optimisticInCart = false);
              if (message.isNotEmpty) Fluttertoast.showToast(msg: message);
            }
          },
        );
      },
      child: BlocBuilder<CartBloc, CartState>(
        builder: (context, cartState) {
          return cartState.maybeMap(
            loaded: (loaded) {
              final inCart = loaded.cart.items
                      ?.map((e) => e.variantId)
                      .contains(widget.selectedVariant?.id) ??
                  false;

              if (inCart || _optimisticInCart) {
                final lineItem = loaded.cart.items?.firstWhere(
                  (e) => e.variantId == widget.selectedVariant?.id,
                  orElse: () => LineItem(title: '', unitPrice: 0, quantity: 1),
                );
                final isUpdating = context
                    .watch<LineItemBloc>()
                    .state
                    .maybeWhen(
                      loading: (id) => id == lineItem?.id,
                      orElse: () => false,
                    );

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 0),
                    Container(
                      color: context.theme.scaffoldBackgroundColor,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(context.l10n.totalPrice,
                                  style: context.bodyMediumW600),
                              Text(context.l10n.withVatSd,
                                  style: context.bodyExtraSmall?.copyWith(
                                      color: ColorConstant.manatee)),
                            ],
                          ),
                          Text(
                              (lineItem!.total ?? 0)
                                      .formatAsPrice(currencyCode) ??
                                  '',
                              style: context.bodyLargeW600),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Container(
                            color: ColorConstant.primary,
                            height: 50,
                            child: _QuantityControls(
                              quantity: lineItem.quantity ?? 1,
                              isUpdating: isUpdating,
                              onDecrement: () {
                                final int newQty = (lineItem.quantity ?? 1) - 1;
                                if (newQty < 1) {
                                  // For simplicity, we don't delete optimistically from this button
                                  // but we could. For now just prevent it.
                                  return;
                                }
                                _optimisticUpdate(newQty);
                                context.read<LineItemBloc>().add(
                                    LineItemEvent.update(
                                        loaded.cart.id!,
                                        lineItem.id!,
                                        newQty));
                              },
                              onIncrement: () {
                                final int newQty = (lineItem.quantity ?? 1) + 1;
                                _optimisticUpdate(newQty);
                                context.read<LineItemBloc>().add(
                                    LineItemEvent.update(
                                        loaded.cart.id!,
                                        lineItem.id!,
                                        newQty));
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () => context.router.push(const CartRoute()),
                            child: Container(
                              height: 50,
                              color: ColorConstant.brownDark,
                              child: Center(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      context.l10n.checkout,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: Colors.white,
                                        size: 13),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: context.bottomViewPadding,
                      color: ColorConstant.brownDark,
                    ),
                  ],
                );
              }

              // Not in cart
              return BottomNavButton(
                label: context.l10n.addToCart,
                onTap: (widget.optionsSelected.length <
                                (widget.product.options?.length ?? 0) ||
                            widget.selectedVariant == null)
                    ? null
                    : () {
                        setState(() => _optimisticInCart = true);
                        _optimisticUpdate(1);
                        context.read<LineItemBloc>().add(LineItemEvent.add(
                            loaded.cart.id!,
                            widget.selectedVariant!.id!,
                            1));
                      },
              );
            },
            loading: (_) => BottomNavButton(
              label: context.l10n.addToCart,
              onTap: null,
            ),
            orElse: () => BottomNavButton(
              label: context.l10n.addToCart,
              onTap: () =>
                  context.read<CartBloc>().add(const CartEvent.loadCart()),
            ),
          );
        },
      ),
    );
  }
}

// +/- row shown inside the "in cart" section
class _QuantityControls extends StatelessWidget {
  const _QuantityControls({
    required this.quantity,
    required this.isUpdating,
    required this.onDecrement,
    required this.onIncrement,
  });
  final int quantity;
  final bool isUpdating;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: [
        Expanded(
          flex: 2,
          child: Material(
            child: InkWell(
              onTap: isUpdating ? null : onDecrement,
              child: Ink(
                height: 50,
                color: ColorConstant.primary,
                child: Center(
                    child: Icon(Icons.remove,
                        color: isUpdating ? Colors.white38 : Colors.white)),
              ),
            ),
          ),
        ),
        Expanded(
          child: Center(
            child: Text(quantity.toString(),
                    style: const TextStyle(color: Colors.white)),
          ),
        ),
        Expanded(
          flex: 2,
          child: Material(
            child: InkWell(
              onTap: isUpdating ? null : onIncrement,
              child: Ink(
                height: 50,
                color: ColorConstant.primary,
                child: Center(
                    child: Icon(Icons.add,
                        color: isUpdating ? Colors.white38 : Colors.white)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
