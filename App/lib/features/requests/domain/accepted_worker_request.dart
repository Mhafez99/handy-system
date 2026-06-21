import 'package:handy_app/features/reviews/domain/service_review.dart';

class AcceptedWorkerRequest {
  const AcceptedWorkerRequest({
    required this.id,
    required this.serviceName,
    required this.categoryName,
    required this.description,
    required this.governorate,
    required this.area,
    required this.address,
    required this.preferredTime,
    required this.status,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.acceptedPrice,
    required this.arrivalTime,
    required this.createdAt,
    required this.review,
    this.finalPrice,
    this.paymentMethod,
  });

  final String id;
  final String serviceName;
  final String categoryName;
  final String description;
  final String governorate;
  final String area;
  final String address;
  final String preferredTime;
  final String status;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final int acceptedPrice;
  final String arrivalTime;
  final DateTime createdAt;
  final ServiceReview? review;
  final int? finalPrice;
  final String? paymentMethod;

  factory AcceptedWorkerRequest.fromJson(Map<String, dynamic> json) {
    final service = json['services'] as Map<String, dynamic>? ?? {};
    final category = service['categories'] as Map<String, dynamic>? ?? {};
    final customer = json['customer'] as Map<String, dynamic>? ?? {};
    final offers = json['offers'] as List<dynamic>? ?? [];
    final acceptedOffer = offers.isEmpty
        ? <String, dynamic>{}
        : offers.first as Map<String, dynamic>;
    final rawReviews = json['service_reviews'] as List<dynamic>? ?? [];

    return AcceptedWorkerRequest(
      id: json['id'] as String,
      serviceName: service['name'] as String? ?? 'خدمة غير محددة',
      categoryName: category['name'] as String? ?? 'تخصص غير محدد',
      description: json['description'] as String? ?? '',
      governorate: json['governorate'] as String? ?? '',
      area: json['area'] as String? ?? '',
      address: json['address'] as String? ?? '',
      preferredTime: json['preferred_time'] as String? ?? '',
      status: json['status'] as String? ?? 'accepted',
      customerName: customer['full_name'] as String? ?? 'عميل',
      customerPhone: customer['phone'] as String? ?? '',
      customerAddress: customer['address'] as String? ?? '',
      acceptedPrice: acceptedOffer['price'] as int? ?? 0,
      arrivalTime: acceptedOffer['arrival_time'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      review: rawReviews.isEmpty
          ? null
          : ServiceReview.fromJson(rawReviews.first as Map<String, dynamic>),
      finalPrice: json['final_price'] as int?,
      paymentMethod: json['payment_method'] as String?,
    );
  }
}
