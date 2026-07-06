import 'menu_item.dart';

class Restaurant {
  final String id;
  final String name;
  final String imageUrl;
  final double rating;
  final int deliveryTimeMin;
  final String distance;
  final double costForTwo;
  final List<String> cuisines;
  final List<String> offers;
  final String description;
  final double? latitude;
  final double? longitude;
  final List<MenuItem> menu;

  const Restaurant({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.rating,
    required this.deliveryTimeMin,
    required this.distance,
    required this.costForTwo,
    required this.cuisines,
    required this.offers,
    required this.description,
    this.latitude,
    this.longitude,
    this.menu = const [],
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.0,
      deliveryTimeMin: json['deliveryTimeMin'] as int? ?? 30,
      distance: json['distance'] as String? ?? '2.0 km',
      costForTwo: (json['costForTwo'] as num?)?.toDouble() ?? 250.0,
      cuisines: (json['cuisines'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      offers: (json['offers'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      description: json['description'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      menu: (json['menu'] as List<dynamic>?)
              ?.map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'rating': rating,
      'deliveryTimeMin': deliveryTimeMin,
      'distance': distance,
      'costForTwo': costForTwo,
      'cuisines': cuisines,
      'offers': offers,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'menu': menu.map((e) => e.toJson()).toList(),
    };
  }
}
