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
      final preferredCountryId = prefRepo.country?.id?.toString();

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
        // Pass the user's preferred country so prices are correct from the start.
        result = await storeApi.carts.createCart(
          req: preferredCountryId != null
              ? StorePostCartReq(regionId: preferredCountryId)
              : null,
        );
        if (result?.cart?.id != null) {
          await prefRepo.setCartId(result!.cart!.id!);
        }
      } else if (preferredCountryId != null &&
          result.cart?.regionId != null &&
          result.cart!.regionId != preferredCountryId) {
        // Cart's country doesn't match the user's current preference — sync it.
        // This handles: country changed while app was closed, or SAR guest cart
        // still active after the user switched to BHD.
        final cartId = result.cart!.id;
        if (cartId != null) {
          try {
            final updated = await storeApi.carts.update(
              cartId: cartId,
              req: StorePostCartsCartReq(regionId: preferredCountryId),
            );
            if (updated != null) result = updated;
          } catch (_) {
            // Best-effort: keep the existing cart if the update fails.
          }
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
