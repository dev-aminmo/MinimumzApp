import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:minimumz/common/doh_client.dart';
import 'data/services/index.dart';

class DataStore {
  DataStore._({
    required this.baseUrl,
    this.interceptors,
    required this.auth,
    required this.carts,
    required this.customers,
    required this.orders,
    required this.orderEdits,
    required this.products,
    required this.regions,
    required this.returnReasons,
    required this.returns,
    required this.shippingOptions,
    required this.swaps,
    required this.collections,
    required this.giftCards,
    required this.paymentMethods,
    required this.reviews,
    required this.brands,
    required this.slider,
  });

  factory DataStore.initialize({
    required String baseUrl,
    List<Interceptor>? interceptors,
  }) {
    final Dio dio = Dio();
    String baseURL = '';

    if (baseUrl.endsWith('/store')) {
      baseURL = baseUrl.replaceAll('/store', '');
    } else {
      baseURL = baseUrl;
    }

    dio.options = BaseOptions(
      baseUrl: baseURL,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
    );

    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
        makeDohHttpClient;

    interceptors?.forEach((element) {
      dio.interceptors.add(element);
    });

    return DataStore._(
      baseUrl: baseUrl,
      interceptors: interceptors,
      auth: AuthResource(dio),
      carts: CartsResource(dio),
      customers: CustomersResource(dio),
      orders: OrdersResource(dio),
      orderEdits: OrderEditsResource(dio),
      products: ProductsResource(dio),
      regions: RegionsResource(dio),
      returnReasons: ReturnReasonsResource(dio),
      returns: ReturnsResource(dio),
      shippingOptions: ShippingOptionsResource(dio),
      swaps: SwapsResource(dio),
      collections: CollectionsResource(dio),
      giftCards: GiftCardsResource(dio),
      paymentMethods: PaymentMethodsResource(dio),
      reviews: ReviewsResource(dio),
      brands: BrandsResource(dio),
      slider: SliderResource(dio),
    );
  }

  final String baseUrl;
  final List<Interceptor>? interceptors;
  final AuthResource auth;
  final CartsResource carts;
  final CustomersResource customers;
  final OrdersResource orders;
  final OrderEditsResource orderEdits;
  final ProductsResource products;
  final RegionsResource regions;
  final ReturnReasonsResource returnReasons;
  final ReturnsResource returns;
  final ShippingOptionsResource shippingOptions;
  final SwapsResource swaps;
  final CollectionsResource collections;
  final GiftCardsResource giftCards;
  final PaymentMethodsResource paymentMethods;
  final ReviewsResource reviews;
  final BrandsResource brands;
  final SliderResource slider;
}
