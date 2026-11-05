import '../store/others/index.dart';

class StoreRegionsListRes {
  List<Region>? regions;

  /// Country the backend resolved from the caller's IP, or null when the IP
  /// could not be placed in a country this store publishes. Used to pre-select
  /// the shipping country on first launch so the user never starts out on the
  /// wrong one. Server-side detection replaces the old on-device geo lookup.
  int? detectedCountryId;
  String? detectedIso2;

  /// The country the backend falls back to when it cannot place the caller —
  /// the store's configured default. Using it keeps an out-of-region visitor on
  /// the same currency the website would give them.
  int? defaultCountryId;
  String? defaultIso2;

  StoreRegionsListRes.fromJson(json) {
    if (json['regions'] != null) {
      regions = <Region>[];
      json['regions'].forEach((v) {
        regions?.add(Region.fromJson(v));
      });
    }

    final detected = _countryBlock(json['detected']);
    detectedCountryId = detected?.$1;
    detectedIso2 = detected?.$2;

    final fallback = _countryBlock(json['default']);
    defaultCountryId = fallback?.$1;
    defaultIso2 = fallback?.$2;
  }

  /// Parses `{country_id, iso_2, region_id}`; null when absent or not an object.
  static (int?, String?)? _countryBlock(dynamic raw) {
    if (raw is! Map) return null;
    final rawId = raw['country_id'];
    return (
      rawId is int ? rawId : int.tryParse(rawId?.toString() ?? ''),
      raw['iso_2']?.toString().toUpperCase(),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['regions'] = regions?.map((e) => e.toJson()).toList();
    return data;
  }
}

class StoreRegionsRes {
  Region? region;

  StoreRegionsRes.fromJson(json) {
    region = json["region"] != null ? Region.fromJson(json["region"]) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['region'] = region?.toJson();
    return data;
  }
}
