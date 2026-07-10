import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';
import 'package:minimumz/presentation/components/index.dart';

@RoutePage()
class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  static const _pageSize = 20;

  WalletBalance? _balance;
  bool _loadingBalance = true;

  final PagingController<int, WalletTransaction> _pagingController =
      PagingController(firstPageKey: 0);

  @override
  void initState() {
    super.initState();
    _fetchBalance();
    _pagingController.addPageRequestListener(_fetchPage);
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  Future<void> _fetchBalance() async {
    final countryId = PreferenceRepository.instance.country?.id;
    final balance = await getIt<DataStore>().wallet.getBalance(countryId: countryId);
    if (!mounted) return;
    setState(() {
      _balance = balance;
      _loadingBalance = false;
    });
  }

  Future<void> _fetchPage(int offset) async {
    try {
      final res = await getIt<DataStore>().wallet.getTransactions(
            offset: offset,
            limit: _pageSize,
          );
      if (!mounted) return;
      final items = res?.transactions ?? [];
      final isLast = items.length < _pageSize;
      if (isLast) {
        _pagingController.appendLastPage(items);
      } else {
        _pagingController.appendPage(items, offset + items.length);
      }
    } catch (e) {
      if (mounted) _pagingController.error = e;
    }
  }

  Future<void> _refresh() async {
    await _fetchBalance();
    _pagingController.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: context.l10n.wallet),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: Column(
          children: [
            _buildBalanceCard(context),
            Expanded(child: _buildTransactions(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    final currency = _balance?.currency ?? PreferenceRepository.currencyCode;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorConstant.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_rounded,
              color: Colors.white, size: 34),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.walletBalance,
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
                const Gap(4),
                if (_loadingBalance)
                  const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                else ...[
                  Text('${_balance?.points ?? 0} ${context.l10n.points}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700)),
                  Text(
                    '≈ ${(_balance?.money ?? 0).formatAsPrice(currency)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactions(BuildContext context) {
    return PagedListView<int, WalletTransaction>(
      pagingController: _pagingController,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      builderDelegate: PagedChildBuilderDelegate<WalletTransaction>(
        itemBuilder: (_, txn, __) => _txnRow(context, txn),
        firstPageProgressIndicatorBuilder: (_) =>
            const Center(child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator.adaptive(),
        )),
        noItemsFoundIndicatorBuilder: (_) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(context.l10n.noTransactions,
                style: context.bodyMedium?.copyWith(color: ColorConstant.manatee)),
          ),
        ),
      ),
    );
  }

  Widget _txnRow(BuildContext context, WalletTransaction txn) {
    final credit = txn.isCredit;
    final color = credit ? Colors.green.shade600 : Colors.red.shade500;
    final sign = credit ? '+' : '';
    final when = txn.createdAt != null ? timeago.format(txn.createdAt!) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.theme.cardColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(credit ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: color, size: 20),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(credit ? context.l10n.pointsEarned : context.l10n.pointsSpent,
                    style: context.bodyMediumW600),
                if (when.isNotEmpty)
                  Text(when,
                      style: context.bodyExtraSmall
                          ?.copyWith(color: ColorConstant.manatee)),
              ],
            ),
          ),
          Text('$sign${txn.amount} ${context.l10n.points}',
              style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
