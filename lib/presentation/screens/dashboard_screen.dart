import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/presentation/components/index.dart';
import 'package:minimumz/presentation/screens/cart/bloc/cart/cart_bloc.dart';
import 'package:minimumz/presentation/screens/cart/bloc/line_item/line_item_bloc.dart';
import '../routes/app_router.dart';

var dashboardScaffoldKey = GlobalKey<ScaffoldState>();

@RoutePage()
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool pop = false;

  @override
  Widget build(BuildContext context) {
    final bottomBarBgColor =
        context.theme.bottomNavigationBarTheme.backgroundColor ??
            context.theme.scaffoldBackgroundColor;
    final systemOverlay = context.theme.appBarTheme.systemOverlayStyle;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: systemOverlay!.copyWith(
        systemNavigationBarColor: bottomBarBgColor,
        systemNavigationBarContrastEnforced: false,
      ),
      child: WillPopScope(
        onWillPop: () async {
          if (Platform.isIOS) return true;
          if (pop) return true;
          Fluttertoast.showToast(msg: context.l10n.pressAgainToExit);
          pop = true;
          Timer(const Duration(seconds: 2), () => pop = false);
          return false;
        },
        child: AutoTabsRouter(
          routes: const [
            HomeRoute(),
            CategoriesRoute(),
            WishlistRoute(),
            CartRoute(),
          ],
          builder: (context, child) {
            final tabsRouter = AutoTabsRouter.of(context);
            final activeIndex = tabsRouter.activeIndex;

            return BlocListener<LineItemBloc, LineItemState>(
              listenWhen: (_, s) => s.maybeWhen(
                success: (_) => true,
                failure: (_, __) => true,
                orElse: () => false,
              ),
              listener: (context, state) {
                state.whenOrNull(
                  // Real cart from server replaces any optimistic state.
                  success: (cart) =>
                      context.read<CartBloc>().add(CartEvent.refreshCart(cart)),
                  // On failure, reload real cart to revert optimistic badge update.
                  failure: (_, __) =>
                      context.read<CartBloc>().add(const CartEvent.loadCart()),
                );
              },
              child: BlocListener<CartBloc, CartState>(
              listenWhen: (previous, current) {
                final prev =
                    previous.whenOrNull(loaded: (cart) => cart.removedItems);
                final curr =
                    current.whenOrNull(loaded: (cart) => cart.removedItems);
                return curr != null && curr.isNotEmpty && curr != prev;
              },
              listener: (context, state) {
                final removed =
                    state.whenOrNull(loaded: (cart) => cart.removedItems) ?? [];
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        '${removed.length} ${context.l10n.itemsRemovedUnavailable}'),
                    duration: const Duration(seconds: 4),
                  ),
                );
              },
              child: Scaffold(
              key: dashboardScaffoldKey,
              drawer: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: const DrawerWidget(),
              ),
              drawerEdgeDragWidth: MediaQuery.of(context).size.width / 4,
              body: child,
              bottomNavigationBar: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        color: bottomBarBgColor,
                        child: NavigationBar(
                          backgroundColor: bottomBarBgColor,
                          surfaceTintColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          selectedIndex: activeIndex,
                          onDestinationSelected: tabsRouter.setActiveIndex,
                          indicatorColor:
                              ColorConstant.primary.withValues(alpha: 0.12),
                          labelBehavior:
                              NavigationDestinationLabelBehavior.alwaysShow,
                          destinations: [
                            NavigationDestination(
                              icon: Icon(minimumzIcons.home,
                                  color: const Color(0xff8F959E)),
                              selectedIcon: Icon(minimumzIcons.home,
                                  color: ColorConstant.primary),
                              label: context.l10n.home,
                            ),
                            NavigationDestination(
                              icon: const Icon(Icons.category_outlined,
                                  color: Color(0xff8F959E)),
                              selectedIcon: Icon(Icons.category_rounded,
                                  color: ColorConstant.primary),
                              label: context.l10n.categories,
                            ),
                            NavigationDestination(
                              icon: Icon(minimumzIcons.heart,
                                  color: const Color(0xff8F959E)),
                              selectedIcon: Icon(minimumzIcons.heart,
                                  color: ColorConstant.primary),
                              label: context.l10n.wishlist,
                            ),
                            NavigationDestination(
                              icon: Icon(minimumzIcons.bag,
                                  color: const Color(0xff8F959E)),
                              selectedIcon: Icon(minimumzIcons.bag,
                                  color: ColorConstant.primary),
                              label: context.l10n.cart,
                            ),
                          ],
                        ),
                      ),
                      // Cart badge
                      BlocBuilder<CartBloc, CartState>(
                        builder: (context, state) {
                          final count = state.whenOrNull(
                                loaded: (cart) => cart.items?.fold<int>(
                                        0, (s, i) => s + (i.quantity ?? 1)) ??
                                    0,
                              ) ??
                              0;
                          if (count == 0) return const SizedBox.shrink();
                          final isRTL = context.isRTL;
                          // Cart is the 4th destination (index 3)
                          final itemWidth =
                              MediaQuery.of(context).size.width / 4;
                          final badge = Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: ColorConstant.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                count > 99 ? '99+' : '$count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                          return isRTL
                              ? Positioned(
                                  top: 8,
                                  left: itemWidth / 2 - 4,
                                  child: badge,
                                )
                              : Positioned(
                                  top: 8,
                                  right: itemWidth / 2 - 4,
                                  child: badge,
                                );
                        },
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        EdgeInsets.only(bottom: context.bottomViewPadding),
                    color: bottomBarBgColor,
                  ),
                ],
              ),
            ),
            ),
            );
          },
        ),
      ),
    );
  }
}

