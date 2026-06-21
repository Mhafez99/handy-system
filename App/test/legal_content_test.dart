import 'package:flutter_test/flutter_test.dart';
import 'package:handy_app/features/legal/domain/legal_content.dart';
import 'package:handy_app/features/legal/domain/legal_document_type.dart';

void main() {
  test('legal documents include essential sections', () {
    final terms = LegalContent.sectionsFor(LegalDocumentType.terms);
    final privacy = LegalContent.sectionsFor(LegalDocumentType.privacy);

    expect(terms.length, greaterThanOrEqualTo(8));
    expect(privacy.length, greaterThanOrEqualTo(8));
    expect(
      terms.every((section) => section.title.isNotEmpty),
      isTrue,
    );
    expect(
      privacy.every(
        (section) => section.paragraphs.every((paragraph) => paragraph.isNotEmpty),
      ),
      isTrue,
    );
  });
}
