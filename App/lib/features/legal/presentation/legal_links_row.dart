import 'package:flutter/material.dart';
import 'package:handy_app/features/legal/domain/legal_document_type.dart';
import 'package:handy_app/features/legal/presentation/legal_document_page.dart';

class LegalLinksRow extends StatelessWidget {
  const LegalLinksRow({
    this.prefix = 'اطّلع على ',
    this.separator = ' و',
    super.key,
  });

  final String prefix;
  final String separator;

  @override
  Widget build(BuildContext context) {
    final linkStyle = TextButton.styleFrom(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      foregroundColor: Theme.of(context).colorScheme.primary,
      textStyle: const TextStyle(fontWeight: FontWeight.w700),
    );

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      runSpacing: 4,
      children: [
        Text(prefix, style: Theme.of(context).textTheme.bodyMedium),
        TextButton(
          style: linkStyle,
          onPressed: () {
            LegalDocumentPage.open(context, LegalDocumentType.terms);
          },
          child: const Text('شروط الاستخدام'),
        ),
        Text(separator, style: Theme.of(context).textTheme.bodyMedium),
        TextButton(
          style: linkStyle,
          onPressed: () {
            LegalDocumentPage.open(context, LegalDocumentType.privacy);
          },
          child: const Text('سياسة الخصوصية'),
        ),
      ],
    );
  }
}

class LegalAgreementCheckbox extends StatelessWidget {
  const LegalAgreementCheckbox({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('أوافق على شروط الاستخدام وسياسة الخصوصية'),
                const SizedBox(height: 6),
                LegalLinksRow(prefix: 'اقرأ '),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class LegalMenuCard extends StatelessWidget {
  const LegalMenuCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('شروط الاستخدام'),
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: () {
              LegalDocumentPage.open(context, LegalDocumentType.terms);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('سياسة الخصوصية'),
            trailing: const Icon(Icons.chevron_left_rounded),
            onTap: () {
              LegalDocumentPage.open(context, LegalDocumentType.privacy);
            },
          ),
        ],
      ),
    );
  }
}
