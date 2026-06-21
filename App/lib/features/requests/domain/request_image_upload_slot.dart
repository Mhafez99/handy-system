class RequestImageUploadSlot {
  const RequestImageUploadSlot({
    required this.id,
    required this.storagePath,
    required this.sortOrder,
    required this.uploadUrl,
    required this.token,
    required this.contentType,
  });

  final String id;
  final String storagePath;
  final int sortOrder;
  final String uploadUrl;
  final String token;
  final String contentType;

  factory RequestImageUploadSlot.fromJson(Map<String, dynamic> json) {
    return RequestImageUploadSlot(
      id: json['id'] as String,
      storagePath: json['storage_path'] as String,
      sortOrder: json['sort_order'] as int? ?? 0,
      uploadUrl: json['upload_url'] as String,
      token: json['token'] as String,
      contentType: json['content_type'] as String? ?? 'image/jpeg',
    );
  }
}
