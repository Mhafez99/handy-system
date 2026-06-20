class CreateOfferData {
  const CreateOfferData({
    required this.requestId,
    required this.price,
    required this.arrivalTime,
    required this.note,
  });

  final String requestId;
  final int price;
  final String arrivalTime;
  final String note;
}
