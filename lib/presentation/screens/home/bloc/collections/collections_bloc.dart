import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';

import '../../../../../domain/usecase/retrieve_collections_usecase.dart';

part 'collections_event.dart';
part 'collections_state.dart';
part 'collections_bloc.freezed.dart';

@injectable
class CollectionsBloc extends Bloc<CollectionsEvent, CollectionsState> {
  static CollectionsBloc get instance => getIt<CollectionsBloc>();

  CollectionsBloc(this._usecase, this._prefs)
      : super(_cachedState(_prefs)) {
    on<_RetrieveCollections>(_onRetrieve);
  }

  final RetrieveCollectionsUsecase _usecase;
  final PreferenceRepository _prefs;

  static CollectionsState _cachedState(PreferenceRepository prefs) {
    final cached = prefs.cachedCollections;
    return cached != null ? _Loaded(cached) : const _Loading();
  }

  Future<void> _onRetrieve(_RetrieveCollections event, Emitter<CollectionsState> emit) async {
    // Only show spinner when there is no cached data already displayed.
    if (state is! _Loaded) emit(const _Loading());

    final result = await _usecase(queryParameters: event.queryParameters);
    result.when(
      (collections) {
        _prefs.setCachedCollections(collections);
        emit(_Loaded(collections));
      },
      (error) {
        // Keep showing cached data if available; only surface error when nothing to show.
        if (state is! _Loaded) emit(_Error(error.message));
      },
    );
  }
}
