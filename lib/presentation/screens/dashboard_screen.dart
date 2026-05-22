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
import '../routes/app_router.dart';
import 'package:sliding_clipped_nav_bar/sliding_clipped_nav_bar.dart';

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
        context.theme.bottomNavigationBarTheme.backgroundColor;
    final systemOverlay = context.theme.appBarTheme.systemOverlayStyle;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          systemOverlay!.copyWith(systemNavigationBarColor: bottomBarBgColor),
      child: WillPopScope(
        onWillPop: () async {
          if (Platform.isIOS) {
            return true;
          }
          if (pop) {
            return true;
          }
          Fluttertoast.showToast(msg: 'Press again to exist the app');
          pop = true;
          Timer(const Duration(seconds: 2), () {
            pop = false;
          });
          return false;
        },
        child: AutoTabsRouter(
          routes: const [
            HomeRoute(),
            // SearchRoute(),
            WishlistRoute(),
            CartRoute(),
          ],
          builder: (context, child) {
            final tabsRouter = AutoTabsRouter.of(context);

            return Scaffold(
              key: dashboardScaffoldKey,
              drawer: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 5.0,
                  sigmaY: 5.0,
                ),
                child: const DrawerWidget(),
              ),
              drawerEdgeDragWidth: MediaQuery.of(context).size.width / 4,
              body: child,
              bottomNavigationBar: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 56,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        SlidingClippedNavBar(
                          backgroundColor: bottomBarBgColor ?? Colors.white,
                          onButtonPressed: (index) {
                            tabsRouter.setActiveIndex(index);
                          },
                          iconSize: 25,
                          activeColor: ColorConstant.primary,
                          inactiveColor: const Color(0xff8F959E),
                          selectedIndex: tabsRouter.activeIndex,
                          barItems: [
                            BarItem(icon: minimumzIcons.home, title: context.l10n.home),
                            BarItem(icon: minimumzIcons.heart, title: context.l10n.wishlist),
                            BarItem(icon: minimumzIcons.bag, title: context.l10n.cart),
                          ],
                        ),
                        // ── Cart badge overlay ──────────────────────
                        BlocBuilder<CartBloc, CartState>(
                          builder: (context, state) {
                            final count = state.whenOrNull(
                                  loaded: (cart) => cart.items?.fold<int>(
                                          0, (s, i) => s + (i.quantity ?? 1)) ??
                                      0,
                                ) ??
                                0;
                            if (count == 0) return const SizedBox.shrink();
                            // Cart is the 3rd item (index 2) — rightmost in LTR, leftmost in RTL.
                            final isRTL = context.isRTL;
                            final itemWidth =
                                MediaQuery.of(context).size.width / 3;
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
                                    top: 6,
                                    left: itemWidth / 2 - 4,
                                    child: badge,
                                  )
                                : Positioned(
                                    top: 6,
                                    right: itemWidth / 2 - 4,
                                    child: badge,
                                  );
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.only(bottom: context.bottomViewPadding),
                    color: bottomBarBgColor,
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
