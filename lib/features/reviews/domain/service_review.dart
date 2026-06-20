class ServiceReview {
  const ServiceReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final int rating;
  final String comment;
  final DateTime createdAt;

  factory ServiceReview.fromJson(Map<String, dynamic> json) {
    return ServiceReview(
      id: json['id'] as String? ?? '',
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
