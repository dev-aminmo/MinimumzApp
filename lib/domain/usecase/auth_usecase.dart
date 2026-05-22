import 'package:injectable/injectable.dart';
import 'package:minimumz/domain/model/failure.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';
import 'package:multiple_result/multiple_result.dart';
import 'dart:developer';

import '../../di/di.dart';

@injectable
class AuthenticationUsecase {
  Future<Result<Customer, Failure>> login({required String email, required String password}) async {
    try {
      final authResource = getIt<DataStore>().auth;
      final result = await authResource.authenticate(req: StoreAuthRequest(email: email, password: password));

      if (result?.customer == null) {
        return Error(Failure(message: 'Received customer is null'));
      } else {
        return Success(result!.customer!);
      }
    } catch (e, stack) {
      log(stack.toString());
      log(e.toString());
      return Error(Failure.from(e));
    }
  }
  Future<Result<String, Failure>> loginJWT({required String email, required String password}) async {
    try {
      final authResource = getIt<DataStore>().auth;
      final result = await authResource.authenticateJWT(req: StoreAuthRequest(email: email, password: password));

      if (result == null) {
        return Error(Failure(message: 'Received jwt is null'));
      } else {
        return Success(result);
      }
    } catch (e, stack) {
      log(stack.toString());
      log(e.toString());
      return Error(Failure.from(e));
    }
  }

  Future<Result<Customer, Failure>> signUp(
      {required String email,
      required String password,
      required String firstName,
      required String lastName,
      required String phone}) async {
    try {
      final authResource = getIt<DataStore>().customers;
      final result = await authResource.create(
          req: StorePostCustomersReq(
              email: email, password: password, firstName: firstName, lastName: lastName, phone: phone));

      if (result?.customer == null) {
        return Error(Failure(message: 'Error, received customer is null'));
      }

      // Registration also returns a token — store it so the user is logged in immediately
      if (result!.accessToken != null) {
        await PreferenceRepository.instance.setCookie(result.accessToken!);
      }

      return Success(result.customer!);
    } on Exception catch (e) {
      log(e.toString());
      return Error(Failure.from(e));
    }
  }

  Future<bool> logoutCustomer() async {
    try {
      final authResource = getIt<DataStore>().auth;
      await authResource.logout();
      return true;
    } on Exception catch (e) {
      log(e.toString());
      return false;
    }
  }

  Future<Result<Customer, Failure>> getCurrentCustomer() async {
    try {
      final authResource = getIt<DataStore>().auth;
      final result = await authResource.getCurrentSession();
      if (result?.customer == null) {
        return Error(Failure(message: 'Received customer is null'));
      } else {
        return Success(result!.customer!);
      }
    } catch (e, stack) {
      log(stack.toString());
      log(e.toString());
      return Error(Failure.from(e));
    }
  }

}
