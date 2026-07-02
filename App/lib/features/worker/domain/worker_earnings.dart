class WorkerEarnings {
  const WorkerEarnings({
    required this.jobsCount,
    required this.totalGross,
    required this.totalCommission,
    required this.totalNet,
    required this.recent,
  });

  final int jobsCount;
  final int totalGross;
  final int totalCommission;
  final int totalNet;
  final List<WorkerEarningItem> recent;

  factory WorkerEarnings.fromJson(Map<String, dynamic> json) {
    final rawRecent = json['recent'] as List<dynamic>? ?? const [];

    return WorkerEarnings(
      jobsCount: _asInt(json['jobs_count']),
      totalGross: _asInt(json['total_gross']),
      totalCommission: _asInt(json['total_commission']),
      totalNet: _asInt(json['total_net']),
      recent: rawRecent
          .map((item) => WorkerEarningItem.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}

class WorkerEarningItem {
  const WorkerEarningItem({
    required this.requestId,
    required this.serviceName,
    required this.categoryName,
    required this.grossAmount,
    required this.commissionRate,
    required this.commissionAmount,
    required this.netAmount,
    required this.createdAt,
  });

  final String requestId;
  final String serviceName;
  final String categoryName;
  final int grossAmount;
  final double commissionRate;
  final int commissionAmount;
  final int netAmount;
  final DateTime? createdAt;

  factory WorkerEarningItem.fromJson(Map<String, dynamic> json) {
    final rawCreatedAt = json['created_at'] as String?;

    return WorkerEarningItem(
      requestId: json['request_id'] as String? ?? '',
      serviceName: json['service_name'] as String? ?? 'خدمة',
      categoryName: json['category_name'] as String? ?? '',
      grossAmount: _asInt(json['gross_amount']),
      commissionRate: _asDouble(json['commission_rate']),
      commissionAmount: _asInt(json['commission_amount']),
      netAmount: _asInt(json['net_amount']),
      createdAt: rawCreatedAt == null ? null : DateTime.tryParse(rawCreatedAt),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('${value ?? ''}') ?? 0;
}

double _asDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse('${value ?? ''}') ?? 0;
}
