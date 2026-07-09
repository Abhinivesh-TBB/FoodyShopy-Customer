import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import '../../../app/constants.dart';
import '../storage/secure_storage_service.dart';
import 'logger_service.dart';

class WebSocketService {
  WebSocketService._internal();

  static final WebSocketService _instance = WebSocketService._internal();

  factory WebSocketService() => _instance;

  IO.Socket? _socket;

  bool _isConnected = false;

  final List<VoidCallback> _reconnectListeners = [];

  bool get isConnected => _isConnected;

  IO.Socket? get socket => _socket;

  Future<void> connect() async {
    if (_socket?.connected == true) return;

    final token = await SecureStorageService.getAccessToken();

    if (token == null || token.isEmpty) {
      LoggerService.logger.w(
        'WebSocket connection skipped. No access token found.',
      );
      return;
    }

    LoggerService.logger.i('Connecting WebSocket: ${AppConstants.wsBaseUrl}');

    _socket = IO.io(
      AppConstants.wsBaseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(2000)
          .setReconnectionDelayMax(10000)
          .build(),
    );

    _socket!
      ..onConnect((_) {
        _isConnected = true;
        LoggerService.logger.i('WebSocket connected.');
      })
      ..onDisconnect((_) {
        _isConnected = false;
        LoggerService.logger.w('WebSocket disconnected.');
      })
      ..onReconnect((_) {
        _isConnected = true;
        LoggerService.logger.i('WebSocket reconnected.');

        for (final listener in List<VoidCallback>.from(_reconnectListeners)) {
          listener();
        }
      })
      ..onConnectError((error) {
        LoggerService.logger.e('WebSocket connection failed.', error: error);
      });

    _socket!.connect();
  }

  void addReconnectListener(VoidCallback listener) {
    if (!_reconnectListeners.contains(listener)) {
      _reconnectListeners.add(listener);
    }
  }

  void removeReconnectListener(VoidCallback listener) {
    _reconnectListeners.remove(listener);
  }

  void subscribeToOrder(
    String orderId,
    void Function(Map<String, dynamic>) onEvent,
  ) {
    if (_socket == null) return;

    _socket!
      ..off('order.update')
      ..off('order.assigned')
      ..off('payment.confirmed');

    LoggerService.logger.i('Subscribed to order: $orderId');

    _socket!.emit('subscribe', {'channel': 'order', 'order_id': orderId});

    _socket!.on('order.update', (data) {
      if (data is Map<String, dynamic> && data['order_id'] == orderId) {
        onEvent(data);
      }
    });

    _socket!.on('order.assigned', (data) {
      if (data is Map<String, dynamic> && data['order_id'] == orderId) {
        onEvent(data);
      }
    });

    _socket!.on('payment.confirmed', (data) {
      if (data is Map<String, dynamic> && data['order_id'] == orderId) {
        onEvent(data);
      }
    });
  }

  void subscribeToRiderLocation(
    String riderId,
    void Function(double, double) onLocation,
  ) {
    if (_socket == null) return;

    _socket!.off('rider.location');

    LoggerService.logger.i('Subscribed to rider: $riderId');

    _socket!.emit('subscribe', {
      'channel': 'rider_location',
      'rider_id': riderId,
    });

    _socket!.on('rider.location', (data) {
      if (data is Map<String, dynamic>) {
        final lat = (data['lat'] as num?)?.toDouble();
        final lng = (data['lng'] as num?)?.toDouble();

        if (lat != null && lng != null) {
          onLocation(lat, lng);
        }
      }
    });
  }

  void unsubscribeFromOrder(String orderId) {
    if (_socket == null) return;

    LoggerService.logger.i('Unsubscribed from order: $orderId');

    _socket!.emit('unsubscribe', {'channel': 'order', 'order_id': orderId});

    _socket!
      ..off('order.update')
      ..off('order.assigned')
      ..off('payment.confirmed');
  }

  void unsubscribeFromRiderLocation(String riderId) {
    if (_socket == null) return;

    LoggerService.logger.i('Unsubscribed from rider: $riderId');

    _socket!.emit('unsubscribe', {
      'channel': 'rider_location',
      'rider_id': riderId,
    });

    _socket!.off('rider.location');
  }

  void disconnect() {
    if (_socket == null) return;

    LoggerService.logger.i('Disconnecting WebSocket.');

    _socket!
      ..dispose()
      ..disconnect();

    _socket = null;
    _isConnected = false;
    _reconnectListeners.clear();
  }
}
