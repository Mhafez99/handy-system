class RequestImage {
  const RequestImage({
    required this.id,
    required this.url,
    required this.sortOrder,
  });

  final String id;
  final String url;
  final int sortOrder;

  factory RequestImage.fromJson(Map<String, dynamic> json) {
    return RequestImage(
      id: json['id'] as String,
      url: json['url'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}
