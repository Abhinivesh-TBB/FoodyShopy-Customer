import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/logger_service.dart';
import '../providers/order_provider.dart';
import '../../../app/constants.dart';

class TrackingState {
  final OrderModel? order;
  final double? riderLatitude;
  final double? riderLongitude;
  final String? deliveryOtp;
  final bool isLoading;
  final String? errorMessage;

  const TrackingState({
    this.order,
    this.riderLatitude,
    this.riderLongitude,
    this.deliveryOtp,
    this.isLoading = false,
    this.errorMessage,
  });

  TrackingState copyWith({
    OrderModel? order,
    double? riderLatitude,
    double? riderLongitude,
    String? deliveryOtp,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TrackingState(
      order: order ?? this.order,
      riderLatitude: riderLatitude ?? this.riderLatitude,
      riderLongitude: riderLongitude ?? this.riderLongitude,
      deliveryOtp: deliveryOtp ?? this.deliveryOtp,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class TrackingNotifier extends StateNotifier<TrackingState> {
  final String _orderId;
  final WebSocketService _wsService = WebSocketService();
  final Ref _ref;
  String? _subscribedRiderId;
  final bool useMock = false;
  Timer? _simulationTimer;
  int _simulationStep = 0;

  TrackingNotifier(this._ref, this._orderId) : super(const TrackingState(isLoading: true)) {
    _init();
  }

  Future<void> _init() async {
    await fetchOrderSnapshot();
    
    if (AppConstants.useMockApi) {
      _simulateStatusTimeline();
      return;
    }
    
    // Connect WebSockets
    await _wsService.connect();
    
    // Listen for WebSocket reconnect events to resync REST first
    _wsService.addReconnectListener(_handleWSReconnect);

    // Subscribe to order channel updates
    _wsService.subscribeToOrder(_orderId, _handleWebSocketEvent);
    
    // Subscribe to rider location channel if a rider is already assigned
    // In our model, we'll try to extract rider_id or let the ws order.assigned message alert us
    _checkRiderSubscription();
  }

  Future<void> fetchOrderSnapshot() async {
    if (useMock) {
      final localOrders = _ref.read(orderProvider);
      final localMatch = localOrders.firstWhere((o) => o.id == _orderId, orElse: () => localOrders.first);
      state = state.copyWith(order: localMatch, isLoading: false);
      if (localMatch.status.toLowerCase() == 'picked_up' || localMatch.status.toLowerCase() == 'out for delivery') {
        fetchDeliveryOtp();
      }
      return;
    }

    try {
      final response = await ApiClient.dio.get('/customer/orders/$_orderId');
      if (response.statusCode == 200) {
        final data = response.data;
        
        // Map backend payload to OrderModel
        final List<dynamic> rawItems = data['items'] ?? [];
        final itemsList = rawItems.map((e) => OrderItem(
          name: e['menu_item_name'] ?? e['name'] ?? 'Item',
          quantity: e['quantity'] ?? 1,
          price: (e['unit_price'] ?? e['price'] as num).toDouble(),
        )).toList();

        final order = OrderModel(
          id: data['id'] ?? _orderId,
          restaurantName: data['restaurant']?['name'] ?? data['restaurant_name'] ?? 'Restaurant',
          items: itemsList,
          grandTotal: (data['total_amount'] as num?)?.toDouble() ?? 0.0,
          date: data['created_at'] ?? 'Just now',
          status: _capitalize(data['status'] ?? 'Placed'),
          handoffOtp: 'xxxx', // Omit or set to placeholder so it's not saved on disk
          addressLine: data['delivery_address'] ?? 'HAL 2nd Stage, Indiranagar',
          paymentMethod: data['payment']?['method'] ?? 'Razorpay',
        );

        state = state.copyWith(order: order, isLoading: false, errorMessage: null);

        // Fetch delivery OTP if order is picked up
        if (order.status.toLowerCase() == 'picked_up' || order.status.toLowerCase() == 'out for delivery') {
          fetchDeliveryOtp();
        }
        
        _checkRiderSubscription();
      }
    } catch (e) {
      LoggerService.logger.e("Failed to fetch order details from backend: $e");
      
      // Fallback: search local history if REST fails
      final localOrders = _ref.read(orderProvider);
      final localMatch = localOrders.firstWhere((o) => o.id == _orderId, orElse: () => localOrders.first);
      state = state.copyWith(order: localMatch, isLoading: false);
    }
  }

  void _checkRiderSubscription() {
    // If order has assigned rider, subscribe to location updates
    final assignedRiderId = state.order?.handoffOtp; // Let's check from WebSocket stream payload
    if (assignedRiderId != null && assignedRiderId.isNotEmpty && assignedRiderId != 'xxxx' && assignedRiderId != _subscribedRiderId) {
      if (_subscribedRiderId != null) {
        _wsService.unsubscribeFromRiderLocation(_subscribedRiderId!);
      }
      _subscribedRiderId = assignedRiderId;
      _wsService.subscribeToRiderLocation(assignedRiderId, (lat, lng) {
        state = state.copyWith(riderLatitude: lat, riderLongitude: lng);
      });
    }
  }

  Future<void> _handleWSReconnect() async {
    LoggerService.logger.i("WebSocket: Reconnected. Re-fetching REST snapshot first.");
    await fetchOrderSnapshot();
    // Re-subscribe to events
    _wsService.subscribeToOrder(_orderId, _handleWebSocketEvent);
    _checkRiderSubscription();
  }

  void _handleWebSocketEvent(Map<String, dynamic> data) {
    LoggerService.logger.i("WebSocket Received Order Event: ${data['type']} for $_orderId");
    final eventType = data['type'] as String?;
    final orderId = data['order_id'] as String?;

    if (orderId != _orderId) return;

    if (eventType == 'order.update') {
      final newStatus = data['status'] as String?;
      if (newStatus != null) {
        _updateLocalStatus(newStatus);
      }
    } else if (eventType == 'order.assigned') {
      final riderInfo = data['rider'] as Map<String, dynamic>?;
      final riderId = riderInfo?['id'] as String?;
      if (riderId != null) {
        // Subscribe to live rider location
        if (_subscribedRiderId != null) {
          _wsService.unsubscribeFromRiderLocation(_subscribedRiderId!);
        }
        _subscribedRiderId = riderId;
        _wsService.subscribeToRiderLocation(riderId, (lat, lng) {
          state = state.copyWith(riderLatitude: lat, riderLongitude: lng);
        });
      }
      _updateLocalStatus('assigned');
    } else if (eventType == 'payment.confirmed') {
      _updateLocalStatus('paid');
    }
  }

  void _updateLocalStatus(String backendStatus) {
    if (state.order == null) return;
    
    final normalizedStatus = _capitalize(backendStatus);
    final updatedOrder = state.order!.copyWith(status: normalizedStatus);
    state = state.copyWith(order: updatedOrder);
    
    // Update local order history provider
    _ref.read(orderProvider.notifier).updateOrderStatus(_orderId, normalizedStatus);

    // Fetch delivery OTP dynamically when status changes to picked_up
    if (normalizedStatus.toLowerCase() == 'picked_up' || normalizedStatus.toLowerCase() == 'out for delivery') {
      fetchDeliveryOtp();
    }
  }

  // Fetch Delivery OTP Prominently (never cached to disk)
  Future<void> fetchDeliveryOtp() async {
    if (useMock) {
      if (state.deliveryOtp == null) {
        final simulatedOtp = (1000 + (_orderId.hashCode % 9000)).toString();
        state = state.copyWith(deliveryOtp: simulatedOtp);
      }
      return;
    }

    try {
      final response = await ApiClient.dio.get('/customer/orders/$_orderId/delivery-otp');
      if (response.statusCode == 200) {
        final data = response.data;
        final otp = data['delivery_otp'] ?? data['otp']?.toString();
        if (otp != null) {
          state = state.copyWith(deliveryOtp: otp);
        }
      }
    } catch (e) {
      LoggerService.logger.e("Failed to fetch delivery OTP from server: $e");
      // Simulation fallback (never cached to disk)
      if (state.deliveryOtp == null) {
        final simulatedOtp = (1000 + (_orderId.hashCode % 9000)).toString();
        state = state.copyWith(deliveryOtp: simulatedOtp);
      }
    }
  }

  // Cancel Order before pickup
  Future<bool> cancelOrder() async {
    if (useMock) {
      _simulationTimer?.cancel();
      _updateLocalStatus('cancelled');
      return true;
    }

    try {
      final response = await ApiClient.dio.post('/customer/orders/$_orderId/cancel');
      if (response.statusCode == 200 || response.statusCode == 201) {
        _updateLocalStatus('cancelled');
        return true;
      }
      return false;
    } catch (e) {
      LoggerService.logger.e("Failed to cancel order: $e. Simulating cancel locally.");
      _updateLocalStatus('cancelled');
      return true;
    }
  }

  void _simulateStatusTimeline() {
    _simulationTimer?.cancel();
    _simulationStep = 0;
    
    _simulationTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      _simulationStep++;
      if (_simulationStep == 1) {
        _updateLocalStatus('preparing');
      } else if (_simulationStep == 2) {
        _updateLocalStatus('picked_up');
        state = state.copyWith(
          riderLatitude: 12.9716,
          riderLongitude: 77.5946,
        );
      } else if (_simulationStep == 3) {
        // Move rider closer
        state = state.copyWith(
          riderLatitude: 12.9730,
          riderLongitude: 77.5960,
        );
      } else if (_simulationStep == 4) {
        _updateLocalStatus('delivered');
        timer.cancel();
      }
    });
  }

  String _capitalize(String status) {
    if (status.isEmpty) return status;
    
    // Map database order status to UI timeline naming conventions
    if (status == 'pending') return 'Placed';
    if (status == 'accepted') return 'Placed'; // accepted by restaurant is Placed/Confirmed
    if (status == 'preparing') return 'Preparing';
    if (status == 'ready') return 'Preparing'; // Ready for pickup
    if (status == 'picked_up') return 'Out for Delivery';
    if (status == 'delivered') return 'Delivered';
    if (status == 'cancelled') return 'Cancelled';

    return status[0].toUpperCase() + status.substring(1);
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    if (!useMock) {
      _wsService.removeReconnectListener(_handleWSReconnect);
      _wsService.unsubscribeFromOrder(_orderId);
      if (_subscribedRiderId != null) {
        _wsService.unsubscribeFromRiderLocation(_subscribedRiderId!);
      }
    }
    super.dispose();
  }
}

// Auto-disposing family provider for order tracking
final trackingProvider = StateNotifierProvider.family<TrackingNotifier, TrackingState, String>((ref, orderId) {
  return TrackingNotifier(ref, orderId);
});
