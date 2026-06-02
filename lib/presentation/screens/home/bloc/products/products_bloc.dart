import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:minimumz/common/pricing_utils.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/data/data.dart';

import '../../../../../domain/usecase/get_home_product_usecase.dart';

part 'products_event.dart';
part 'products_state.dart';
part 'products_bloc.freezed.dart';

@injectable
class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  static ProductsBloc get instance => getIt<ProductsBloc>();
  ProductsBloc(this._usecase) : super(const _Loading()) {
    on<_LoadProducts>((event, emit) async {
      final result = await _usecase(queryParameters: event.queryParameters);
      result.when(
        (response) {
          if (response.products != null) {
            emit(_Loaded(
              filterPricedProducts(response.products!),
              count: response.count,
              limit: response.limit,
              offset: response.offset,
            ));
          }
        },
        (error) => emit(_Error(error.message)),
      );
    });
    on<_ResetProducts>((event, emit) {
      emit(const _Loading());
    });
  }

  final GetHomeProductUsecase _usecase;
}
