import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:minimumz/data/src/data/models/store/products/product.dart';
import 'package:minimumz/domain/repository/preference_repository.dart';

class WishlistCubit extends Cubit<List<Product>> {
  WishlistCubit() : super(PreferenceRepository.instance.wishlistProducts);

  bool isWishlisted(String? productId) =>
      productId != null && state.any((p) => p.id == productId);

  Future<void> toggle(Product product) async {
    final updated = List<Product>.from(state);
    final idx = updated.indexWhere((p) => p.id == product.id);
    if (idx >= 0) {
      updated.removeAt(idx);
    } else {
      updated.add(product);
    }
    await PreferenceRepository.instance.setWishlistProducts(updated);
    emit(List.unmodifiable(updated));
  }
}
