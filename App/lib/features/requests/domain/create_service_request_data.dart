class CreateServiceRequestData {
  const CreateServiceRequestData({
    required this.categoryId,
    required this.serviceId,
    required this.description,
    required this.governorate,
    required this.area,
    required this.address,
    required this.preferredTime,
  });

  final int categoryId;
  final int serviceId;
  final String description;
  final String governorate;
  final String area;
  final String address;
  final String preferredTime;
}
