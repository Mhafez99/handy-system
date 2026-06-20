class ServiceCategory {
  const ServiceCategory({required this.id, required this.name});

  final int id;
  final String name;

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(id: json['id'] as int, name: json['name'] as String);
  }
}
