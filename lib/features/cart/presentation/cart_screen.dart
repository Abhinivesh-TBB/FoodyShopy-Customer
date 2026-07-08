import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/models/cart_item.dart';
import '../../offers/providers/offer_provider.dart';
import '../providers/cart_provider.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../location/providers/location_provider.dart';
import '../../payment/providers/payment_provider.dart';
import '../../orders/providers/order_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final TextEditingController _couponController = TextEditingController();
  bool _isPlacingOrder = false;
  PaymentMethod? _selectedPaymentMethod;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    String period = now.hour >= 12 ? 'PM' : 'AM';
    int hour = now.hour % 12;
    if (hour == 0) hour = 12;
    String min = now.minute.toString().padLeft(2, '0');
    return '${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}, ${hour.toString().padLeft(2, '0')}:$min $period';
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final offerState = ref.watch(offerProvider);
    final locationState = ref.watch(locationProvider);
    final paymentState = ref.watch(paymentProvider);

    if (_selectedPaymentMethod == null && paymentState.methods.isNotEmpty) {
      _selectedPaymentMethod = paymentState.methods.firstWhere(
        (e) => e.isDefault,
        orElse: () => paymentState.methods.first,
      );
    }

    if (cartState.items.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Cart'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
              margin: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
              ),
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
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                      leading: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                      title: const Text('Add more items', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      onTap: () {
                        context.pop();
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Coupon Code Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
              ),
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
                                            .validateOffer(
                                              restaurantId: cartState.restaurantId,
                                              items: cartState.items.map((e) => {
                                                'menu_item_id': e.item.id,
                                                'quantity': e.quantity,
                                              }).toList(),
                                              code: _couponController.text,
                                              cartTotal: cartState.total,
                                            );
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

            // Billing Details Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.3)),
              ),
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

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        color: Theme.of(context).cardColor,
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
                  const Text(
                    'Total Amount',
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: cartState.items.isEmpty
                      ? null
                      : () => context.push(AppRoutes.checkout),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'PROCEED TO CHECKOUT',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                InkWell(
                  onTap: () {
                    ref.read(cartProvider.notifier).removeItem(item.item);
                  },
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(5)),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Icon(Icons.remove, size: 12, color: AppColors.primary),
                  ),
                ),
                Text(
                  item.quantity.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 13,
                  ),
                ),
                InkWell(
                  onTap: () {
                    ref.read(cartProvider.notifier).addItem(item.item, item.restaurantId, item.restaurantName);
                  },
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(5)),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Icon(Icons.add, size: 12, color: AppColors.primary),
                  ),
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

  // Address Selector Bottom Sheet
  void _showAddressSelectorSheet(BuildContext context, WidgetRef ref, LocationState locationState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Select Delivery Address', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            if (locationState.savedAddresses.isEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('No saved addresses found. Please add one in Profile tab.'),
                ),
              ),
            ] else ...[
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: locationState.savedAddresses.length,
                  itemBuilder: (ctx, index) {
                    final address = locationState.savedAddresses[index];
                    final isSelected = locationState.activeAddressLine == address.addressLine;
                    return ListTile(
                      leading: Icon(
                        address.label.toLowerCase().contains('home') ? Icons.home_outlined : Icons.work_outline,
                        color: AppColors.primary,
                      ),
                      title: Text(address.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(address.addressLine, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                      onTap: () {
                        ref.read(locationProvider.notifier).selectActiveAddress(
                              address.addressLine,
                              address.latitude,
                              address.longitude,
                            );
                        Navigator.pop(sheetCtx);
                        AppSnackbar.showSuccess(context, "Address updated!");
                      },
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Payment Selector Bottom Sheet
  void _showPaymentSelectorSheet(BuildContext context, WidgetRef ref, PaymentState paymentState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Select Payment Method', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                shrinkWrap: true,
                children: [
                  // Pre-populate actual saved payment methods
                  ...paymentState.methods.map((method) {
                    final isSelected = _selectedPaymentMethod?.id == method.id;
                    IconData payIcon = Icons.payment;
                    if (method.type == PaymentType.upi) {
                      payIcon = Icons.account_balance_wallet_outlined;
                    } else if (method.type == PaymentType.cod) {
                      payIcon = Icons.money;
                    }

                    return ListTile(
                      leading: Icon(payIcon, color: AppColors.primary),
                      title: Text(method.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(method.subtitle),
                      trailing: isSelected ? const Icon(Icons.check_circle, color: AppColors.primary) : null,
                      onTap: () {
                        setState(() {
                          _selectedPaymentMethod = method;
                        });
                        Navigator.pop(sheetCtx);
                      },
                    );
                  }),
                  // Add Razorpay explicitly
                  ListTile(
                    leading: const Icon(Icons.flash_on, color: Colors.blueAccent),
                    title: const Text('Pay via Razorpay', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Cards, Netbanking, UPI simulator gateway'),
                    trailing: _selectedPaymentMethod?.id == 'razorpay_select'
                        ? const Icon(Icons.check_circle, color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() {
                        _selectedPaymentMethod = const PaymentMethod(
                          id: 'razorpay_select',
                          type: PaymentType.card,
                          title: 'Razorpay Secure',
                          subtitle: 'Cards, Netbanking, UPI',
                          isDefault: false,
                        );
                      });
                      Navigator.pop(sheetCtx);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Razorpay Gateway Simulation Modal Dialog
  void _showRazorpayGateway(BuildContext context, double total, VoidCallback onSuccess) {
    showDialog(
      context: context,
      barrierDismissible: false, // Force interactive response
      builder: (dialogCtx) {
        bool payLoading = false;
        bool paySuccess = false;
        String selectedSubMethod = 'upi';

        return StatefulBuilder(
          builder: (context, setState) {
            if (paySuccess) {
              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 70),
                    const SizedBox(height: 16),
                    const Text(
                      'Payment Successful',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Razorpay Order ID: pay_${DateTime.now().millisecondsSinceEpoch}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        onSuccess();
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('PROCEED TO TRACKING'),
                    ),
                  ],
                ),
              );
            }

            if (payLoading) {
              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                content: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.blueAccent),
                      const SizedBox(height: 24),
                      Text(
                        'Processing Payment...',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent),
                      ),
                      const SizedBox(height: 8),
                      Text('Secure connection via Razorpay API', style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
              );
            }

            return Dialog(
              backgroundColor: const Color(0xFF0F172A), // Premium Dark Slate Razorpay color
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Razorpay Header Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E293B),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(4)),
                              child: const Text('R', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Razorpay Checkout',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            Navigator.pop(dialogCtx);
                            AppSnackbar.showError(context, "Payment cancelled by user");
                          },
                        ),
                      ],
                    ),
                  ),

                  // Amount block
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    child: Column(
                      children: [
                        const Text('AMOUNT TO PAY', style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 0.5)),
                        const SizedBox(height: 4),
                        Text(
                          '₹${total.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'FoodyShopy Store Order Payment',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: Colors.white12),

                  // Payment method tabs
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('SELECT PAYMENT MODE', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildRazorpayOption(
                          title: 'Google Pay / UPI',
                          subtitle: 'Instant transfer via mock handle',
                          icon: Icons.account_balance_wallet_outlined,
                          isSelected: selectedSubMethod == 'upi',
                          onTap: () => setState(() => selectedSubMethod = 'upi'),
                        ),
                        const SizedBox(height: 8),
                        _buildRazorpayOption(
                          title: 'Credit / Debit Card',
                          subtitle: 'Simulate card authorization',
                          icon: Icons.credit_card_outlined,
                          isSelected: selectedSubMethod == 'card',
                          onTap: () => setState(() => selectedSubMethod = 'card'),
                        ),
                        const SizedBox(height: 8),
                        _buildRazorpayOption(
                          title: 'Netbanking',
                          subtitle: 'Mock login gateway',
                          icon: Icons.business,
                          isSelected: selectedSubMethod == 'netbank',
                          onTap: () => setState(() => selectedSubMethod = 'netbank'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Pay Button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() => payLoading = true);
                        await Future.delayed(const Duration(seconds: 2));
                        setState(() {
                          payLoading = false;
                          paySuccess = true;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('PAY NOW  ₹${total.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const Center(
                    child: Text(
                      '🔒 Secured by Razorpay Sandbox',
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRazorpayOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.blueAccent : Colors.grey, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Colors.blueAccent, size: 18),
          ],
        ),
      ),
    );
  }

  // Order submission
  Future<void> _placeOrder() async {
    final cartState = ref.read(cartProvider);
    final locationState = ref.read(locationProvider);
    final discount = ref.read(offerProvider).discount;
    final grandTotal = (cartState.total - discount).clamp(0.0, double.infinity);

    final addressLine = locationState.activeAddressLine;
    final paymentMethod = _selectedPaymentMethod?.title ?? 'Cash on Delivery';

    if (_selectedPaymentMethod?.id == 'razorpay_select') {
      // Launch Razorpay simulation gateway
      _showRazorpayGateway(context, grandTotal, () {
        _createAndSaveOrder(addressLine, 'Razorpay', grandTotal);
      });
    } else {
      // Direct Cash on Delivery
      setState(() => _isPlacingOrder = true);
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _isPlacingOrder = false);
      _createAndSaveOrder(addressLine, paymentMethod, grandTotal);
    }
  }

  void _createAndSaveOrder(String addressLine, String paymentMethod, double total) {
    final cartState = ref.read(cartProvider);
    
    // Generate mock order UUID details
    final orderId = 'ord_${(10000 + (DateTime.now().millisecondsSinceEpoch % 90000))}';
    final otp = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();

    final order = OrderModel(
      id: orderId,
      restaurantName: cartState.restaurantName,
      items: cartState.items.map((e) => OrderItem(
        name: e.item.name,
        quantity: e.quantity,
        price: e.item.price,
      )).toList(),
      grandTotal: total,
      date: _getFormattedDate(),
      status: 'Placed',
      handoffOtp: otp,
      addressLine: addressLine,
      paymentMethod: paymentMethod,
    );

    // Save order inside dynamic history
    ref.read(orderProvider.notifier).addOrder(order);

    // Clear cart and offers
    ref.read(offerProvider.notifier).removeOffer();
    ref.read(cartProvider.notifier).clearCart();

    // Notify user
    AppSnackbar.showSuccess(context, "Order Placed Successfully!");

    // Navigate to Order Status Tracking page
    context.go(AppRoutes.trackingPath(orderId));
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
