import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:minimumz/common/colors.dart';
import 'package:minimumz/common/doh_cache_manager.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/data/data.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/domain/model/product_filter.dart';

const _kGenders   = ['male', 'female'];
// Age slider ranges per unit
const _kAgeMonthsMax = 36.0;
const _kAgeYearsMax  = 100.0;
const _kPriceMin  = 0.0;
const _kPriceMax  = 10000.0;

class ProductFilterSheet extends StatefulWidget {
  const ProductFilterSheet({super.key, required this.initial});
  final ProductFilter initial;

  // Session-level cache so the sheet never re-fetches within the same app run
  static List<Map<String, String?>>? _cachedBrands;
  static List<String>?              _cachedColors;

  static void clearCache() {
    _cachedBrands = null;
    _cachedColors = null;
  }

  static Future<ProductFilter?> show(BuildContext context, ProductFilter current) {
    return showModalBottomSheet<ProductFilter>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProductFilterSheet(initial: current),
    );
  }

  @override
  State<ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<ProductFilterSheet> {
  late ProductFilter _filter;

  List<Map<String, String?>> _brands = [];
  List<String> _colors = [];
  bool _loading = true;

  late final TextEditingController _minPriceCtrl;
  late final TextEditingController _maxPriceCtrl;
  bool _updatingFromSlider = false;

  RangeValues get _priceRange => RangeValues(
        _filter.minPrice ?? _kPriceMin,
        _filter.maxPrice ?? _kPriceMax,
      );

  bool _ageInYears = false;

  double get _ageSliderMax => _ageInYears ? _kAgeYearsMax : _kAgeMonthsMax;

  // Convert stored months → slider unit
  double _monthsToSlider(int months) =>
      _ageInYears ? months / 12.0 : months.toDouble();

  // Convert slider value → months for storage
  int _sliderToMonths(double v) =>
      _ageInYears ? (v * 12).round() : v.round();

  RangeValues get _ageRange => RangeValues(
        _filter.minAge != null ? _monthsToSlider(_filter.minAge!) : 0.0,
        _filter.maxAge != null ? _monthsToSlider(_filter.maxAge!) : _ageSliderMax,
      );

  bool get _ageActive => _filter.minAge != null || _filter.maxAge != null;

  @override
  void initState() {
    super.initState();
    _filter = widget.initial;
    _minPriceCtrl = TextEditingController(
        text: _filter.minPrice != null ? _filter.minPrice!.toStringAsFixed(0) : '');
    _maxPriceCtrl = TextEditingController(
        text: _filter.maxPrice != null ? _filter.maxPrice!.toStringAsFixed(0) : '');
    _minPriceCtrl.addListener(_onMinPriceTyped);
    _maxPriceCtrl.addListener(_onMaxPriceTyped);
    // Populate from cache synchronously so the sheet opens with no spinner
    if (ProductFilterSheet._cachedBrands != null) {
      _brands  = ProductFilterSheet._cachedBrands!;
      _colors  = ProductFilterSheet._cachedColors ?? [];
      _loading = false;
    } else {
      _loadOptions();
    }
  }

  @override
  void dispose() {
    _minPriceCtrl.dispose();
    _maxPriceCtrl.dispose();
    super.dispose();
  }

  void _onMinPriceTyped() {
    if (_updatingFromSlider) return;
    final v = double.tryParse(_minPriceCtrl.text);
    if (v == null) return;
    final clamped = v.clamp(_kPriceMin, _priceRange.end);
    setState(() => _filter = _filter.copyWith(minPrice: clamped <= _kPriceMin ? null : clamped));
  }

  void _onMaxPriceTyped() {
    if (_updatingFromSlider) return;
    final v = double.tryParse(_maxPriceCtrl.text);
    if (v == null) return;
    final clamped = v.clamp(_priceRange.start, _kPriceMax);
    setState(() => _filter = _filter.copyWith(maxPrice: clamped >= _kPriceMax ? null : clamped));
  }

  void _onPriceSliderChanged(RangeValues v) {
    _updatingFromSlider = true;
    setState(() {
      _filter = _filter.copyWith(
        minPrice: v.start <= _kPriceMin ? null : v.start,
        maxPrice: v.end   >= _kPriceMax ? null : v.end,
      );
      _minPriceCtrl.text = v.start.toStringAsFixed(0);
      _maxPriceCtrl.text = v.end.toStringAsFixed(0);
    });
    _updatingFromSlider = false;
  }

  Future<void> _loadOptions() async {
    final data = await getIt<DataStore>().products.fetchFilters();
    if (!mounted || data == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final brands = (data['brands'] as List? ?? []).map((b) {
      final m = b as Map<String, dynamic>;
      return <String, String?>{
        'id':   m['id'] as String,
        'name': (m['name'] as String?) ?? '',
        'logo': m['logo'] as String?,
      };
    }).where((b) => b['name']!.isNotEmpty).toList();

    final colors = (data['colors'] as List? ?? [])
        .map((c) => c as String)
        .where((c) => c.isNotEmpty)
        .toList();

    ProductFilterSheet._cachedBrands = brands;
    ProductFilterSheet._cachedColors = colors;

    if (!mounted) return;
    setState(() {
      _brands  = brands;
      _colors  = colors;
      _loading = false;
    });
  }

  void _toggleGender(String g) {
    final updated = List<String>.from(_filter.genders);
    updated.contains(g) ? updated.remove(g) : updated.add(g);
    setState(() => _filter = _filter.copyWith(genders: updated));
  }

  void _toggleBrand(String id) {
    final updated = List<String>.from(_filter.brandIds);
    updated.contains(id) ? updated.remove(id) : updated.add(id);
    setState(() => _filter = _filter.copyWith(brandIds: updated));
  }

  void _toggleColor(String hex) {
    final updated = List<String>.from(_filter.colors);
    updated.contains(hex) ? updated.remove(hex) : updated.add(hex);
    setState(() => _filter = _filter.copyWith(colors: updated));
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ColorConstant.manatee.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(context.l10n.filters, style: context.bodyLargeW500),
                    TextButton(
                      onPressed: () => setState(() {
                        _filter = ProductFilter.empty;
                      }),
                      child: Text(context.l10n.clearFilters,
                          style: TextStyle(color: ColorConstant.primary)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator.adaptive())
                    : ListView(
                        controller: scrollController,
                        padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPad + 80),
                        children: [
                          if (_kPriceMax > _kPriceMin) ...[
                            const Gap(24),
                            _buildPriceSection(context),
                          ],
                          const Gap(24),
                          _buildGenderSection(context),
                          if (_brands.isNotEmpty) ...[
                            const Gap(24),
                            _buildBrandSection(context),
                          ],
                          if (_colors.isNotEmpty) ...[
                            const Gap(24),
                            _buildColorSection(context),
                          ],
                          const Gap(24),
                          _buildAgeSection(context),
                        ],
                      ),
              ),
              // Apply button
              Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPad + 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(_filter),
                    child: Text(context.l10n.applyFilters),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(text, style: context.bodyMediumW500),
      );

  Widget _priceField(BuildContext context, TextEditingController ctrl, String label) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    );
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      style: context.bodyMediumW500,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: context.bodySmall?.copyWith(color: ColorConstant.manatee),
        filled: true,
        fillColor: context.theme.cardColor,
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: ColorConstant.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
    );
  }

  Widget _buildPriceSection(BuildContext context) {
    final range = _priceRange;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, context.l10n.priceRange),
        RangeSlider(
          values: range,
          min: _kPriceMin,
          max: _kPriceMax,
          divisions: (_kPriceMax - _kPriceMin).round().clamp(1, 500),
          labels: RangeLabels(
            range.start.toStringAsFixed(0),
            range.end.toStringAsFixed(0),
          ),
          onChanged: _onPriceSliderChanged,
        ),
        const Gap(8),
        Row(
          children: [
            Expanded(child: _priceField(context, _minPriceCtrl, context.l10n.minPrice)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('–', style: context.bodyMedium?.copyWith(color: ColorConstant.manatee)),
            ),
            Expanded(child: _priceField(context, _maxPriceCtrl, context.l10n.maxPrice)),
          ],
        ),
      ],
    );
  }

  Widget _buildGenderSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, context.l10n.gender),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _kGenders.map((g) {
            final selected = _filter.genders.contains(g);
            return FilterChip(
              label: Text(_localizeGender(context, g)),
              selected: selected,
              onSelected: (_) => _toggleGender(g),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBrandSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, context.l10n.brand),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _brands.map((b) {
            final selected = _filter.brandIds.contains(b['id']);
            final logoUrl  = b['logo'];
            return FilterChip(
              avatar: logoUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        cacheManager: DohCacheManager.instance,
                        imageUrl: logoUrl,
                        width: 24,
                        height: 24,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    )
                  : null,
              label: Text(b['name']!),
              selected: selected,
              onSelected: (_) => _toggleBrand(b['id']!),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildColorSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(context, context.l10n.color),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _colors.map((hex) {
            final color   = _hexToColor(hex);
            final selected = _filter.colors.contains(hex);
            return GestureDetector(
              onTap: () => _toggleColor(hex),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? ColorConstant.primary : Colors.transparent,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: selected
                    ? Icon(Icons.check,
                        size: 16,
                        color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white)
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _ageLabel(double v) =>
      _ageInYears ? '${v.toInt()}y' : '${v.round()}m';

  Widget _buildAgeSection(BuildContext context) {
    final range = _ageRange;
    final divisions = _ageInYears ? _kAgeYearsMax.toInt() : _kAgeMonthsMax.toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle(context, context.l10n.ageRange),
            if (_ageActive)
              TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => setState(() =>
                    _filter = _filter.copyWith(minAge: null, maxAge: null)),
                child: Text(context.l10n.clearFilters,
                    style: TextStyle(color: ColorConstant.primary, fontSize: 12)),
              ),
          ],
        ),
        const Gap(10),
        // Unit toggle pill
        _AgeUnitToggle(
          inYears: _ageInYears,
          onChanged: (inYears) => setState(() {
            _ageInYears = inYears;
            // Clear selection when switching — avoids out-of-range values
            _filter = _filter.copyWith(minAge: null, maxAge: null);
          }),
        ),
        const Gap(4),
        RangeSlider(
          values: range,
          min: 0,
          max: _ageSliderMax,
          divisions: divisions,
          labels: RangeLabels(_ageLabel(range.start), _ageLabel(range.end)),
          activeColor: ColorConstant.primary,
          onChanged: (v) => setState(() {
            _filter = _filter.copyWith(
              minAge: v.start <= 0 ? null : _sliderToMonths(v.start),
              maxAge: v.end >= _ageSliderMax ? null : _sliderToMonths(v.end),
            );
          }),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_ageLabel(range.start),
                style: context.bodySmall?.copyWith(color: ColorConstant.manatee)),
            Text(_ageLabel(range.end),
                style: context.bodySmall?.copyWith(color: ColorConstant.manatee)),
          ],
        ),
      ],
    );
  }

  String _localizeGender(BuildContext context, String g) {
    return switch (g.toLowerCase()) {
      'male'   => context.l10n.male,
      'female' => context.l10n.female,
      _        => g,
    };
  }

  Color _hexToColor(String hex) {
    final clean = hex.replaceAll('#', '').replaceAll('0x', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    } else if (clean.length == 8) {
      return Color(int.parse(clean, radix: 16));
    }
    return Colors.grey;
  }
}

class _AgeUnitToggle extends StatelessWidget {
  const _AgeUnitToggle({required this.inYears, required this.onChanged});
  final bool inYears;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: ColorConstant.beige,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _pill(context, label: 'Months', selected: !inYears, onTap: () => onChanged(false)),
          _pill(context, label: 'Years',  selected: inYears,  onTap: () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, {required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: selected ? ColorConstant.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : ColorConstant.manatee,
          ),
        ),
      ),
    );
  }
}
