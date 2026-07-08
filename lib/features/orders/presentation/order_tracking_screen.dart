import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../providers/tracking_provider.dart';
import '../../../core/utils/app_snackbar.dart';

class OrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;
  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends ConsumerState<OrderTrackingScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingProvider(widget.orderId));
    final trackingNotifier = ref.read(trackingProvider(widget.orderId).notifier);

    if (trackingState.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final order = trackingState.order;
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Status')),
        body: const Center(child: Text('Order not found')),
      );
    }

    // Determine ETA and Status Description
    int etaMin = 25;
    String statusDesc = 'Waiting for restaurant confirmation';
    if (order.status == 'Preparing') {
      etaMin = 18;
      statusDesc = 'Restaurant is preparing your delicious meal';
    } else if (order.status == 'Out for Delivery') {
      etaMin = 8;
      statusDesc = 'Rider is on the way to your door';
    } else if (order.status == 'Delivered') {
      etaMin = 0;
      statusDesc = 'Order delivered successfully';
    } else if (order.status == 'Cancelled') {
      etaMin = 0;
      statusDesc = 'Order cancelled';
    }

    // Set Map Markers if rider coordinates are available
    if (trackingState.riderLatitude != null && trackingState.riderLongitude != null) {
      final pos = LatLng(trackingState.riderLatitude!, trackingState.riderLongitude!);
      
      _markers.add(
        Marker(
          markerId: const MarkerId('rider'),
          position: pos,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: const InfoWindow(title: 'Delivery Agent Location'),
        ),
      );

      // Animate map camera to center rider
      if (_mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLng(pos));
      }
    }

    // Show cancel action only before picked up / out for delivery
    final isCancellable = order.status != 'Out for Delivery' && order.status != 'Delivered' && order.status != 'Cancelled';

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
        actions: [
          if (isCancellable)
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cancel Order'),
                    content: const Text('Are you sure you want to cancel this order?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('NO')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('YES, CANCEL')),
                    ],
                  ),
                );

                if (confirm == true) {
                  final success = await trackingNotifier.cancelOrder();
                  if (context.mounted) {
                    if (success) {
                      AppSnackbar.showSuccess(context, "Order cancelled successfully!");
                    } else {
                      AppSnackbar.showError(context, "Failed to cancel order");
                    }
                  }
                }
              },
              child: const Text('CANCEL', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            ),
        ],
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
                      order.status == 'Delivered'
                          ? 'DELIVERED'
                          : order.status == 'Cancelled'
                              ? 'CANCELLED'
                              : '$etaMin MINS',
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

            // Live Rider tracking on Map (only shown when location coordinate is available)
            if (trackingState.riderLatitude != null && trackingState.riderLongitude != null) ...[
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.divider),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 200,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(trackingState.riderLatitude!, trackingState.riderLongitude!),
                        zoom: 15.0,
                      ),
                      markers: _markers,
                      onMapCreated: (controller) => _mapController = controller,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Prominent Delivery handoff OTP card (visible ONLY when out for delivery / picked up)
            if (trackingState.deliveryOtp != null &&
                (order.status == 'Out for Delivery' || order.status == 'Delivered')) ...[
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery Handoff OTP',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Show this code to the delivery partner at your door.',
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
                          trackingState.deliveryOtp!,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary, letterSpacing: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

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
                      isCompleted: order.status != 'Placed' && order.status != 'Cancelled',
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
                      subtitle: order.status == 'Cancelled' ? 'Cancelled' : 'Enjoy your food!',
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
