import 'package:flutter/material.dart';
import 'package:handy_app/features/auth/presentation/profile_page.dart';
import 'package:handy_app/features/requests/data/service_requests_repository.dart';
import 'package:handy_app/features/requests/domain/customer_request.dart';
import 'package:handy_app/features/requests/presentation/create_request_page.dart';
import 'package:handy_app/features/requests/presentation/request_details_page.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({
    required this.profile,
    required this.onSignOut,
    required this.onProfileChanged,
    super.key,
  });

  final Map<String, dynamic> profile;
  final Future<void> Function() onSignOut;
  final VoidCallback onProfileChanged;

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  final repository = ServiceRequestsRepository();
  late Future<List<CustomerRequest>> requestsFuture;

  @override
  void initState() {
    super.initState();
    requestsFuture = repository.loadCustomerRequests();
  }

  void reloadRequests() {
    setState(() {
      requestsFuture = repository.loadCustomerRequests();
    });
  }

  Future<void> openProfile() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );

    if (updated == true) {
      onProfileChanged();
    }
  }

  Future<void> openCreateRequest() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CreateRequestPage(profile: widget.profile),
      ),
    );

    if (created == true) {
      reloadRequests();
    }
  }

  Future<void> openRequestDetails(CustomerRequest request) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => RequestDetailsPage(requestId: request.id),
      ),
    );

    reloadRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الرئيسية'),
        actions: [
          IconButton(
            tooltip: 'الملف الشخصي',
            onPressed: openProfile,
            icon: const Icon(Icons.person_outline_rounded),
          ),
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: widget.onSignOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openCreateRequest,
        icon: const Icon(Icons.add_rounded),
        label: const Text('طلب خدمة'),
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
              'اطلب صنايعي موثوق في منطقتك بدون دفع إلكتروني.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: openCreateRequest,
              icon: const Icon(Icons.home_repair_service_outlined),
              label: const Text('إنشاء طلب جديد'),
            ),
            const SizedBox(height: 28),
            Text(
              'طلباتي',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
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
                  return ErrorCard(
                    message: 'تعذر تحميل الطلبات.',
                    onRetry: reloadRequests,
                  );
                }

                final requests = snapshot.data ?? [];
                if (requests.isEmpty) {
                  return const EmptyRequestsCard();
                }

                return Column(
                  children: [
                    for (final request in requests)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RequestCard(
                          request: request,
                          onOpen: () => openRequestDetails(request),
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

class RequestCard extends StatelessWidget {
  const RequestCard({required this.request, required this.onOpen, super.key});

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
                  StatusChip(status: request.status),
                ],
              ),
              const SizedBox(height: 8),
              Text('${request.categoryName} • ${request.area}'),
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

class StatusChip extends StatelessWidget {
  const StatusChip({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'new' => 'جديد',
      'offered' => 'به عروض',
      'accepted' => 'مقبول',
      'in_progress' => 'قيد التنفيذ',
      'completed' => 'مكتمل',
      'cancelled' => 'ملغي',
      'complaint' => 'شكوى',
      _ => status,
    };

    return Chip(label: Text(label), visualDensity: VisualDensity.compact);
  }
}

class EmptyRequestsCard extends StatelessWidget {
  const EmptyRequestsCard({super.key});

  @override
  Widget build(BuildContext context) {
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
            const Text('لسه مفيش طلبات.', textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(
              'ابدأ بأول طلب خدمة وسيظهر هنا.',
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
