import 'package:flutter/material.dart';
import 'package:handy_app/features/offers/presentation/send_offer_page.dart';
import 'package:handy_app/features/requests/data/service_requests_repository.dart';
import 'package:handy_app/features/requests/domain/accepted_worker_request.dart';
import 'package:handy_app/features/requests/domain/available_worker_request.dart';
import 'package:handy_app/features/reviews/domain/service_review.dart';

class WorkerHomePage extends StatefulWidget {
  const WorkerHomePage({
    required this.profile,
    required this.onSignOut,
    super.key,
  });

  final Map<String, dynamic> profile;
  final Future<void> Function() onSignOut;

  @override
  State<WorkerHomePage> createState() => _WorkerHomePageState();
}

class _WorkerHomePageState extends State<WorkerHomePage> {
  final repository = ServiceRequestsRepository();
  late Future<List<AvailableWorkerRequest>> requestsFuture;
  late Future<List<AcceptedWorkerRequest>> acceptedRequestsFuture;
  String? startingRequestId;

  @override
  void initState() {
    super.initState();
    requestsFuture = repository.loadAvailableWorkerRequests();
    acceptedRequestsFuture = repository.loadAcceptedWorkerRequests();
  }

  void reloadRequests() {
    setState(() {
      requestsFuture = repository.loadAvailableWorkerRequests();
      acceptedRequestsFuture = repository.loadAcceptedWorkerRequests();
    });
  }

  Future<void> openSendOffer(AvailableWorkerRequest request) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => SendOfferPage(request: request)),
    );

    if (created == true) {
      reloadRequests();
    }
  }

  Future<void> startWork(AcceptedWorkerRequest request) async {
    setState(() => startingRequestId = request.id);

    try {
      await repository.startWork(request.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الطلب إلى قيد التنفيذ.')),
      );
      reloadRequests();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر بدء الشغل. حاول مرة أخرى.')),
      );
    } finally {
      if (mounted) {
        setState(() => startingRequestId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلبات متاحة'),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => reloadRequests(),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'أهلًا ${widget.profile['full_name'] ?? ''}',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'هنا تظهر طلبات نفس تخصصك ونفس منطقتك بعد اعتماد حسابك.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            InfoCard(
              icon: Icons.place_outlined,
              title: 'منطقتك الحالية',
              value:
                  '${widget.profile['governorate'] ?? ''} - ${widget.profile['area'] ?? ''}',
            ),
            const SizedBox(height: 24),
            Text(
              'طلباتي المقبولة',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<AcceptedWorkerRequest>>(
              future: acceptedRequestsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return ErrorCard(
                    message: 'تعذر تحميل طلباتك المقبولة.',
                    onRetry: reloadRequests,
                  );
                }

                final acceptedRequests = snapshot.data ?? [];
                if (acceptedRequests.isEmpty) {
                  return const EmptyAcceptedRequestsCard();
                }

                return Column(
                  children: [
                    for (final request in acceptedRequests)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AcceptedRequestCard(
                          request: request,
                          isStarting: startingRequestId == request.id,
                          onStartWork: () => startWork(request),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              'الطلبات المتاحة',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<AvailableWorkerRequest>>(
              future: requestsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError) {
                  return ErrorCard(
                    message: 'تعذر تحميل الطلبات المتاحة.',
                    onRetry: reloadRequests,
                  );
                }

                final requests = snapshot.data ?? [];
                if (requests.isEmpty) {
                  return const EmptyWorkerRequestsCard();
                }

                return Column(
                  children: [
                    for (final request in requests)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AvailableRequestCard(
                          request: request,
                          onSendOffer: () => openSendOffer(request),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(value),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AcceptedRequestCard extends StatelessWidget {
  const AcceptedRequestCard({
    required this.request,
    required this.isStarting,
    required this.onStartWork,
    super.key,
  });

  final AcceptedWorkerRequest request;
  final bool isStarting;
  final VoidCallback onStartWork;

  @override
  Widget build(BuildContext context) {
    final canStart = request.status == 'accepted';

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
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
                Chip(
                  label: Text(requestStatusLabel(request.status)),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('السعر المقبول: ${request.acceptedPrice} جنيه'),
            const SizedBox(height: 8),
            Text('${request.categoryName} • ${request.area}'),
            const SizedBox(height: 8),
            Text(request.description),
            const Divider(height: 28),
            Text(
              'بيانات العميل',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            ContactRow(icon: Icons.person_outline, text: request.customerName),
            if (request.customerPhone.isNotEmpty) ...[
              const SizedBox(height: 6),
              ContactRow(
                icon: Icons.phone_outlined,
                text: request.customerPhone,
              ),
            ],
            const SizedBox(height: 6),
            ContactRow(
              icon: Icons.home_outlined,
              text: request.customerAddress.isEmpty
                  ? '${request.governorate} - ${request.area} - ${request.address}'
                  : request.customerAddress,
            ),
            const SizedBox(height: 6),
            ContactRow(
              icon: Icons.schedule_outlined,
              text: 'ميعاد العميل: ${request.preferredTime}',
            ),
            if (request.arrivalTime.isNotEmpty) ...[
              const SizedBox(height: 6),
              ContactRow(
                icon: Icons.directions_walk_outlined,
                text: 'وعدك بالوصول: ${request.arrivalTime}',
              ),
            ],
            const SizedBox(height: 16),
            if (canStart)
              FilledButton.icon(
                onPressed: isStarting ? null : onStartWork,
                icon: isStarting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_circle_outline),
                label: const Text('بدأت الشغل'),
              )
            else if (request.status == 'in_progress')
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.construction_outlined),
                label: const Text('الشغل قيد التنفيذ'),
              ),
            if (request.review != null) ...[
              const SizedBox(height: 16),
              WorkerReviewSummaryCard(review: request.review!),
            ],
          ],
        ),
      ),
    );
  }
}

class WorkerReviewSummaryCard extends StatelessWidget {
  const WorkerReviewSummaryCard({required this.review, super.key});

  final ServiceReview review;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تقييم العميل',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var index = 1; index <= 5; index++)
                  Icon(
                    index <= review.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                const SizedBox(width: 8),
                Text('${review.rating}/5'),
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment),
            ],
          ],
        ),
      ),
    );
  }
}

String requestStatusLabel(String status) {
  return switch (status) {
    'in_progress' => 'قيد التنفيذ',
    'completed' => 'مكتمل',
    _ => 'مقبول',
  };
}

class ContactRow extends StatelessWidget {
  const ContactRow({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 6),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class AvailableRequestCard extends StatelessWidget {
  const AvailableRequestCard({
    required this.request,
    required this.onSendOffer,
    super.key,
  });

  final AvailableWorkerRequest request;
  final VoidCallback onSendOffer;

  @override
  Widget build(BuildContext context) {
    return Card(
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
                Chip(
                  label: Text(request.priceRange),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${request.categoryName} • ${request.area}'),
            const SizedBox(height: 8),
            Text(request.description),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(request.preferredTime)),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onSendOffer,
              icon: const Icon(Icons.local_offer_outlined),
              label: const Text('إرسال عرض سعر'),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyAcceptedRequestsCard extends StatelessWidget {
  const EmptyAcceptedRequestsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 44,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'لا توجد طلبات مقبولة حتى الآن.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'عندما يقبل العميل عرضك ستظهر بياناته هنا للتواصل وتنفيذ الشغل.',
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

class EmptyWorkerRequestsCard extends StatelessWidget {
  const EmptyWorkerRequestsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'لا توجد طلبات مناسبة الآن.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'ستظهر هنا الطلبات الجديدة في نفس تخصصك ومنطقتك.',
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

class ErrorCard extends StatelessWidget {
  const ErrorCard({required this.message, required this.onRetry, super.key});

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
