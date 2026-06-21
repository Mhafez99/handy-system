class CreateComplaintData {
  const CreateComplaintData({
    required this.requestId,
    required this.category,
    required this.description,
  });

  final String requestId;
  final String category;
  final String description;
}
