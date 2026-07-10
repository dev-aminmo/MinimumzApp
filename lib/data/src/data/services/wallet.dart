import 'dart:developer';
import 'base.dart';

/// Points wallet balance + its money value in the caller's currency.
class WalletBalance {
  const WalletBalance({
    required this.points,
    required this.money,
    required this.currency,
  });

  final int points;
  final double money;
  final String currency;

  factory WalletBalance.fromJson(Map<String, dynamic> json) => WalletBalance(
        points: (json['balance_points'] as num?)?.toInt() ?? 0,
        money: (json['balance_money'] as num?)?.toDouble() ?? 0.0,
        currency: (json['currency'] as String?) ?? '',
      );
}

/// A single wallet ledger entry.
class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.createdAt,
  });

  final int id;
  final String type; // 'deposit' | 'withdraw'
  final int amount; // signed points (+in / -out)
  final DateTime? createdAt;

  bool get isCredit => type == 'deposit';

  factory WalletTransaction.fromJson(Map<String, dynamic> json) => WalletTransaction(
        id: (json['id'] as num?)?.toInt() ?? 0,
        type: (json['type'] as String?) ?? 'deposit',
        amount: (json['amount'] as num?)?.toInt() ?? 0,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
      );
}

class WalletTransactionsRes {
  const WalletTransactionsRes({required this.transactions, required this.count});
  final List<WalletTransaction> transactions;
  final int count;

  factory WalletTransactionsRes.fromJson(Map<String, dynamic> json) => WalletTransactionsRes(
        transactions: (json['transactions'] as List? ?? [])
            .map((e) => WalletTransaction.fromJson(e as Map<String, dynamic>))
            .toList(),
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

class WalletResource extends BaseResource {
  WalletResource(super.client);

  /// GET /store/me/wallet — balance in points + money equivalent.
  Future<WalletBalance?> getBalance({int? countryId}) async {
    try {
      final response = await client.get('/store/me/wallet', queryParameters: {
        if (countryId != null) 'country_id': countryId,
      });
      if (response.statusCode == 200) {
        return WalletBalance.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
    }
    return null;
  }

  /// GET /store/me/wallet/transactions — paginated history.
  Future<WalletTransactionsRes?> getTransactions({int offset = 0, int limit = 20}) async {
    try {
      final response = await client.get('/store/me/wallet/transactions', queryParameters: {
        'offset': offset,
        'limit': limit,
      });
      if (response.statusCode == 200) {
        return WalletTransactionsRes.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
    }
    return null;
  }
}
