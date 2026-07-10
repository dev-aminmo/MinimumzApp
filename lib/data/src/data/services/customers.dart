import 'dart:developer';

import 'package:minimumz/data/src/data/models/store/others/address.dart';
import 'package:minimumz/data/src/data/models/store/orders/order.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';

import '../models/request/index.dart';
import '../models/response/index.dart';
import 'base.dart';

class CustomersResource extends BaseResource {
  CustomersResource(super.client);

  /// Creates a customer
  /// @param {StorePostCustomersReq} payload information of customer
  /// @param customHeaders
  /// @return { ResponsePromise<StoreCustomersRes>}
  Future<StoreCustomersRes?> create({StorePostCustomersReq? req, Map<String, dynamic>? customHeaders}) async {
    try {
      if (customHeaders != null) {
        client.options.headers.addAll(customHeaders);
      }
      // Attach a referral code captured from an install deep link (new invitee).
      final payload = req?.toJson() ?? <String, dynamic>{};
      final pendingReferral = PreferenceRepository.instance.pendingReferralCode;
      if (pendingReferral != null && pendingReferral.isNotEmpty) {
        payload['referral_code'] = pendingReferral;
      }

      final response = await client.post('/store/customers', data: payload);
      if (response.statusCode == 200) {
        if (pendingReferral != null) {
          await PreferenceRepository.instance.clearPendingReferralCode();
        }
        return StoreCustomersRes.fromJson(response.data);
      } else {
        throw response;
      }
    } catch (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }

  ///Retrieves the customer that is currently logged
  /// @param customHeaders
  /// @return {ResponsePromise<StoreCustomersRes>}
  Future<StoreCustomersRes?> retrieve({Map<String, dynamic>? customHeaders}) async {
    try {
      if (customHeaders != null) {
        client.options.headers.addAll(customHeaders);
      }
      final response = await client.get(
        '/store/customers/me',
      );
      if (response.statusCode == 200) {
        return StoreCustomersRes.fromJson(response.data);
      } else {
        throw response;
      }
    } catch (error) {
      log(error.toString());
      rethrow;
    }
  }

  /// Updates a customer
  /// @param {StorePostCustomersCustomerReq} payload information to update customer with
  /// @param customHeaders
  /// @return {ResponsePromise<StoreCustomersRes>}
  Future<StoreCustomersRes?> update({StorePostCustomersCustomerReq? req, Map<String, dynamic>? customHeaders}) async {
    try {
      if (customHeaders != null) {
        client.options.headers.addAll(customHeaders);
      }
      final response = await client.post('/store/customers/me', data: req?.toJson());
      if (response.statusCode == 200) {
        return StoreCustomersRes.fromJson(response.data);
      } else {
        throw response;
      }
    } catch (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Retrieve customer orders
  /// @param {StoreGetCustomersCustomerOrdersParams} params optional params to retrieve orders
  /// @param customHeaders
  /// @return {ResponsePromise<StoreCustomersListOrdersRes>}

  Future<StoreCustomersListOrdersRes?> listOrders(
      {Map<String, dynamic>? queryParameters, Map<String, dynamic>? customHeaders}) async {
    try {
      if (customHeaders != null) {
        client.options.headers.addAll(customHeaders);
      }
      final response = await client.get('/store/customers/me/orders', queryParameters: queryParameters);
      if (response.statusCode == 200) {
        return StoreCustomersListOrdersRes.fromJson(response.data);
      } else {
        throw response;
      }
    } catch (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Retrieve a single order by id.
  Future<Order?> getOrder(String id, {Map<String, dynamic>? customHeaders}) async {
    try {
      if (customHeaders != null) {
        client.options.headers.addAll(customHeaders);
      }
      final response = await client.get('/store/customers/me/orders/$id');
      if (response.statusCode == 200 && response.data['order'] != null) {
        return Order.fromJson(response.data['order']);
      }
      return null;
    } catch (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Resets customer password
  /// @param {StorePostCustomersCustomerPasswordTokenReq} payload info used to reset customer password
  /// @param customHeaders
  /// @return {ResponsePromise<StoreCustomersRes>}
  Future<StoreCustomersRes?> resetPassword(
      {StorePostCustomersCustomerPasswordTokenReq? req, Map<String, dynamic>? customHeaders}) async {
    try {
      if (customHeaders != null) {
        client.options.headers.addAll(customHeaders);
      }
      final response = await client.post('/store/customers/password-reset', data: req?.toJson());
      if (response.statusCode == 200) {
        return StoreCustomersRes.fromJson(response.data);
      } else {
        throw response;
      }
    } catch (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Change the logged-in customer's password.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await client.post('/store/customers/me/password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
      if (response.statusCode != 200) throw response;
    } catch (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Generates a reset password token, which can be used to reset the password.
  /// The token is not returned but should be sent out to the customer in an email.
  /// @param {StorePostCustomersCustomerPasswordTokenReq} payload info used to generate token
  /// @param customHeaders
  /// @return {ResponsePromise}
  Future generatePasswordToken(
      {StorePostCustomersCustomerPasswordTokenReq? req, Map<String, dynamic>? customHeaders}) async {
    try {
      if (customHeaders != null) {
        client.options.headers.addAll(customHeaders);
      }
      final response = await client.post('/store/customers/password-token', data: req?.toJson());
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw response;
      }
    } catch (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<Address>> listShippingAddresses() async {
    try {
      final response = await client.get('/store/customers/me/addresses');
      if (response.statusCode == 200) {
        return (response.data['addresses'] as List)
            .map((e) => Address.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        throw response;
      }
    } catch (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Add a Shipping Address to a Customer's saved addresses.
  Future<void> updateFcmToken(String? token) async {
    try {
      await client.post('/store/customers/me/fcm-token', data: {'token': token ?? ''});
    } catch (error) {
      log(error.toString());
    }
  }

  Future addShippingAddress(
      { required Address address, Map<String, dynamic>? customHeaders}) async {
    try {
      if (customHeaders != null) {
        client.options.headers.addAll(customHeaders);
      }
      final response = await client.post('/store/customers/me/addresses', data: address.toJson());
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw response;
      }
    } catch (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }
  /// Update the logged-in customer's saved Shipping Address's details.
  Future updateShippingAddress(
      {
        required String addressId,
        required Address address, Map<String, dynamic>? customHeaders}) async {
    try {
      if (customHeaders != null) {
        client.options.headers.addAll(customHeaders);
      }
      final response = await client.post('/store/customers/me/addresses/$addressId', data: address.toJson());
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw response;
      }
    } catch (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Delete an Address from the Customer's saved addresses.
  Future deleteShippingAddress(
      {
        required String addressId,
       Map<String, dynamic>? customHeaders}) async {
    try {
      if (customHeaders != null) {
        client.options.headers.addAll(customHeaders);
      }
      final response = await client.delete('/store/customers/me/addresses/$addressId');
      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw response;
      }
    } catch (error, stackTrace) {
      log(error.toString(), stackTrace: stackTrace);
      rethrow;
    }
  }
}
