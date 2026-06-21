enum LegalDocumentType {
  terms,
  privacy,
}

extension LegalDocumentTypeLabels on LegalDocumentType {
  String get title {
    return switch (this) {
      LegalDocumentType.terms => 'شروط الاستخدام',
      LegalDocumentType.privacy => 'سياسة الخصوصية',
    };
  }
}
