import 'dart:developer';
import 'package:injectable/injectable.dart' hide Order;
import 'package:minimumz/data/data.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../di/di.dart';
import '../model/failure.dart';

@injectable
class RetrieveOrdersUsecase {
  Future<Result<List<Order>, Failure>> call({
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final storeApi = getIt<DataStore>();
      final result = await storeApi.customers.listOrders(
        queryParameters: queryParameters,
      );
      return Success(result?.orders ?? []);
    } on Exception catch (e, stack) {
      log(stack.toString());
      log(e.toString());
      return Error(Failure.from(e));
    }
  }
}
