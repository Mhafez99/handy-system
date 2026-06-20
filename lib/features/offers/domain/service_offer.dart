class ServiceOffer {
  const ServiceOffer({
    required this.id,
    required this.workerId,
    required this.workerName,
    required this.workerPhone,
    required this.price,
    required this.arrivalTime,
    required this.note,
    required this.status,
    required this.createdAt,
    this.averageRating,
    this.reviewCount = 0,
  });

  final String id;
  final String workerId;
  final String workerName;
  final String workerPhone;
  final int price;
  final String arrivalTime;
  final String note;
  final String status;
  final DateTime createdAt;
  final double? averageRating;
  final int reviewCount;

  ServiceOffer withRatingSummary({
    required double? averageRating,
    required int reviewCount,
  }) {
    return ServiceOffer(
      id: id,
      workerId: workerId,
      workerName: workerName,
      workerPhone: workerPhone,
      price: price,
      arrivalTime: arrivalTime,
      note: note,
      status: status,
      createdAt: createdAt,
      averageRating: averageRating,
      reviewCount: reviewCount,
    );
  }

  factory ServiceOffer.fromJson(Map<String, dynamic> json) {
    final worker = json['worker'] as Map<String, dynamic>? ?? {};

    return ServiceOffer(
      id: json['id'] as String,
      workerId: json['worker_id'] as String? ?? '',
      workerName: worker['full_name'] as String? ?? 'صنايعي',
      workerPhone: worker['phone'] as String? ?? '',
      price: json['price'] as int,
      arrivalTime: json['arrival_time'] as String? ?? '',
      note: json['note'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
