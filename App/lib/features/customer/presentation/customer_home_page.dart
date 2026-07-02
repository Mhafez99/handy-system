import 'package:flutter/material.dart';
import 'package:handy_app/core/widgets/app_ui.dart';
import 'package:handy_app/features/customer/domain/customer_request_filter.dart';
import 'package:handy_app/features/customer/presentation/customer_request_widgets.dart';
import 'package:handy_app/features/requests/domain/customer_request.dart';

class CustomerHomePage extends StatelessWidget {
  const CustomerHomePage({
    required this.profile,
    required this.requestsFuture,
    required this.onReload,
    required this.onOpenAllRequests,
    required this.onOpenCreateRequest,
    required this.onOpenRequestDetails,
    super.key,
  });

  final Map<String, dynamic> profile;
  final Future<List<CustomerRequest>> requestsFuture;
  final VoidCallback onReload;
  final VoidCallback onOpenAllRequests;
  final VoidCallback onOpenCreateRequest;
  final ValueChanged<CustomerRequest> onOpenRequestDetails;

  static const _previewLimit = 3;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async => onReload(),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _HomeHero(
            name: profile['full_name'] as String? ?? '',
            onCreate: onOpenCreateRequest,
          ),
          const SizedBox(height: 28),
          AppSectionHeader(
            title: 'آخر الطلبات',
            trailing: TextButton(
              onPressed: onOpenAllRequests,
              child: const Text('كل الطلبات'),
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<CustomerRequest>>(
            future: requestsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                return CustomerRequestsErrorCard(
                  message: 'تعذر تحميل الطلبات.',
                  onRetry: onReload,
                );
              }

              final requests = snapshot.data ?? [];
              if (requests.isEmpty) {
                return const CustomerRequestsEmptyCard(
                  filter: CustomerRequestFilter.all,
                );
              }

              final preview = requests.take(_previewLimit).toList(growable: false);

              return Column(
                children: [
                  for (final request in preview)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CustomerRequestCard(
                        request: request,
                        onOpen: () => onOpenRequestDetails(request),
                      ),
                    ),
                  if (requests.length > _previewLimit)
                    OutlinedButton.icon(
                      onPressed: onOpenAllRequests,
                      icon: const Icon(Icons.list_alt_outlined),
                      label: Text('عرض كل الطلبات (${requests.length})'),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({required this.name, required this.onCreate});

  final String name;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.waving_hand_rounded, color: cs.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أهلًا $name',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'اطلب صنايعي موثوق في منطقتك بدون دفع إلكتروني.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.home_repair_service_outlined),
            label: const Text('إنشاء طلب جديد'),
          ),
        ],
      ),
    );
  }
}
