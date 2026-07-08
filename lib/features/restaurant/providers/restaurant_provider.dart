import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/restaurant.dart';
import '../../../shared/models/menu_item.dart';
import '../../../core/api/api_client.dart';
import '../../../core/services/logger_service.dart';
import '../../../shared/mocks/mock_data.dart';

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
  final bool useMock = false;

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
    return mockRestaurants;
  }
}

final restaurantProvider = StateNotifierProvider<RestaurantNotifier, RestaurantState>((ref) {
  return RestaurantNotifier();
});
