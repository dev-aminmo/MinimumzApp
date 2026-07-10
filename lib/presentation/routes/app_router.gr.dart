// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

abstract class _$AppRouter extends RootStackRouter {
  // ignore: unused_element
  _$AppRouter({super.navigatorKey});

  @override
  final Map<String, PageFactory> pagesMap = {
    AccountInformationRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const AccountInformationScreen(),
      );
    },
    AddReviewRoute.name: (routeData) {
      final args = routeData.argsAs<AddReviewRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: AddReviewScreen(
          key: args.key,
          productId: args.productId,
        ),
      );
    },
    AddressBookRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const AddressBookScreen(),
      );
    },
    CartRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const CartScreen(),
      );
    },
    CartTabRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const CartTabScreen(),
      );
    },
    CategoriesRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const CategoriesScreen(),
      );
    },
    CategoriesTabRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const CategoriesTabScreen(),
      );
    },
    CollectionRoute.name: (routeData) {
      final args = routeData.argsAs<CollectionRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: CollectionScreen(
          key: args.key,
          collection: args.collection,
        ),
      );
    },
    DashboardRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const DashboardScreen(),
      );
    },
    ForgotPasswordRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const ForgotPasswordScreen(),
      );
    },
    HomeRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const HomeScreen(),
      );
    },
    HomeTabRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const HomeTabScreen(),
      );
    },
    InviteEarnRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const InviteEarnScreen(),
      );
    },
    NewPasswordRoute.name: (routeData) {
      final args = routeData.argsAs<NewPasswordRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: NewPasswordScreen(
          key: args.key,
          email: args.email,
          code: args.code,
        ),
      );
    },
    NotificationsRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const NotificationsScreen(),
      );
    },
    OrderConfirmedRoute.name: (routeData) {
      final args = routeData.argsAs<OrderConfirmedRouteArgs>(
          orElse: () => const OrderConfirmedRouteArgs());
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: OrderConfirmedScreen(
          key: args.key,
          order: args.order,
        ),
      );
    },
    OrderDetailsRoute.name: (routeData) {
      final args = routeData.argsAs<OrderDetailsRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: OrderDetailsScreen(
          key: args.key,
          orderId: args.orderId,
          order: args.order,
        ),
      );
    },
    OrdersRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const OrdersScreen(),
      );
    },
    ProductDetailsRoute.name: (routeData) {
      final args = routeData.argsAs<ProductDetailsRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: ProductDetailsScreen(
          key: args.key,
          product: args.product,
        ),
      );
    },
    RecentlyViewedRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const RecentlyViewedScreen(),
      );
    },
    ReviewsRoute.name: (routeData) {
      final args = routeData.argsAs<ReviewsRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: ReviewsScreen(
          key: args.key,
          productId: args.productId,
          productTitle: args.productTitle,
        ),
      );
    },
    SearchRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const SearchScreen(),
      );
    },
    SettingsRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const SettingsScreen(),
      );
    },
    SignInRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const SignInScreen(),
      );
    },
    SignInWithEmailRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const SignInWithEmailScreen(),
      );
    },
    SignUpRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const SignUpScreen(),
      );
    },
    SplashRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const SplashScreen(),
      );
    },
    VerificationCodeRoute.name: (routeData) {
      final args = routeData.argsAs<VerificationCodeRouteArgs>();
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: VerificationCodeScreen(
          key: args.key,
          email: args.email,
        ),
      );
    },
    WalletRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const WalletScreen(),
      );
    },
    WishlistRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const WishlistScreen(),
      );
    },
    WishlistTabRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const WishlistTabScreen(),
      );
    },
  };
}

/// generated route for
/// [AccountInformationScreen]
class AccountInformationRoute extends PageRouteInfo<void> {
  const AccountInformationRoute({List<PageRouteInfo>? children})
      : super(
          AccountInformationRoute.name,
          initialChildren: children,
        );

  static const String name = 'AccountInformationRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [AddReviewScreen]
class AddReviewRoute extends PageRouteInfo<AddReviewRouteArgs> {
  AddReviewRoute({
    Key? key,
    required String productId,
    List<PageRouteInfo>? children,
  }) : super(
          AddReviewRoute.name,
          args: AddReviewRouteArgs(
            key: key,
            productId: productId,
          ),
          initialChildren: children,
        );

  static const String name = 'AddReviewRoute';

  static const PageInfo<AddReviewRouteArgs> page =
      PageInfo<AddReviewRouteArgs>(name);
}

class AddReviewRouteArgs {
  const AddReviewRouteArgs({
    this.key,
    required this.productId,
  });

  final Key? key;

  final String productId;

  @override
  String toString() {
    return 'AddReviewRouteArgs{key: $key, productId: $productId}';
  }
}

/// generated route for
/// [AddressBookScreen]
class AddressBookRoute extends PageRouteInfo<void> {
  const AddressBookRoute({List<PageRouteInfo>? children})
      : super(
          AddressBookRoute.name,
          initialChildren: children,
        );

  static const String name = 'AddressBookRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [CartScreen]
class CartRoute extends PageRouteInfo<void> {
  const CartRoute({List<PageRouteInfo>? children})
      : super(
          CartRoute.name,
          initialChildren: children,
        );

  static const String name = 'CartRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [CartTabScreen]
class CartTabRoute extends PageRouteInfo<void> {
  const CartTabRoute({List<PageRouteInfo>? children})
      : super(
          CartTabRoute.name,
          initialChildren: children,
        );

  static const String name = 'CartTabRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [CategoriesScreen]
class CategoriesRoute extends PageRouteInfo<void> {
  const CategoriesRoute({List<PageRouteInfo>? children})
      : super(
          CategoriesRoute.name,
          initialChildren: children,
        );

  static const String name = 'CategoriesRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [CategoriesTabScreen]
class CategoriesTabRoute extends PageRouteInfo<void> {
  const CategoriesTabRoute({List<PageRouteInfo>? children})
      : super(
          CategoriesTabRoute.name,
          initialChildren: children,
        );

  static const String name = 'CategoriesTabRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [CollectionScreen]
class CollectionRoute extends PageRouteInfo<CollectionRouteArgs> {
  CollectionRoute({
    Key? key,
    required ProductCollection collection,
    List<PageRouteInfo>? children,
  }) : super(
          CollectionRoute.name,
          args: CollectionRouteArgs(
            key: key,
            collection: collection,
          ),
          initialChildren: children,
        );

  static const String name = 'CollectionRoute';

  static const PageInfo<CollectionRouteArgs> page =
      PageInfo<CollectionRouteArgs>(name);
}

class CollectionRouteArgs {
  const CollectionRouteArgs({
    this.key,
    required this.collection,
  });

  final Key? key;

  final ProductCollection collection;

  @override
  String toString() {
    return 'CollectionRouteArgs{key: $key, collection: $collection}';
  }
}

/// generated route for
/// [DashboardScreen]
class DashboardRoute extends PageRouteInfo<void> {
  const DashboardRoute({List<PageRouteInfo>? children})
      : super(
          DashboardRoute.name,
          initialChildren: children,
        );

  static const String name = 'DashboardRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [ForgotPasswordScreen]
class ForgotPasswordRoute extends PageRouteInfo<void> {
  const ForgotPasswordRoute({List<PageRouteInfo>? children})
      : super(
          ForgotPasswordRoute.name,
          initialChildren: children,
        );

  static const String name = 'ForgotPasswordRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [HomeScreen]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [HomeTabScreen]
class HomeTabRoute extends PageRouteInfo<void> {
  const HomeTabRoute({List<PageRouteInfo>? children})
      : super(
          HomeTabRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeTabRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [InviteEarnScreen]
class InviteEarnRoute extends PageRouteInfo<void> {
  const InviteEarnRoute({List<PageRouteInfo>? children})
      : super(
          InviteEarnRoute.name,
          initialChildren: children,
        );

  static const String name = 'InviteEarnRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [NewPasswordScreen]
class NewPasswordRoute extends PageRouteInfo<NewPasswordRouteArgs> {
  NewPasswordRoute({
    Key? key,
    required String email,
    required String code,
    List<PageRouteInfo>? children,
  }) : super(
          NewPasswordRoute.name,
          args: NewPasswordRouteArgs(
            key: key,
            email: email,
            code: code,
          ),
          initialChildren: children,
        );

  static const String name = 'NewPasswordRoute';

  static const PageInfo<NewPasswordRouteArgs> page =
      PageInfo<NewPasswordRouteArgs>(name);
}

class NewPasswordRouteArgs {
  const NewPasswordRouteArgs({
    this.key,
    required this.email,
    required this.code,
  });

  final Key? key;

  final String email;

  final String code;

  @override
  String toString() {
    return 'NewPasswordRouteArgs{key: $key, email: $email, code: $code}';
  }
}

/// generated route for
/// [NotificationsScreen]
class NotificationsRoute extends PageRouteInfo<void> {
  const NotificationsRoute({List<PageRouteInfo>? children})
      : super(
          NotificationsRoute.name,
          initialChildren: children,
        );

  static const String name = 'NotificationsRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [OrderConfirmedScreen]
class OrderConfirmedRoute extends PageRouteInfo<OrderConfirmedRouteArgs> {
  OrderConfirmedRoute({
    Key? key,
    Order? order,
    List<PageRouteInfo>? children,
  }) : super(
          OrderConfirmedRoute.name,
          args: OrderConfirmedRouteArgs(
            key: key,
            order: order,
          ),
          initialChildren: children,
        );

  static const String name = 'OrderConfirmedRoute';

  static const PageInfo<OrderConfirmedRouteArgs> page =
      PageInfo<OrderConfirmedRouteArgs>(name);
}

class OrderConfirmedRouteArgs {
  const OrderConfirmedRouteArgs({
    this.key,
    this.order,
  });

  final Key? key;

  final Order? order;

  @override
  String toString() {
    return 'OrderConfirmedRouteArgs{key: $key, order: $order}';
  }
}

/// generated route for
/// [OrderDetailsScreen]
class OrderDetailsRoute extends PageRouteInfo<OrderDetailsRouteArgs> {
  OrderDetailsRoute({
    Key? key,
    required String orderId,
    Order? order,
    List<PageRouteInfo>? children,
  }) : super(
          OrderDetailsRoute.name,
          args: OrderDetailsRouteArgs(
            key: key,
            orderId: orderId,
            order: order,
          ),
          initialChildren: children,
        );

  static const String name = 'OrderDetailsRoute';

  static const PageInfo<OrderDetailsRouteArgs> page =
      PageInfo<OrderDetailsRouteArgs>(name);
}

class OrderDetailsRouteArgs {
  const OrderDetailsRouteArgs({
    this.key,
    required this.orderId,
    this.order,
  });

  final Key? key;

  final String orderId;

  final Order? order;

  @override
  String toString() {
    return 'OrderDetailsRouteArgs{key: $key, orderId: $orderId, order: $order}';
  }
}

/// generated route for
/// [OrdersScreen]
class OrdersRoute extends PageRouteInfo<void> {
  const OrdersRoute({List<PageRouteInfo>? children})
      : super(
          OrdersRoute.name,
          initialChildren: children,
        );

  static const String name = 'OrdersRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [ProductDetailsScreen]
class ProductDetailsRoute extends PageRouteInfo<ProductDetailsRouteArgs> {
  ProductDetailsRoute({
    Key? key,
    required Product product,
    List<PageRouteInfo>? children,
  }) : super(
          ProductDetailsRoute.name,
          args: ProductDetailsRouteArgs(
            key: key,
            product: product,
          ),
          initialChildren: children,
        );

  static const String name = 'ProductDetailsRoute';

  static const PageInfo<ProductDetailsRouteArgs> page =
      PageInfo<ProductDetailsRouteArgs>(name);
}

class ProductDetailsRouteArgs {
  const ProductDetailsRouteArgs({
    this.key,
    required this.product,
  });

  final Key? key;

  final Product product;

  @override
  String toString() {
    return 'ProductDetailsRouteArgs{key: $key, product: $product}';
  }
}

/// generated route for
/// [RecentlyViewedScreen]
class RecentlyViewedRoute extends PageRouteInfo<void> {
  const RecentlyViewedRoute({List<PageRouteInfo>? children})
      : super(
          RecentlyViewedRoute.name,
          initialChildren: children,
        );

  static const String name = 'RecentlyViewedRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [ReviewsScreen]
class ReviewsRoute extends PageRouteInfo<ReviewsRouteArgs> {
  ReviewsRoute({
    Key? key,
    required String productId,
    String? productTitle,
    List<PageRouteInfo>? children,
  }) : super(
          ReviewsRoute.name,
          args: ReviewsRouteArgs(
            key: key,
            productId: productId,
            productTitle: productTitle,
          ),
          initialChildren: children,
        );

  static const String name = 'ReviewsRoute';

  static const PageInfo<ReviewsRouteArgs> page =
      PageInfo<ReviewsRouteArgs>(name);
}

class ReviewsRouteArgs {
  const ReviewsRouteArgs({
    this.key,
    required this.productId,
    this.productTitle,
  });

  final Key? key;

  final String productId;

  final String? productTitle;

  @override
  String toString() {
    return 'ReviewsRouteArgs{key: $key, productId: $productId, productTitle: $productTitle}';
  }
}

/// generated route for
/// [SearchScreen]
class SearchRoute extends PageRouteInfo<void> {
  const SearchRoute({List<PageRouteInfo>? children})
      : super(
          SearchRoute.name,
          initialChildren: children,
        );

  static const String name = 'SearchRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [SettingsScreen]
class SettingsRoute extends PageRouteInfo<void> {
  const SettingsRoute({List<PageRouteInfo>? children})
      : super(
          SettingsRoute.name,
          initialChildren: children,
        );

  static const String name = 'SettingsRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [SignInScreen]
class SignInRoute extends PageRouteInfo<void> {
  const SignInRoute({List<PageRouteInfo>? children})
      : super(
          SignInRoute.name,
          initialChildren: children,
        );

  static const String name = 'SignInRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [SignInWithEmailScreen]
class SignInWithEmailRoute extends PageRouteInfo<void> {
  const SignInWithEmailRoute({List<PageRouteInfo>? children})
      : super(
          SignInWithEmailRoute.name,
          initialChildren: children,
        );

  static const String name = 'SignInWithEmailRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [SignUpScreen]
class SignUpRoute extends PageRouteInfo<void> {
  const SignUpRoute({List<PageRouteInfo>? children})
      : super(
          SignUpRoute.name,
          initialChildren: children,
        );

  static const String name = 'SignUpRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [SplashScreen]
class SplashRoute extends PageRouteInfo<void> {
  const SplashRoute({List<PageRouteInfo>? children})
      : super(
          SplashRoute.name,
          initialChildren: children,
        );

  static const String name = 'SplashRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [VerificationCodeScreen]
class VerificationCodeRoute extends PageRouteInfo<VerificationCodeRouteArgs> {
  VerificationCodeRoute({
    Key? key,
    required String email,
    List<PageRouteInfo>? children,
  }) : super(
          VerificationCodeRoute.name,
          args: VerificationCodeRouteArgs(
            key: key,
            email: email,
          ),
          initialChildren: children,
        );

  static const String name = 'VerificationCodeRoute';

  static const PageInfo<VerificationCodeRouteArgs> page =
      PageInfo<VerificationCodeRouteArgs>(name);
}

class VerificationCodeRouteArgs {
  const VerificationCodeRouteArgs({
    this.key,
    required this.email,
  });

  final Key? key;

  final String email;

  @override
  String toString() {
    return 'VerificationCodeRouteArgs{key: $key, email: $email}';
  }
}

/// generated route for
/// [WalletScreen]
class WalletRoute extends PageRouteInfo<void> {
  const WalletRoute({List<PageRouteInfo>? children})
      : super(
          WalletRoute.name,
          initialChildren: children,
        );

  static const String name = 'WalletRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [WishlistScreen]
class WishlistRoute extends PageRouteInfo<void> {
  const WishlistRoute({List<PageRouteInfo>? children})
      : super(
          WishlistRoute.name,
          initialChildren: children,
        );

  static const String name = 'WishlistRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [WishlistTabScreen]
class WishlistTabRoute extends PageRouteInfo<void> {
  const WishlistTabRoute({List<PageRouteInfo>? children})
      : super(
          WishlistTabRoute.name,
          initialChildren: children,
        );

  static const String name = 'WishlistTabRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}
