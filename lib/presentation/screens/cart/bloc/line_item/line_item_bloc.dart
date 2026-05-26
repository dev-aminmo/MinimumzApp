import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/usecase/line_item_usecase.dart';
import 'package:minimumz/data/data.dart';

part 'line_item_event.dart';
part 'line_item_state.dart';
part 'line_item_bloc.freezed.dart';

@injectable
class LineItemBloc extends Bloc<LineItemEvent, LineItemState> {
  static LineItemBloc get instance => getIt<LineItemBloc>();
  LineItemBloc(this.lineItemUsecase) : super(const _Initial()) {
    on<_Add>((event, emit) async {
      emit(_Loading(lineItemId: event.variantId));
      final result = await lineItemUsecase.add(
          cartId: event.id,
          variantId: event.variantId,
          quantity: event.quantity);
      result.when(
        (cart) => emit(_Success(cart)),
        (error) => emit(_Failure(error.message, lineItemId: event.variantId)),
      );
    });

    on<_Update>((event, emit) async {
      emit(_Loading(lineItemId: event.lineId));
      final result = await lineItemUsecase.update(
          cartId: event.cartId, quantity: event.quantity, lineId: event.lineId);
      result.when(
        (cart) => emit(_Success(cart)),
        (error) => emit(_Failure(error.message, lineItemId: event.lineId)),
      );
    });

    on<_Delete>((event, emit) async {
      emit(_Loading(lineItemId: event.lineId));
      final result = await lineItemUsecase.delete(
          cartId: event.cartId, lineId: event.lineId);
      result.when(
        (cart) => emit(_Success(cart)),
        (error) => emit(_Failure(error.message, lineItemId: event.lineId)),
      );
    });
  }

  final LineItemUsecase lineItemUsecase;
}
