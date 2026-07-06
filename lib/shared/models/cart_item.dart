import 'menu_item.dart';

class CartItem {
  final MenuItem item;
  final int quantity;
  final String restaurantId;
  final String restaurantName;

  const CartItem({
    required this.item,
    required this.quantity,
    required this.restaurantId,
    required this.restaurantName,
  });

  CartItem copyWith({
    MenuItem? item,
    int? quantity,
    String? restaurantId,
    String? restaurantName,
  }) {
    return CartItem(
      item: item ?? this.item,
      quantity: quantity ?? this.quantity,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      item: MenuItem.fromJson(json['item'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      restaurantId: json['restaurantId'] as String? ?? '',
      restaurantName: json['restaurantName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item': item.toJson(),
      'quantity': quantity,
      'restaurantId': restaurantId,
      'restaurantName': restaurantName,
    };
  }
}
