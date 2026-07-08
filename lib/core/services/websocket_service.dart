import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../app/constants.dart';
import '../storage/secure_storage_service.dart';
import 'logger_service.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  final List<void Function()> _reconnectListeners = [];

  bool get isConnected => _isConnected;

  Future<void> connect() async {
    if (_socket != null && _socket!.connected) return;

    final token = await SecureStorageService.getAccessToken();
    if (token == null || token.isEmpty) {
      LoggerService.logger.w("WebSocket: No access token found. Refusing to connect.");
      return;
    }

    LoggerService.logger.i("WebSocket: Connecting to ${AppConstants.wsBaseUrl}");

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

    _socket!.onConnect((_) {
      LoggerService.logger.i("WebSocket: Connected successfully.");
      _isConnected = true;
    });

    _socket!.onDisconnect((_) {
      LoggerService.logger.w("WebSocket: Disconnected.");
      _isConnected = false;
    });

    _socket!.onReconnect((_) {
      LoggerService.logger.i("WebSocket: Reconnected. Alerting listeners.");
      _isConnected = true;
      for (final listener in _reconnectListeners) {
        listener();
      }
    });

    _socket!.onConnectError((err) {
      LoggerService.logger.e("WebSocket Connect Error: $err");
    });

    _socket!.connect();
  }

  void addReconnectListener(void Function() listener) {
    _reconnectListeners.add(listener);
  }

  void removeReconnectListener(void Function() listener) {
    _reconnectListeners.remove(listener);
  }

  void subscribeToOrder(String orderId, void Function(Map<String, dynamic> event) onEvent) {
    if (_socket == null) return;
    
    LoggerService.logger.i("WebSocket: Subscribing to order channel order:$orderId");
    // Emit subscribe message per spec
    _socket!.emit('subscribe', {'channel': 'order', 'order_id': orderId});

    // Listen on order status events
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

  void subscribeToRiderLocation(String riderId, void Function(double lat, double lng) onLocation) {
    if (_socket == null) return;

    LoggerService.logger.i("WebSocket: Subscribing to rider channel rider:$riderId:location");
    _socket!.emit('subscribe', {'channel': 'rider_location', 'rider_id': riderId});

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
    LoggerService.logger.i("WebSocket: Unsubscribing from order channel order:$orderId");
    _socket!.emit('unsubscribe', {'channel': 'order', 'order_id': orderId});
    _socket!.off('order.update');
    _socket!.off('order.assigned');
    _socket!.off('payment.confirmed');
  }

  void unsubscribeFromRiderLocation(String riderId) {
    if (_socket == null) return;
    LoggerService.logger.i("WebSocket: Unsubscribing from rider channel rider:$riderId:location");
    _socket!.emit('unsubscribe', {'channel': 'rider_location', 'rider_id': riderId});
    _socket!.off('rider.location');
  }

  void disconnect() {
    if (_socket != null) {
      LoggerService.logger.i("WebSocket: Disconnecting.");
      _socket!.disconnect();
      _socket = null;
      _isConnected = false;
    }
  }
}
