import 'dart:developer';

import 'package:injectable/injectable.dart';
import 'package:minimumz/data/data.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../di/di.dart';
import '../model/failure.dart';

/// Regions plus the country the backend resolved from the caller's IP.
///
/// The country travels with the regions because it comes from the same call —
/// `/store/regions` returns both, so first launch can pre-select a country
/// without a second request or an on-device geo lookup.
class RegionsPayload {
  const RegionsPayload({
    required this.regions,
    this.detectedCountryId,
    this.detectedIso2,
    this.defaultCountryId,
    this.defaultIso2,
  });

  final List<Region> regions;

  /// Null when the IP is unknown, private, or maps to a country the store does
  /// not publish — i.e. a visitor outside the served markets.
  final int? detectedCountryId;
  final String? detectedIso2;

  /// The store's configured default, used when [detectedCountryId] is null so
  /// the app and the website agree on what an out-of-region visitor is shown.
  /// Null only against a server too old to send it.
  final int? defaultCountryId;
  final String? defaultIso2;
}

@injectable
class RetrieveRegionsUsecase {
  Future<Result<RegionsPayload, Failure>> call() async {
    try {
      final storeApi = getIt<DataStore>();

      final result = await storeApi.regions.list();

      if (result?.regions?.isEmpty ?? true) {
        return Error(Failure(message: 'No regions found.'));
      }

      return Success(RegionsPayload(
        regions: result!.regions!,
        detectedCountryId: result.detectedCountryId,
        detectedIso2: result.detectedIso2,
        defaultCountryId: result.defaultCountryId,
        defaultIso2: result.defaultIso2,
      ));
    } catch (e, stack) {
      log(stack.toString());
      log(e.toString());
      return Error(Failure.from(e));
    }
  }
}
