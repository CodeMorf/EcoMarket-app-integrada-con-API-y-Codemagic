import 'package:shop/models/product_model.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get lineTotal => (product.priceAfetDiscount ?? product.price) * quantity;

  Map<String, dynamic> toApiJson() => {
        'product_id': product.id,
        'quantity': quantity,
      };
}

class CartService {
  CartService._();
  static final CartService instance = CartService._();

  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get count => _items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => _items.fold(0, (sum, item) => sum + item.lineTotal);

  void add(ProductModel product, {int quantity = 1}) {
    if (product.id == null) return;
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
  }

  void updateQuantity(int productId, int quantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index < 0) return;
    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].quantity = quantity;
    }
  }

  void remove(int productId) => _items.removeWhere((item) => item.product.id == productId);
  void clear() => _items.clear();

  List<Map<String, dynamic>> toApiItems() => _items.map((item) => item.toApiJson()).toList();
}
