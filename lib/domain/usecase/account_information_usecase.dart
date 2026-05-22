import 'dart:developer';
import 'package:injectable/injectable.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/model/failure.dart';
import 'package:minimumz/data/data.dart';
import 'package:multiple_result/multiple_result.dart';

@injectable
class AccountInformationUsecase {
  static AccountInformationUsecase get instance => AccountInformationUsecase();
  final _customerResource = getIt<DataStore>().customers;

  Future<Result<Customer, Failure>> updateInformation(
      StorePostCustomersCustomerReq req) async {
    try {
      final result = await _customerResource.update(req: req);
      return Success(result!.customer!);
    } catch (e, stack) {
      log(stack.toString());
      log(e.toString());
      return Error(Failure.from(e));
    }
  }
}
