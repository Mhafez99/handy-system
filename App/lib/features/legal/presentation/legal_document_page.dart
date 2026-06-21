import 'package:flutter/material.dart';
import 'package:handy_app/features/legal/domain/legal_content.dart';
import 'package:handy_app/features/legal/domain/legal_document_type.dart';

class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({
    required this.documentType,
    super.key,
  });

  final LegalDocumentType documentType;

  static Future<void> open(
    BuildContext context,
    LegalDocumentType documentType,
  ) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => LegalDocumentPage(documentType: documentType),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = LegalContent.sectionsFor(documentType);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(documentType.title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Text(
            'آخر تحديث: ${LegalContent.lastUpdated}',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          for (final section in sections) ...[
            Text(
              section.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            for (final paragraph in section.paragraphs) ...[
              Text(
                paragraph,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.7,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
