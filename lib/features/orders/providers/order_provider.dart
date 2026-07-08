import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_cache.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/logger_service.dart';
import '../../../shared/mocks/mock_data.dart';

class OrderItem {
  final String name;
  final int quantity;
  final double price;

  const OrderItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] ?? json['menu_item_name'] ?? 'Item',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] ?? json['unit_price'] as num).toDouble(),
    );
  }
}

class OrderModel {
  final String id;
  final String restaurantName;
  final List<OrderItem> items;
  final double grandTotal;
  final String date;
  final String status;
  final String handoffOtp;
  final String addressLine;
  final String paymentMethod;

  const OrderModel({
    required this.id,
    required this.restaurantName,
    required this.items,
    required this.grandTotal,
    required this.date,
    required this.status,
    required this.handoffOtp,
    required this.addressLine,
    required this.paymentMethod,
  });

  OrderModel copyWith({
    String? id,
    String? restaurantName,
    List<OrderItem>? items,
    double? grandTotal,
    String? date,
    String? status,
    String? handoffOtp,
    String? addressLine,
    String? paymentMethod,
  }) {
    return OrderModel(
      id: id ?? this.id,
      restaurantName: restaurantName ?? this.restaurantName,
      items: items ?? this.items,
      grandTotal: grandTotal ?? this.grandTotal,
      date: date ?? this.date,
      status: status ?? this.status,
      handoffOtp: handoffOtp ?? this.handoffOtp,
      addressLine: addressLine ?? this.addressLine,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantName': restaurantName,
      'items': items.map((e) => e.toJson()).toList(),
      'grandTotal': grandTotal,
      'date': date,
      'status': status,
      'handoffOtp': handoffOtp,
      'addressLine': addressLine,
      'paymentMethod': paymentMethod,
    };
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      restaurantName: json['restaurantName'] ?? json['restaurant_name'] ?? 'Restaurant',
      items: (json['items'] as List).map((e) => OrderItem.fromJson(e)).toList(),
      grandTotal: (json['grandTotal'] ?? json['total_amount'] as num).toDouble(),
      date: json['date'] ?? json['created_at'] ?? 'Just now',
      status: json['status'],
      handoffOtp: json['handoffOtp'] ?? '0000',
      addressLine: json['addressLine'] ?? json['delivery_address'] ?? 'Location',
      paymentMethod: json['paymentMethod'] ?? 'Razorpay',
    );
  }
}

class OrderNotifier extends StateNotifier<List<OrderModel>> {
  static const String _keyOrders = 'key_order_history';
  final bool useMock = false;

  OrderNotifier() : super(const []) {
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    if (!useMock) {
      try {
        final response = await ApiClient.dio.get('/customer/orders');
        if (response.statusCode == 200) {
          final List<dynamic> data = response.data;
          final list = data.map((json) {
            final List<dynamic> rawItems = json['items'] ?? [];
            final itemsList = rawItems.map((e) => OrderItem(
              name: e['menu_item_name'] ?? e['name'] ?? 'Item',
              quantity: e['quantity'] ?? 1,
              price: (e['unit_price'] ?? e['price'] as num).toDouble(),
            )).toList();

            return OrderModel(
              id: json['id'] ?? 'ord_unknown',
              restaurantName: json['restaurant']?['name'] ?? json['restaurant_name'] ?? 'Restaurant',
              items: itemsList,
              grandTotal: (json['total_amount'] as num).toDouble(),
              date: json['created_at'] ?? 'Just now',
              status: _capitalize(json['status'] ?? 'Placed'),
              handoffOtp: 'xxxx',
              addressLine: json['delivery_address'] ?? 'Address',
              paymentMethod: json['payment']?['method'] ?? 'Razorpay',
            );
          }).toList();
          
          state = list;
          _saveToCache(list);
          return;
        }
      } catch (e) {
        LoggerService.logger.e("Failed to fetch order history: $e. Falling back to local cache.");
      }
    }

    // Cache/Mock Fallback
    _loadOrdersFromCache();
  }

  void _loadOrdersFromCache() {
    try {
      final jsonString = LocalCache.getString(_keyOrders);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decodedList = json.decode(jsonString);
        final list = decodedList.map((e) => OrderModel.fromJson(e)).toList();
        state = list;
      } else {
        // Mock default orders
        final defaults = mockDefaultOrders;
        state = defaults;
        _saveToCache(defaults);
      }
    } catch (_) {
      // Fallback
    }
  }

  void _saveToCache(List<OrderModel> list) {
    try {
      final listJson = list.map((e) => e.toJson()).toList();
      LocalCache.setString(_keyOrders, json.encode(listJson));
    } catch (_) {
      // Fallback
    }
  }

  void addOrder(OrderModel order) {
    final list = [order, ...state];
    state = list;
    _saveToCache(list);
  }

  void updateOrderStatus(String orderId, String newStatus) {
    final list = state.map((order) {
      if (order.id == orderId) {
        return order.copyWith(status: newStatus);
      }
      return order;
    }).toList();
    state = list;
    _saveToCache(list);
  }

  String _capitalize(String status) {
    if (status.isEmpty) return status;
    if (status == 'pending') return 'Placed';
    if (status == 'accepted') return 'Placed';
    if (status == 'preparing') return 'Preparing';
    if (status == 'ready') return 'Preparing';
    if (status == 'picked_up') return 'Out for Delivery';
    if (status == 'delivered') return 'Delivered';
    if (status == 'cancelled') return 'Cancelled';
    return status[0].toUpperCase() + status.substring(1);
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, List<OrderModel>>((ref) {
  return OrderNotifier();
});
