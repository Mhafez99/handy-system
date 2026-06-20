import 'package:handy_app/features/offers/domain/service_offer.dart';
import 'package:handy_app/features/reviews/domain/service_review.dart';

class ServiceRequestDetails {
  const ServiceRequestDetails({
    required this.id,
    required this.serviceName,
    required this.categoryName,
    required this.priceRange,
    required this.description,
    required this.governorate,
    required this.area,
    required this.address,
    required this.preferredTime,
    required this.status,
    required this.createdAt,
    required this.offers,
    required this.review,
  });

  final String id;
  final String serviceName;
  final String categoryName;
  final String priceRange;
  final String description;
  final String governorate;
  final String area;
  final String address;
  final String preferredTime;
  final String status;
  final DateTime createdAt;
  final List<ServiceOffer> offers;
  final ServiceReview? review;

  ServiceRequestDetails withOffers(List<ServiceOffer> nextOffers) {
    return ServiceRequestDetails(
      id: id,
      serviceName: serviceName,
      categoryName: categoryName,
      priceRange: priceRange,
      description: description,
      governorate: governorate,
      area: area,
      address: address,
      preferredTime: preferredTime,
      status: status,
      createdAt: createdAt,
      offers: nextOffers,
      review: review,
    );
  }

  factory ServiceRequestDetails.fromJson(Map<String, dynamic> json) {
    final service = json['services'] as Map<String, dynamic>? ?? {};
    final category = service['categories'] as Map<String, dynamic>? ?? {};
    final minPrice = service['min_price'] as int?;
    final maxPrice = service['max_price'] as int?;
    final rawOffers = json['offers'] as List<dynamic>? ?? [];
    final rawReviews = json['service_reviews'] as List<dynamic>? ?? [];

    return ServiceRequestDetails(
      id: json['id'] as String,
      serviceName: service['name'] as String? ?? 'خدمة غير محددة',
      categoryName: category['name'] as String? ?? 'تخصص غير محدد',
      priceRange: minPrice == null || maxPrice == null
          ? 'غير محدد'
          : '$minPrice - $maxPrice جنيه',
      description: json['description'] as String? ?? '',
      governorate: json['governorate'] as String? ?? '',
      area: json['area'] as String? ?? '',
      address: json['address'] as String? ?? '',
      preferredTime: json['preferred_time'] as String? ?? '',
      status: json['status'] as String? ?? 'new',
      createdAt: DateTime.parse(json['created_at'] as String),
      offers: rawOffers
          .map((offer) => ServiceOffer.fromJson(offer as Map<String, dynamic>))
          .toList(growable: false),
      review: rawReviews.isEmpty
          ? null
          : ServiceReview.fromJson(rawReviews.first as Map<String, dynamic>),
    );
  }
}
