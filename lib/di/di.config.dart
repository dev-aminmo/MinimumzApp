// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:minimumz/blocs/auth/authentication_bloc.dart' as _i864;
import 'package:minimumz/blocs/region/region_bloc.dart' as _i975;
import 'package:minimumz/cubits/locale/locale_cubit.dart' as _i516;
import 'package:minimumz/cubits/theme/theme_cubit.dart' as _i530;
import 'package:minimumz/domain/repository/preference_repository.dart' as _i745;
import 'package:minimumz/domain/repository/theme_repository.dart' as _i283;
import 'package:minimumz/domain/usecase/account_information_usecase.dart'
    as _i517;
import 'package:minimumz/domain/usecase/auth_usecase.dart' as _i143;
import 'package:minimumz/domain/usecase/get_home_category_usecase.dart'
    as _i438;
import 'package:minimumz/domain/usecase/get_home_product_usecase.dart' as _i463;
import 'package:minimumz/domain/usecase/line_item_usecase.dart' as _i479;
import 'package:minimumz/domain/usecase/retrieve_cart_usecase.dart' as _i272;
import 'package:minimumz/domain/usecase/retrieve_collections_usecase.dart'
    as _i993;
import 'package:minimumz/domain/usecase/retrieve_orders_usecase.dart' as _i62;
import 'package:minimumz/domain/usecase/retrieve_regions_usecase.dart' as _i386;
import 'package:minimumz/domain/usecase/update_cart_usercase.dart' as _i269;
import 'package:minimumz/presentation/screens/cart/bloc/cart/cart_bloc.dart'
    as _i869;
import 'package:minimumz/presentation/screens/cart/bloc/line_item/line_item_bloc.dart'
    as _i137;
import 'package:minimumz/presentation/screens/home/bloc/collections/collections_bloc.dart'
    as _i583;
import 'package:minimumz/presentation/screens/home/bloc/products/products_bloc.dart'
    as _i705;
import 'package:minimumz/presentation/screens/orders/bloc/orders/orders_bloc.dart'
    as _i503;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    gh.factory<_i530.ThemeCubit>(() => _i530.ThemeCubit());
    gh.factory<_i283.ThemeRepository>(() => _i283.ThemeRepository());
    gh.factory<_i993.RetrieveCollectionsUsecase>(
        () => _i993.RetrieveCollectionsUsecase());
    gh.factory<_i143.AuthenticationUsecase>(
        () => _i143.AuthenticationUsecase());
    gh.factory<_i463.GetHomeProductUsecase>(
        () => _i463.GetHomeProductUsecase());
    gh.factory<_i272.RetrieveCartUsecase>(() => _i272.RetrieveCartUsecase());
    gh.factory<_i479.LineItemUsecase>(() => _i479.LineItemUsecase());
    gh.factory<_i269.UpdateCartUsecase>(() => _i269.UpdateCartUsecase());
    gh.factory<_i62.RetrieveOrdersUsecase>(() => _i62.RetrieveOrdersUsecase());
    gh.factory<_i438.GetHomeCategoryUsecase>(
        () => _i438.GetHomeCategoryUsecase());
    gh.factory<_i386.RetrieveRegionsUsecase>(
        () => _i386.RetrieveRegionsUsecase());
    gh.factory<_i517.AccountInformationUsecase>(
        () => _i517.AccountInformationUsecase());
    gh.singleton<_i516.LocaleCubit>(
        () => _i516.LocaleCubit(gh<_i460.SharedPreferences>()));
    gh.singleton<_i745.PreferenceRepository>(() =>
        _i745.PreferenceRepository(gh<_i460.SharedPreferences>())..init());
    gh.factory<_i503.OrdersBloc>(
        () => _i503.OrdersBloc(gh<_i62.RetrieveOrdersUsecase>()));
    gh.factory<_i705.ProductsBloc>(
        () => _i705.ProductsBloc(gh<_i463.GetHomeProductUsecase>()));
    gh.factory<_i869.CartBloc>(() => _i869.CartBloc(
          gh<_i272.RetrieveCartUsecase>(),
          gh<_i269.UpdateCartUsecase>(),
          gh<_i745.PreferenceRepository>(),
        ));
    gh.factory<_i864.AuthenticationBloc>(
        () => _i864.AuthenticationBloc(gh<_i143.AuthenticationUsecase>()));
    gh.factory<_i975.RegionBloc>(
        () => _i975.RegionBloc(gh<_i386.RetrieveRegionsUsecase>()));
    gh.factory<_i137.LineItemBloc>(
        () => _i137.LineItemBloc(gh<_i479.LineItemUsecase>()));
    gh.factory<_i583.CollectionsBloc>(
        () => _i583.CollectionsBloc(gh<_i993.RetrieveCollectionsUsecase>()));
    return this;
  }
}
