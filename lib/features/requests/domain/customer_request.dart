class CustomerRequest {
  const CustomerRequest({
    required this.id,
    required this.serviceName,
    required this.categoryName,
    required this.area,
    required this.status,
    required this.offerCount,
    required this.createdAt,
  });

  final String id;
  final String serviceName;
  final String categoryName;
  final String area;
  final String status;
  final int offerCount;
  final DateTime createdAt;

  factory CustomerRequest.fromJson(Map<String, dynamic> json) {
    final service = json['services'] as Map<String, dynamic>? ?? {};
    final category = service['categories'] as Map<String, dynamic>? ?? {};
    final offers = json['offers'] as List<dynamic>? ?? [];

    return CustomerRequest(
      id: json['id'] as String,
      serviceName: service['name'] as String? ?? 'خدمة غير محددة',
      categoryName: category['name'] as String? ?? 'تخصص غير محدد',
      area: json['area'] as String? ?? '',
      status: json['status'] as String? ?? 'new',
      offerCount: offers.length,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
