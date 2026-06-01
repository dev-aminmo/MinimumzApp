import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class HomeTabScreen extends StatelessWidget {
  const HomeTabScreen({super.key});
  @override
  Widget build(BuildContext context) => const AutoRouter();
}

@RoutePage()
class CategoriesTabScreen extends StatelessWidget {
  const CategoriesTabScreen({super.key});
  @override
  Widget build(BuildContext context) => const AutoRouter();
}

@RoutePage()
class WishlistTabScreen extends StatelessWidget {
  const WishlistTabScreen({super.key});
  @override
  Widget build(BuildContext context) => const AutoRouter();
}

@RoutePage()
class CartTabScreen extends StatelessWidget {
  const CartTabScreen({super.key});
  @override
  Widget build(BuildContext context) => const AutoRouter();
}
