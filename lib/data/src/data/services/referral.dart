import 'dart:developer';
import 'base.dart';

/// The customer's referral code + stats (from GET /store/me/referral).
class ReferralInfo {
  const ReferralInfo({
    required this.code,
    required this.strength,
    required this.successfulUses,
    required this.usesToNextLevel,
    required this.totalReferrals,
    required this.totalEarnedPoints,
  });

  final String code;
  final int strength; // % an existing customer gets when using this code
  final int successfulUses;
  final int usesToNextLevel; // 0 when at the 15% cap
  final int totalReferrals;
  final int totalEarnedPoints;

  bool get atMaxStrength => usesToNextLevel == 0;

  /// Progress (0..1) toward the next strength level.
  double get levelProgress =>
      atMaxStrength ? 1.0 : (10 - usesToNextLevel) / 10.0;

  factory ReferralInfo.fromJson(Map<String, dynamic> json) => ReferralInfo(
        code: (json['code'] as String?) ?? '',
        strength: (json['strength'] as num?)?.toInt() ?? 5,
        successfulUses: (json['successful_uses'] as num?)?.toInt() ?? 0,
        usesToNextLevel: (json['uses_to_next_level'] as num?)?.toInt() ?? 10,
        totalReferrals: (json['total_referrals'] as num?)?.toInt() ?? 0,
        totalEarnedPoints: (json['total_earned_points'] as num?)?.toInt() ?? 0,
      );
}

class ReferralResource extends BaseResource {
  ReferralResource(super.client);

  /// GET /store/me/referral
  Future<ReferralInfo?> get() async {
    try {
      final response = await client.get('/store/me/referral');
      if (response.statusCode == 200) {
        return ReferralInfo.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
    }
    return null;
  }
}
