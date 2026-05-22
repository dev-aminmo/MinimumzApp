import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:minimumz/blocs/auth/authentication_bloc.dart';
import 'package:minimumz/common/colors.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../routes/app_router.dart';

@RoutePage()
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _navigationScheduled = false;

  void _navigate(AuthenticationState state) {
    state.map(
      loggedInAsGuest: (_) =>
          context.router.replaceAll([const DashboardRoute()]),
      loggedIn: (_) => context.router.replace(const DashboardRoute()),
      loggedOut: (_) => context.router.replace(const SignInRoute()),
      error: (_) => context.router.replace(const SignInRoute()),
      loading: (_) {},
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_navigationScheduled) return;
    // Handle the case where auth resolved before the BlocListener subscribed
    final state = context.read<AuthenticationBloc>().state;
    final resolved = state.maybeMap(loading: (_) => false, orElse: () => true);
    if (resolved) {
      _navigationScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _navigate(state);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: ColorConstant.cream,
        systemNavigationBarColor: ColorConstant.cream,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: BlocListener<AuthenticationBloc, AuthenticationState>(
        listener: (context, state) => _navigate(state),
        child: Scaffold(
          backgroundColor: ColorConstant.cream,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Image.asset(
                  'assets/images/logo_minimumz.png',
                  width: 200,
                ),
              ),
              const Gap(10.0),
              LoadingAnimationWidget.staggeredDotsWave(
                  color: ColorConstant.primary, size: 40),
            ],
          ),
        ),
      ),
    );
  }
}
