import 'package:flutter/material.dart';
import 'package:handy_app/features/customer/domain/customer_request_filter.dart';
import 'package:handy_app/features/requests/domain/customer_request.dart';

class CustomerRequestCard extends StatelessWidget {
  const CustomerRequestCard({required this.request, required this.onOpen, super.key});

  final CustomerRequest request;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.serviceName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  CustomerRequestStatusChip(status: request.status),
                ],
              ),
              const SizedBox(height: 8),
              Text('${request.categoryName} • ${request.area}'),
              if (request.status == 'completed' && request.finalPrice != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.payments_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${request.finalPrice} جنيه'
                      '${request.paymentMethodLabel.isNotEmpty ? ' • ${request.paymentMethodLabel}' : ''}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 4),
              Text(
                'تم الإنشاء: ${request.createdAt.day}/${request.createdAt.month}/${request.createdAt.year}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.local_offer_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text('${request.offerCount} عروض'),
                  const Spacer(),
                  Text(
                    'عرض التفاصيل',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerRequestStatusChip extends StatelessWidget {
  const CustomerRequestStatusChip({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(customerRequestStatusLabel(status)),
      visualDensity: VisualDensity.compact,
    );
  }
}

class CustomerRequestsEmptyCard extends StatelessWidget {
  const CustomerRequestsEmptyCard({
    required this.filter,
    super.key,
  });

  final CustomerRequestFilter filter;

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      CustomerRequestFilter.all =>
        'ابدأ بأول طلب خدمة وسيظهر هنا.',
      CustomerRequestFilter.active =>
        'لا توجد طلبات نشطة حاليًا.',
      CustomerRequestFilter.completed =>
        'لا توجد طلبات مكتملة بعد.',
      CustomerRequestFilter.cancelled =>
        'لا توجد طلبات ملغاة.',
      CustomerRequestFilter.complaint =>
        'لا توجد شكاوى مسجّلة.',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              filter == CustomerRequestFilter.all
                  ? 'لسه مفيش طلبات.'
                  : 'مفيش طلبات في "${filter.label}".',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CustomerRequestsErrorCard extends StatelessWidget {
  const CustomerRequestsErrorCard({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(message),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

List<CustomerRequest> filterCustomerRequests(
  List<CustomerRequest> requests,
  CustomerRequestFilter filter,
) {
  return requests
      .where((request) => filter.matchesStatus(request.status))
      .toList(growable: false);
}
