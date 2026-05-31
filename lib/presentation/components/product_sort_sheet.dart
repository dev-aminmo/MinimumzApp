import 'package:flutter/material.dart';
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/domain/model/product_filter.dart';

class ProductSortSheet extends StatelessWidget {
  const ProductSortSheet({super.key, required this.current});
  final String? current;

  // Sentinel returned when user explicitly picks "Default" (vs. dismissing the sheet)
  static const _kDefault = '';

  static Future<String?> show(BuildContext context, String? current) {
    return showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductSortSheet(current: current),
    );
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      (_kDefault,      context.l10n.defaultSort),
      ('created_at',   context.l10n.newestFirst),
      ('price_asc',    context.l10n.priceAscLabel),
      ('price_desc',   context.l10n.priceDescLabel),
      ('rating',       context.l10n.topRated),
      ('best_sellers', context.l10n.bestSellers),
    ];
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: context.theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: ColorConstant.manatee.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(context.l10n.sortBy, style: context.bodyLargeW500),
            ),
          ),
          const Divider(height: 1),
          ...options.map((opt) {
            final selected = (opt.$1 == _kDefault) ? current == null : current == opt.$1;
            return ListTile(
              title: Text(opt.$2, style: context.bodyMedium),
              trailing: selected
                  ? Icon(Icons.check_rounded, color: ColorConstant.primary)
                  : null,
              onTap: () => Navigator.of(context).pop(opt.$1),
              selected: selected,
              selectedColor: ColorConstant.primary,
            );
          }),
          SizedBox(height: bottomPad + 8),
        ],
      ),
    );
  }
}
