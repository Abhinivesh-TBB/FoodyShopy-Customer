import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_text_styles.dart';
import '../restaurant/providers/restaurant_provider.dart';
import '../cart/providers/cart_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final restState = ref.watch(restaurantProvider);
    final cartState = ref.watch(cartProvider);
    final notifier = ref.read(restaurantProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        leadingWidth: 0,
        leading: const SizedBox.shrink(),
        title: Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.primary, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Indiranagar',
                        style: AppTextStyles.heading2.copyWith(fontSize: 18),
                      ),
                      const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                    ],
                  ),
                  Text(
                    'HAL 2nd Stage, Bengaluru, Karnataka 560038',
                    style: AppTextStyles.caption.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, size: 28),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: restState.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => notifier.fetchRestaurants(),
              child: CustomScrollView(
                slivers: [
                  // Search Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => notifier.setSearchQuery(val),
                          decoration: InputDecoration(
                            hintText: 'Search for restaurants, cuisines or dishes',
                            hintStyle: AppTextStyles.caption.copyWith(color: Colors.grey[500]),
                            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                                    onPressed: () {
                                      _searchController.clear();
                                      notifier.setSearchQuery('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Promotional Banner Carousel
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 140,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _buildPromoCard(
                            '50% OFF UPTO ₹100',
                            'On top local favourites',
                            'USE CODE: WELCOME50',
                            const [Color(0xFFE65100), Color(0xFFFFB74D)],
                          ),
                          _buildPromoCard(
                            'FREE DELIVERY WEEK',
                            'No delivery charge on orders above ₹199',
                            'AUTOMATIC UNLOCK',
                            const [Color(0xFF1B5E20), Color(0xFF81C784)],
                          ),
                          _buildPromoCard(
                            'SWEET DESSERT FESTIVAL',
                            'Indulge in desserts starting at ₹49',
                            'NO CODE REQUIRED',
                            const [Color(0xFF880E4F), Color(0xFFF06292)],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),

                  // What's on your mind? (Categories Grid)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "What's on your mind?",
                        style: AppTextStyles.heading2.copyWith(fontSize: 20),
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 110,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        children: [
                          _buildCategoryItem('Biryani', 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?q=80&w=200'),
                          _buildCategoryItem('Burger', 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=200'),
                          _buildCategoryItem('Pizza', 'https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=200'),
                          _buildCategoryItem('Desserts', 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?q=80&w=200'),
                          _buildCategoryItem('North Indian', 'https://images.unsplash.com/photo-1601050690597-df056fb4ce78?q=80&w=200'),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 16)),

                  // Filters Section Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        "Restaurants to explore",
                        style: AppTextStyles.heading2.copyWith(fontSize: 20),
                      ),
                    ),
                  ),

                  // Filter Chips
                  SliverToBoxAdapter(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'Veg Only',
                            isSelected: restState.isVegOnly,
                            onTap: () => notifier.toggleVegFilter(),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Ratings 4.3+',
                            isSelected: restState.isHighRatingOnly,
                            onTap: () => notifier.toggleHighRatingFilter(),
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Fast Delivery (<25m)',
                            isSelected: restState.isFastDeliveryOnly,
                            onTap: () => notifier.toggleFastDeliveryFilter(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Restaurant List
                  restState.filteredRestaurants.isEmpty
                      ? const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text(
                                'No restaurants match your filters.',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final restaurant = restState.filteredRestaurants[index];
                              return _buildRestaurantCard(context, restaurant);
                            },
                            childCount: restState.filteredRestaurants.length,
                          ),
                        ),

                  const SliverToBoxAdapter(child: SizedBox(height: 80)),
                ],
              ),
            ),
      // Local floating cart notification
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
                        '${cartState.totalItemCount} ITEM${cartState.totalItemCount > 1 ? 'S' : ''} | ₹${cartState.total.toStringAsFixed(0)}',
                        style: AppTextStyles.button.copyWith(fontSize: 14),
                      ),
                      Text(
                        'From ${cartState.restaurantName}',
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
                        const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildPromoCard(String title, String subtitle, String code, List<Color> colors) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 2),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
            child: Text(code, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(String title, String imageUrl) {
    return GestureDetector(
      onTap: () {
        _searchController.text = title;
        ref.read(restaurantProvider.notifier).setSearchQuery(title);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.transparent,
              backgroundImage: NetworkImage(imageUrl),
            ),
            const SizedBox(height: 6),
            Text(title, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.divider),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(BuildContext context, var restaurant) {
    return GestureDetector(
      onTap: () {
        ref.read(restaurantProvider.notifier).selectRestaurant(restaurant.id);
        context.push(AppRoutes.menuPath(restaurant.id));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                restaurant.imageUrl,
                width: 100,
                height: 100,
                fit: double.infinity == 0.0 ? null : BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 100,
                  height: 100,
                  color: Colors.grey[200],
                  child: const Icon(Icons.fastfood, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: AppTextStyles.heading2.copyWith(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restaurant.cuisines.join(', '),
                    style: AppTextStyles.caption.copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: AppColors.success, size: 14),
                            const SizedBox(width: 2),
                            Text(
                              restaurant.rating.toString(),
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('•', style: TextStyle(color: Colors.grey[400])),
                      const SizedBox(width: 8),
                      Text(
                        '${restaurant.deliveryTimeMin} mins',
                        style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Text('•', style: TextStyle(color: Colors.grey[400])),
                      const SizedBox(width: 8),
                      Text(
                        restaurant.distance,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  if (restaurant.offers.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.local_offer, color: AppColors.primary, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            restaurant.offers.first,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
