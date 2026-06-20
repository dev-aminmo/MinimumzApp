import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:minimumz/domain/model/failure.dart';
import 'package:minimumz/domain/usecase/auth_usecase.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/services/notification_service.dart';

import '../../di/di.dart';
import '../../domain/repository/preference_repository.dart';

part 'authentication_event.dart';
part 'authentication_state.dart';
part 'authentication_bloc.freezed.dart';

@injectable
class AuthenticationBloc
    extends Bloc<AuthenticationEvent, AuthenticationState> {
  static AuthenticationBloc get instance => getIt<AuthenticationBloc>();
  AuthenticationBloc(this._authUsecase) : super(const _Loading()) {
    on<_Init>(_onInitialize);
    on<_LoginCustomer>(_onLogin);
    on<_LogoutCustomer>(_onLogout);
    on<_SignUpCustomer>(_onSignUp);
    on<_LoginAsGuest>(_onLoginAsGuest);
    add(const _Init());
  }

  Future<void> _onInitialize(
    _Init event,
    Emitter<AuthenticationState> emit,
  ) async {
    try {
      final prefs = getIt<PreferenceRepository>();

      if (prefs.isGuest) {
        emit(const _LoggedInAsGuest());
        return;
      }

      final hasToken = prefs.cookie?.isNotEmpty == true;
      if (!hasToken) {
        emit(const _LoggedOut());
        return;
      }

      final result = await _authUsecase.getCurrentCustomer();
      result.when((customer) {
        _storeCurrencyCode(customer);
        // A confirmed customer session is never a guest. Clear the flag so
        // wishlist/search sync works even if the user started as a guest and
        // later signed in (and on every session restore).
        PreferenceRepository.instance.setGuest(value: false);
        emit(_LoggedIn(customer));
        // Returning users restore their session here (no fresh login), so
        // re-register the FCM token — it may be new, rotated, or never sent.
        NotificationService.instance.registerToken();
      }, (error) {
        if (error.code == 401) {
          emit(const _LoggedOut());
        } else {
          emit(_Error(error));
        }
      });
    } catch (_) {
      emit(const _LoggedOut());
    }
  }

  Future<void> _onLogin(
    _LoginCustomer event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(const _Loading());
    final jwt = await _authUsecase.loginJWT(
        email: event.email, password: event.password);
    await jwt.when((jwt) async {
      await PreferenceRepository.instance.setCookie(jwt);
      final result = await _authUsecase.getCurrentCustomer();
      result.when((customer) {
        _storeCurrencyCode(customer);
        PreferenceRepository.instance.setGuest(value: false);
        emit(_LoggedIn(customer));
        NotificationService.instance.registerToken();
      }, (error) {
        final isGuest = PreferenceRepository.instance.isGuest;
        if (isGuest) {
          emit(_LoggedInAsGuest(failure: error));
        } else {
          emit(_LoggedOut(failure: error));
        }
      });
    }, (error) {
      final isGuest = PreferenceRepository.instance.isGuest;
      if (isGuest) {
        emit(_LoggedInAsGuest(failure: error));
      } else {
        emit(_LoggedOut(failure: error));
      }
    });
  }

  Future<void> _onLogout(
    _LogoutCustomer event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(const _Loading());
    // Unregister this device from the account while the session is still valid,
    // so a later login (e.g. a different user on this device) doesn't inherit it.
    await NotificationService.instance.clearToken();
    final result = await _authUsecase.logoutCustomer();
    if (result) {
      await getIt<PreferenceRepository>().clearUserSessionData();
      emit(const _LoggedOut());
    } else {
      emit(_Error(Failure(message: 'Error signing out')));
    }
  }

  void _storeCurrencyCode(Customer customer) {
    // Only apply the account's currency when no country has been explicitly
    // selected by the user. If the user picked Bahrain, we keep BHD.
    if (PreferenceRepository.instance.country != null) return;
    final code = customer.currencyCode;
    if (code != null && code.isNotEmpty) {
      PreferenceRepository.instance.setCurrencyCode(code);
    }
  }

  Future<void> _onSignUp(
    _SignUpCustomer event,
    Emitter<AuthenticationState> emit,
  ) async {
    emit(const _Loading());
    final result = await _authUsecase.signUp(
        email: event.email,
        password: event.password,
        firstName: event.firstName,
        lastName: event.lastName,
        phone: '');
    result.when((customer) {
      _storeCurrencyCode(customer);
      PreferenceRepository.instance.setGuest(value: false);
      emit(_LoggedIn(customer));
      NotificationService.instance.registerToken();
    }, (error) {
      final isGuest = getIt<PreferenceRepository>().isGuest;
      if (isGuest) {
        emit(_LoggedInAsGuest(failure: error));
      } else {
        emit(_LoggedOut(failure: error));
      }
    });
  }

  Future<void> _onLoginAsGuest(
    _LoginAsGuest event,
    Emitter<AuthenticationState> emit,
  ) async {
    getIt<PreferenceRepository>().setGuest();
    emit(const _LoggedInAsGuest());
  }

  final AuthenticationUsecase _authUsecase;
}
