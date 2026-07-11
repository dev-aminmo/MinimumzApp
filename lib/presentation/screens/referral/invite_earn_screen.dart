import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gap/gap.dart';
import 'package:share_plus/share_plus.dart';
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/presentation/components/index.dart';
import 'package:minimumz/services/deeplink/deep_link_service.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

@RoutePage()
class InviteEarnScreen extends StatefulWidget {
  const InviteEarnScreen({super.key});

  @override
  State<InviteEarnScreen> createState() => _InviteEarnScreenState();
}

class _InviteEarnScreenState extends State<InviteEarnScreen> {
  ReferralInfo? _info;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await getIt<DataStore>().referral.get();
    if (!mounted) return;
    setState(() {
      _info = info;
      _loading = false;
    });
  }

  void _copyCode() {
    final code = _info?.code;
    if (code == null || code.isEmpty) return;
    Clipboard.setData(ClipboardData(text: code));
    Fluttertoast.showToast(msg: context.l10n.copiedToClipboard);
  }

  Future<void> _share() async {
    final code = _info?.code;
    if (code == null || code.isEmpty) return;
    final message = context.l10n.inviteShareMessage(code);
    final errorMsg = context.l10n.couldNotCreateShareLink;

    EasyLoading.show();
    final link = await DeepLinkService.instance.shareReferral(code);
    EasyLoading.dismiss();
    if (link == null) {
      Fluttertoast.showToast(msg: errorMsg);
      return;
    }
    await SharePlus.instance.share(ShareParams(text: '$message\n$link'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: context.l10n.inviteAndEarn),
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : _info == null
              ? Center(
                  child: Text(context.l10n.somethingWentWrong,
                      style: context.bodyMedium
                          ?.copyWith(color: ColorConstant.manatee)),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _intro(context),
                      const Gap(16),
                      _codeCard(context),
                      const Gap(12),
                      _shareButton(context),
                      const Gap(20),
                      _strengthCard(context),
                      const Gap(16),
                      _statsRow(context),
                    ],
                  ),
                ),
    );
  }

  Widget _intro(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.inviteAndEarn,
              style: context.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
          const Gap(6),
          Text(context.l10n.inviteEarnSubtitle,
              style: context.bodyMedium?.copyWith(color: ColorConstant.manatee)),
        ],
      );

  Widget _codeCard(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: context.theme.cardColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ColorConstant.primary.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.l10n.yourReferralCode,
                      style: context.bodySmall
                          ?.copyWith(color: ColorConstant.manatee)),
                  const Gap(4),
                  Text(_info!.code,
                      style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy_rounded),
              tooltip: context.l10n.copy,
              onPressed: _copyCode,
            ),
          ],
        ),
      );

  Widget _shareButton(BuildContext context) => SizedBox(
        height: 50,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: ColorConstant.primary,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _share,
          icon: const Icon(Icons.ios_share_rounded, size: 20),
          label: Text(context.l10n.shareYourCode,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      );

  Widget _strengthCard(BuildContext context) {
    final info = _info!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.theme.cardColor.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.l10n.codeStrength, style: context.bodyMediumW600),
              Text('${info.strength}%',
                  style: TextStyle(
                      color: ColorConstant.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18)),
            ],
          ),
          const Gap(10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: info.levelProgress,
              minHeight: 8,
              backgroundColor: ColorConstant.beige,
              valueColor: AlwaysStoppedAnimation(ColorConstant.primary),
            ),
          ),
          const Gap(8),
          Text(
            info.atMaxStrength
                ? context.l10n.maxStrengthReached
                : context.l10n.usesToNextLevel(info.usesToNextLevel),
            style:
                context.bodyExtraSmall?.copyWith(color: ColorConstant.manatee),
          ),
        ],
      ),
    );
  }

  Widget _statsRow(BuildContext context) => Row(
        children: [
          Expanded(
            child: _stat(context, '${_info!.totalReferrals}',
                context.l10n.totalReferrals),
          ),
          const Gap(12),
          Expanded(
            child: _stat(context, '${_info!.totalEarnedPoints}',
                context.l10n.pointsEarned),
          ),
        ],
      );

  Widget _stat(BuildContext context, String value, String label) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: context.theme.cardColor.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800)),
            const Gap(2),
            Text(label,
                textAlign: TextAlign.center,
                style: context.bodyExtraSmall
                    ?.copyWith(color: ColorConstant.manatee)),
          ],
        ),
      );
}
