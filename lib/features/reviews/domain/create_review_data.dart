class CreateReviewData {
  const CreateReviewData({
    required this.requestId,
    required this.rating,
    required this.comment,
  });

  final String requestId;
  final int rating;
  final String comment;
}
