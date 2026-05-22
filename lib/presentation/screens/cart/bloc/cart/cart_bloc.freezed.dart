// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cart_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$CartEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadCart,
    required TResult Function(String cartId, StorePostCartsCartReq req)
        updateCart,
    required TResult Function(Cart cart) refreshCart,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadCart,
    TResult? Function(String cartId, StorePostCartsCartReq req)? updateCart,
    TResult? Function(Cart cart)? refreshCart,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadCart,
    TResult Function(String cartId, StorePostCartsCartReq req)? updateCart,
    TResult Function(Cart cart)? refreshCart,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadCart value) loadCart,
    required TResult Function(_UpdateCart value) updateCart,
    required TResult Function(_RefreshCart value) refreshCart,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadCart value)? loadCart,
    TResult? Function(_UpdateCart value)? updateCart,
    TResult? Function(_RefreshCart value)? refreshCart,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadCart value)? loadCart,
    TResult Function(_UpdateCart value)? updateCart,
    TResult Function(_RefreshCart value)? refreshCart,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CartEventCopyWith<$Res> {
  factory $CartEventCopyWith(CartEvent value, $Res Function(CartEvent) then) =
      _$CartEventCopyWithImpl<$Res, CartEvent>;
}

/// @nodoc
class _$CartEventCopyWithImpl<$Res, $Val extends CartEvent>
    implements $CartEventCopyWith<$Res> {
  _$CartEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$LoadCartImplCopyWith<$Res> {
  factory _$$LoadCartImplCopyWith(
          _$LoadCartImpl value, $Res Function(_$LoadCartImpl) then) =
      __$$LoadCartImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadCartImplCopyWithImpl<$Res>
    extends _$CartEventCopyWithImpl<$Res, _$LoadCartImpl>
    implements _$$LoadCartImplCopyWith<$Res> {
  __$$LoadCartImplCopyWithImpl(
      _$LoadCartImpl _value, $Res Function(_$LoadCartImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$LoadCartImpl implements _LoadCart {
  const _$LoadCartImpl();

  @override
  String toString() {
    return 'CartEvent.loadCart()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoadCartImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadCart,
    required TResult Function(String cartId, StorePostCartsCartReq req)
        updateCart,
    required TResult Function(Cart cart) refreshCart,
  }) {
    return loadCart();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadCart,
    TResult? Function(String cartId, StorePostCartsCartReq req)? updateCart,
    TResult? Function(Cart cart)? refreshCart,
  }) {
    return loadCart?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadCart,
    TResult Function(String cartId, StorePostCartsCartReq req)? updateCart,
    TResult Function(Cart cart)? refreshCart,
    required TResult orElse(),
  }) {
    if (loadCart != null) {
      return loadCart();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadCart value) loadCart,
    required TResult Function(_UpdateCart value) updateCart,
    required TResult Function(_RefreshCart value) refreshCart,
  }) {
    return loadCart(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadCart value)? loadCart,
    TResult? Function(_UpdateCart value)? updateCart,
    TResult? Function(_RefreshCart value)? refreshCart,
  }) {
    return loadCart?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadCart value)? loadCart,
    TResult Function(_UpdateCart value)? updateCart,
    TResult Function(_RefreshCart value)? refreshCart,
    required TResult orElse(),
  }) {
    if (loadCart != null) {
      return loadCart(this);
    }
    return orElse();
  }
}

abstract class _LoadCart implements CartEvent {
  const factory _LoadCart() = _$LoadCartImpl;
}

/// @nodoc
abstract class _$$UpdateCartImplCopyWith<$Res> {
  factory _$$UpdateCartImplCopyWith(
          _$UpdateCartImpl value, $Res Function(_$UpdateCartImpl) then) =
      __$$UpdateCartImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String cartId, StorePostCartsCartReq req});
}

/// @nodoc
class __$$UpdateCartImplCopyWithImpl<$Res>
    extends _$CartEventCopyWithImpl<$Res, _$UpdateCartImpl>
    implements _$$UpdateCartImplCopyWith<$Res> {
  __$$UpdateCartImplCopyWithImpl(
      _$UpdateCartImpl _value, $Res Function(_$UpdateCartImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cartId = null,
    Object? req = null,
  }) {
    return _then(_$UpdateCartImpl(
      cartId: null == cartId
          ? _value.cartId
          : cartId // ignore: cast_nullable_to_non_nullable
              as String,
      req: null == req
          ? _value.req
          : req // ignore: cast_nullable_to_non_nullable
              as StorePostCartsCartReq,
    ));
  }
}

/// @nodoc

class _$UpdateCartImpl implements _UpdateCart {
  const _$UpdateCartImpl({required this.cartId, required this.req});

  @override
  final String cartId;
  @override
  final StorePostCartsCartReq req;

  @override
  String toString() {
    return 'CartEvent.updateCart(cartId: $cartId, req: $req)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UpdateCartImpl &&
            (identical(other.cartId, cartId) || other.cartId == cartId) &&
            (identical(other.req, req) || other.req == req));
  }

  @override
  int get hashCode => Object.hash(runtimeType, cartId, req);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$UpdateCartImplCopyWith<_$UpdateCartImpl> get copyWith =>
      __$$UpdateCartImplCopyWithImpl<_$UpdateCartImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadCart,
    required TResult Function(String cartId, StorePostCartsCartReq req)
        updateCart,
    required TResult Function(Cart cart) refreshCart,
  }) {
    return updateCart(cartId, req);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadCart,
    TResult? Function(String cartId, StorePostCartsCartReq req)? updateCart,
    TResult? Function(Cart cart)? refreshCart,
  }) {
    return updateCart?.call(cartId, req);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadCart,
    TResult Function(String cartId, StorePostCartsCartReq req)? updateCart,
    TResult Function(Cart cart)? refreshCart,
    required TResult orElse(),
  }) {
    if (updateCart != null) {
      return updateCart(cartId, req);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadCart value) loadCart,
    required TResult Function(_UpdateCart value) updateCart,
    required TResult Function(_RefreshCart value) refreshCart,
  }) {
    return updateCart(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadCart value)? loadCart,
    TResult? Function(_UpdateCart value)? updateCart,
    TResult? Function(_RefreshCart value)? refreshCart,
  }) {
    return updateCart?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadCart value)? loadCart,
    TResult Function(_UpdateCart value)? updateCart,
    TResult Function(_RefreshCart value)? refreshCart,
    required TResult orElse(),
  }) {
    if (updateCart != null) {
      return updateCart(this);
    }
    return orElse();
  }
}

abstract class _UpdateCart implements CartEvent {
  const factory _UpdateCart(
      {required final String cartId,
      required final StorePostCartsCartReq req}) = _$UpdateCartImpl;

  String get cartId;
  StorePostCartsCartReq get req;
  @JsonKey(ignore: true)
  _$$UpdateCartImplCopyWith<_$UpdateCartImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RefreshCartImplCopyWith<$Res> {
  factory _$$RefreshCartImplCopyWith(
          _$RefreshCartImpl value, $Res Function(_$RefreshCartImpl) then) =
      __$$RefreshCartImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Cart cart});
}

/// @nodoc
class __$$RefreshCartImplCopyWithImpl<$Res>
    extends _$CartEventCopyWithImpl<$Res, _$RefreshCartImpl>
    implements _$$RefreshCartImplCopyWith<$Res> {
  __$$RefreshCartImplCopyWithImpl(
      _$RefreshCartImpl _value, $Res Function(_$RefreshCartImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cart = null,
  }) {
    return _then(_$RefreshCartImpl(
      null == cart
          ? _value.cart
          : cart // ignore: cast_nullable_to_non_nullable
              as Cart,
    ));
  }
}

/// @nodoc

class _$RefreshCartImpl implements _RefreshCart {
  const _$RefreshCartImpl(this.cart);

  @override
  final Cart cart;

  @override
  String toString() {
    return 'CartEvent.refreshCart(cart: $cart)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RefreshCartImpl &&
            (identical(other.cart, cart) || other.cart == cart));
  }

  @override
  int get hashCode => Object.hash(runtimeType, cart);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RefreshCartImplCopyWith<_$RefreshCartImpl> get copyWith =>
      __$$RefreshCartImplCopyWithImpl<_$RefreshCartImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loadCart,
    required TResult Function(String cartId, StorePostCartsCartReq req)
        updateCart,
    required TResult Function(Cart cart) refreshCart,
  }) {
    return refreshCart(cart);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loadCart,
    TResult? Function(String cartId, StorePostCartsCartReq req)? updateCart,
    TResult? Function(Cart cart)? refreshCart,
  }) {
    return refreshCart?.call(cart);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loadCart,
    TResult Function(String cartId, StorePostCartsCartReq req)? updateCart,
    TResult Function(Cart cart)? refreshCart,
    required TResult orElse(),
  }) {
    if (refreshCart != null) {
      return refreshCart(cart);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_LoadCart value) loadCart,
    required TResult Function(_UpdateCart value) updateCart,
    required TResult Function(_RefreshCart value) refreshCart,
  }) {
    return refreshCart(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_LoadCart value)? loadCart,
    TResult? Function(_UpdateCart value)? updateCart,
    TResult? Function(_RefreshCart value)? refreshCart,
  }) {
    return refreshCart?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_LoadCart value)? loadCart,
    TResult Function(_UpdateCart value)? updateCart,
    TResult Function(_RefreshCart value)? refreshCart,
    required TResult orElse(),
  }) {
    if (refreshCart != null) {
      return refreshCart(this);
    }
    return orElse();
  }
}

abstract class _RefreshCart implements CartEvent {
  const factory _RefreshCart(final Cart cart) = _$RefreshCartImpl;

  Cart get cart;
  @JsonKey(ignore: true)
  _$$RefreshCartImplCopyWith<_$RefreshCartImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$CartState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(Cart cart) loaded,
    required TResult Function(String? message) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(Cart cart)? loaded,
    TResult? Function(String? message)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(Cart cart)? loaded,
    TResult Function(String? message)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Error value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Error value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CartStateCopyWith<$Res> {
  factory $CartStateCopyWith(CartState value, $Res Function(CartState) then) =
      _$CartStateCopyWithImpl<$Res, CartState>;
}

/// @nodoc
class _$CartStateCopyWithImpl<$Res, $Val extends CartState>
    implements $CartStateCopyWith<$Res> {
  _$CartStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$InitialImplCopyWith<$Res> {
  factory _$$InitialImplCopyWith(
          _$InitialImpl value, $Res Function(_$InitialImpl) then) =
      __$$InitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$InitialImplCopyWithImpl<$Res>
    extends _$CartStateCopyWithImpl<$Res, _$InitialImpl>
    implements _$$InitialImplCopyWith<$Res> {
  __$$InitialImplCopyWithImpl(
      _$InitialImpl _value, $Res Function(_$InitialImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$InitialImpl implements _Initial {
  const _$InitialImpl();

  @override
  String toString() {
    return 'CartState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$InitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(Cart cart) loaded,
    required TResult Function(String? message) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(Cart cart)? loaded,
    TResult? Function(String? message)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(Cart cart)? loaded,
    TResult Function(String? message)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Error value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Error value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class _Initial implements CartState {
  const factory _Initial() = _$InitialImpl;
}

/// @nodoc
abstract class _$$LoadingImplCopyWith<$Res> {
  factory _$$LoadingImplCopyWith(
          _$LoadingImpl value, $Res Function(_$LoadingImpl) then) =
      __$$LoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadingImplCopyWithImpl<$Res>
    extends _$CartStateCopyWithImpl<$Res, _$LoadingImpl>
    implements _$$LoadingImplCopyWith<$Res> {
  __$$LoadingImplCopyWithImpl(
      _$LoadingImpl _value, $Res Function(_$LoadingImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$LoadingImpl implements _Loading {
  const _$LoadingImpl();

  @override
  String toString() {
    return 'CartState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(Cart cart) loaded,
    required TResult Function(String? message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(Cart cart)? loaded,
    TResult? Function(String? message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(Cart cart)? loaded,
    TResult Function(String? message)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Error value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Error value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class _Loading implements CartState {
  const factory _Loading() = _$LoadingImpl;
}

/// @nodoc
abstract class _$$LoadedImplCopyWith<$Res> {
  factory _$$LoadedImplCopyWith(
          _$LoadedImpl value, $Res Function(_$LoadedImpl) then) =
      __$$LoadedImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Cart cart});
}

/// @nodoc
class __$$LoadedImplCopyWithImpl<$Res>
    extends _$CartStateCopyWithImpl<$Res, _$LoadedImpl>
    implements _$$LoadedImplCopyWith<$Res> {
  __$$LoadedImplCopyWithImpl(
      _$LoadedImpl _value, $Res Function(_$LoadedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cart = null,
  }) {
    return _then(_$LoadedImpl(
      null == cart
          ? _value.cart
          : cart // ignore: cast_nullable_to_non_nullable
              as Cart,
    ));
  }
}

/// @nodoc

class _$LoadedImpl implements _Loaded {
  const _$LoadedImpl(this.cart);

  @override
  final Cart cart;

  @override
  String toString() {
    return 'CartState.loaded(cart: $cart)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoadedImpl &&
            (identical(other.cart, cart) || other.cart == cart));
  }

  @override
  int get hashCode => Object.hash(runtimeType, cart);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LoadedImplCopyWith<_$LoadedImpl> get copyWith =>
      __$$LoadedImplCopyWithImpl<_$LoadedImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(Cart cart) loaded,
    required TResult Function(String? message) error,
  }) {
    return loaded(cart);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(Cart cart)? loaded,
    TResult? Function(String? message)? error,
  }) {
    return loaded?.call(cart);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(Cart cart)? loaded,
    TResult Function(String? message)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(cart);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Error value) error,
  }) {
    return loaded(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Error value)? error,
  }) {
    return loaded?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (loaded != null) {
      return loaded(this);
    }
    return orElse();
  }
}

abstract class _Loaded implements CartState {
  const factory _Loaded(final Cart cart) = _$LoadedImpl;

  Cart get cart;
  @JsonKey(ignore: true)
  _$$LoadedImplCopyWith<_$LoadedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ErrorImplCopyWith<$Res> {
  factory _$$ErrorImplCopyWith(
          _$ErrorImpl value, $Res Function(_$ErrorImpl) then) =
      __$$ErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String? message});
}

/// @nodoc
class __$$ErrorImplCopyWithImpl<$Res>
    extends _$CartStateCopyWithImpl<$Res, _$ErrorImpl>
    implements _$$ErrorImplCopyWith<$Res> {
  __$$ErrorImplCopyWithImpl(
      _$ErrorImpl _value, $Res Function(_$ErrorImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = freezed,
  }) {
    return _then(_$ErrorImpl(
      freezed == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ErrorImpl implements _Error {
  const _$ErrorImpl(this.message);

  @override
  final String? message;

  @override
  String toString() {
    return 'CartState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      __$$ErrorImplCopyWithImpl<_$ErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(Cart cart) loaded,
    required TResult Function(String? message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(Cart cart)? loaded,
    TResult? Function(String? message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(Cart cart)? loaded,
    TResult Function(String? message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Initial value) initial,
    required TResult Function(_Loading value) loading,
    required TResult Function(_Loaded value) loaded,
    required TResult Function(_Error value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Initial value)? initial,
    TResult? Function(_Loading value)? loading,
    TResult? Function(_Loaded value)? loaded,
    TResult? Function(_Error value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Initial value)? initial,
    TResult Function(_Loading value)? loading,
    TResult Function(_Loaded value)? loaded,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _Error implements CartState {
  const factory _Error(final String? message) = _$ErrorImpl;

  String? get message;
  @JsonKey(ignore: true)
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
