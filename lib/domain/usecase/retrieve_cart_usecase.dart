import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/model/failure.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';
import 'package:minimumz/data/data.dart';
import 'package:multiple_result/multiple_result.dart';


@injectable
class RetrieveCartUsecase {
  Future<Result<Cart, Failure>> call() async {
    try {
      final storeApi = getIt<DataStore>();
      final prefRepo = getIt<PreferenceRepository>();
      StoreCartsRes? result;
      if (prefRepo.cartId?.isNotEmpty ?? false) {
        try {
          result = await storeApi.carts.retrieve(cartId: prefRepo.cartId!);
        } on DioException catch (e) {
          if (e.response?.statusCode == 404) {
            // Stale cart ID — clear it and create a new cart
            await prefRepo.clearCartId();
            result = null;
          } else {
            rethrow;
          }
        }
      }

      if (result == null) {
        result = await storeApi.carts.createCart();
        if (result?.cart?.id != null) {
          await prefRepo.setCartId(result!.cart!.id!);
        }
      }

      if (result?.cart == null) {
        return Error(Failure(message: 'Failed to load cart'));
      } else {
        return Success(result!.cart!);
      }
    } catch (e, stack) {
      log(stack.toString());
      log(e.toString());
      return Error(Failure.from(e));
    }
  }
}
