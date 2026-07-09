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

  // Helper method for dynamic status colors
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return Colors.red;
      case 'preparing':
      case 'on the way':
        return AppColors.primary;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(orderProvider);

    if (orders.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Your Orders',
            style: AppTextStyles.heading2.copyWith(fontSize: 16),
          ),
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
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
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
        title: Text(
          'Your Orders',
          style: AppTextStyles.heading2.copyWith(fontSize: 16),
        ),
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

          final bool isDelivered = order.status.toLowerCase() == 'delivered';
          final Color statusColor = _getStatusColor(order.status);

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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order.addressLine,
                              style: AppTextStyles.caption.copyWith(
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Dynamic Status Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text(
                            'REORDER',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (!isDelivered) {
                              context.push(AppRoutes.trackingPath(order.id));
                            } else {
                              AppSnackbar.showSuccess(
                                context,
                                "Thank you for rating your meal!",
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            foregroundColor: AppColors.textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text(
                            isDelivered ? 'RATE MEAL' : 'TRACK ORDER',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
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

  void _handleReorder(BuildContext context, WidgetRef ref, var order) {
    try {
      final restaurantState = ref.read(restaurantProvider);

      // 1. Strict lookup: Find restaurant, or throw an error if it closed down
      final restaurant = restaurantState.allRestaurants.firstWhere(
        (r) => r.name.toLowerCase() == order.restaurantName.toLowerCase(),
        orElse: () => throw Exception('Restaurant no longer available'),
      );

      // 2. Strict lookup: Ensure all past items still exist on the current menu
      final itemsToReorder = [];
      for (final orderItem in order.items) {
        final menuItem = restaurant.menu.firstWhere(
          (m) => m.name.toLowerCase() == orderItem.name.toLowerCase(),
          orElse: () => throw Exception('Some items are no longer on the menu'),
        );
        itemsToReorder.add({'item': menuItem, 'qty': orderItem.quantity});
      }

      // 3. Clear current cart and add the new items
      ref.read(cartProvider.notifier).clearCart();

      for (final target in itemsToReorder) {
        for (int i = 0; i < target['qty']; i++) {
          ref
              .read(cartProvider.notifier)
              .addItem(target['item'], restaurant.id, restaurant.name);
        }
      }

      AppSnackbar.showSuccess(context, "Items added back to your cart!");

      // Navigate to the checkout flow
      context.go(AppRoutes.cart);
    } on Exception catch (e) {
      // Show the specific reason the reorder failed
      final errorMessage = e.toString().replaceAll('Exception: ', '');
      AppSnackbar.showError(context, errorMessage);
    } catch (e) {
      AppSnackbar.showError(context, "Unable to reorder items at this time.");
    }
  }
}
