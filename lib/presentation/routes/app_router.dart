import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:minimumz/presentation/screens/account_information/account_information_screen.dart';
import 'package:minimumz/presentation/screens/index.dart';
import 'package:minimumz/data/data.dart';

import '../screens/home/home_screen.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/account_information/address_book_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/categories_screen.dart';

part 'app_router.gr.dart';

@AutoRouterConfig(replaceInRouteName: 'Screen,Route')
class AppRouter extends _$AppRouter {
  @override
  List<AutoRoute> get routes => [
        AutoRoute(initial: true, page: SplashRoute.page),
        AutoRoute(page: SignUpRoute.page),
        AutoRoute(page: SignInRoute.page),
        AutoRoute(page: SignInWithEmailRoute.page),
        AutoRoute(page: ForgotPasswordRoute.page),
        AutoRoute(page: NewPasswordRoute.page),
        AutoRoute(page: VerificationCodeRoute.page),
        AutoRoute(page: SearchRoute.page, fullscreenDialog: true),
        AutoRoute(page: ReviewsRoute.page),
        AutoRoute(page: ProductDetailsRoute.page),
        AutoRoute(page: OrderConfirmedRoute.page),
        AutoRoute(page: CollectionRoute.page),
        AutoRoute(page: AddReviewRoute.page),
        AutoRoute(page: CartRoute.page),
        AutoRoute(page: OrdersRoute.page),
        AutoRoute(page: AccountInformationRoute.page),
        AutoRoute(page: AddressBookRoute.page),
        AutoRoute(page: SettingsRoute.page),
        AutoRoute(page: NotificationsRoute.page),
        AutoRoute(page: RecentlyViewedRoute.page),
        AutoRoute(
          page: DashboardRoute.page,
          children: [
            AutoRoute(page: HomeRoute.page),
            AutoRoute(page: CategoriesRoute.page),
            AutoRoute(page: WishlistRoute.page),
            AutoRoute(page: CartRoute.page),
          ],
        ),
      ];
}
