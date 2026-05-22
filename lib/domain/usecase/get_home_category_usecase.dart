import 'dart:developer';
import 'package:injectable/injectable.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/model/failure.dart';
import 'package:minimumz/data/data.dart';
import 'package:multiple_result/multiple_result.dart';

@injectable
class GetHomeCategoryUsecase {
  Future<Result<List<ProductCollection>, Failure>> call() async {
    try {
      final storeApi = getIt<DataStore>();

      final result = await storeApi.collections.list();

      if (result?.collections?.isEmpty ?? true) {
        return Error(Failure(message: 'No collections found.'));
      } else {
        return Success(result!.collections!);
      }
    } catch (e, stack) {
      log(stack.toString());
      log(e.toString());
      return Error(Failure.from(e));
    }
  }
}
