class StorePostCustomersCustomerReq {
  String? billingAddress;
  String? email;
  String? firstName;
  String? lastName;
  Map<String, dynamic>? metadata;
  String? password;
  String? phone;
  int? countryId;

  StorePostCustomersCustomerReq({
    this.billingAddress,
    this.email,
    this.firstName,
    this.lastName,
    this.metadata,
    this.password,
    this.phone,
    this.countryId,
  });

  StorePostCustomersCustomerReq.fromJson(Map<String, dynamic> json) {
    billingAddress = json['billing_address'];
    email = json['email'];
    firstName = json['first_name'];
    lastName = json['last_name'];
    metadata = json['metadata'];
    password = json['password'];
    phone = json['phone'];
    countryId = json['country_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['billing_address'] = billingAddress;
    data['email'] = email;
    data['first_name'] = firstName;
    data['last_name'] = lastName;
    if (metadata != null) {
      data['metadata'] = metadata;
    }
    data['password'] = password;
    data['phone'] = phone;
    if (countryId != null) data['country_id'] = countryId;
    return data;
  }
}
