import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../providers/order_provider.dart';
import '../../../core/utils/app_snackbar.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  Timer? _statusTimer;
  int _elapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startMockStatusTimeline();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _startMockStatusTimeline() {
    _statusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      setState(() {
        _elapsedSeconds++;
      });

      // Update state at boundaries
      final orders = ref.read(orderProvider);
      final currentOrder = orders.firstWhere((o) => o.id == widget.orderId, orElse: () => orders.first);

      if (currentOrder.status == 'Delivered') {
        _statusTimer?.cancel();
        return;
      }

      if (_elapsedSeconds == 6) {
        // Transition to Preparing
        ref.read(orderProvider.notifier).updateOrderStatus(widget.orderId, 'Preparing');
        _triggerNotification('🍳 Chef is preparing your delicious food at ${currentOrder.restaurantName}!');
      } else if (_elapsedSeconds == 14) {
        // Transition to Out for Delivery
        ref.read(orderProvider.notifier).updateOrderStatus(widget.orderId, 'Out for Delivery');
        _triggerNotification('🚴 Delivery partner is on the way with your hot meal! Share handoff OTP: ${currentOrder.handoffOtp}');
      } else if (_elapsedSeconds == 22) {
        // Transition to Delivered
        ref.read(orderProvider.notifier).updateOrderStatus(widget.orderId, 'Delivered');
        _triggerNotification('🎉 Order delivered successfully! Enjoy your meal!');
        _statusTimer?.cancel();
      }
    });
  }

  void _triggerNotification(String message) {
    if (!mounted) return;
    
    // Simulate push notification in-app popup using local alert
    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) {
        Future.delayed(const Duration(seconds: 3), () {
          if (ctx.mounted) {
            Navigator.pop(ctx);
          }
        });
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 60, left: 16, right: 16),
            child: Material(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ORDER UPDATE',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 10, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersList = ref.watch(orderProvider);
    final order = ordersList.firstWhere(
      (o) => o.id == widget.orderId,
      orElse: () => OrderModel(
        id: widget.orderId,
        restaurantName: 'FoodyShopy Restaurant',
        items: const [],
        grandTotal: 0.0,
        date: 'Just now',
        status: 'Placed',
        handoffOtp: '4829',
        addressLine: 'HAL 2nd Stage, Indiranagar, Bengaluru',
        paymentMethod: 'UPI',
      ),
    );

    int etaMin = 25;
    String statusDesc = 'Waiting for restaurant confirmation';
    if (order.status == 'Preparing') {
      etaMin = 18;
      statusDesc = 'Restaurant is preparing your food';
    } else if (order.status == 'Out for Delivery') {
      etaMin = 8;
      statusDesc = 'Delivery partner has picked up your order';
    } else if (order.status == 'Delivered') {
      etaMin = 0;
      statusDesc = 'Order delivered';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Order Status'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ETA and Header info card
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.divider),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('ESTIMATED DELIVERY TIME', style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    Text(
                      order.status == 'Delivered' ? 'DELIVERED' : '$etaMin MINS',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 32, color: AppColors.primary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      statusDesc,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const Divider(height: 24, color: AppColors.divider),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Order ID', style: TextStyle(color: Colors.grey, fontSize: 10)),
                            const SizedBox(height: 2),
                            Text(order.id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Restaurant', style: TextStyle(color: Colors.grey, fontSize: 10)),
                            const SizedBox(height: 2),
                            Text(order.restaurantName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Handoff Verification OTP Card
            Card(
              elevation: 0,
              color: AppColors.primary.withOpacity(0.06),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.vpn_key_outlined, color: AppColors.primary, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Delivery Handoff OTP',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Show this to the delivery partner at your door.',
                            style: TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Text(
                        order.handoffOtp,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Timeline Card
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.divider),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ORDER TRACKING TIMELINE', style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 0.5)),
                    const SizedBox(height: 20),
                    _buildTimelineStep(
                      title: 'Order Placed',
                      subtitle: order.date,
                      isCompleted: true,
                      isActive: order.status == 'Placed',
                      isLast: false,
                    ),
                    _buildTimelineStep(
                      title: 'Preparing Food',
                      subtitle: 'Chef is cooking your meal',
                      isCompleted: order.status != 'Placed',
                      isActive: order.status == 'Preparing',
                      isLast: false,
                    ),
                    _buildTimelineStep(
                      title: 'Out for Delivery',
                      subtitle: 'Rider is on the way to you',
                      isCompleted: order.status == 'Out for Delivery' || order.status == 'Delivered',
                      isActive: order.status == 'Out for Delivery',
                      isLast: false,
                    ),
                    _buildTimelineStep(
                      title: 'Delivered',
                      subtitle: 'Enjoy your food!',
                      isCompleted: order.status == 'Delivered',
                      isActive: order.status == 'Delivered',
                      isLast: true,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Order details summary
            Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.divider),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BILL SUMMARY', style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    ...order.items.map((item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${item.quantity} x ${item.name}', style: const TextStyle(fontSize: 12)),
                              Text('₹${(item.price * item.quantity).toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        )),
                    const Divider(height: 20, color: AppColors.divider),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Paid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('₹${order.grandTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Payment Mode', style: TextStyle(color: Colors.grey, fontSize: 11)),
                        Text(order.paymentMethod, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Divider(height: 20, color: AppColors.divider),
                    const Text('DELIVERY ADDRESS', style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 0.5)),
                    const SizedBox(height: 6),
                    Text(
                      order.addressLine,
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('BACK TO HOMEPAGE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    required bool isLast,
  }) {
    final dotColor = isActive
        ? AppColors.primary
        : isCompleted
            ? Colors.green
            : Colors.grey[300]!;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: isActive
                    ? Border.all(color: AppColors.primary.withOpacity(0.3), width: 4)
                    : null,
              ),
              child: isCompleted && !isActive
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isCompleted ? Colors.green : Colors.grey[200],
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isActive
                      ? AppColors.primary
                      : isCompleted
                          ? Colors.black87
                          : Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive
                      ? AppColors.primary.withOpacity(0.8)
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
