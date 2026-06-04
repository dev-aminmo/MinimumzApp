import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:minimumz/common/extensions/extensions.dart';
import 'package:minimumz/data/data.dart';

import '../components/index.dart';
import '../routes/app_router.dart';

@RoutePage()
class OrderConfirmedScreen extends StatelessWidget {
  const OrderConfirmedScreen({super.key, this.order});

  final Order? order;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: context.theme.appBarTheme.systemOverlayStyle!,
      child: Scaffold(
        appBar: const CustomAppBar(),
        bottomNavigationBar: BottomNavButton(
          label: context.l10n.continueShopping,
          onTap: () {
            // OrderConfirmed lives inside a tab's nested stack, so popping to
            // DashboardRoute (its grandparent) empties the navigator → blank
            // page. Instead, clear this tab's stack and jump to the Home tab.
            final tabsRouter = AutoTabsRouter.of(context);
            context.router.popUntilRoot();
            tabsRouter.setActiveIndex(0);
          },
        ),
        body: SafeArea(
            child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset('assets/images/mask_group.png'),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                Center(
                    child: SvgPicture.asset(
                        'assets/images/order_confirmed.svg')),
                const SizedBox(height: 40.0),
                Column(
                  children: [
                    Text(
                      context.l10n.orderConfirmed,
                      style: context.headlineMedium,
                    ),
                    const SizedBox(height: 10.0),
                    if (order?.id != null)
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 25.0),
                        child: Text(
                          'Order #${order!.id}',
                          style: TextStyle(
                              fontSize: 13,
                              color: const Color(0xff8F959E),
                              fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 8.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Text(
                        context.l10n.orderConfirmedMessage,
                        style: const TextStyle(
                            fontSize: 15, color: Color(0xff8F959E)),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 2),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20.0),
                  child: InkWell(
                    borderRadius:
                        const BorderRadius.all(Radius.circular(10.0)),
                    onTap: () => context.router.push(const OrdersRoute()),
                    child: Ink(
                      width: double.infinity,
                      height: 50,
                      decoration: const BoxDecoration(
                        borderRadius:
                            BorderRadius.all(Radius.circular(10.0)),
                        color: Color(0xffF5F5F5),
                      ),
                      child: Center(
                          child: Text(
                        context.l10n.goToOrders,
                        style: const TextStyle(
                            fontSize: 17.0,
                            color: Color(0xff8F959E),
                            fontWeight: FontWeight.w500),
                      )),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ],
        )),
      ),
    );
  }
}
