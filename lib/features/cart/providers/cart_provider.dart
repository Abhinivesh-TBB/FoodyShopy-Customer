import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/logger_service.dart';
import '../../../app/constants.dart';
import '../../../core/storage/local_cache.dart';
import '../../../shared/models/cart_item.dart';
import '../../../shared/models/menu_item.dart';

class CartState {
  final List<CartItem> items;
  final String restaurantId;
  final String restaurantName;

  static const double _platformFee = 15.0;
  static const double _deliveryFee = 29.0;
  static const double _taxRate = 0.05;

  const CartState({
    this.items = const [],
    this.restaurantId = '',
    this.restaurantName = '',
  });

  double get subtotal =>
      items.fold(0.0, (sum, item) => sum + (item.item.price * item.quantity));

  double get platformFee => subtotal > 0 ? _platformFee : 0;

  double get deliveryFee => subtotal > 0 ? _deliveryFee : 0;

  double get taxesAndCharges => subtotal > 0 ? subtotal * _taxRate : 0;

  double get total => subtotal + taxesAndCharges + deliveryFee + platformFee;

  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({
    List<CartItem>? items,
    String? restaurantId,
    String? restaurantName,
  }) {
    return CartState(
      items: items ?? this.items,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantName: restaurantName ?? this.restaurantName,
    );
  }
}

enum CartResult { success, conflict }

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState()) {
    _loadCart();
  }

  void _loadCart() {
    try {
      final cartJsonString = LocalCache.getString(AppConstants.keyCartItems);
      if (cartJsonString != null && cartJsonString.isNotEmpty) {
        final List<dynamic> decodedList = json.decode(cartJsonString);
        final items = decodedList.map((e) => CartItem.fromJson(e)).toList();

        if (items.isNotEmpty) {
          state = CartState(
            items: items,
            restaurantId: items.first.restaurantId,
            restaurantName: items.first.restaurantName,
          );
        }
      }
    } catch (e, stackTrace) {
      LoggerService.logger.e(
        'Failed to load cart.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _saveCart() {
    try {
      final list = state.items.map((e) => e.toJson()).toList();
      LocalCache.setString(AppConstants.keyCartItems, json.encode(list));
    } catch (e, stackTrace) {
      LoggerService.logger.e(
        'Failed to save cart.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Adds an item to the cart.
  /// Returns 'success' if added, or 'conflict' if the item belongs to a different restaurant.
  CartResult addItem(
    MenuItem item,
    String restaurantId,
    String restaurantName,
  ) {
    if (state.items.isNotEmpty && state.restaurantId != restaurantId) {
      return CartResult.conflict;
    }

    final existingIndex = state.items.indexWhere((e) => e.item.id == item.id);
    List<CartItem> newItems;

    if (existingIndex >= 0) {
      final existingItem = state.items[existingIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + 1,
      );
      newItems = List<CartItem>.from(state.items)
        ..[existingIndex] = updatedItem;
    } else {
      newItems = List<CartItem>.from(state.items)
        ..add(
          CartItem(
            item: item,
            quantity: 1,
            restaurantId: restaurantId,
            restaurantName: restaurantName,
          ),
        );
    }

    state = state.copyWith(
      items: newItems,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
    );

    _saveCart();
    return CartResult.success;
  }

  /// Clears the current cart and adds the item (used when overriding restaurant conflict)
  void clearAndAddItem(
    MenuItem item,
    String restaurantId,
    String restaurantName,
  ) {
    final newItem = CartItem(
      item: item,
      quantity: 1,
      restaurantId: restaurantId,
      restaurantName: restaurantName,
    );

    state = CartState(
      items: [newItem],
      restaurantId: restaurantId,
      restaurantName: restaurantName,
    );

    _saveCart();
  }

  void removeItem(MenuItem item) {
    final existingIndex = state.items.indexWhere((e) => e.item.id == item.id);
    if (existingIndex < 0) return;

    final existingItem = state.items[existingIndex];
    List<CartItem> newItems;

    if (existingItem.quantity > 1) {
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity - 1,
      );
      newItems = List<CartItem>.from(state.items)
        ..[existingIndex] = updatedItem;
      state = state.copyWith(items: newItems);
    } else {
      newItems = List<CartItem>.from(state.items)..removeAt(existingIndex);
      if (newItems.isEmpty) {
        state = const CartState();
      } else {
        state = state.copyWith(items: newItems);
      }
    }

    _saveCart();
  }

  void updateQuantity(MenuItem item, int newQty) {
    if (newQty <= 0) {
      removeItem(item);
      return;
    }

    final existingIndex = state.items.indexWhere((e) => e.item.id == item.id);
    if (existingIndex < 0) return;

    final existingItem = state.items[existingIndex];
    final updatedItem = existingItem.copyWith(quantity: newQty);
    final newItems = List<CartItem>.from(state.items)
      ..[existingIndex] = updatedItem;

    state = state.copyWith(items: newItems);
    _saveCart();
  }

  void clearCart() {
    state = const CartState();
    LocalCache.remove(AppConstants.keyCartItems);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
