import 'package:dio/dio.dart';
import '../../shared/mocks/mock_data.dart';
import '../../shared/models/menu_item.dart';
import '../../features/orders/providers/order_provider.dart';

class MockApiInterceptor extends Interceptor {
  // In-memory order database initialized with default orders
  final List<OrderModel> _orders = List.from(mockDefaultOrders);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Introduce a mock network latency for realistic feel
    await Future.delayed(const Duration(milliseconds: 500));

    final path = options.path;

    // 1. POST /auth/otp/request
    if (path.endsWith('/auth/otp/request') || path == '/auth/otp/request') {
      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {'message': 'OTP sent successfully'},
      ));
    }

    // 2. POST /auth/otp/verify
    if (path.endsWith('/auth/otp/verify') || path == '/auth/otp/verify') {
      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'access_token': 'mock_access_token_123',
          'refresh_token': 'mock_refresh_token_123',
        },
      ));
    }

    // 3. GET /customer/restaurants
    if (path.endsWith('/customer/restaurants') || path == '/customer/restaurants') {
      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: mockRestaurants.map((e) => e.toJson()).toList(),
      ));
    }

    // 3b. PUT /customer/profile (FCM Token registration)
    if (path.endsWith('/customer/profile') || path == '/customer/profile') {
      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {'message': 'Profile updated successfully'},
      ));
    }

    // 4. GET /customer/restaurants/:id/menu
    final menuMatch = RegExp(r'/customer/restaurants/([^/]+)/menu$').firstMatch(path);
    if (menuMatch != null) {
      final restId = menuMatch.group(1);
      final rest = mockRestaurants.firstWhere(
        (e) => e.id == restId,
        orElse: () => mockRestaurants.first,
      );
      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: rest.menu.map((e) => e.toJson()).toList(),
      ));
    }

    // 5. POST /customer/offers/validate
    if (path.endsWith('/customer/offers/validate') || path == '/customer/offers/validate') {
      final data = options.data as Map<String, dynamic>;
      final restaurantId = data['restaurant_id'];
      final items = data['items'] as List;
      final code = data['code'] as String?;

      final rest = mockRestaurants.firstWhere(
        (e) => e.id == restaurantId,
        orElse: () => mockRestaurants.first,
      );

      double cartTotal = 0;
      for (final itemReq in items) {
        final itemId = itemReq['menu_item_id'];
        final qty = itemReq['quantity'] ?? 1;
        final menuItem = rest.menu.firstWhere(
          (m) => m.id == itemId,
          orElse: () => MenuItem(
            id: itemId,
            name: 'Item',
            description: '',
            price: 100,
            imageUrl: '',
            isVeg: true,
            category: '',
          ),
        );
        cartTotal += menuItem.price * qty;
      }

      double discountVal = 0.0;
      if (code != null) {
        final formattedCode = code.trim().toUpperCase();
        if (formattedCode == 'WELCOME50') {
          discountVal = (cartTotal * 0.5 > 100) ? 100.0 : cartTotal * 0.5;
        } else if (formattedCode == 'FREEDEL') {
          discountVal = 29.0;
        }
      }

      final finalTotal = (cartTotal - discountVal).clamp(0.0, double.infinity);

      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'discount_amount': discountVal,
          'total_amount': finalTotal,
        },
      ));
    }

    // 6. POST /customer/orders
    if (path.endsWith('/customer/orders') || path == '/customer/orders') {
      final data = options.data as Map<String, dynamic>;
      final restId = data['restaurant_id'];
      final address = data['delivery_address'] ?? 'HAL 2nd Stage, Indiranagar';
      final itemsReq = data['items'] as List;
      final code = data['code'] as String?;

      final rest = mockRestaurants.firstWhere(
        (e) => e.id == restId,
        orElse: () => mockRestaurants.first,
      );

      double cartTotal = 0;
      List<OrderItem> orderItems = [];
      for (final itemReq in itemsReq) {
        final itemId = itemReq['menu_item_id'];
        final qty = itemReq['quantity'] ?? 1;
        final menuItem = rest.menu.firstWhere(
          (m) => m.id == itemId,
          orElse: () => MenuItem(
            id: itemId,
            name: 'Item',
            description: '',
            price: 100,
            imageUrl: '',
            isVeg: true,
            category: '',
          ),
        );
        cartTotal += menuItem.price * qty;
        orderItems.add(OrderItem(name: menuItem.name, quantity: qty, price: menuItem.price));
      }

      double discountVal = 0.0;
      if (code != null) {
        final formattedCode = code.trim().toUpperCase();
        if (formattedCode == 'WELCOME50') {
          discountVal = (cartTotal * 0.5 > 100) ? 100.0 : cartTotal * 0.5;
        } else if (formattedCode == 'FREEDEL') {
          discountVal = 29.0;
        }
      }

      final double subtotal = cartTotal;
      final double deliveryFee = 29.0;
      final double platformFee = 2.0;
      final double gst = subtotal * 0.05;
      final double grandTotal = (subtotal + deliveryFee + platformFee + gst - discountVal).clamp(0.0, double.infinity);

      final orderId = 'ord_${(10000 + (DateTime.now().millisecondsSinceEpoch % 90000))}';
      final otp = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();

      final now = DateTime.now();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      String period = now.hour >= 12 ? 'PM' : 'AM';
      int hour = now.hour % 12;
      if (hour == 0) hour = 12;
      String min = now.minute.toString().padLeft(2, '0');
      final formattedDate = '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}, ${hour.toString().padLeft(2, '0')}:$min $period';

      final newOrder = OrderModel(
        id: orderId,
        restaurantName: rest.name,
        items: orderItems,
        grandTotal: grandTotal,
        date: formattedDate,
        status: 'Placed',
        handoffOtp: otp,
        addressLine: address,
        paymentMethod: 'Razorpay', // Checkout summary sets pay method
      );

      _orders.insert(0, newOrder);

      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 201,
        data: {
          'id': orderId,
          'order_id': orderId,
          'total_amount': grandTotal,
          'status': 'placed',
          'created_at': formattedDate,
          'delivery_address': address,
        },
      ));
    }

    // 7. GET /customer/orders
    if (path.endsWith('/customer/orders') || path == '/customer/orders') {
      final mappedOrders = _orders.map((o) => {
        'id': o.id,
        'restaurant': {'name': o.restaurantName},
        'items': o.items.map((i) => {
          'menu_item_name': i.name,
          'quantity': i.quantity,
          'unit_price': i.price,
        }).toList(),
        'total_amount': o.grandTotal,
        'created_at': o.date,
        'status': o.status,
        'delivery_address': o.addressLine,
        'payment': {'method': o.paymentMethod},
      }).toList();

      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: mappedOrders,
      ));
    }

    // 8. GET /customer/orders/:id/delivery-otp
    final otpMatch = RegExp(r'/customer/orders/([^/]+)/delivery-otp$').firstMatch(path);
    if (otpMatch != null) {
      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {'delivery_otp': '5821'},
      ));
    }

    // 9. POST /customer/orders/:id/pay
    final payMatch = RegExp(r'/customer/orders/([^/]+)/pay$').firstMatch(path);
    if (payMatch != null) {
      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'razorpay_order_id': 'pay_${DateTime.now().millisecondsSinceEpoch}',
          'key_id': 'rzp_test_mockkey',
        },
      ));
    }

    // 10. POST /customer/orders/:id/cancel
    final cancelMatch = RegExp(r'/customer/orders/([^/]+)/cancel$').firstMatch(path);
    if (cancelMatch != null) {
      final orderId = cancelMatch.group(1);
      for (int i = 0; i < _orders.length; i++) {
        if (_orders[i].id == orderId) {
          _orders[i] = _orders[i].copyWith(status: 'Cancelled');
          break;
        }
      }
      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {'status': 'cancelled'},
      ));
    }

    // 11. GET /customer/orders/:id (matches general order detail request)
    final singleOrderMatch = RegExp(r'/customer/orders/([^/]+)$').firstMatch(path);
    if (singleOrderMatch != null) {
      final orderId = singleOrderMatch.group(1);
      final order = _orders.firstWhere(
        (e) => e.id == orderId,
        orElse: () => _orders.first,
      );
      return handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'id': order.id,
          'restaurant': {'name': order.restaurantName},
          'items': order.items.map((i) => {
            'menu_item_name': i.name,
            'quantity': i.quantity,
            'unit_price': i.price,
          }).toList(),
          'total_amount': order.grandTotal,
          'created_at': order.date,
          'status': order.status,
          'delivery_address': order.addressLine,
          'payment': {'method': order.paymentMethod},
        },
      ));
    }

    // Delegate other unhandled routes to the original path handler
    super.onRequest(options, handler);
  }
}
