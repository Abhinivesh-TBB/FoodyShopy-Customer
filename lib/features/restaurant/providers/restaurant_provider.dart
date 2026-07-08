import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/restaurant.dart';
import '../../../shared/models/menu_item.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/logger_service.dart';

class RestaurantState {
  final List<Restaurant> allRestaurants;
  final List<Restaurant> filteredRestaurants;
  final bool isLoading;
  final String searchQuery;
  final bool isVegOnly;
  final bool isHighRatingOnly;
  final bool isFastDeliveryOnly;
  final Restaurant? selectedRestaurant;

  const RestaurantState({
    this.allRestaurants = const [],
    this.filteredRestaurants = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.isVegOnly = false,
    this.isHighRatingOnly = false,
    this.isFastDeliveryOnly = false,
    this.selectedRestaurant,
  });

  RestaurantState copyWith({
    List<Restaurant>? allRestaurants,
    List<Restaurant>? filteredRestaurants,
    bool? isLoading,
    String? searchQuery,
    bool? isVegOnly,
    bool? isHighRatingOnly,
    bool? isFastDeliveryOnly,
    Restaurant? selectedRestaurant,
  }) {
    return RestaurantState(
      allRestaurants: allRestaurants ?? this.allRestaurants,
      filteredRestaurants: filteredRestaurants ?? this.filteredRestaurants,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      isVegOnly: isVegOnly ?? this.isVegOnly,
      isHighRatingOnly: isHighRatingOnly ?? this.isHighRatingOnly,
      isFastDeliveryOnly: isFastDeliveryOnly ?? this.isFastDeliveryOnly,
      selectedRestaurant: selectedRestaurant ?? this.selectedRestaurant,
    );
  }
}

class RestaurantNotifier extends StateNotifier<RestaurantState> {
  final bool useMock = true;

  RestaurantNotifier() : super(const RestaurantState()) {
    fetchRestaurants();
  }

  Future<void> fetchRestaurants({String? zoneId}) async {
    state = state.copyWith(isLoading: true);

    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      final mockList = _getMockRestaurants();
      state = state.copyWith(
        allRestaurants: mockList,
        filteredRestaurants: mockList,
        isLoading: false,
      );
      _applyFiltersAndSearch();
      return;
    }

    try {
      final response = await ApiClient.dio.get(
        '/customer/restaurants',
        queryParameters: {'zone_id': zoneId ?? 'zone_1'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final list = data.map((e) => Restaurant.fromJson(e)).toList();
        state = state.copyWith(
          allRestaurants: list,
          filteredRestaurants: list,
          isLoading: false,
        );
        _applyFiltersAndSearch();
      } else {
        throw Exception("Server returned status ${response.statusCode}");
      }
    } catch (e) {
      LoggerService.logger.e("Failed to fetch restaurants: $e. Falling back to mock.");
      final mockList = _getMockRestaurants();
      state = state.copyWith(
        allRestaurants: mockList,
        filteredRestaurants: mockList,
        isLoading: false,
      );
      _applyFiltersAndSearch();
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFiltersAndSearch();
  }

  void toggleVegFilter() {
    state = state.copyWith(isVegOnly: !state.isVegOnly);
    _applyFiltersAndSearch();
  }

  void toggleHighRatingFilter() {
    state = state.copyWith(isHighRatingOnly: !state.isHighRatingOnly);
    _applyFiltersAndSearch();
  }

  void toggleFastDeliveryFilter() {
    state = state.copyWith(isFastDeliveryOnly: !state.isFastDeliveryOnly);
    _applyFiltersAndSearch();
  }

  Future<void> selectRestaurant(String id) async {
    // Locate in state first as immediate feedback
    Restaurant? restaurant = state.allRestaurants.firstWhere(
      (e) => e.id == id,
      orElse: () => _getMockRestaurants().firstWhere((e) => e.id == id),
    );
    state = state.copyWith(selectedRestaurant: restaurant);

    if (useMock) return;

    try {
      final response = await ApiClient.dio.get('/customer/restaurants/$id/menu');
      if (response.statusCode == 200) {
        final List<dynamic> menuData = response.data;
        final rawItems = menuData.map((e) => MenuItem.fromJson(e)).toList();
        // Hide out of stock items per spec
        final items = rawItems.where((e) => e.inStock).toList();

        // Update selected restaurant with real items
        final updatedRestaurant = Restaurant(
          id: restaurant.id,
          zoneId: restaurant.zoneId,
          name: restaurant.name,
          imageUrl: restaurant.imageUrl,
          rating: restaurant.rating,
          deliveryTimeMin: restaurant.deliveryTimeMin,
          distance: restaurant.distance,
          costForTwo: restaurant.costForTwo,
          cuisines: restaurant.cuisines,
          offers: restaurant.offers,
          description: restaurant.description,
          latitude: restaurant.latitude,
          longitude: restaurant.longitude,
          menu: items,
        );

        state = state.copyWith(selectedRestaurant: updatedRestaurant);
      }
    } catch (e) {
      LoggerService.logger.e("Failed to fetch menu: $e. Falling back to mock menu.");
      try {
        final mockRestaurant = _getMockRestaurants().firstWhere((e) => e.id == id);
        final updatedRestaurant = Restaurant(
          id: restaurant.id,
          zoneId: restaurant.zoneId,
          name: restaurant.name,
          imageUrl: restaurant.imageUrl,
          rating: restaurant.rating,
          deliveryTimeMin: restaurant.deliveryTimeMin,
          distance: restaurant.distance,
          costForTwo: restaurant.costForTwo,
          cuisines: restaurant.cuisines,
          offers: restaurant.offers,
          description: restaurant.description,
          latitude: restaurant.latitude,
          longitude: restaurant.longitude,
          menu: mockRestaurant.menu,
        );
        state = state.copyWith(selectedRestaurant: updatedRestaurant);
      } catch (_) {}
    }
  }

  void _applyFiltersAndSearch() {
    var list = List<Restaurant>.from(state.allRestaurants);

    // Search query
    if (state.searchQuery.isNotEmpty) {
      final q = state.searchQuery.toLowerCase();
      list = list.where((r) {
        final matchesName = r.name.toLowerCase().contains(q);
        final matchesCuisines = r.cuisines.any((c) => c.toLowerCase().contains(q));
        return matchesName || matchesCuisines;
      }).toList();
    }

    // High rating filter (4.3+)
    if (state.isHighRatingOnly) {
      list = list.where((r) => r.rating >= 4.3).toList();
    }

    // Fast delivery filter (under 25 mins)
    if (state.isFastDeliveryOnly) {
      list = list.where((r) => r.deliveryTimeMin <= 25).toList();
    }

    // Veg Only filter (displays restaurants which have vegetarian options or cuisines containing vegetarian hints)
    if (state.isVegOnly) {
      list = list.where((r) => r.menu.any((item) => item.isVeg)).toList();
    }

    state = state.copyWith(filteredRestaurants: list);
  }

  List<Restaurant> _getMockRestaurants() {
    return [
      Restaurant(
        id: 'rest_1',
        name: 'Meghana Foods',
        imageUrl: 'https://images.unsplash.com/photo-1633945274405-b6c8069047b0?q=80&w=600&auto=format&fit=crop',
        rating: 4.5,
        deliveryTimeMin: 22,
        distance: '2.8 km',
        costForTwo: 350,
        cuisines: ['Biryani', 'Andhra', 'North Indian'],
        offers: ['50% OFF up to ₹100', 'Free delivery on gold'],
        description: 'Authentic rich spices and flavorful traditional biryanis.',
        latitude: 12.9716,
        longitude: 77.5946,
        menu: [
          const MenuItem(
            id: 'm1',
            name: 'Meghana Special Chicken Biryani',
            description: 'Fragrant long-grained basmati rice cooked with succulent chicken pieces in robust signature spices.',
            price: 320,
            imageUrl: 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?q=80&w=400&auto=format&fit=crop',
            isVeg: false,
            isBestseller: true,
            category: 'Biryani Specialities',
            rating: 4.6,
          ),
          const MenuItem(
            id: 'm2',
            name: 'Special Paneer Biryani',
            description: 'Delicious basmati rice cooked with soft, marinated cottage cheese chunks in aromatic spices.',
            price: 285,
            imageUrl: 'https://images.unsplash.com/photo-1645177625172-595e25c7ef7f?q=80&w=400&auto=format&fit=crop',
            isVeg: true,
            isBestseller: false,
            category: 'Biryani Specialities',
            rating: 4.3,
          ),
          const MenuItem(
            id: 'm3',
            name: 'Gobi 65 Dry',
            description: 'Deep-fried crispy cauliflower florets marinated in yogurt, curry leaves, and spicy red chillies.',
            price: 180,
            imageUrl: 'https://images.unsplash.com/photo-1601050690597-df056fb4ce78?q=80&w=400&auto=format&fit=crop',
            isVeg: true,
            isBestseller: true,
            category: 'Starters',
            rating: 4.4,
          ),
          const MenuItem(
            id: 'm4',
            name: 'Boneless Chicken Kabab',
            description: 'Classic starter made with tender chicken strips marinated in handpicked spices and fried crisp.',
            price: 230,
            imageUrl: 'https://images.unsplash.com/photo-1608897013039-887f21d8c804?q=80&w=400&auto=format&fit=crop',
            isVeg: false,
            isBestseller: true,
            category: 'Starters',
            rating: 4.5,
          ),
        ],
      ),
      Restaurant(
        id: 'rest_2',
        name: "Leon's Burgers & Wings",
        imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=600&auto=format&fit=crop',
        rating: 4.3,
        deliveryTimeMin: 18,
        distance: '1.4 km',
        costForTwo: 300,
        cuisines: ['Burgers', 'American', 'Fast Food'],
        offers: ['Buy 1 Get 1 Free on Selects', 'Free Delivery above ₹199'],
        description: 'Juicy American style burgers, crispy chicken wings and rich milkshakes.',
        latitude: 12.9730,
        longitude: 77.6010,
        menu: [
          const MenuItem(
            id: 'm5',
            name: 'Jumbo Crispy Chicken Burger',
            description: 'Crispy fried chicken breast fillet loaded with creamy cheese, fresh lettuce, and burger sauce.',
            price: 199,
            imageUrl: 'https://images.unsplash.com/photo-1625813506062-0aeb1d7a094b?q=80&w=400&auto=format&fit=crop',
            isVeg: false,
            isBestseller: true,
            category: 'Gourmet Burgers',
            rating: 4.4,
          ),
          const MenuItem(
            id: 'm6',
            name: 'Spicy Veg Crunch Burger',
            description: 'Double layer crispy vegetable patty topped with sliced jalapenos, spicy mayo and cheese slice.',
            price: 149,
            imageUrl: 'https://images.unsplash.com/photo-1525059696034-4967a8e1dca2?q=80&w=400&auto=format&fit=crop',
            isVeg: true,
            isBestseller: true,
            category: 'Gourmet Burgers',
            rating: 4.2,
          ),
          const MenuItem(
            id: 'm7',
            name: 'BBQ Glazed Chicken Wings',
            description: '6 pieces of golden-fried chicken wings tossed generously in sticky smokey sweet BBQ sauce.',
            price: 219,
            imageUrl: 'https://images.unsplash.com/photo-1567620832903-9fc6debc209f?q=80&w=400&auto=format&fit=crop',
            isVeg: false,
            isBestseller: false,
            category: 'Chicken Wings',
            rating: 4.3,
          ),
        ],
      ),
      Restaurant(
        id: 'rest_3',
        name: 'Corner House Ice Creams',
        imageUrl: 'https://images.unsplash.com/photo-1563805042-7684c019e1cb?q=80&w=600&auto=format&fit=crop',
        rating: 4.7,
        deliveryTimeMin: 15,
        distance: '3.1 km',
        costForTwo: 200,
        cuisines: ['Desserts', 'Ice Cream', 'Waffles'],
        offers: ['Flat 15% OFF on Tubs'],
        description: 'Bengalurus iconic legendary ice cream parlour serving rich hot chocolate fudge.',
        latitude: 12.9698,
        longitude: 77.6120,
        menu: [
          const MenuItem(
            id: 'm8',
            name: 'Death By Chocolate (DBC)',
            description: 'Our legendary dessert! Two scoops of vanilla ice cream served with warm chocolate cake, cherries, and hot fudge.',
            price: 260,
            imageUrl: 'https://images.unsplash.com/photo-1579954115545-a95591f28bfc?q=80&w=400&auto=format&fit=crop',
            isVeg: true,
            isBestseller: true,
            category: 'Legendary Sundaes',
            rating: 4.9,
          ),
          const MenuItem(
            id: 'm9',
            name: 'Hot Chocolate Fudge (HCF)',
            description: 'Silky smooth vanilla ice cream drowned in hot, home-cooked thick chocolate fudge topped with roasted cashew nuts.',
            price: 190,
            imageUrl: 'https://images.unsplash.com/photo-1505394033774-8ff14aacf77f?q=80&w=400&auto=format&fit=crop',
            isVeg: true,
            isBestseller: true,
            category: 'Legendary Sundaes',
            rating: 4.8,
          ),
          const MenuItem(
            id: 'm10',
            name: 'Nutty Chocolate Waffle',
            description: 'Freshly baked crisp Belgian waffle drizzled with melted dark chocolate and sprinkled with crunchy peanuts.',
            price: 170,
            imageUrl: 'https://images.unsplash.com/photo-1562376502-6f769499c886?q=80&w=400&auto=format&fit=crop',
            isVeg: true,
            isBestseller: false,
            category: 'Baked Waffles',
            rating: 4.5,
          ),
        ],
      ),
      Restaurant(
        id: 'rest_4',
        name: 'The Pizza Palace',
        imageUrl: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=600&auto=format&fit=crop',
        rating: 4.2,
        deliveryTimeMin: 28,
        distance: '4.2 km',
        costForTwo: 450,
        cuisines: ['Pizza', 'Italian', 'Pastas'],
        offers: ['₹100 OFF on Orders above ₹399', 'Buy 1 Get 1 on Mediums'],
        description: 'Artisanal stone-baked sourdough pizzas covered in rich marinara and fresh cheese.',
        latitude: 12.9805,
        longitude: 77.5850,
        menu: [
          const MenuItem(
            id: 'm11',
            name: 'Classic Margherita Pizza',
            description: 'Sourdough crust topped with homemade tomato sauce, premium mozzarella pearls, and fresh basil leaves.',
            price: 299,
            imageUrl: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?q=80&w=400&auto=format&fit=crop',
            isVeg: true,
            isBestseller: true,
            category: 'Sourdough Pizzas',
            rating: 4.4,
          ),
          const MenuItem(
            id: 'm12',
            name: 'Spicy Double Pepperoni Pizza',
            description: 'Double portion of spicy pork pepperoni, mozzarella, chili flakes, and hot honey drizzle.',
            price: 449,
            imageUrl: 'https://images.unsplash.com/photo-1628840042765-356cda07504e?q=80&w=400&auto=format&fit=crop',
            isVeg: false,
            isBestseller: true,
            category: 'Sourdough Pizzas',
            rating: 4.6,
          ),
          const MenuItem(
            id: 'm13',
            name: 'Creamy Garlic Pesto Pasta',
            description: 'Penne pasta tossed in aromatic basil pesto sauce with fresh garlic, cream, broccoli, and parmesan.',
            price: 249,
            imageUrl: 'https://images.unsplash.com/photo-1608897013039-887f21d8c804?q=80&w=400&auto=format&fit=crop',
            isVeg: true,
            isBestseller: false,
            category: 'Gourmet Pastas',
            rating: 4.1,
          ),
        ],
      ),
    ];
  }
}

final restaurantProvider = StateNotifierProvider<RestaurantNotifier, RestaurantState>((ref) {
  return RestaurantNotifier();
});
