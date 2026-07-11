/// A driver-agnostic description of a deep-link action: what to open/apply.
/// Both the outbound (share-link) and inbound (incoming-link) sides speak this
/// language, so drivers only translate to/from their own URL/SDK format.
enum DeepLinkKind { product, cart, referral, unknown }

class DeepLinkTarget {
  const DeepLinkTarget(this.kind, [this.params = const {}]);

  final DeepLinkKind kind;
  final Map<String, String> params;

  String? get productId => params['product_id'];
  String? get cartId => params['cart_id'];
  String? get referralCode => params['referral_code'];

  factory DeepLinkTarget.product(String id) =>
      DeepLinkTarget(DeepLinkKind.product, {'product_id': id});
  factory DeepLinkTarget.cart(String id) =>
      DeepLinkTarget(DeepLinkKind.cart, {'cart_id': id});
  factory DeepLinkTarget.referral(String code) =>
      DeepLinkTarget(DeepLinkKind.referral, {'referral_code': code});
}
