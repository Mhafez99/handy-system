enum CustomerRequestFilter {
  all,
  active,
  completed,
  cancelled,
  complaint,
}

extension CustomerRequestFilterX on CustomerRequestFilter {
  String get label {
    return switch (this) {
      CustomerRequestFilter.all => 'الكل',
      CustomerRequestFilter.active => 'نشطة',
      CustomerRequestFilter.completed => 'مكتملة',
      CustomerRequestFilter.cancelled => 'ملغاة',
      CustomerRequestFilter.complaint => 'شكاوى',
    };
  }

  bool matchesStatus(String status) {
    return switch (this) {
      CustomerRequestFilter.all => true,
      CustomerRequestFilter.active => const {
        'new',
        'offered',
        'accepted',
        'on_the_way',
        'in_progress',
      }.contains(status),
      CustomerRequestFilter.completed => status == 'completed',
      CustomerRequestFilter.cancelled => status == 'cancelled',
      CustomerRequestFilter.complaint => status == 'complaint',
    };
  }
}

String customerRequestStatusLabel(String status) {
  return switch (status) {
    'new' => 'جديد',
    'offered' => 'به عروض',
    'accepted' => 'مقبول',
    'on_the_way' => 'في الطريق',
    'in_progress' => 'قيد التنفيذ',
    'completed' => 'مكتمل',
    'cancelled' => 'ملغي',
    'complaint' => 'شكوى',
    _ => status,
  };
}
