class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final bool isVeg;
  final bool isBestseller;
  final String category;
  final double rating;
  final bool inStock;

  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.isVeg,
    this.isBestseller = false,
    required this.category,
    this.rating = 4.0,
    this.inStock = true,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String? ?? '',
      isVeg: json['isVeg'] as bool? ?? true,
      isBestseller: json['isBestseller'] as bool? ?? false,
      category: json['category'] as String? ?? 'General',
      rating: (json['rating'] as num?)?.toDouble() ?? 4.0,
      inStock: json['inStock'] as bool? ?? json['in_stock'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'isVeg': isVeg,
      'isBestseller': isBestseller,
      'category': category,
      'rating': rating,
      'inStock': inStock,
    };
  }
}
