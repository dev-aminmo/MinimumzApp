import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:minimumz/services/notification_service.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:minimumz/l10n/app_localizations.dart';
import 'package:minimumz/blocs/auth/authentication_bloc.dart';
import 'package:minimumz/cubits/locale/locale_cubit.dart';
import 'package:minimumz/presentation/screens/cart/bloc/cart/cart_bloc.dart';
import 'package:minimumz/presentation/screens/cart/bloc/line_item/line_item_bloc.dart';
import 'package:minimumz/blocs/region/region_bloc.dart';
import 'package:minimumz/cubits/theme/theme_cubit.dart';
import 'package:minimumz/cubits/notifications/notification_cubit.dart';
import 'package:minimumz/cubits/wishlist/wishlist_cubit.dart';
import 'package:minimumz/presentation/routes/app_router.dart';
import 'package:minimumz/presentation/screens/home/bloc/collections/collections_bloc.dart';
import 'package:minimumz/presentation/screens/home/bloc/products/products_bloc.dart';
import 'package:minimumz/presentation/theme/theme.dart';
import 'package:minimumz/common/doh_client.dart';
import 'di/di.dart';
import 'observer.dart';

Future<bool> ping(String host) async {
  try {
    final client = makeDohHttpClient();
    final request = await client.getUrl(Uri.parse(host));
    request.headers.set('User-Agent', 'Mozilla/5.0');
    final response = await request.close();
    print('Status: ${response.statusCode}');
    client.close(force: true);
    return response.statusCode > 0;
  } catch (e) {
    print('error ping $e');
    return false;
  }
}
var host='https://darkorchid-mouse-412686.hostingersite.com';
Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  // Keep splash visible while DI and auth state load
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  ping(host);
  Bloc.observer = MyBlocObserver();
  await Firebase.initializeApp();
  await NotificationService.instance.init();
  await configureInjection();

  // Splash is dismissed as soon as Flutter draws its first frame
  FlutterNativeSplash.remove();

  runApp(const minimumzApp());
}

class minimumzApp extends StatelessWidget {
  const minimumzApp({super.key});

  AppRouter get _router => getIt<AppRouter>();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthenticationBloc>(
          create: (_) => AuthenticationBloc.instance,
          lazy: false,
        ),
        BlocProvider<ThemeCubit>(
          create: (_) => ThemeCubit.instance..loadTheme(),
          lazy: false,
        ),
        BlocProvider<ProductsBloc>(
          create: (_) => ProductsBloc.instance,
        ),
        BlocProvider<CollectionsBloc>(
          create: (_) => CollectionsBloc.instance
            ..add(const CollectionsEvent.retrieveCollections(
                queryParameters: {'limit': 4})),
        ),
        BlocProvider<RegionBloc>(
          create: (_) =>
              RegionBloc.instance..add(const RegionEvent.retrieveRegions()),
          lazy: false,
        ),
        BlocProvider<CartBloc>(
          create: (_) => CartBloc.instance..add(const CartEvent.loadCart()),
        ),
        BlocProvider<LineItemBloc>(
          create: (_) => LineItemBloc.instance,
        ),
        BlocProvider<WishlistCubit>(
          create: (_) => WishlistCubit(),
          lazy: false,
        ),
        BlocProvider<LocaleCubit>(
          create: (_) => LocaleCubit.instance,
          lazy: false,
        ),
        BlocProvider<NotificationCubit>(
          create: (_) => NotificationCubit(),
          lazy: false,
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) {
              return MaterialApp.router(
                title: 'MiniMumz',
                debugShowCheckedModeBanner: false,
                themeMode: themeState.themeMode,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                locale: locale,
                supportedLocales: const [Locale('en'), Locale('ar')],
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                routerConfig: _router.config(),
                builder: EasyLoading.init(),
              );
            },
          );
        },
      ),
    );
  }
}
