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
      final payload = (await _usecase()).tryGetSuccess();
      if (payload != null) {
        // Also resolve here: regions and the chosen country are cached under
        // separate keys, so an install that cached regions but failed to save a
        // country would otherwise never auto-select one. _resolveCountry() is a
        // no-op once a country exists.
        await _resolveCountry(payload, prefRepo);
        if (_hasChanged(cached, payload.regions)) {
          await prefRepo.setCachedRegions(payload.regions);
          emit(RegionState.loaded(payload.regions));
        }
      }
      return;
    }

    // First launch — no cache yet
    emit(const RegionState.loading());
    final result = await _usecase();
    final payload = result.tryGetSuccess();
    if (payload != null) {
      await _resolveCountry(payload, prefRepo);
      await prefRepo.setCachedRegions(payload.regions);
      emit(RegionState.loaded(payload.regions));
    } else {
      emit(RegionState.error(result.tryGetError()?.message));
    }
  }

  /// Auto-selects the shipping country when the user has not picked one.
  ///
  /// A saved country always wins — this returns immediately once one exists, so
  /// an explicit choice is never overwritten. Otherwise it takes the country the
  /// backend resolved from the request IP (`detected` on /store/regions), which
  /// replaced the on-device lookup: that hit a third-party geo API directly from
  /// the phone and now returns a Cloudflare challenge, so every install silently
  /// fell back to Saudi Arabia.
  Future<void> _resolveCountry(
      RegionsPayload payload, PreferenceRepository prefRepo) async {
    final regions = payload.regions;
    if (!(regions.firstOrNull?.countries?.isNotEmpty ?? false)) return;
    if (prefRepo.country != null && prefRepo.region != null) return;

    // 1. Where the server placed this IP.
    var match = _findCountry(
        regions, payload.detectedCountryId, payload.detectedIso2);

    // 2. Outside the served markets, or an IP the server could not place: take
    //    the store's own default, so the app shows the same currency the website
    //    would. Hardcoding a country here is what made the two disagree.
    match ??= _findCountry(
        regions, payload.defaultCountryId, payload.defaultIso2);

    // 3. Server too old to send `default` — keep the historical behaviour.
    match ??= _findCountry(regions, null, 'SA');

    final targetRegion = match?.$1 ?? regions.first;
    final targetCountry = match?.$2 ?? regions.first.countries!.first;

    await prefRepo.setRegion(targetRegion);
    await prefRepo.setCountry(targetCountry);
  }

  /// First region/country matching [countryId], else [iso2]. Null if neither is
  /// supplied or nothing matches.
  (Region, Country)? _findCountry(
      List<Region> regions, int? countryId, String? iso2) {
    if (countryId == null && iso2 == null) return null;

    for (final region in regions) {
      for (final country in region.countries ?? <Country>[]) {
        final byId = countryId != null && country.id == countryId;
        final byIso = iso2 != null && country.iso2?.toUpperCase() == iso2;
        if (byId || byIso) return (region, country);
      }
    }
    return null;
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
