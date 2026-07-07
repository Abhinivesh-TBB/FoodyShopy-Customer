import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';
import '../../../../core/utils/app_snackbar.dart';
import '../../../orders/providers/order_provider.dart';
import '../../../cart/providers/cart_provider.dart';
import '../../../restaurant/providers/restaurant_provider.dart';

class HistoryView extends ConsumerWidget {
  const HistoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(orderProvider);

    if (orders.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Your Orders', style: AppTextStyles.heading2.copyWith(fontSize: 16)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No orders placed yet',
                style: AppTextStyles.heading2.copyWith(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your past orders will appear here.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Your Orders', style: AppTextStyles.heading2.copyWith(fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 14),
        itemBuilder: (context, index) {
          final order = orders[index];

          final String itemsDescription = order.items
              .map((item) => '${item.quantity} x ${item.name}')
              .join(', ');

          final bool isDelivered = order.status == 'Delivered';

          return Card(
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.restaurantName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order.addressLine,
                              style: AppTextStyles.caption.copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDelivered 
                              ? AppColors.success.withOpacity(0.1) 
                              : AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.status.toUpperCase(),
                          style: TextStyle(
                            color: isDelivered ? AppColors.success : AppColors.primary, 
                            fontWeight: FontWeight.bold, 
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.divider),
                  Text(
                    itemsDescription,
                    style: TextStyle(color: Colors.grey[800], fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${order.grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        order.date,
                        style: AppTextStyles.caption.copyWith(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleReorder(context, ref, order),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text(
                            'REORDER', 
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (!isDelivered) {
                              // If order is active, let them view tracking page
                              context.go(AppRoutes.trackingPath(order.id));
                            } else {
                              AppSnackbar.showSuccess(context, "Thank you for rating your meal!");
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            foregroundColor: AppColors.textPrimary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text(
                            isDelivered ? 'RATE MEAL' : 'TRACK ORDER', 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleReorder(BuildContext context, WidgetRef ref, OrderModel order) {
    try {
      final restaurantState = ref.read(restaurantProvider);
      
      // Attempt to look up the restaurant by name in our list database
      final restaurant = restaurantState.allRestaurants.firstWhere(
        (r) => r.name.toLowerCase() == order.restaurantName.toLowerCase(),
        orElse: () => restaurantState.allRestaurants.first,
      );

      // Clear the current active cart
      ref.read(cartProvider.notifier).clearCart();

      // Loop through order items and add them back to the active cart with matching quantity
      for (final orderItem in order.items) {
        final menuItem = restaurant.menu.firstWhere(
          (m) => m.name.toLowerCase() == orderItem.name.toLowerCase(),
          orElse: () => restaurant.menu.first,
        );

        for (int i = 0; i < orderItem.quantity; i++) {
          ref.read(cartProvider.notifier).addItem(
                menuItem,
                restaurant.id,
                restaurant.name,
              );
        }
      }

      AppSnackbar.showSuccess(context, "Items added back to your cart!");
      
      // Navigate straight to the Checkout Cart Screen
      context.go(AppRoutes.cart);
    } catch (e) {
      AppSnackbar.showError(context, "Unable to reorder items at this time.");
    }
  }
}
