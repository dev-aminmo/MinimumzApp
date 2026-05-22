// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'authentication_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$AuthenticationEvent {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() init,
    required TResult Function(String email, String password) loginCustomer,
    required TResult Function() loginAsGuest,
    required TResult Function(
            String email, String password, String firstName, String lastName)
        signUpCustomer,
    required TResult Function() logoutCustomer,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? init,
    TResult? Function(String email, String password)? loginCustomer,
    TResult? Function()? loginAsGuest,
    TResult? Function(
            String email, String password, String firstName, String lastName)?
        signUpCustomer,
    TResult? Function()? logoutCustomer,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? init,
    TResult Function(String email, String password)? loginCustomer,
    TResult Function()? loginAsGuest,
    TResult Function(
            String email, String password, String firstName, String lastName)?
        signUpCustomer,
    TResult Function()? logoutCustomer,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Init value) init,
    required TResult Function(_LoginCustomer value) loginCustomer,
    required TResult Function(_LoginAsGuest value) loginAsGuest,
    required TResult Function(_SignUpCustomer value) signUpCustomer,
    required TResult Function(_LogoutCustomer value) logoutCustomer,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Init value)? init,
    TResult? Function(_LoginCustomer value)? loginCustomer,
    TResult? Function(_LoginAsGuest value)? loginAsGuest,
    TResult? Function(_SignUpCustomer value)? signUpCustomer,
    TResult? Function(_LogoutCustomer value)? logoutCustomer,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Init value)? init,
    TResult Function(_LoginCustomer value)? loginCustomer,
    TResult Function(_LoginAsGuest value)? loginAsGuest,
    TResult Function(_SignUpCustomer value)? signUpCustomer,
    TResult Function(_LogoutCustomer value)? logoutCustomer,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthenticationEventCopyWith<$Res> {
  factory $AuthenticationEventCopyWith(
          AuthenticationEvent value, $Res Function(AuthenticationEvent) then) =
      _$AuthenticationEventCopyWithImpl<$Res, AuthenticationEvent>;
}

/// @nodoc
class _$AuthenticationEventCopyWithImpl<$Res, $Val extends AuthenticationEvent>
    implements $AuthenticationEventCopyWith<$Res> {
  _$AuthenticationEventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$InitImplCopyWith<$Res> {
  factory _$$InitImplCopyWith(
          _$InitImpl value, $Res Function(_$InitImpl) then) =
      __$$InitImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$InitImplCopyWithImpl<$Res>
    extends _$AuthenticationEventCopyWithImpl<$Res, _$InitImpl>
    implements _$$InitImplCopyWith<$Res> {
  __$$InitImplCopyWithImpl(_$InitImpl _value, $Res Function(_$InitImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$InitImpl implements _Init {
  const _$InitImpl();

  @override
  String toString() {
    return 'AuthenticationEvent.init()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$InitImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() init,
    required TResult Function(String email, String password) loginCustomer,
    required TResult Function() loginAsGuest,
    required TResult Function(
            String email, String password, String firstName, String lastName)
        signUpCustomer,
    required TResult Function() logoutCustomer,
  }) {
    return init();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? init,
    TResult? Function(String email, String password)? loginCustomer,
    TResult? Function()? loginAsGuest,
    TResult? Function(
            String email, String password, String firstName, String lastName)?
        signUpCustomer,
    TResult? Function()? logoutCustomer,
  }) {
    return init?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? init,
    TResult Function(String email, String password)? loginCustomer,
    TResult Function()? loginAsGuest,
    TResult Function(
            String email, String password, String firstName, String lastName)?
        signUpCustomer,
    TResult Function()? logoutCustomer,
    required TResult orElse(),
  }) {
    if (init != null) {
      return init();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Init value) init,
    required TResult Function(_LoginCustomer value) loginCustomer,
    required TResult Function(_LoginAsGuest value) loginAsGuest,
    required TResult Function(_SignUpCustomer value) signUpCustomer,
    required TResult Function(_LogoutCustomer value) logoutCustomer,
  }) {
    return init(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Init value)? init,
    TResult? Function(_LoginCustomer value)? loginCustomer,
    TResult? Function(_LoginAsGuest value)? loginAsGuest,
    TResult? Function(_SignUpCustomer value)? signUpCustomer,
    TResult? Function(_LogoutCustomer value)? logoutCustomer,
  }) {
    return init?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Init value)? init,
    TResult Function(_LoginCustomer value)? loginCustomer,
    TResult Function(_LoginAsGuest value)? loginAsGuest,
    TResult Function(_SignUpCustomer value)? signUpCustomer,
    TResult Function(_LogoutCustomer value)? logoutCustomer,
    required TResult orElse(),
  }) {
    if (init != null) {
      return init(this);
    }
    return orElse();
  }
}

abstract class _Init implements AuthenticationEvent {
  const factory _Init() = _$InitImpl;
}

/// @nodoc
abstract class _$$LoginCustomerImplCopyWith<$Res> {
  factory _$$LoginCustomerImplCopyWith(
          _$LoginCustomerImpl value, $Res Function(_$LoginCustomerImpl) then) =
      __$$LoginCustomerImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String email, String password});
}

/// @nodoc
class __$$LoginCustomerImplCopyWithImpl<$Res>
    extends _$AuthenticationEventCopyWithImpl<$Res, _$LoginCustomerImpl>
    implements _$$LoginCustomerImplCopyWith<$Res> {
  __$$LoginCustomerImplCopyWithImpl(
      _$LoginCustomerImpl _value, $Res Function(_$LoginCustomerImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? email = null,
    Object? password = null,
  }) {
    return _then(_$LoginCustomerImpl(
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      password: null == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$LoginCustomerImpl implements _LoginCustomer {
  const _$LoginCustomerImpl({required this.email, required this.password});

  @override
  final String email;
  @override
  final String password;

  @override
  String toString() {
    return 'AuthenticationEvent.loginCustomer(email: $email, password: $password)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoginCustomerImpl &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.password, password) ||
                other.password == password));
  }

  @override
  int get hashCode => Object.hash(runtimeType, email, password);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LoginCustomerImplCopyWith<_$LoginCustomerImpl> get copyWith =>
      __$$LoginCustomerImplCopyWithImpl<_$LoginCustomerImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() init,
    required TResult Function(String email, String password) loginCustomer,
    required TResult Function() loginAsGuest,
    required TResult Function(
            String email, String password, String firstName, String lastName)
        signUpCustomer,
    required TResult Function() logoutCustomer,
  }) {
    return loginCustomer(email, password);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? init,
    TResult? Function(String email, String password)? loginCustomer,
    TResult? Function()? loginAsGuest,
    TResult? Function(
            String email, String password, String firstName, String lastName)?
        signUpCustomer,
    TResult? Function()? logoutCustomer,
  }) {
    return loginCustomer?.call(email, password);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? init,
    TResult Function(String email, String password)? loginCustomer,
    TResult Function()? loginAsGuest,
    TResult Function(
            String email, String password, String firstName, String lastName)?
        signUpCustomer,
    TResult Function()? logoutCustomer,
    required TResult orElse(),
  }) {
    if (loginCustomer != null) {
      return loginCustomer(email, password);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Init value) init,
    required TResult Function(_LoginCustomer value) loginCustomer,
    required TResult Function(_LoginAsGuest value) loginAsGuest,
    required TResult Function(_SignUpCustomer value) signUpCustomer,
    required TResult Function(_LogoutCustomer value) logoutCustomer,
  }) {
    return loginCustomer(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Init value)? init,
    TResult? Function(_LoginCustomer value)? loginCustomer,
    TResult? Function(_LoginAsGuest value)? loginAsGuest,
    TResult? Function(_SignUpCustomer value)? signUpCustomer,
    TResult? Function(_LogoutCustomer value)? logoutCustomer,
  }) {
    return loginCustomer?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Init value)? init,
    TResult Function(_LoginCustomer value)? loginCustomer,
    TResult Function(_LoginAsGuest value)? loginAsGuest,
    TResult Function(_SignUpCustomer value)? signUpCustomer,
    TResult Function(_LogoutCustomer value)? logoutCustomer,
    required TResult orElse(),
  }) {
    if (loginCustomer != null) {
      return loginCustomer(this);
    }
    return orElse();
  }
}

abstract class _LoginCustomer implements AuthenticationEvent {
  const factory _LoginCustomer(
      {required final String email,
      required final String password}) = _$LoginCustomerImpl;

  String get email;
  String get password;
  @JsonKey(ignore: true)
  _$$LoginCustomerImplCopyWith<_$LoginCustomerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LoginAsGuestImplCopyWith<$Res> {
  factory _$$LoginAsGuestImplCopyWith(
          _$LoginAsGuestImpl value, $Res Function(_$LoginAsGuestImpl) then) =
      __$$LoginAsGuestImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoginAsGuestImplCopyWithImpl<$Res>
    extends _$AuthenticationEventCopyWithImpl<$Res, _$LoginAsGuestImpl>
    implements _$$LoginAsGuestImplCopyWith<$Res> {
  __$$LoginAsGuestImplCopyWithImpl(
      _$LoginAsGuestImpl _value, $Res Function(_$LoginAsGuestImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$LoginAsGuestImpl implements _LoginAsGuest {
  const _$LoginAsGuestImpl();

  @override
  String toString() {
    return 'AuthenticationEvent.loginAsGuest()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LoginAsGuestImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() init,
    required TResult Function(String email, String password) loginCustomer,
    required TResult Function() loginAsGuest,
    required TResult Function(
            String email, String password, String firstName, String lastName)
        signUpCustomer,
    required TResult Function() logoutCustomer,
  }) {
    return loginAsGuest();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? init,
    TResult? Function(String email, String password)? loginCustomer,
    TResult? Function()? loginAsGuest,
    TResult? Function(
            String email, String password, String firstName, String lastName)?
        signUpCustomer,
    TResult? Function()? logoutCustomer,
  }) {
    return loginAsGuest?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? init,
    TResult Function(String email, String password)? loginCustomer,
    TResult Function()? loginAsGuest,
    TResult Function(
            String email, String password, String firstName, String lastName)?
        signUpCustomer,
    TResult Function()? logoutCustomer,
    required TResult orElse(),
  }) {
    if (loginAsGuest != null) {
      return loginAsGuest();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Init value) init,
    required TResult Function(_LoginCustomer value) loginCustomer,
    required TResult Function(_LoginAsGuest value) loginAsGuest,
    required TResult Function(_SignUpCustomer value) signUpCustomer,
    required TResult Function(_LogoutCustomer value) logoutCustomer,
  }) {
    return loginAsGuest(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Init value)? init,
    TResult? Function(_LoginCustomer value)? loginCustomer,
    TResult? Function(_LoginAsGuest value)? loginAsGuest,
    TResult? Function(_SignUpCustomer value)? signUpCustomer,
    TResult? Function(_LogoutCustomer value)? logoutCustomer,
  }) {
    return loginAsGuest?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Init value)? init,
    TResult Function(_LoginCustomer value)? loginCustomer,
    TResult Function(_LoginAsGuest value)? loginAsGuest,
    TResult Function(_SignUpCustomer value)? signUpCustomer,
    TResult Function(_LogoutCustomer value)? logoutCustomer,
    required TResult orElse(),
  }) {
    if (loginAsGuest != null) {
      return loginAsGuest(this);
    }
    return orElse();
  }
}

abstract class _LoginAsGuest implements AuthenticationEvent {
  const factory _LoginAsGuest() = _$LoginAsGuestImpl;
}

/// @nodoc
abstract class _$$SignUpCustomerImplCopyWith<$Res> {
  factory _$$SignUpCustomerImplCopyWith(_$SignUpCustomerImpl value,
          $Res Function(_$SignUpCustomerImpl) then) =
      __$$SignUpCustomerImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String email, String password, String firstName, String lastName});
}

/// @nodoc
class __$$SignUpCustomerImplCopyWithImpl<$Res>
    extends _$AuthenticationEventCopyWithImpl<$Res, _$SignUpCustomerImpl>
    implements _$$SignUpCustomerImplCopyWith<$Res> {
  __$$SignUpCustomerImplCopyWithImpl(
      _$SignUpCustomerImpl _value, $Res Function(_$SignUpCustomerImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? email = null,
    Object? password = null,
    Object? firstName = null,
    Object? lastName = null,
  }) {
    return _then(_$SignUpCustomerImpl(
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      password: null == password
          ? _value.password
          : password // ignore: cast_nullable_to_non_nullable
              as String,
      firstName: null == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String,
      lastName: null == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc

class _$SignUpCustomerImpl implements _SignUpCustomer {
  const _$SignUpCustomerImpl(
      {required this.email,
      required this.password,
      required this.firstName,
      required this.lastName});

  @override
  final String email;
  @override
  final String password;
  @override
  final String firstName;
  @override
  final String lastName;

  @override
  String toString() {
    return 'AuthenticationEvent.signUpCustomer(email: $email, password: $password, firstName: $firstName, lastName: $lastName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SignUpCustomerImpl &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.password, password) ||
                other.password == password) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, email, password, firstName, lastName);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SignUpCustomerImplCopyWith<_$SignUpCustomerImpl> get copyWith =>
      __$$SignUpCustomerImplCopyWithImpl<_$SignUpCustomerImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() init,
    required TResult Function(String email, String password) loginCustomer,
    required TResult Function() loginAsGuest,
    required TResult Function(
            String email, String password, String firstName, String lastName)
        signUpCustomer,
    required TResult Function() logoutCustomer,
  }) {
    return signUpCustomer(email, password, firstName, lastName);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? init,
    TResult? Function(String email, String password)? loginCustomer,
    TResult? Function()? loginAsGuest,
    TResult? Function(
            String email, String password, String firstName, String lastName)?
        signUpCustomer,
    TResult? Function()? logoutCustomer,
  }) {
    return signUpCustomer?.call(email, password, firstName, lastName);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? init,
    TResult Function(String email, String password)? loginCustomer,
    TResult Function()? loginAsGuest,
    TResult Function(
            String email, String password, String firstName, String lastName)?
        signUpCustomer,
    TResult Function()? logoutCustomer,
    required TResult orElse(),
  }) {
    if (signUpCustomer != null) {
      return signUpCustomer(email, password, firstName, lastName);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Init value) init,
    required TResult Function(_LoginCustomer value) loginCustomer,
    required TResult Function(_LoginAsGuest value) loginAsGuest,
    required TResult Function(_SignUpCustomer value) signUpCustomer,
    required TResult Function(_LogoutCustomer value) logoutCustomer,
  }) {
    return signUpCustomer(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Init value)? init,
    TResult? Function(_LoginCustomer value)? loginCustomer,
    TResult? Function(_LoginAsGuest value)? loginAsGuest,
    TResult? Function(_SignUpCustomer value)? signUpCustomer,
    TResult? Function(_LogoutCustomer value)? logoutCustomer,
  }) {
    return signUpCustomer?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Init value)? init,
    TResult Function(_LoginCustomer value)? loginCustomer,
    TResult Function(_LoginAsGuest value)? loginAsGuest,
    TResult Function(_SignUpCustomer value)? signUpCustomer,
    TResult Function(_LogoutCustomer value)? logoutCustomer,
    required TResult orElse(),
  }) {
    if (signUpCustomer != null) {
      return signUpCustomer(this);
    }
    return orElse();
  }
}

abstract class _SignUpCustomer implements AuthenticationEvent {
  const factory _SignUpCustomer(
      {required final String email,
      required final String password,
      required final String firstName,
      required final String lastName}) = _$SignUpCustomerImpl;

  String get email;
  String get password;
  String get firstName;
  String get lastName;
  @JsonKey(ignore: true)
  _$$SignUpCustomerImplCopyWith<_$SignUpCustomerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LogoutCustomerImplCopyWith<$Res> {
  factory _$$LogoutCustomerImplCopyWith(_$LogoutCustomerImpl value,
          $Res Function(_$LogoutCustomerImpl) then) =
      __$$LogoutCustomerImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LogoutCustomerImplCopyWithImpl<$Res>
    extends _$AuthenticationEventCopyWithImpl<$Res, _$LogoutCustomerImpl>
    implements _$$LogoutCustomerImplCopyWith<$Res> {
  __$$LogoutCustomerImplCopyWithImpl(
      _$LogoutCustomerImpl _value, $Res Function(_$LogoutCustomerImpl) _then)
      : super(_value, _then);
}

/// @nodoc

class _$LogoutCustomerImpl implements _LogoutCustomer {
  const _$LogoutCustomerImpl();

  @override
  String toString() {
    return 'AuthenticationEvent.logoutCustomer()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$LogoutCustomerImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() init,
    required TResult Function(String email, String password) loginCustomer,
    required TResult Function() loginAsGuest,
    required TResult Function(
            String email, String password, String firstName, String lastName)
        signUpCustomer,
    required TResult Function() logoutCustomer,
  }) {
    return logoutCustomer();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? init,
    TResult? Function(String email, String password)? loginCustomer,
    TResult? Function()? loginAsGuest,
    TResult? Function(
            String email, String password, String firstName, String lastName)?
        signUpCustomer,
    TResult? Function()? logoutCustomer,
  }) {
    return logoutCustomer?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? init,
    TResult Function(String email, String password)? loginCustomer,
    TResult Function()? loginAsGuest,
    TResult Function(
            String email, String password, String firstName, String lastName)?
        signUpCustomer,
    TResult Function()? logoutCustomer,
    required TResult orElse(),
  }) {
    if (logoutCustomer != null) {
      return logoutCustomer();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Init value) init,
    required TResult Function(_LoginCustomer value) loginCustomer,
    required TResult Function(_LoginAsGuest value) loginAsGuest,
    required TResult Function(_SignUpCustomer value) signUpCustomer,
    required TResult Function(_LogoutCustomer value) logoutCustomer,
  }) {
    return logoutCustomer(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Init value)? init,
    TResult? Function(_LoginCustomer value)? loginCustomer,
    TResult? Function(_LoginAsGuest value)? loginAsGuest,
    TResult? Function(_SignUpCustomer value)? signUpCustomer,
    TResult? Function(_LogoutCustomer value)? logoutCustomer,
  }) {
    return logoutCustomer?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Init value)? init,
    TResult Function(_LoginCustomer value)? loginCustomer,
    TResult Function(_LoginAsGuest value)? loginAsGuest,
    TResult Function(_SignUpCustomer value)? signUpCustomer,
    TResult Function(_LogoutCustomer value)? logoutCustomer,
    required TResult orElse(),
  }) {
    if (logoutCustomer != null) {
      return logoutCustomer(this);
    }
    return orElse();
  }
}

abstract class _LogoutCustomer implements AuthenticationEvent {
  const factory _LogoutCustomer() = _$LogoutCustomerImpl;
}

/// @nodoc
mixin _$AuthenticationState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(Failure? failure) loggedInAsGuest,
    required TResult Function(Failure? failure) loggedOut,
    required TResult Function(Customer customer) loggedIn,
    required TResult Function(Failure failure) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(Failure? failure)? loggedInAsGuest,
    TResult? Function(Failure? failure)? loggedOut,
    TResult? Function(Customer customer)? loggedIn,
    TResult? Function(Failure failure)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(Failure? failure)? loggedInAsGuest,
    TResult Function(Failure? failure)? loggedOut,
    TResult Function(Customer customer)? loggedIn,
    TResult Function(Failure failure)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Loading value) loading,
    required TResult Function(_LoggedInAsGuest value) loggedInAsGuest,
    required TResult Function(_LoggedOut value) loggedOut,
    required TResult Function(_LoggedIn value) loggedIn,
    required TResult Function(_Error value) error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Loading value)? loading,
    TResult? Function(_LoggedInAsGuest value)? loggedInAsGuest,
    TResult? Function(_LoggedOut value)? loggedOut,
    TResult? Function(_LoggedIn value)? loggedIn,
    TResult? Function(_Error value)? error,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Loading value)? loading,
    TResult Function(_LoggedInAsGuest value)? loggedInAsGuest,
    TResult Function(_LoggedOut value)? loggedOut,
    TResult Function(_LoggedIn value)? loggedIn,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthenticationStateCopyWith<$Res> {
  factory $AuthenticationStateCopyWith(
          AuthenticationState value, $Res Function(AuthenticationState) then) =
      _$AuthenticationStateCopyWithImpl<$Res, AuthenticationState>;
}

/// @nodoc
class _$AuthenticationStateCopyWithImpl<$Res, $Val extends AuthenticationState>
    implements $AuthenticationStateCopyWith<$Res> {
  _$AuthenticationStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$LoadingImplCopyWith<$Res> {
  factory _$$LoadingImplCopyWith(
          _$LoadingImpl value, $Res Function(_$LoadingImpl) then) =
      __$$LoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$LoadingImplCopyWithImpl<$Res>
    extends _$AuthenticationStateCopyWithImpl<$Res, _$LoadingImpl>
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
    return 'AuthenticationState.loading()';
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
    required TResult Function() loading,
    required TResult Function(Failure? failure) loggedInAsGuest,
    required TResult Function(Failure? failure) loggedOut,
    required TResult Function(Customer customer) loggedIn,
    required TResult Function(Failure failure) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(Failure? failure)? loggedInAsGuest,
    TResult? Function(Failure? failure)? loggedOut,
    TResult? Function(Customer customer)? loggedIn,
    TResult? Function(Failure failure)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(Failure? failure)? loggedInAsGuest,
    TResult Function(Failure? failure)? loggedOut,
    TResult Function(Customer customer)? loggedIn,
    TResult Function(Failure failure)? error,
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
    required TResult Function(_Loading value) loading,
    required TResult Function(_LoggedInAsGuest value) loggedInAsGuest,
    required TResult Function(_LoggedOut value) loggedOut,
    required TResult Function(_LoggedIn value) loggedIn,
    required TResult Function(_Error value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Loading value)? loading,
    TResult? Function(_LoggedInAsGuest value)? loggedInAsGuest,
    TResult? Function(_LoggedOut value)? loggedOut,
    TResult? Function(_LoggedIn value)? loggedIn,
    TResult? Function(_Error value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Loading value)? loading,
    TResult Function(_LoggedInAsGuest value)? loggedInAsGuest,
    TResult Function(_LoggedOut value)? loggedOut,
    TResult Function(_LoggedIn value)? loggedIn,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class _Loading implements AuthenticationState {
  const factory _Loading() = _$LoadingImpl;
}

/// @nodoc
abstract class _$$LoggedInAsGuestImplCopyWith<$Res> {
  factory _$$LoggedInAsGuestImplCopyWith(_$LoggedInAsGuestImpl value,
          $Res Function(_$LoggedInAsGuestImpl) then) =
      __$$LoggedInAsGuestImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Failure? failure});
}

/// @nodoc
class __$$LoggedInAsGuestImplCopyWithImpl<$Res>
    extends _$AuthenticationStateCopyWithImpl<$Res, _$LoggedInAsGuestImpl>
    implements _$$LoggedInAsGuestImplCopyWith<$Res> {
  __$$LoggedInAsGuestImplCopyWithImpl(
      _$LoggedInAsGuestImpl _value, $Res Function(_$LoggedInAsGuestImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? failure = freezed,
  }) {
    return _then(_$LoggedInAsGuestImpl(
      failure: freezed == failure
          ? _value.failure
          : failure // ignore: cast_nullable_to_non_nullable
              as Failure?,
    ));
  }
}

/// @nodoc

class _$LoggedInAsGuestImpl implements _LoggedInAsGuest {
  const _$LoggedInAsGuestImpl({this.failure});

  @override
  final Failure? failure;

  @override
  String toString() {
    return 'AuthenticationState.loggedInAsGuest(failure: $failure)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoggedInAsGuestImpl &&
            (identical(other.failure, failure) || other.failure == failure));
  }

  @override
  int get hashCode => Object.hash(runtimeType, failure);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LoggedInAsGuestImplCopyWith<_$LoggedInAsGuestImpl> get copyWith =>
      __$$LoggedInAsGuestImplCopyWithImpl<_$LoggedInAsGuestImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(Failure? failure) loggedInAsGuest,
    required TResult Function(Failure? failure) loggedOut,
    required TResult Function(Customer customer) loggedIn,
    required TResult Function(Failure failure) error,
  }) {
    return loggedInAsGuest(failure);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(Failure? failure)? loggedInAsGuest,
    TResult? Function(Failure? failure)? loggedOut,
    TResult? Function(Customer customer)? loggedIn,
    TResult? Function(Failure failure)? error,
  }) {
    return loggedInAsGuest?.call(failure);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(Failure? failure)? loggedInAsGuest,
    TResult Function(Failure? failure)? loggedOut,
    TResult Function(Customer customer)? loggedIn,
    TResult Function(Failure failure)? error,
    required TResult orElse(),
  }) {
    if (loggedInAsGuest != null) {
      return loggedInAsGuest(failure);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Loading value) loading,
    required TResult Function(_LoggedInAsGuest value) loggedInAsGuest,
    required TResult Function(_LoggedOut value) loggedOut,
    required TResult Function(_LoggedIn value) loggedIn,
    required TResult Function(_Error value) error,
  }) {
    return loggedInAsGuest(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Loading value)? loading,
    TResult? Function(_LoggedInAsGuest value)? loggedInAsGuest,
    TResult? Function(_LoggedOut value)? loggedOut,
    TResult? Function(_LoggedIn value)? loggedIn,
    TResult? Function(_Error value)? error,
  }) {
    return loggedInAsGuest?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Loading value)? loading,
    TResult Function(_LoggedInAsGuest value)? loggedInAsGuest,
    TResult Function(_LoggedOut value)? loggedOut,
    TResult Function(_LoggedIn value)? loggedIn,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (loggedInAsGuest != null) {
      return loggedInAsGuest(this);
    }
    return orElse();
  }
}

abstract class _LoggedInAsGuest implements AuthenticationState {
  const factory _LoggedInAsGuest({final Failure? failure}) =
      _$LoggedInAsGuestImpl;

  Failure? get failure;
  @JsonKey(ignore: true)
  _$$LoggedInAsGuestImplCopyWith<_$LoggedInAsGuestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LoggedOutImplCopyWith<$Res> {
  factory _$$LoggedOutImplCopyWith(
          _$LoggedOutImpl value, $Res Function(_$LoggedOutImpl) then) =
      __$$LoggedOutImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Failure? failure});
}

/// @nodoc
class __$$LoggedOutImplCopyWithImpl<$Res>
    extends _$AuthenticationStateCopyWithImpl<$Res, _$LoggedOutImpl>
    implements _$$LoggedOutImplCopyWith<$Res> {
  __$$LoggedOutImplCopyWithImpl(
      _$LoggedOutImpl _value, $Res Function(_$LoggedOutImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? failure = freezed,
  }) {
    return _then(_$LoggedOutImpl(
      failure: freezed == failure
          ? _value.failure
          : failure // ignore: cast_nullable_to_non_nullable
              as Failure?,
    ));
  }
}

/// @nodoc

class _$LoggedOutImpl implements _LoggedOut {
  const _$LoggedOutImpl({this.failure});

  @override
  final Failure? failure;

  @override
  String toString() {
    return 'AuthenticationState.loggedOut(failure: $failure)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoggedOutImpl &&
            (identical(other.failure, failure) || other.failure == failure));
  }

  @override
  int get hashCode => Object.hash(runtimeType, failure);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LoggedOutImplCopyWith<_$LoggedOutImpl> get copyWith =>
      __$$LoggedOutImplCopyWithImpl<_$LoggedOutImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(Failure? failure) loggedInAsGuest,
    required TResult Function(Failure? failure) loggedOut,
    required TResult Function(Customer customer) loggedIn,
    required TResult Function(Failure failure) error,
  }) {
    return loggedOut(failure);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(Failure? failure)? loggedInAsGuest,
    TResult? Function(Failure? failure)? loggedOut,
    TResult? Function(Customer customer)? loggedIn,
    TResult? Function(Failure failure)? error,
  }) {
    return loggedOut?.call(failure);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(Failure? failure)? loggedInAsGuest,
    TResult Function(Failure? failure)? loggedOut,
    TResult Function(Customer customer)? loggedIn,
    TResult Function(Failure failure)? error,
    required TResult orElse(),
  }) {
    if (loggedOut != null) {
      return loggedOut(failure);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Loading value) loading,
    required TResult Function(_LoggedInAsGuest value) loggedInAsGuest,
    required TResult Function(_LoggedOut value) loggedOut,
    required TResult Function(_LoggedIn value) loggedIn,
    required TResult Function(_Error value) error,
  }) {
    return loggedOut(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Loading value)? loading,
    TResult? Function(_LoggedInAsGuest value)? loggedInAsGuest,
    TResult? Function(_LoggedOut value)? loggedOut,
    TResult? Function(_LoggedIn value)? loggedIn,
    TResult? Function(_Error value)? error,
  }) {
    return loggedOut?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Loading value)? loading,
    TResult Function(_LoggedInAsGuest value)? loggedInAsGuest,
    TResult Function(_LoggedOut value)? loggedOut,
    TResult Function(_LoggedIn value)? loggedIn,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (loggedOut != null) {
      return loggedOut(this);
    }
    return orElse();
  }
}

abstract class _LoggedOut implements AuthenticationState {
  const factory _LoggedOut({final Failure? failure}) = _$LoggedOutImpl;

  Failure? get failure;
  @JsonKey(ignore: true)
  _$$LoggedOutImplCopyWith<_$LoggedOutImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$LoggedInImplCopyWith<$Res> {
  factory _$$LoggedInImplCopyWith(
          _$LoggedInImpl value, $Res Function(_$LoggedInImpl) then) =
      __$$LoggedInImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Customer customer});
}

/// @nodoc
class __$$LoggedInImplCopyWithImpl<$Res>
    extends _$AuthenticationStateCopyWithImpl<$Res, _$LoggedInImpl>
    implements _$$LoggedInImplCopyWith<$Res> {
  __$$LoggedInImplCopyWithImpl(
      _$LoggedInImpl _value, $Res Function(_$LoggedInImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? customer = null,
  }) {
    return _then(_$LoggedInImpl(
      null == customer
          ? _value.customer
          : customer // ignore: cast_nullable_to_non_nullable
              as Customer,
    ));
  }
}

/// @nodoc

class _$LoggedInImpl implements _LoggedIn {
  const _$LoggedInImpl(this.customer);

  @override
  final Customer customer;

  @override
  String toString() {
    return 'AuthenticationState.loggedIn(customer: $customer)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LoggedInImpl &&
            (identical(other.customer, customer) ||
                other.customer == customer));
  }

  @override
  int get hashCode => Object.hash(runtimeType, customer);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$LoggedInImplCopyWith<_$LoggedInImpl> get copyWith =>
      __$$LoggedInImplCopyWithImpl<_$LoggedInImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(Failure? failure) loggedInAsGuest,
    required TResult Function(Failure? failure) loggedOut,
    required TResult Function(Customer customer) loggedIn,
    required TResult Function(Failure failure) error,
  }) {
    return loggedIn(customer);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(Failure? failure)? loggedInAsGuest,
    TResult? Function(Failure? failure)? loggedOut,
    TResult? Function(Customer customer)? loggedIn,
    TResult? Function(Failure failure)? error,
  }) {
    return loggedIn?.call(customer);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(Failure? failure)? loggedInAsGuest,
    TResult Function(Failure? failure)? loggedOut,
    TResult Function(Customer customer)? loggedIn,
    TResult Function(Failure failure)? error,
    required TResult orElse(),
  }) {
    if (loggedIn != null) {
      return loggedIn(customer);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Loading value) loading,
    required TResult Function(_LoggedInAsGuest value) loggedInAsGuest,
    required TResult Function(_LoggedOut value) loggedOut,
    required TResult Function(_LoggedIn value) loggedIn,
    required TResult Function(_Error value) error,
  }) {
    return loggedIn(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Loading value)? loading,
    TResult? Function(_LoggedInAsGuest value)? loggedInAsGuest,
    TResult? Function(_LoggedOut value)? loggedOut,
    TResult? Function(_LoggedIn value)? loggedIn,
    TResult? Function(_Error value)? error,
  }) {
    return loggedIn?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Loading value)? loading,
    TResult Function(_LoggedInAsGuest value)? loggedInAsGuest,
    TResult Function(_LoggedOut value)? loggedOut,
    TResult Function(_LoggedIn value)? loggedIn,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (loggedIn != null) {
      return loggedIn(this);
    }
    return orElse();
  }
}

abstract class _LoggedIn implements AuthenticationState {
  const factory _LoggedIn(final Customer customer) = _$LoggedInImpl;

  Customer get customer;
  @JsonKey(ignore: true)
  _$$LoggedInImplCopyWith<_$LoggedInImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ErrorImplCopyWith<$Res> {
  factory _$$ErrorImplCopyWith(
          _$ErrorImpl value, $Res Function(_$ErrorImpl) then) =
      __$$ErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Failure failure});
}

/// @nodoc
class __$$ErrorImplCopyWithImpl<$Res>
    extends _$AuthenticationStateCopyWithImpl<$Res, _$ErrorImpl>
    implements _$$ErrorImplCopyWith<$Res> {
  __$$ErrorImplCopyWithImpl(
      _$ErrorImpl _value, $Res Function(_$ErrorImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? failure = null,
  }) {
    return _then(_$ErrorImpl(
      null == failure
          ? _value.failure
          : failure // ignore: cast_nullable_to_non_nullable
              as Failure,
    ));
  }
}

/// @nodoc

class _$ErrorImpl implements _Error {
  const _$ErrorImpl(this.failure);

  @override
  final Failure failure;

  @override
  String toString() {
    return 'AuthenticationState.error(failure: $failure)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ErrorImpl &&
            (identical(other.failure, failure) || other.failure == failure));
  }

  @override
  int get hashCode => Object.hash(runtimeType, failure);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      __$$ErrorImplCopyWithImpl<_$ErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() loading,
    required TResult Function(Failure? failure) loggedInAsGuest,
    required TResult Function(Failure? failure) loggedOut,
    required TResult Function(Customer customer) loggedIn,
    required TResult Function(Failure failure) error,
  }) {
    return error(failure);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? loading,
    TResult? Function(Failure? failure)? loggedInAsGuest,
    TResult? Function(Failure? failure)? loggedOut,
    TResult? Function(Customer customer)? loggedIn,
    TResult? Function(Failure failure)? error,
  }) {
    return error?.call(failure);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? loading,
    TResult Function(Failure? failure)? loggedInAsGuest,
    TResult Function(Failure? failure)? loggedOut,
    TResult Function(Customer customer)? loggedIn,
    TResult Function(Failure failure)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(failure);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Loading value) loading,
    required TResult Function(_LoggedInAsGuest value) loggedInAsGuest,
    required TResult Function(_LoggedOut value) loggedOut,
    required TResult Function(_LoggedIn value) loggedIn,
    required TResult Function(_Error value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Loading value)? loading,
    TResult? Function(_LoggedInAsGuest value)? loggedInAsGuest,
    TResult? Function(_LoggedOut value)? loggedOut,
    TResult? Function(_LoggedIn value)? loggedIn,
    TResult? Function(_Error value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Loading value)? loading,
    TResult Function(_LoggedInAsGuest value)? loggedInAsGuest,
    TResult Function(_LoggedOut value)? loggedOut,
    TResult Function(_LoggedIn value)? loggedIn,
    TResult Function(_Error value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class _Error implements AuthenticationState {
  const factory _Error(final Failure failure) = _$ErrorImpl;

  Failure get failure;
  @JsonKey(ignore: true)
  _$$ErrorImplCopyWith<_$ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
