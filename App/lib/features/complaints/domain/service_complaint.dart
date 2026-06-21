class ServiceComplaint {
  const ServiceComplaint({
    required this.id,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String category;
  final String description;
  final String status;
  final DateTime createdAt;

  String get categoryLabel => complaintCategoryLabel(category);

  String get statusLabel => complaintStatusLabel(status);

  factory ServiceComplaint.fromJson(Map<String, dynamic> json) {
    return ServiceComplaint(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? 'other',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

const complaintCategories = <String, String>{
  'poor_quality': 'جودة الشغل ضعيفة',
  'no_show': 'الصنايعي ما حضرش',
  'overcharge': 'زيادة في السعر',
  'behavior': 'سلوك غير لائق',
  'other': 'سبب آخر',
};

String complaintCategoryLabel(String category) {
  return complaintCategories[category] ?? category;
}

String complaintStatusLabel(String status) {
  return switch (status) {
    'open' => 'جديدة',
    'in_review' => 'قيد المراجعة',
    'resolved' => 'تم الحل',
    'dismissed' => 'مرفوضة',
    _ => status,
  };
}
