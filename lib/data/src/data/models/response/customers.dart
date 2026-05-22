import '../store/orders/order.dart';
import '../store/others/index.dart';

class StoreCustomersRes {
  Customer? customer;
  String? accessToken;

  StoreCustomersRes.fromJson(Map<String, dynamic> json) {
    customer = json['customer'] != null ? Customer.fromJson(json["customer"]) : null;
    accessToken = json['access_token'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (customer != null) {
      data['customer'] = customer;
    }
    if (accessToken != null) {
      data['access_token'] = accessToken;
    }
    return data;
  }
}

class StoreCustomersListOrdersRes {
  final List<Order>? orders;
  StoreCustomersListOrdersRes(this.orders);
  factory StoreCustomersListOrdersRes.fromJson(json) {
    if (json['orders'] != null) {
      var orders = <Order>[];
      json['orders'].forEach((v) {
        orders.add(Order.fromJson(v));
      });
      return StoreCustomersListOrdersRes(orders);
    }

    return StoreCustomersListOrdersRes(null);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['orders'] = orders?.map((e) => e.toJson()).toList();
    return data;
  }
}
