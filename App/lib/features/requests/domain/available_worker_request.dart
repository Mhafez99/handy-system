class AvailableWorkerRequest {
  const AvailableWorkerRequest({
    required this.id,
    required this.serviceName,
    required this.categoryName,
    required this.priceRange,
    required this.description,
    required this.area,
    required this.address,
    required this.preferredTime,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String serviceName;
  final String categoryName;
  final String priceRange;
  final String description;
  final String area;
  final String address;
  final String preferredTime;
  final String status;
  final DateTime createdAt;

  factory AvailableWorkerRequest.fromJson(Map<String, dynamic> json) {
    final service = json['services'] as Map<String, dynamic>? ?? {};
    final category = service['categories'] as Map<String, dynamic>? ?? {};
    final minPrice = service['min_price'] as int?;
    final maxPrice = service['max_price'] as int?;

    return AvailableWorkerRequest(
      id: json['id'] as String,
      serviceName: service['name'] as String? ?? 'خدمة غير محددة',
      categoryName: category['name'] as String? ?? 'تخصص غير محدد',
      priceRange: minPrice == null || maxPrice == null
          ? 'غير محدد'
          : '$minPrice - $maxPrice جنيه',
      description: json['description'] as String? ?? '',
      area: json['area'] as String? ?? '',
      address: json['address'] as String? ?? '',
      preferredTime: json['preferred_time'] as String? ?? '',
      status: json['status'] as String? ?? 'new',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
