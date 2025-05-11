import 'item_model.dart';

class CartItem {
  final int id;
  final Item item;
  int quantity;

  CartItem({
    required this.id,
    required this.item,
    this.quantity = 1,
  });

  factory CartItem.fromJson(Map<String, dynamic> json, Item item) {
    return CartItem(
      id: json['id'],
      item: item,
      quantity: json['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'item_id': item.id,
      'quantity': quantity,
    };
  }

  double get totalPrice => item.price * quantity;

  CartItem copyWith({
    int? id,
    Item? item,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
    );
  }
}

class Cart {
  final List<CartItem> items;

  Cart({this.items = const []});

  double get totalPrice =>
      items.fold(0, (total, item) => total + item.totalPrice);

  int get itemCount => items.fold(0, (total, item) => total + item.quantity);

  bool get isEmpty => items.isEmpty;

  Cart copyWith({List<CartItem>? items}) {
    return Cart(
      items: items ?? this.items,
    );
  }

  Cart addItem(CartItem item) {
    final existingIndex = items.indexWhere((i) => i.item.id == item.item.id);

    if (existingIndex >= 0) {
      final existingItem = items[existingIndex];
      final updatedItems = [...items];
      updatedItems[existingIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + item.quantity);
      return copyWith(items: updatedItems);
    } else {
      return copyWith(items: [...items, item]);
    }
  }

  Cart removeItem(int itemId) {
    return copyWith(
        items: items.where((item) => item.item.id != itemId).toList());
  }

  Cart updateQuantity(int itemId, int quantity) {
    final updatedItems = [...items];
    final itemIndex = items.indexWhere((item) => item.item.id == itemId);

    if (itemIndex >= 0) {
      if (quantity <= 0) {
        updatedItems.removeAt(itemIndex);
      } else {
        updatedItems[itemIndex] = items[itemIndex].copyWith(quantity: quantity);
      }
    }

    return copyWith(items: updatedItems);
  }

  Cart clear() {
    return copyWith(items: []);
  }
}
