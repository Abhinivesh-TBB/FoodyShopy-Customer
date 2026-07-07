import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/local_cache.dart';

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
      name: json['name'],
      quantity: json['quantity'],
      price: (json['price'] as num).toDouble(),
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
      restaurantName: json['restaurantName'],
      items: (json['items'] as List).map((e) => OrderItem.fromJson(e)).toList(),
      grandTotal: (json['grandTotal'] as num).toDouble(),
      date: json['date'],
      status: json['status'],
      handoffOtp: json['handoffOtp'] ?? '0000',
      addressLine: json['addressLine'] ?? 'Location',
      paymentMethod: json['paymentMethod'] ?? 'Razorpay',
    );
  }
}

class OrderNotifier extends StateNotifier<List<OrderModel>> {
  static const String _keyOrders = 'key_order_history';

  OrderNotifier() : super(const []) {
    _loadOrders();
  }

  void _loadOrders() {
    try {
      final jsonString = LocalCache.getString(_keyOrders);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decodedList = json.decode(jsonString);
        final list = decodedList.map((e) => OrderModel.fromJson(e)).toList();
        state = list;
      } else {
        // Mock default orders
        final defaults = [
          OrderModel(
            id: 'ord_98124',
            restaurantName: 'Meghana Foods',
            items: [
              const OrderItem(name: 'Meghana Special Chicken Biryani', quantity: 1, price: 320),
              const OrderItem(name: 'Gobi 65 Dry', quantity: 1, price: 180),
            ],
            grandTotal: 531.0,
            date: '05 July 2026, 08:30 PM',
            status: 'Delivered',
            handoffOtp: '4932',
            addressLine: 'HAL 2nd Stage, Indiranagar, Bengaluru',
            paymentMethod: 'UPI',
          ),
          OrderModel(
            id: 'ord_12763',
            restaurantName: "Leon's Burgers & Wings",
            items: [
              const OrderItem(name: 'Jumbo Crispy Chicken Burger', quantity: 1, price: 199),
            ],
            grandTotal: 214.0,
            date: '28 June 2026, 01:15 PM',
            status: 'Delivered',
            handoffOtp: '1176',
            addressLine: 'HAL 2nd Stage, Indiranagar, Bengaluru',
            paymentMethod: 'Credit/Debit Card',
          ),
        ];
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
}

final orderProvider = StateNotifierProvider<OrderNotifier, List<OrderModel>>((ref) {
  return OrderNotifier();
});
