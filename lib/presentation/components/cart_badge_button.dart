import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/presentation/screens/cart/bloc/cart/cart_bloc.dart';
import '../routes/app_router.dart';
import 'minimumz_icons.dart';

/// Circle icon button with a live cart-item count badge.
/// Tapping it pushes [CartRoute].
class CartBadgeButton extends StatelessWidget {
  const CartBadgeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (context, state) {
        final itemCount = state.whenOrNull(
              loaded: (cart) =>
                  cart.items?.fold<int>(0, (sum, i) => sum + (i.quantity ?? 1)) ?? 0,
            ) ??
            0;

        return InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(50)),
          onTap: () => context.router.push(const CartRoute()),
          child: Ink(
            width: 45,
            height: 45,
            decoration: ShapeDecoration(
              color: context.theme.cardColor,
              shape: const CircleBorder(),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(child: Icon(minimumzIcons.bag, color: context.theme.iconTheme.color)),
                if (itemCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: ColorConstant.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          itemCount > 99 ? '99+' : '$itemCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
