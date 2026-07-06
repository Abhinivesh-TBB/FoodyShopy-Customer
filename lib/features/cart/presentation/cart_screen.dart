import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/models/cart_item.dart';
import '../../offers/providers/offer_provider.dart';
import '../providers/cart_provider.dart';
import '../../../core/utils/app_snackbar.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final TextEditingController _couponController = TextEditingController();
  bool _isPlacingOrder = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final offerState = ref.watch(offerProvider);

    if (cartState.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Cart'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 24),
                Text(
                  'Your cart is empty',
                  style: AppTextStyles.heading2.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Good food is always cooking! Go ahead and order some yummy items from the menu.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () => context.go(AppRoutes.home),
                    child: const Text('Browse Restaurants'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final double discount = offerState.discount;
    final double grandTotal = (cartState.total - discount).clamp(0.0, double.infinity);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Checkout', style: AppTextStyles.heading2.copyWith(fontSize: 16)),
            Text(
              cartState.restaurantName,
              style: AppTextStyles.caption.copyWith(fontSize: 12),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // List of items
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cartState.items.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (context, index) {
                      final item = cartState.items[index];
                      return _buildCartItemRow(item);
                    },
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  // Add more items trigger
                  ListTile(
                    leading: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                    title: const Text('Add more items', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    onTap: () {
                      context.pop();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Coupon Code Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Offers & Coupons',
                    style: AppTextStyles.heading2.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  offerState.appliedCode != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.success.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '"${offerState.appliedCode}" APPLIED',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success),
                                      ),
                                      Text(
                                        'You saved ₹${discount.toStringAsFixed(0)}',
                                        style: TextStyle(color: Colors.grey[800], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  ref.read(offerProvider.notifier).removeOffer();
                                  _couponController.clear();
                                },
                                child: const Text('REMOVE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextField(
                                  controller: _couponController,
                                  decoration: InputDecoration(
                                    hintText: 'Enter coupon code (e.g. WELCOME50)',
                                    hintStyle: AppTextStyles.caption.copyWith(fontSize: 12),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: offerState.isLoading
                                    ? null
                                    : () async {
                                        if (_couponController.text.trim().isEmpty) return;
                                        final success = await ref
                                            .read(offerProvider.notifier)
                                            .validateOffer(_couponController.text, cartState.total);
                                        if (success) {
                                          if (context.mounted) {
                                            AppSnackbar.showSuccess(context, "Promo code applied successfully!");
                                          }
                                        } else {
                                          if (context.mounted) {
                                            AppSnackbar.showError(context, offerState.errorMessage ?? "Invalid code");
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                ),
                                child: offerState.isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Text('APPLY'),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Billing Details Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bill Details',
                    style: AppTextStyles.heading2.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildBillingRow('Item Total', '₹${cartState.subtotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 10),
                  _buildBillingRow('Delivery Partner Fee', '₹${cartState.deliveryFee.toStringAsFixed(2)}'),
                  const SizedBox(height: 10),
                  _buildBillingRow('Platform Fee', '₹${cartState.platformFee.toStringAsFixed(2)}'),
                  const SizedBox(height: 10),
                  _buildBillingRow('GST & Restaurant Charges', '₹${(cartState.subtotal * 0.05).toStringAsFixed(2)}'),
                  if (discount > 0) ...[
                    const SizedBox(height: 10),
                    _buildBillingRow(
                      'Coupon Discount (${offerState.appliedCode})',
                      '- ₹${discount.toStringAsFixed(2)}',
                      textColor: AppColors.success,
                    ),
                  ],
                  const Divider(height: 24, color: AppColors.divider),
                  _buildBillingRow(
                    'To Pay',
                    '₹${grandTotal.toStringAsFixed(2)}',
                    isBold: true,
                    fontSize: 16,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Delivery Strip (Placeholder)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Deliver to Home', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(
                          'HAL 2nd Stage, Indiranagar, Bengaluru',
                          style: AppTextStyles.caption.copyWith(fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 120),
          ],
        ),
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹${grandTotal.toStringAsFixed(0)}',
                    style: AppTextStyles.heading2.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      'VIEW DETAILED BILL',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isPlacingOrder ? null : _placeOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isPlacingOrder
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'PLACE ORDER',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItemRow(CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          _VegIndicator(isVeg: item.item.isVeg),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                Text(
                  '₹${item.item.price.toStringAsFixed(0)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),

          // Quantity controls
          Container(
            height: 32,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove, size: 14, color: AppColors.primary),
                  onPressed: () {
                    ref.read(cartProvider.notifier).removeItem(item.item);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Text(
                  item.quantity.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 14, color: AppColors.primary),
                  onPressed: () {
                    ref.read(cartProvider.notifier).addItem(item.item, item.restaurantId, item.restaurantName);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '₹${(item.item.price * item.quantity).toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingRow(String title, String value, {bool isBold = false, double fontSize = 13, Color? textColor}) {
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontSize: fontSize,
      color: textColor ?? (isBold ? AppColors.textPrimary : AppColors.textSecondary),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: style),
        Text(value, style: style),
      ],
    );
  }

  Future<void> _placeOrder() async {
    setState(() => _isPlacingOrder = true);

    // Generate unique Idempotency Key
    final orderUuid = const Uuid().v4();

    // Simulate API order creation with idempotency key
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isPlacingOrder = false);

    // Show success dialog / popup
    AppSnackbar.showSuccess(context, "Order Placed Successfully! ID: $orderUuid");
    
    // Clear coupon and cart
    ref.read(offerProvider.notifier).removeOffer();
    ref.read(cartProvider.notifier).clearCart();

    // Navigate to order history or home
    context.go(AppRoutes.home);
  }
}

class _VegIndicator extends StatelessWidget {
  final bool isVeg;
  const _VegIndicator({required this.isVeg});

  @override
  Widget build(BuildContext context) {
    final color = isVeg ? const Color(0xFF0F8A5F) : const Color(0xFFC43F3F);
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: color,
          shape: isVeg ? BoxShape.circle : BoxShape.rectangle,
        ),
      ),
    );
  }
}
