class Area {
  const Area({
    required this.id,
    required this.governorate,
    required this.name,
  });

  final int id;
  final String governorate;
  final String name;

  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      id: json['id'] as int,
      governorate: json['governorate'] as String,
      name: json['name'] as String,
    );
  }
}
