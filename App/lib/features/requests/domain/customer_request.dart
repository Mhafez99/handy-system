class CustomerRequest {
  const CustomerRequest({
    required this.id,
    required this.serviceName,
    required this.categoryName,
    required this.area,
    required this.status,
    required this.offerCount,
    required this.createdAt,
    this.finalPrice,
    this.paymentMethod,
  });

  final String id;
  final String serviceName;
  final String categoryName;
  final String area;
  final String status;
  final int offerCount;
  final DateTime createdAt;
  final int? finalPrice;
  final String? paymentMethod;

  String get paymentMethodLabel {
    return switch (paymentMethod) {
      'cash' => 'كاش',
      _ => paymentMethod ?? '',
    };
  }

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
      offerCount: json['offer_count'] as int? ?? offers.length,
      createdAt: DateTime.parse(json['created_at'] as String),
      finalPrice: json['final_price'] as int?,
      paymentMethod: json['payment_method'] as String?,
    );
  }
}
