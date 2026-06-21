import 'package:flutter/material.dart';
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
          Text(
            'أهلًا ${profile['full_name'] ?? ''}',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'اطلب صنايعي موثوق في منطقتك بدون دفع إلكتروني.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onOpenCreateRequest,
            icon: const Icon(Icons.home_repair_service_outlined),
            label: const Text('إنشاء طلب جديد'),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: Text(
                  'آخر الطلبات',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              TextButton(onPressed: onOpenAllRequests, child: const Text('كل الطلبات')),
            ],
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
