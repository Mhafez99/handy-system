class ServiceItem {
  const ServiceItem({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.minPrice,
    required this.maxPrice,
  });

  final int id;
  final int categoryId;
  final String name;
  final int minPrice;
  final int maxPrice;

  String get priceRange => '$minPrice - $maxPrice جنيه';

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] as int,
      categoryId: json['category_id'] as int,
      name: json['name'] as String,
      minPrice: json['min_price'] as int,
      maxPrice: json['max_price'] as int,
    );
  }
}
