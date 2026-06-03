import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';
import 'package:minimumz/domain/usecase/retrieve_cart_usecase.dart';
import 'package:minimumz/domain/usecase/update_cart_usercase.dart';
import 'package:minimumz/data/data.dart';

part 'cart_event.dart';
part 'cart_state.dart';
part 'cart_bloc.freezed.dart';

@injectable
class CartBloc extends Bloc<CartEvent, CartState> {
  static CartBloc get instance => getIt<CartBloc>();

  CartBloc(this._usecase, this._updateCartUsecase, this._prefs)
      : super(_cachedState(_prefs)) {
    on<_LoadCart>(_onLoadCart);
    on<_RefreshCart>(_onRefreshCart);
    on<_UpdateCart>(_onUpdateCart);
  }

  final RetrieveCartUsecase _usecase;
  final UpdateCartUsecase _updateCartUsecase;
  final PreferenceRepository _prefs;

  /// Start from cached cart if available — zero spinner on warm launches.
  static CartState _cachedState(PreferenceRepository prefs) {
    final cached = prefs.cachedCart;
    return cached != null ? CartState.loaded(cached) : const CartState.initial();
  }

  Future<void> _onLoadCart(_LoadCart event, Emitter<CartState> emit) async {
    // Only show spinner when there's no cached data already displayed.
    if (state is! _Loaded) emit(const CartState.loading());

    final result = await _usecase();
    result.when(
      (cart) {
        final prefCountry = _prefs.country?.iso2?.toLowerCase();
        final cartCountry = cart.shippingAddress?.countryCode?.toLowerCase();
        final resolved = (prefCountry != null &&
                cartCountry != null &&
                cartCountry.isNotEmpty &&
                cartCountry != prefCountry)
            ? cart.copyWith(shippingAddress: null)
            : cart;
        emit(CartState.loaded(resolved));
        _prefs.setCachedCart(resolved);
      },
      (error) {
        // Silently keep cached data if we have it; only surface the error when
        // there's nothing to show.
        if (state is! _Loaded) emit(CartState.error(error.message));
      },
    );
  }

  Future<void> _onRefreshCart(_RefreshCart event, Emitter<CartState> emit) async {
    // Backend sometimes omits subTotal/total in line item responses — recalculate from items.
    final cart = (event.cart.subTotal == null && event.cart.items != null)
        ? event.cart.recalculate()
        : event.cart;
    emit(CartState.loaded(cart));
    _prefs.setCachedCart(cart);
  }

  Future<void> _onUpdateCart(_UpdateCart event, Emitter<CartState> emit) async {
    if (state is! _Loaded) emit(const CartState.loading());
    final result =
        await _updateCartUsecase(cartId: event.cartId, req: event.req);
    result.when(
      (cart) {
        // If the server returns an address from a different country than the
        // one the user selected, strip it so the UI prompts for a new one.
        final prefCountry = _prefs.country?.iso2?.toLowerCase();
        final cartCountry = cart.shippingAddress?.countryCode?.toLowerCase();
        final resolved = (prefCountry != null &&
                cartCountry != null &&
                cartCountry.isNotEmpty &&
                cartCountry != prefCountry)
            ? cart.copyWith(shippingAddress: null)
            : cart;
        emit(CartState.loaded(resolved));
        _prefs.setCachedCart(resolved);
      },
      (error) => emit(CartState.error(error.message)),
    );
  }
}
