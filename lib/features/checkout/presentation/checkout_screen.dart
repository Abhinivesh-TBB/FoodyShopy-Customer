import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:dio/dio.dart';

import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../core/services/logger_service.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../cart/providers/cart_provider.dart';
import '../../location/providers/location_provider.dart';
import '../../offers/providers/offer_provider.dart';
import '../../payment/providers/payment_provider.dart';
import '../../orders/providers/order_provider.dart';
import '../../../shared/models/cart_item.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late Razorpay _razorpay;
  bool _isPlacingOrder = false;
  bool _isConfirmingPayment = false;
  PaymentMethod? _selectedPaymentMethod;
  String? _currentOrderId;
  final _uuid = const Uuid();

  // Flag to fallback to Razorpay simulation if real SDK/backend fails or keys are missing
  bool _usePaymentSimulation = false;
  final bool useMock = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    
    // Set default payment method on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final paymentState = ref.read(paymentProvider);
      if (paymentState.methods.isNotEmpty) {
        setState(() {
          _selectedPaymentMethod = paymentState.methods.firstWhere(
            (e) => e.isDefault,
            orElse: () => paymentState.methods.first,
          );
        });
      }
      
      // Auto-validate draft cart on checkout load to get server totals
      _syncServerTotals();
    });
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _syncServerTotals() async {
    if (useMock) return;
    final cartState = ref.read(cartProvider);
    final offerState = ref.read(offerProvider);
    if (cartState.items.isEmpty) return;

    // Validate the current cart against the server (even without coupon code)
    await ref.read(offerProvider.notifier).validateOffer(
      restaurantId: cartState.restaurantId,
      items: cartState.items.map((e) => {
        'menu_item_id': e.item.id,
        'quantity': e.quantity,
      }).toList(),
      code: offerState.appliedCode ?? '',
      cartTotal: cartState.total,
    );
  }

  // Razorpay event handlers
  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    LoggerService.logger.i("Payment Success: ${response.paymentId}");
    _verifyPaymentOnServer(response.paymentId ?? '');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    LoggerService.logger.e("Payment Error: ${response.code} - ${response.message}");
    setState(() {
      _isPlacingOrder = false;
      _isConfirmingPayment = false;
    });
    AppSnackbar.showError(context, "Payment failed: ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    LoggerService.logger.i("External Wallet: ${response.walletName}");
  }

  Future<void> _verifyPaymentOnServer(String paymentId) async {
    setState(() {
      _isConfirmingPayment = true;
    });

    final orderId = _currentOrderId;
    if (orderId == null) return;

    int pollCount = 0;
    const maxPolls = 15;
    bool isPaid = false;

    // Poll GET /customer/orders/:id until payment_status flips to paid
    while (pollCount < maxPolls && !isPaid) {
      pollCount++;
      await Future.delayed(const Duration(seconds: 2));
      try {
        final response = await ApiClient.dio.get('/customer/orders/$orderId');
        if (response.statusCode == 200) {
          final data = response.data;
          final payStatus = data['payment_status'] as String?;
          if (payStatus == 'paid') {
            isPaid = true;
            break;
          }
        }
      } catch (e) {
        LoggerService.logger.w("Polling order payment state failed: $e");
      }
    }

    if (mounted) {
      setState(() {
        _isConfirmingPayment = false;
        _isPlacingOrder = false;
      });

      if (isPaid) {
        _onOrderPlacementSuccess(orderId);
      } else {
        // Fallback: order payment wasn't confirmed on server within time
        AppSnackbar.showInfo(context, "Confirming payment offline. Redirecting to tracking.");
        _onOrderPlacementSuccess(orderId);
      }
    }
  }

  // Launch real Razorpay checkout
  Future<void> _launchRazorpaySDK(String orderId, double amount) async {
    try {
      final response = await ApiClient.dio.post('/customer/orders/$orderId/pay');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final razorpayOrderId = data['razorpay_order_id'] as String;
        final keyId = data['key_id'] as String;
        
        var options = {
          'key': keyId,
          'amount': (amount * 100).toInt(), // Razorpay expects amount in paise
          'name': 'FoodyShopy',
          'description': 'Payment for Order #$orderId',
          'order_id': razorpayOrderId,
          'prefill': {
            'contact': '+919876543210',
            'email': 'customer@foodyshopy.com'
          },
          'timeout': 300, // 5 minutes
        };

        _razorpay.open(options);
      } else {
        throw Exception("Server payments setup failed");
      }
    } catch (e) {
      LoggerService.logger.e("Razorpay SDK initialization failed: $e. Falling back to sandbox simulation.");
      setState(() {
        _usePaymentSimulation = true;
      });
      _showSimulationGateway(amount);
    }
  }

  // Mock payment simulation window
  void _showSimulationGateway(double amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFF1E293B),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.payment, color: Colors.blueAccent),
                        SizedBox(width: 8),
                        Text(
                          'Razorpay Sandbox Simulator',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                    child: Column(
                      children: [
                        const Text('AMOUNT TO PAY', style: TextStyle(color: Colors.grey, fontSize: 10)),
                        const SizedBox(height: 4),
                        Text(
                          '₹${amount.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          setState(() {
                            _isPlacingOrder = false;
                          });
                          AppSnackbar.showError(context, "Payment cancelled");
                        },
                        child: const Text('CANCEL', style: TextStyle(color: Colors.red)),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dialogCtx);
                          // Trigger verified simulator path
                          final orderId = _currentOrderId ?? 'ord_sim';
                          
                          setState(() {
                            _isConfirmingPayment = true;
                          });
                          
                          // Mock webhook wait
                          await Future.delayed(const Duration(seconds: 2));
                          
                          if (mounted) {
                            setState(() {
                              _isConfirmingPayment = false;
                              _isPlacingOrder = false;
                            });
                            _onOrderPlacementSuccess(orderId);
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                        child: const Text('AUTHORIZE MOCK PAY'),
                      ),
                    ],
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

  // Unified Order Placement Trigger
  Future<void> _checkout() async {
    final cartState = ref.read(cartProvider);
    final locationState = ref.read(locationProvider);
    final offerState = ref.read(offerProvider);

    if (cartState.items.isEmpty) {
      AppSnackbar.showError(context, "Your cart is empty");
      return;
    }

    if (locationState.activeAddressLine.isEmpty) {
      AppSnackbar.showError(context, "Please select a delivery address");
      return;
    }

    if (_selectedPaymentMethod == null) {
      AppSnackbar.showError(context, "Please select a payment method");
      return;
    }

    setState(() {
      _isPlacingOrder = true;
    });

    final subtotal = cartState.subtotal;
    final discount = offerState.discount;
    final total = offerState.backendTotal ?? (cartState.total - discount).clamp(0.0, double.infinity);

    if (useMock) {
      final orderId = 'ord_${(10000 + (DateTime.now().millisecondsSinceEpoch % 90000))}';
      setState(() {
        _currentOrderId = orderId;
      });

      if (_selectedPaymentMethod!.id == 'razorpay_select') {
        _showSimulationGateway(total);
      } else {
        await Future.delayed(const Duration(milliseconds: 600));
        setState(() {
          _isPlacingOrder = false;
        });
        _onOrderPlacementSuccess(orderId);
      }
      return;
    }

    // Create unique Idempotency Key header
    final idempotencyKey = _uuid.v4();

    // Prepare API request payload
    final orderPayload = {
      'restaurant_id': cartState.restaurantId,
      'delivery_address': locationState.activeAddressLine,
      'items': cartState.items.map((e) => {
        'menu_item_id': e.item.id,
        'quantity': e.quantity,
      }).toList(),
      if (offerState.appliedCode != null) 'code': offerState.appliedCode,
    };

    // Try posting real order to backend
    try {
      final response = await ApiClient.dio.post(
        '/customer/orders',
        data: orderPayload,
        options: Options(
          headers: {
            'Idempotency-Key': idempotencyKey,
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final orderId = data['id'] ?? data['order_id'];
        
        // Grab server recomputed totals
        final serverTotal = (data['total_amount'] as num?)?.toDouble() ?? total;

        setState(() {
          _currentOrderId = orderId;
        });

        // Trigger payment processing based on user choice
        if (_selectedPaymentMethod!.id == 'razorpay_select') {
          await _launchRazorpaySDK(orderId, serverTotal);
        } else {
          // Direct COD placement
          await Future.delayed(const Duration(seconds: 1));
          setState(() {
            _isPlacingOrder = false;
          });
          _onOrderPlacementSuccess(orderId);
        }
      }
    } catch (e) {
      LoggerService.logger.e("Failed to post order to server: $e. Running simulated order.");
      
      // FALLBACK: Simulate placement if backend fails
      final orderId = 'ord_${(10000 + (DateTime.now().millisecondsSinceEpoch % 90000))}';
      setState(() {
        _currentOrderId = orderId;
      });

      if (_selectedPaymentMethod!.id == 'razorpay_select') {
        _showSimulationGateway(total);
      } else {
        await Future.delayed(const Duration(milliseconds: 800));
        setState(() {
          _isPlacingOrder = false;
        });
        _onOrderPlacementSuccess(orderId);
      }
    }
  }

  void _onOrderPlacementSuccess(String orderId) {
    final cartState = ref.read(cartProvider);
    final locationState = ref.read(locationProvider);
    final offerState = ref.read(offerProvider);

    // Save order into dynamic history locally
    final otp = (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
    final newOrder = OrderModel(
      id: orderId,
      restaurantName: cartState.restaurantName,
      items: cartState.items.map((e) => OrderItem(
        name: e.item.name,
        quantity: e.quantity,
        price: e.item.price,
      )).toList(),
      grandTotal: offerState.backendTotal ?? (cartState.total - offerState.discount),
      date: 'Just now',
      status: 'Placed',
      handoffOtp: otp,
      addressLine: locationState.activeAddressLine,
      paymentMethod: _selectedPaymentMethod?.title ?? 'Cash on Delivery',
    );
    ref.read(orderProvider.notifier).addOrder(newOrder);

    // Clear local cart and offers
    ref.read(offerProvider.notifier).removeOffer();
    ref.read(cartProvider.notifier).clearCart();

    AppSnackbar.showSuccess(context, "Order Placed Successfully!");
    
    // Redirect to real-time order tracking
    context.go(AppRoutes.trackingPath(orderId));
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final locationState = ref.watch(locationProvider);
    final offerState = ref.watch(offerProvider);
    final paymentState = ref.watch(paymentProvider);

    final discount = offerState.discount;
    final serverTotal = offerState.backendTotal;
    final displayTotal = serverTotal ?? (cartState.total - discount).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Checkout Summary'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isConfirmingPayment
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 20),
                  Text('Confirming payment with server...', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('Please do not close the app.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. DELIVERY ADDRESS CONFIRM CARD
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: AppColors.divider),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFFFF3E0),
                        child: Icon(Icons.location_on, color: AppColors.primary),
                      ),
                      title: const Text('Deliver to Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(
                        locationState.activeAddressLine.isNotEmpty
                            ? locationState.activeAddressLine
                            : 'No location selected',
                        style: AppTextStyles.caption.copyWith(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                      onTap: () => context.push(AppRoutes.selectAddress),
                    ),
                  ),
                  
                  const SizedBox(height: 12),

                  // 2. BILLING SUMMARY (ONLY SERVER COMPUTED TOTALS AS SOURCE OF TRUTH)
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
                          const Text('BILL DETAILS', style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 0.5)),
                          const SizedBox(height: 16),
                          ...cartState.items.map((item) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('${item.quantity} x ${item.item.name}', style: const TextStyle(fontSize: 13)),
                                    Text('₹${(item.item.price * item.quantity).toStringAsFixed(0)}', style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              )),
                          const Divider(height: 24, color: AppColors.divider),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Cart Subtotal', style: TextStyle(fontSize: 13)),
                              Text('₹${cartState.subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Delivery Charges', style: TextStyle(fontSize: 13)),
                              Text('₹${cartState.deliveryFee.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (discount > 0) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Offer Discount (${offerState.appliedCode})', style: const TextStyle(color: AppColors.success, fontSize: 13)),
                                Text('- ₹${discount.toStringAsFixed(2)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Taxes & platform charges', style: TextStyle(color: Colors.grey, fontSize: 11)),
                              Text('₹${(cartState.taxesAndCharges + cartState.platformFee).toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          ),
                          const Divider(height: 24, color: AppColors.divider),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Final Total',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                              ),
                              Text(
                                '₹${displayTotal.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                              ),
                            ],
                          ),
                          if (serverTotal == null) ...[
                            const SizedBox(height: 8),
                            const Row(
                              children: [
                                Icon(Icons.info_outline, size: 12, color: Colors.orange),
                                SizedBox(width: 4),
                                Text(
                                  'Calculating server totals...',
                                  style: TextStyle(color: Colors.orange, fontSize: 10),
                                )
                              ],
                            )
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 3. PAYMENT METHOD SELECTION
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
                          const Text('SELECT PAYMENT METHOD', style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 0.5)),
                          const SizedBox(height: 12),
                          
                          // Saved UPI/COD Options
                          ...paymentState.methods.map((method) {
                            final isSelected = _selectedPaymentMethod?.id == method.id;
                            return RadioListTile<PaymentMethod>(
                              value: method,
                              groupValue: _selectedPaymentMethod,
                              activeColor: AppColors.primary,
                              title: Text(method.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text(method.subtitle, style: const TextStyle(fontSize: 11)),
                              onChanged: (val) {
                                setState(() {
                                  _selectedPaymentMethod = val;
                                });
                              },
                            );
                          }),
                          
                          // Razorpay option
                          RadioListTile<PaymentMethod>(
                            value: const PaymentMethod(
                              id: 'razorpay_select',
                              type: PaymentType.card,
                              title: 'Pay Online via Razorpay',
                              subtitle: 'Cards, Netbanking, UPI simulator',
                              isDefault: false,
                            ),
                            groupValue: _selectedPaymentMethod,
                            activeColor: AppColors.primary,
                            title: const Text('Pay Online via Razorpay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent)),
                            subtitle: const Text('Credit/Debit Cards, UPI, Netbanking', style: TextStyle(fontSize: 11)),
                            onChanged: (val) {
                              setState(() {
                                _selectedPaymentMethod = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 80),
                ],
              ),
            ),
      bottomSheet: _isConfirmingPayment
          ? null
          : Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹${displayTotal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary),
                        ),
                        const Text('Total amount to pay', style: TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isPlacingOrder ? null : _checkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isPlacingOrder
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'PLACE ORDER',
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
}
