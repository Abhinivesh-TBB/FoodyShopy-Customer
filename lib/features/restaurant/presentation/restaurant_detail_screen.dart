import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_text_styles.dart';
import '../../../shared/models/menu_item.dart';
import '../../../shared/models/restaurant.dart';
import '../../../shared/models/cart_item.dart';
import '../../cart/providers/cart_provider.dart';
import '../providers/restaurant_provider.dart';

class RestaurantDetailScreen extends ConsumerStatefulWidget {
  final String restaurantId;

  const RestaurantDetailScreen({super.key, required this.restaurantId});

  @override
  ConsumerState<RestaurantDetailScreen> createState() => _RestaurantDetailScreenState();
}

class _RestaurantDetailScreenState extends ConsumerState<RestaurantDetailScreen> {
  bool _isVegFilter = false;

  @override
  void initState() {
    super.initState();
    // Load/select target restaurant
    Future.microtask(() {
      ref.read(restaurantProvider.notifier).selectRestaurant(widget.restaurantId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final restState = ref.watch(restaurantProvider);
    final cartState = ref.watch(cartProvider);
    final restaurant = restState.selectedRestaurant;

    if (restaurant == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    // Group items by category
    final menuItems = _isVegFilter 
        ? restaurant.menu.where((e) => e.isVeg).toList()
        : restaurant.menu;

    final categories = <String, List<MenuItem>>{};
    for (final item in menuItems) {
      categories.putIfAbsent(item.category, () => []).add(item);
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom Header SliverAppBar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            title: Text(restaurant.name, style: AppTextStyles.heading2.copyWith(fontSize: 18)),
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
              onPressed: () => context.pop(),
            ),
          ),

          // Restaurant Info Header
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  )
                ],
                border: Border.all(color: AppColors.divider.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star, color: AppColors.success, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${restaurant.rating} (${restaurant.deliveryTimeMin} mins)',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            restaurant.cuisines.join(', '),
                            style: AppTextStyles.caption.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          restaurant.distance,
                          style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.divider),
                  Row(
                    children: [
                      const Icon(Icons.local_offer, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          restaurant.offers.join('  |  '),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Filters Bar (Veg Only toggle)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Text('Veg Only', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(width: 8),
                  Switch.adaptive(
                    value: _isVegFilter,
                    activeColor: AppColors.success,
                    onChanged: (val) {
                      setState(() {
                        _isVegFilter = val;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: Divider(height: 1, color: AppColors.divider)),

          // Menu List Grouped by Category
          if (categories.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(48),
                child: Center(
                  child: Text(
                    'No items match your preferences.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, catIndex) {
                  final categoryName = categories.keys.elementAt(catIndex);
                  final items = categories[categoryName]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 8),
                        child: Text(
                          '$categoryName (${items.length})',
                          style: AppTextStyles.heading2.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: items.length,
                        separatorBuilder: (context, index) => const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: AppColors.divider,
                        ),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final cartItem = cartState.items.firstWhere(
                            (e) => e.item.id == item.id,
                            orElse: () => CartItem(
                              item: item,
                              quantity: 0,
                              restaurantId: '',
                              restaurantName: '',
                            ),
                          );

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Item Detail
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _VegNonVegIndicator(isVeg: item.isVeg),
                                      const SizedBox(height: 6),
                                      if (item.isBestseller) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.amber[100],
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '★ BESTSELLER',
                                            style: TextStyle(
                                              color: Colors.amber[900],
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                      ],
                                      Text(
                                        item.name,
                                        style: AppTextStyles.heading2.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${item.price.toStringAsFixed(0)}',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        item.description,
                                        style: AppTextStyles.caption.copyWith(fontSize: 12),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Image & Add controls
                                Column(
                                  children: [
                                    Stack(
                                      alignment: Alignment.bottomCenter,
                                      clipBehavior: Clip.none,
                                      children: [
                                        // Food image
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            item.imageUrl,
                                            width: 110,
                                            height: 110,
                                            fit: double.infinity == 0.0 ? null : BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Container(
                                              width: 110,
                                              height: 110,
                                              color: Colors.grey[100],
                                              child: const Icon(Icons.fastfood, color: Colors.grey),
                                            ),
                                          ),
                                        ),

                                        // Add button
                                        Positioned(
                                          bottom: -15,
                                          child: Container(
                                            height: 38,
                                            width: 90,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.06),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 3),
                                                ),
                                              ],
                                            ),
                                            child: cartItem.quantity == 0
                                                ? TextButton(
                                                    onPressed: () => _handleAddItem(ref, context, item, restaurant),
                                                    style: TextButton.styleFrom(
                                                      foregroundColor: AppColors.primary,
                                                      padding: EdgeInsets.zero,
                                                    ),
                                                    child: Text(
                                                      'ADD',
                                                      style: AppTextStyles.button.copyWith(
                                                        color: AppColors.primary,
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  )
                                                : Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      InkWell(
                                                        onTap: () {
                                                          ref.read(cartProvider.notifier).removeItem(item);
                                                        },
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: const Padding(
                                                          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                                                          child: Icon(Icons.remove, size: 14, color: AppColors.primary),
                                                        ),
                                                      ),
                                                      Text(
                                                        cartItem.quantity.toString(),
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: AppColors.primary,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      InkWell(
                                                        onTap: () {
                                                          _handleAddItem(ref, context, item, restaurant);
                                                        },
                                                        borderRadius: BorderRadius.circular(4),
                                                        child: const Padding(
                                                          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                                                          child: Icon(Icons.add, size: 14, color: AppColors.primary),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 15),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  );
                },
                childCount: categories.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),

      // Floating bottom sheet cart summary
      bottomNavigationBar: cartState.totalItemCount > 0
          ? Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        '${cartState.totalItemCount} ITEM${cartState.totalItemCount > 1 ? 'S' : ''} | ₹${cartState.subtotal.toStringAsFixed(0)}',
                        style: AppTextStyles.button.copyWith(fontSize: 14),
                      ),
                      Text(
                        'Taxes & Charges extra',
                        style: AppTextStyles.caption.copyWith(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRoutes.cart),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('View Cart', style: AppTextStyles.button.copyWith(fontSize: 14)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  void _handleAddItem(WidgetRef ref, BuildContext context, MenuItem item, Restaurant restaurant) {
    final result = ref.read(cartProvider.notifier).addItem(item, restaurant.id, restaurant.name);

    if (result == 'conflict') {
      showDialog(
        context: context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Replace cart items?'),
          content: Text(
            'Your cart contains dishes from "${ref.read(cartProvider).restaurantName}". '
            'Do you want to discard them and add this dish from "${restaurant.name}" instead?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('CANCEL', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                ref.read(cartProvider.notifier).clearAndAddItem(item, restaurant.id, restaurant.name);
                Navigator.pop(dialogCtx);
              },
              child: const Text('YES, REPLACE', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }
}

class _VegNonVegIndicator extends StatelessWidget {
  final bool isVeg;
  const _VegNonVegIndicator({required this.isVeg});

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
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          shape: isVeg ? BoxShape.circle : BoxShape.rectangle,
        ),
      ),
    );
  }
}
