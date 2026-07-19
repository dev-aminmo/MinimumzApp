import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:minimumz/presentation/components/drawer.dart';

/// The Profile bottom-nav tab — renders the account menu as a full screen.
@RoutePage()
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: DrawerWidget(isDrawer: false));
  }
}
