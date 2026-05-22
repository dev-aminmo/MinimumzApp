import 'dart:developer';

import 'package:injectable/injectable.dart';
import 'package:minimumz/domain/model/failure.dart';
import 'package:minimumz/data/data.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../di/di.dart';

@injectable
class RetrieveCollectionsUsecase {
  Future<Result<List<ProductCollection>, Failure>> call({Map<String, dynamic>? queryParameters}) async {
    try {
      final storeApi = getIt<DataStore>();

      final result = await storeApi.collections.list(queryParams: queryParameters);
      if (result?.collections!=null) {
        return Success(result!.collections!);
      } else {
        return Error(Failure(message: 'Error loading collections'));
      }
    } catch (e, stack) {
      log(stack.toString());
      log(e.toString());
      return Error(Failure.from(e));
    }
  }
}
