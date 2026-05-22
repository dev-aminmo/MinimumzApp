import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/usecase/retrieve_regions_usecase.dart';
import 'package:minimumz/data/data.dart';

import '../../domain/repository/preference_repository.dart';

part 'region_event.dart';
part 'region_state.dart';
part 'region_bloc.freezed.dart';

@injectable
class RegionBloc extends Bloc<RegionEvent, RegionState> {
  static RegionBloc get instance => getIt<RegionBloc>();
  RegionBloc(this._usecase) : super(const RegionState.initial()) {
    on<_RetrieveRegions>(_onRetrieveRegions);
  }

  Future<void> _onRetrieveRegions(
      _RetrieveRegions event, Emitter<RegionState> emit) async {
    final prefRepo = PreferenceRepository.instance;
    final cached = prefRepo.cachedRegions;

    if (cached != null && cached.isNotEmpty) {
      // Serve cache immediately — UI is instant
      emit(RegionState.loaded(cached));
      // Emitter is still open; revalidate in background
      final fresh = (await _usecase()).tryGetSuccess();
      if (fresh != null && _hasChanged(cached, fresh)) {
        await prefRepo.setCachedRegions(fresh);
        emit(RegionState.loaded(fresh));
      }
      return;
    }

    // First launch — no cache yet
    emit(const RegionState.loading());
    final result = await _usecase();
    final regions = result.tryGetSuccess();
    if (regions != null) {
      await _resolveCountry(regions, prefRepo);
      await prefRepo.setCachedRegions(regions);
      emit(RegionState.loaded(regions));
    } else {
      emit(RegionState.error(result.tryGetError()?.message));
    }
  }

  // Detects and persists the user's country on first launch only.
  Future<void> _resolveCountry(
      List<Region> regions, PreferenceRepository prefRepo) async {
    if (!(regions.firstOrNull?.countries?.isNotEmpty ?? false)) return;
    if (prefRepo.country != null && prefRepo.region != null) return;

    final detectedCode = await GeoIpService.detectCountryCode();

    Region? targetRegion;
    Country? targetCountry;

    outer:
    for (final region in regions) {
      for (final country in region.countries ?? <Country>[]) {
        if (country.iso2?.toUpperCase() == detectedCode) {
          targetRegion = region;
          targetCountry = country;
          break outer;
        }
      }
    }

    if (targetCountry == null) {
      outer:
      for (final region in regions) {
        for (final country in region.countries ?? <Country>[]) {
          if (country.iso2?.toUpperCase() == 'SA') {
            targetRegion = region;
            targetCountry = country;
            break outer;
          }
        }
      }
    }

    targetRegion ??= regions.first;
    targetCountry ??= regions.first.countries!.first;

    await prefRepo.setRegion(targetRegion);
    await prefRepo.setCountry(targetCountry);
  }

  // Compares cached vs fresh regions by count, IDs, and per-region country count.
  bool _hasChanged(List<Region> cached, List<Region> fresh) {
    if (cached.length != fresh.length) return true;
    for (var i = 0; i < cached.length; i++) {
      if (cached[i].id != fresh[i].id) return true;
      if ((cached[i].countries?.length ?? 0) != (fresh[i].countries?.length ?? 0)) return true;
    }
    return false;
  }

  final RetrieveRegionsUsecase _usecase;
}
