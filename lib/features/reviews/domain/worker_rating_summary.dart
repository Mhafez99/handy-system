class WorkerRatingSummary {
  const WorkerRatingSummary({
    required this.workerId,
    required this.averageRating,
    required this.reviewCount,
  });

  final String workerId;
  final double averageRating;
  final int reviewCount;

  factory WorkerRatingSummary.fromJson(Map<String, dynamic> json) {
    return WorkerRatingSummary(
      workerId: json['worker_id'] as String,
      averageRating: double.parse('${json['average_rating'] ?? 0}'),
      reviewCount: json['review_count'] as int? ?? 0,
    );
  }
}
