import 'package:handy_app/features/reviews/domain/service_review.dart';

class WorkerPublicDetails {
  const WorkerPublicDetails({
    required this.workerId,
    required this.fullName,
    required this.governorate,
    required this.area,
    required this.profession,
    required this.yearsExperience,
    required this.bio,
    required this.averageRating,
    required this.reviewCount,
    required this.reviews,
  });

  final String workerId;
  final String fullName;
  final String governorate;
  final String area;
  final String profession;
  final int yearsExperience;
  final String bio;
  final double? averageRating;
  final int reviewCount;
  final List<ServiceReview> reviews;

  factory WorkerPublicDetails.fromJson(Map<String, dynamic> json) {
    final rawReviews = json['reviews'] as List<dynamic>? ?? [];
    final rawAverageRating = json['average_rating'];

    return WorkerPublicDetails(
      workerId: json['worker_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'صنايعي',
      governorate: json['governorate'] as String? ?? '',
      area: json['area'] as String? ?? '',
      profession: json['profession'] as String? ?? '',
      yearsExperience: json['years_experience'] as int? ?? 0,
      bio: json['bio'] as String? ?? '',
      averageRating: rawAverageRating == null
          ? null
          : double.parse('$rawAverageRating'),
      reviewCount: json['review_count'] as int? ?? 0,
      reviews: rawReviews
          .map(
            (review) => ServiceReview.fromJson(review as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }
}
