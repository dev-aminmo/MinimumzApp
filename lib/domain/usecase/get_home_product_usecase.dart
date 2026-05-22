import 'dart:developer';

import 'package:injectable/injectable.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';
import 'package:minimumz/data/data.dart';
import 'package:multiple_result/multiple_result.dart';

import '../model/failure.dart';

@injectable
class GetHomeProductUsecase {
  Future<Result<StoreProductsListRes, Failure>> call({Map<String, dynamic>? queryParameters}) async {
    try {
      final storeApi = getIt<DataStore>();
      final prefRepo = getIt<PreferenceRepository>();

      final countryId = prefRepo.country?.id;

      Map<String, dynamic> queryParams = {
        'is_giftcard': false,
        if (countryId != null) 'country_id': countryId,
      };

      if (queryParameters != null) {
        queryParams.addAll(queryParameters);
      }
      final result = await storeApi.products.list(queryParams: queryParams);
      if (result?.products == null) {
        return Error(Failure(message: 'Failed to load products, please try again.'));
      } else {
        return Success(result!);
      }
    } catch (e, stack) {
      log(stack.toString());
      return Error(Failure.from(e));
    }
  }
}
