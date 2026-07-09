import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../cart/providers/cart_provider.dart';
import 'presentation/views/main_feed_view.dart';
import 'presentation/views/search_view.dart';
import 'presentation/views/history_view.dart';
import 'presentation/views/account_view.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _views = const [
    MainFeedView(),
    SearchView(),
    CartScreen(),
    HistoryView(),
    AccountView(),
  ];

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);

    // Hide floating strip if we are on the Cart tab (index 2) or cart is empty
    final showFloatingCart = _currentIndex != 2 && cartState.totalItemCount > 0;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _views),

      // 1. Animated Slide Transition for the Cart Strip
      bottomSheet: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 1), // Slide up from the bottom
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
        child: showFloatingCart
            ? _buildFloatingCart(cartState)
            : const SizedBox.shrink(key: ValueKey('empty_cart')),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.lunch_dining_outlined),
            activeIcon: Icon(Icons.lunch_dining, color: AppColors.primary),
            label: 'FoodyShopy',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search, color: AppColors.primary),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text(cartState.totalItemCount.toString()),
              isLabelVisible: cartState.totalItemCount > 0,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.shopping_bag_outlined),
            ),
            activeIcon: Badge(
              label: Text(cartState.totalItemCount.toString()),
              isLabelVisible: cartState.totalItemCount > 0,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.shopping_bag, color: AppColors.primary),
            ),
            label: 'Cart',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long, color: AppColors.primary),
            label: 'Orders',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  // 2. Extracted the UI into a clean helper method
  Widget _buildFloatingCart(cartState) {
    return Container(
      key: const ValueKey('floating_cart'), // Required for AnimatedSwitcher
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${cartState.totalItemCount} ITEM${cartState.totalItemCount > 1 ? 'S' : ''} | ₹${cartState.total.toStringAsFixed(0)}',
                  // Guaranteed white text for contrast
                  style: AppTextStyles.button.copyWith(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'From ${cartState.restaurantName}',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _currentIndex = 2; // Jump directly to Cart tab
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.white.withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Cart',
                    style: AppTextStyles.button.copyWith(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
