import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
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
import 'package:google_fonts/src/google_fonts_base.dart' as gfb;
import 'package:http/io_client.dart';
import 'common/doh_client.dart';
import 'di/di.dart';
import 'observer.dart';

Future<void> main() async {
  await SentryFlutter.init(
    (options) {
      if(!kDebugMode) {
        options.dsn =
        'https://5815bdbfe2036e14560c72f3c20a4c52@o4511479315890176.ingest.de.sentry.io/4511479317266512';
      }else{
        options.dsn="";

      }
      options.tracesSampleRate = 1.0;
      options.environment = 'production';
      options.enableLogs = true;
    },
    appRunner: () async {
      gfb.httpClient = IOClient(makeDohHttpClient());
      final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
      Bloc.observer = MyBlocObserver();
      await Firebase.initializeApp();
      await NotificationService.instance.init();
      await configureInjection();
      FlutterNativeSplash.remove();
      runApp(const minimumzApp());
    },
  );
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
            ..add(const CollectionsEvent.retrieveCollections()),
        ),
        BlocProvider<RegionBloc>(
          create: (_) =>
              RegionBloc.instance..add(const RegionEvent.retrieveRegions()),
          lazy: false,
        ),
        BlocProvider<CartBloc>(
          create: (_) => CartBloc.instance..add(const CartEvent.loadCart()),
          lazy: false,
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
      child: BlocListener<AuthenticationBloc, AuthenticationState>(
        listenWhen: (previous, current) =>
            !previous.maybeMap(loggedOut: (_) => true, orElse: () => false) &&
            current.maybeMap(loggedOut: (_) => true, orElse: () => false),
        listener: (context, _) =>
            context.read<CartBloc>().add(const CartEvent.loadCart()),
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
      ),
    );
  }
}
