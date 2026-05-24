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
  @override
  Widget build(BuildContext context) {
    final String currencyCode = PreferenceRepository.currencyCode;
    return BlocConsumer<LineItemBloc, LineItemState>(
      listener: (context, lineState) {
        lineState.whenOrNull(
          success: (_) =>
              context.read<CartBloc>().add(CartEvent.refreshCart(_)),
          failure: (message) => Fluttertoast.showToast(msg: message),
        );
      },
      builder: (context, lineState) {
        return BlocBuilder<CartBloc, CartState>(
          builder: (context, cartState) {
            return cartState.maybeMap(
                loaded: (loaded) {
                  final inCart = loaded.cart.items
                          ?.map((e) => e.variantId)
                          .toList()
                          .contains(widget.selectedVariant?.id) ??
                      false;
                  final lineItem = loaded.cart.items
                      ?.where((element) =>
                          element.variantId == widget.selectedVariant?.id)
                      .firstOrNull;
                  final Widget addRemoveItemWidget = Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Material(
                          child: InkWell(
                            onTap: () {
                              context.read<LineItemBloc>().add(
                                  LineItemEvent.update(
                                      loaded.cart.id!,
                                      lineItem!.id!,
                                      lineItem.quantity! - 1));
                            },
                            child: Ink(
                              height: 50,
                              color: ColorConstant.primary,
                              child: const Center(
                                  child: Icon(Icons.remove, color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                          child: Center(
                              child: Text(lineItem?.quantity
                                  ?.toString() ??
                                  '', style: const TextStyle(color: Colors.white),))),
                      Expanded(
                        flex: 2,
                        child: Material(
                          child: InkWell(
                            onTap: () {
                              context.read<LineItemBloc>().add(
                                  LineItemEvent.update(
                                      loaded.cart.id!,
                                      lineItem!.id!,
                                      lineItem.quantity! + 1));
                            },
                            child: Ink(
                              height: 50,
                              color: ColorConstant.primary,
                              child: const Center(
                                  child: Icon(Icons.add, color: Colors.white)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                  final Widget addRemoveItemLoadingWidget = Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        flex: 2,
                        child: Material(
                          child: InkWell(
                            onTap:null,
                            child: Ink(
                              height: 50,
                              color: ColorConstant.primary,
                              child: const Center(
                                  child: Icon(Icons.remove, color: Colors.white70)),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                          child: Center(
                              child: LoadingAnimationWidget
                                  .threeArchedCircle(
                                  color: Colors.white, size: 24))),
                      Expanded(
                        flex: 2,
                        child: Material(
                          child: InkWell(
                            onTap:null,
                            child: Ink(
                              height: 50,
                              color: ColorConstant.primary,
                              child: const Center(
                                  child: Icon(Icons.add, color: Colors.white70)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );

                  if (inCart) {
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
                                  lineItem?.total.formatAsPrice(currencyCode) ??
                                      '',
                                  style: context.bodyLargeW600)
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
                                child: BlocBuilder<LineItemBloc, LineItemState>(
                                  builder: (context, state) {
                                    return state.map(
                                      initial: (_) => addRemoveItemWidget,
                                      success: (cart) => addRemoveItemWidget,
                                      loading: (_) => addRemoveItemLoadingWidget,
                                      failure: (error) {
                                        return Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(context.l10n.errorAddingItem),
                                            TextButton(
                                                onPressed: widget.selectedVariant == null ? null : () {
                                                  context.read<LineItemBloc>().add(
                                                      LineItemEvent.add(
                                                          loaded.cart.id!,
                                                          widget.selectedVariant!.id!,
                                                          1));
                                                },
                                                child: Text(context.l10n.retry)),
                                          ],
                                        );
                                      },
                                    );
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
                                        const Icon(Icons.arrow_forward_ios_rounded,
                                            color: Colors.white, size: 13),
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
                        )
                      ],
                    );
                  } else if(!inCart && lineState == LineItemState.loading(lineItemId: widget.selectedVariant?.id)){
                    return Container(
                      color: ColorConstant.primary,
                      height: 50,
                      child: Center(
                          child: LoadingAnimationWidget.threeArchedCircle(
                              color: Colors.white, size: 24)),
                    );
                  }
                  return BottomNavButton(
                      label: context.l10n.addToCart,
                      onTap: (widget.optionsSelected.length <
                                      (widget.product.options?.length ?? 0) ||
                                  widget.selectedVariant == null)
                          ? null
                          : () {
                              context.read<LineItemBloc>().add(
                                  LineItemEvent.add(
                                      loaded.cart.id!,
                                      widget.selectedVariant!.id!,
                                      1));
                            });
                },
                loading: (_) => Container(
                      color: ColorConstant.primary,
                      height: 50,
                      child: Center(
                          child: LoadingAnimationWidget.threeArchedCircle(
                              color: Colors.white, size: 24)),
                    ),
                orElse: () => BottomNavButton(
                      label: context.l10n.addToCart,
                      onTap: () =>
                          context.read<CartBloc>().add(const CartEvent.loadCart()),
                    ));
          },
        );
      },
    );
  }
}
