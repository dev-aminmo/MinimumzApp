import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flag/flag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:minimumz/blocs/auth/authentication_bloc.dart';
import 'package:minimumz/presentation/screens/cart/bloc/cart/cart_bloc.dart';
import 'package:minimumz/blocs/region/region_bloc.dart';
import 'package:minimumz/cubits/theme/theme_cubit.dart';
import 'package:minimumz/di/di.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/data/data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/repository/preference_repository.dart';
import '../../../domain/usecase/account_information_usecase.dart';
import '../../common/colors.dart';
import '../routes/app_router.dart';
import '../screens/dashboard_screen.dart';
import '../screens/home/bloc/products/products_bloc.dart';
import 'minimumz_icons.dart';

class DrawerWidget extends StatefulWidget {
  const DrawerWidget({super.key});

  @override
  State<DrawerWidget> createState() => _DrawerWidgetState();
}

class _DrawerWidgetState extends State<DrawerWidget> {
  @override
  Widget build(BuildContext context) {
    const contentPadding = EdgeInsets.symmetric(horizontal: 20.0);
    return BlocConsumer<AuthenticationBloc, AuthenticationState>(
      listener: (BuildContext context, AuthenticationState state) {
        state.whenOrNull(loggedOut: (_) {
          getIt<SharedPreferences>().clear();
          context.router.replaceAll([const SignInRoute()]);
        });
      },
      builder: (context, state) {
        final loggedIn = state.maybeMap(loggedIn: (_) => true, orElse: () => false);
        final isGuest = state.maybeMap(loggedInAsGuest: (_) => true, orElse: () => false);
        final color = loggedIn ? null : ColorConstant.manatee;
        return Drawer(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Theme.of(context).scaffoldBackgroundColor,
          child: SafeArea(
            bottom: false,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0).copyWith(top: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset('assets/images/logo_minimumz.png', height: 36),
                          InkWell(
                            borderRadius: const BorderRadius.all(Radius.circular(50)),
                            onTap: () => Scaffold.of(context).closeDrawer(),
                            child: Ink(
                              width: 45,
                              height: 45,
                              decoration: ShapeDecoration(
                                color: context.theme.cardColor,
                                shape: const CircleBorder(),
                              ),
                              child: const Icon(minimumzIcons.menu_vertical),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(30),
                    state.maybeMap(
                        loggedIn: (data) => Padding(
                              padding: contentPadding,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Flexible(
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          maxRadius: 24,
                                          child: Text(data.customer.firstName?[0] ?? ''),
                                        ),
                                        const Gap(10),
                                        Flexible(
                                          child: Text(
                                            (data.customer.firstName ?? '') +
                                                (data.customer.lastName ?? ''),
                                            style: context.bodyLargeW500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (data.customer.orders?.isNotEmpty ?? false)
                                    Container(
                                      padding: const EdgeInsets.all(10.0),
                                      decoration: BoxDecoration(
                                          color: context.theme.cardColor,
                                          borderRadius:
                                              const BorderRadius.all(Radius.circular(5.0))),
                                      child: Text(
                                        data.customer.orders?.length.toString() ?? '',
                                        style: TextStyle(color: ColorConstant.manatee),
                                      ),
                                    )
                                ],
                              ),
                            ),
                        orElse: () => const SizedBox.shrink()),
                    const Gap(30),
                    BlocBuilder<ThemeCubit, ThemeState>(
                      builder: (context, state) {
                        IconData iconData = Icons.brightness_auto;
                        switch (state.themeMode) {
                          case ThemeMode.system:
                            iconData = Icons.brightness_auto_outlined;
                          case ThemeMode.light:
                            iconData = minimumzIcons.sun;
                          case ThemeMode.dark:
                            iconData = Icons.dark_mode_outlined;
                        }
                        return ListTile(
                          leading: Icon(iconData),
                          onTap: () async {
                            await showModalActionSheet(
                                context: context,
                                style: AdaptiveStyle.material,
                                title: context.l10n.chooseAppearance,
                                actions: <SheetAction<ThemeMode>>[
                                  SheetAction(
                                      label: context.l10n.automatic,
                                      key: ThemeMode.system),
                                  SheetAction(
                                      label: context.l10n.light,
                                      key: ThemeMode.light),
                                  SheetAction(
                                      label: context.l10n.dark,
                                      key: ThemeMode.dark),
                                ]).then((result) {
                              if (result == null) return;
                              context.read<ThemeCubit>().updateTheme(result);
                            });
                          },
                          contentPadding: contentPadding,
                          title: Text(context.l10n.appearance),
                          horizontalTitleGap: 10.0,
                        );
                      },
                    ),
                    if (!isGuest) ...[
                      ListTile(
                        leading: Icon(minimumzIcons.info_circle,
                            color: loggedIn ? null : ColorConstant.manatee),
                        onTap: loggedIn
                            ? () => context.pushRoute(const AccountInformationRoute())
                            : null,
                        contentPadding: contentPadding,
                        title: Text(
                          context.l10n.accountInformation,
                          style: TextStyle(color: loggedIn ? null : ColorConstant.manatee),
                        ),
                        horizontalTitleGap: 10.0,
                      ),
                      ListTile(
                        leading: Icon(minimumzIcons.lock, color: color),
                        onTap: loggedIn ? () => _showPasswordSheet(context) : null,
                        contentPadding: contentPadding,
                        title: Text(context.l10n.password, style: TextStyle(color: color)),
                        horizontalTitleGap: 10.0,
                      ),
                      ListTile(
                        leading: Icon(minimumzIcons.bag, color: color),
                        onTap: loggedIn ? () => context.pushRoute(const OrdersRoute()) : null,
                        contentPadding: contentPadding,
                        title: Text(context.l10n.orders, style: TextStyle(color: color)),
                        horizontalTitleGap: 10.0,
                      ),
                      ListTile(
                        leading: Icon(minimumzIcons.wallet, color: color),
                        onTap: loggedIn ? () {} : null,
                        contentPadding: contentPadding,
                        title: Text(context.l10n.myCards, style: TextStyle(color: color)),
                        horizontalTitleGap: 10.0,
                      ),
                    ],
                    ListTile(
                      leading: const Icon(minimumzIcons.heart),
                      onTap: () {
                        Scaffold.of(context).closeDrawer();
                        AutoTabsRouter.of(dashboardScaffoldKey.currentContext!)
                            .setActiveIndex(2);
                      },
                      contentPadding: contentPadding,
                      title: Text(context.l10n.wishlist),
                      horizontalTitleGap: 10.0,
                    ),
                    ListTile(
                      leading: const Icon(minimumzIcons.clock),
                      onTap: () {
                        Scaffold.of(context).closeDrawer();
                        context.pushRoute(const RecentlyViewedRoute());
                      },
                      contentPadding: contentPadding,
                      title: Text(context.l10n.recentlyViewed),
                      horizontalTitleGap: 10.0,
                    ),
                    ListTile(
                      leading: const Icon(minimumzIcons.settings),
                      onTap: () => context.pushRoute(const SettingsRoute()),
                      contentPadding: contentPadding,
                      title: Text(context.l10n.settings),
                      horizontalTitleGap: 10.0,
                    ),
                  ],
                ),
                  ),
                ),
                Column(
                  children: [
                    BlocBuilder<RegionBloc, RegionState>(
                      builder: (context, regionState) {
                        return regionState.maybeMap(
                          loaded: (loaded) {
                            List<Country> countries = [];
                            for (var region in loaded.regions) {
                              if (region.countries?.isNotEmpty ?? false) {
                                countries.addAll(region.countries!);
                              }
                            }
                            return ListTile(
                              leading: const Icon(Icons.local_shipping_outlined),
                              onTap: () async {
                                final savedCountry = getIt<PreferenceRepository>().country;
                                final countryId = await _showCountryPicker(
                                  context: context,
                                  title: context.l10n.shippingTo,
                                  countries: countries,
                                  selectedId: savedCountry?.id,
                                );
                                await onShippingTap(countries, loaded.regions, countryId);
                              },
                              contentPadding: contentPadding,
                              title: Text(context.l10n.shippingTo),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (getIt<PreferenceRepository>().country != null)
                                    Row(
                                      children: [
                                        Flag.fromString(
                                            getIt<PreferenceRepository>().country!.iso2!,
                                            height: 15,
                                            width: 20),
                                        const Gap(10),
                                        Text(
                                          getIt<PreferenceRepository>()
                                                  .country
                                                  ?.iso2
                                                  ?.toUpperCase() ??
                                              '',
                                          style: context.bodyMedium,
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              horizontalTitleGap: 10.0,
                            );
                          },
                          loading: (_) => const SizedBox.shrink(),
                          orElse: () => const SizedBox.shrink(),
                        );
                      },
                    ),
                    state.maybeMap(
                        loggedIn: (_) => ListTile(
                              leading: const Icon(minimumzIcons.logout, color: Colors.red),
                              onTap: () async {
                                await showOkCancelAlertDialog(
                                  context: context,
                                  style: AdaptiveStyle.material,
                                  title: context.l10n.confirmLogout,
                                  message: context.l10n.confirmLogoutMessage,
                                  isDestructiveAction: true,
                                  okLabel: context.l10n.logout,
                                ).then((result) {
                                  if (result == OkCancelResult.ok) {
                                    context
                                        .read<AuthenticationBloc>()
                                        .add(const AuthenticationEvent.logoutCustomer());
                                  }
                                });
                              },
                              contentPadding: contentPadding,
                              title: Text(context.l10n.logout),
                              horizontalTitleGap: 10.0,
                            ),
                        loggedOut: (_) => ListTile(
                              leading: const Icon(Icons.login),
                              onTap: () => context.pushRoute(const SignInRoute()),
                              contentPadding: contentPadding,
                              title: Text(context.l10n.signIn),
                              horizontalTitleGap: 10.0,
                            ),
                        loggedInAsGuest: (_) => ListTile(
                              leading: const Icon(Icons.login),
                              onTap: () => context.pushRoute(const SignInRoute()),
                              contentPadding: contentPadding,
                              title: Text(context.l10n.signIn),
                              horizontalTitleGap: 10.0,
                            ),
                        orElse: () => const SizedBox.shrink()),
                    const Gap(30),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _PasswordChangeSheet(),
    );
  }

  Future<void> onShippingTap(
      List<Country> countries, List<Region> regions, int? countryId) async {
    final prefRepo = getIt<PreferenceRepository>();
    final savedCountry = prefRepo.country;
    if (countryId == null || countryId == savedCountry?.id) return;

    final country = countries.firstWhere((c) => c.id == countryId);
    final region = regions.firstWhere((r) => r.id == country.regionId);

    await prefRepo.setCountry(country);
    await prefRepo.setRegion(region);

    if (region.currencyCode != null) {
      await prefRepo.setCurrencyCode(region.currencyCode!);
    }

    final authState = context.read<AuthenticationBloc>().state;
    final isLoggedIn = authState.maybeMap(loggedIn: (_) => true, orElse: () => false);
    if (isLoggedIn && country.id != null) {
      await AccountInformationUsecase.instance
          .updateInformation(StorePostCustomersCustomerReq(countryId: country.id));
    }

    context.read<ProductsBloc>().add(const ProductsEvent.resetProducts());
    if (prefRepo.cartId != null) {
      context.read<CartBloc>().add(CartEvent.updateCart(
          cartId: prefRepo.cartId!,
          req: StorePostCartsCartReq(regionId: region.id)));
    }

    setState(() {});
  }
}

// ── Country picker dialog ─────────────────────────────────────────────────────

Future<int?> _showCountryPicker({
  required BuildContext context,
  required String title,
  required List<Country> countries,
  int? selectedId,
}) {
  int? current = selectedId;
  return showDialog<int?>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: Text(title),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: countries.length,
            itemBuilder: (_, i) {
              final c = countries[i];
              return RadioListTile<int?>(
                value: c.id,
                groupValue: current,
                activeColor: ColorConstant.primary,
                title: Text(c.name ?? ''),
                onChanged: (v) => setLocal(() => current = v),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, current),
            child: Text(MaterialLocalizations.of(ctx).okButtonLabel),
          ),
        ],
      ),
    ),
  );
}

// ── Change Password sheet ─────────────────────────────────────────────────────

class _PasswordChangeSheet extends StatefulWidget {
  const _PasswordChangeSheet();

  @override
  State<_PasswordChangeSheet> createState() => _PasswordChangeSheetState();
}

class _PasswordChangeSheetState extends State<_PasswordChangeSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _showCurrent = false;
  bool _showNew = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await getIt<DataStore>().customers.changePassword(
            currentPassword: _currentCtrl.text,
            newPassword: _newCtrl.text,
          );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.passwordUpdated)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.currentPasswordIncorrect)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ───────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ColorConstant.manatee.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ColorConstant.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_outline,
                        color: ColorConstant.primary, size: 22),
                  ),
                  const Gap(12),
                  Text(context.l10n.changePassword, style: context.bodyLargeW600),
                ],
              ),
            ),
            const Divider(height: 0),

            // ── Fields ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                children: [
                  _PwdField(
                    controller: _currentCtrl,
                    hint: context.l10n.currentPassword,
                    visible: _showCurrent,
                    onToggle: () => setState(() => _showCurrent = !_showCurrent),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? context.l10n.required : null,
                  ),
                  const Gap(12),
                  _PwdField(
                    controller: _newCtrl,
                    hint: context.l10n.newPassword,
                    visible: _showNew,
                    onToggle: () => setState(() => _showNew = !_showNew),
                    validator: (v) {
                      if (v == null || v.isEmpty) return context.l10n.required;
                      if (v.length < 6) return context.l10n.atLeast6Characters;
                      return null;
                    },
                  ),
                  const Gap(12),
                  _PwdField(
                    controller: _confirmCtrl,
                    hint: context.l10n.confirmNewPassword,
                    visible: false,
                    onToggle: null,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) {
                      if (v == null || v.isEmpty) return context.l10n.required;
                      if (v != _newCtrl.text) return context.l10n.passwordsDoNotMatch;
                      return null;
                    },
                  ),
                ],
              ),
            ),

            // ── Save button ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: ColorConstant.brownDark,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(context.l10n.save,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PwdField extends StatelessWidget {
  const _PwdField({
    required this.controller,
    required this.hint,
    required this.visible,
    required this.onToggle,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
  });

  final TextEditingController controller;
  final String hint;
  final bool visible;
  final VoidCallback? onToggle;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: !visible,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: hint,
        filled: true,
        fillColor: context.theme.cardColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: ColorConstant.manatee.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: ColorConstant.manatee.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ColorConstant.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        suffixIcon: onToggle != null
            ? IconButton(
                icon: Icon(visible ? Icons.visibility_off : Icons.visibility,
                    size: 20, color: ColorConstant.manatee),
                onPressed: onToggle,
              )
            : null,
      ),
      validator: validator,
    );
  }
}
