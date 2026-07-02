import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:handy_app/core/widgets/app_ui.dart';
import 'package:handy_app/features/offers/presentation/send_offer_page.dart';
import 'package:handy_app/features/requests/data/service_requests_repository.dart';
import 'package:handy_app/features/requests/domain/accepted_worker_request.dart';
import 'package:handy_app/features/requests/domain/available_worker_request.dart';
import 'package:handy_app/features/requests/presentation/payment_summary_widgets.dart';
import 'package:handy_app/features/reviews/domain/service_review.dart';

class WorkerHomePage extends StatefulWidget {
  const WorkerHomePage({
    required this.profile,
    required this.availableRequestsFuture,
    required this.activeRequestsFuture,
    required this.onReload,
    super.key,
  });

  final Map<String, dynamic> profile;
  final Future<List<AvailableWorkerRequest>> availableRequestsFuture;
  final Future<List<AcceptedWorkerRequest>> activeRequestsFuture;
  final VoidCallback onReload;

  @override
  State<WorkerHomePage> createState() => _WorkerHomePageState();
}

class _WorkerHomePageState extends State<WorkerHomePage> {
  final repository = ServiceRequestsRepository();
  String? markingOnTheWayRequestId;
  String? startingRequestId;
  String? completingRequestId;

  void reloadRequests() {
    widget.onReload();
  }

  Future<void> openSendOffer(AvailableWorkerRequest request) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => SendOfferPage(request: request)),
    );

    if (created == true) {
      reloadRequests();
    }
  }

  Future<void> markOnTheWay(AcceptedWorkerRequest request) async {
    setState(() => markingOnTheWayRequestId = request.id);

    try {
      await repository.markOnTheWay(request.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الطلب إلى في الطريق.')),
      );
      reloadRequests();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر تحديث حالة الطلب. حاول مرة أخرى.')),
      );
    } finally {
      if (mounted) {
        setState(() => markingOnTheWayRequestId = null);
      }
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

  Future<void> completeWork(
    AcceptedWorkerRequest request,
    String completionCode,
    int finalPrice,
  ) async {
    setState(() => completingRequestId = request.id);

    try {
      await repository.completeRequestByWorker(
        requestId: request.id,
        completionCode: completionCode,
        finalPrice: finalPrice,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تأكيد إتمام الخدمة بنجاح.')),
      );
      reloadRequests();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر إتمام الخدمة. تأكد من الكود والسعر وحاول مرة أخرى.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => completingRequestId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
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
              future: widget.activeRequestsFuture,
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
                          isMarkingOnTheWay:
                              markingOnTheWayRequestId == request.id,
                          isStarting: startingRequestId == request.id,
                          isCompleting: completingRequestId == request.id,
                          onMarkOnTheWay: () => markOnTheWay(request),
                          onStartWork: () => startWork(request),
                          onCompleteWork: (code, price) =>
                              completeWork(request, code, price),
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
              future: widget.availableRequestsFuture,
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
    required this.isMarkingOnTheWay,
    required this.isStarting,
    required this.isCompleting,
    required this.onMarkOnTheWay,
    required this.onStartWork,
    required this.onCompleteWork,
    super.key,
  });

  final AcceptedWorkerRequest request;
  final bool isMarkingOnTheWay;
  final bool isStarting;
  final bool isCompleting;
  final VoidCallback onMarkOnTheWay;
  final VoidCallback onStartWork;
  final void Function(String completionCode, int finalPrice) onCompleteWork;

  @override
  Widget build(BuildContext context) {
    final canMarkOnTheWay = request.status == 'accepted';
    final canStart = request.status == 'on_the_way';
    final canComplete = request.status == 'in_progress';
    final isBusy = isMarkingOnTheWay || isStarting || isCompleting;

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
                AppBadge(
                  label: requestStatusLabel(request.status),
                  variant: request.status == 'completed'
                      ? AppBadgeVariant.success
                      : AppBadgeVariant.primary,
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
            if (canMarkOnTheWay)
              FilledButton.icon(
                onPressed: isBusy ? null : onMarkOnTheWay,
                icon: isMarkingOnTheWay
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.directions_walk_outlined),
                label: const Text('في الطريق'),
              )
            else if (canStart)
              FilledButton.icon(
                onPressed: isBusy ? null : onStartWork,
                icon: isStarting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_circle_outline),
                label: const Text('بدأت الشغل'),
              )
            else if (canComplete)
              CompleteWorkSection(
                acceptedPrice: request.acceptedPrice,
                isCompleting: isCompleting,
                onComplete: onCompleteWork,
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

class CompleteWorkSection extends StatefulWidget {
  const CompleteWorkSection({
    required this.acceptedPrice,
    required this.isCompleting,
    required this.onComplete,
    super.key,
  });

  final int acceptedPrice;
  final bool isCompleting;
  final void Function(String completionCode, int finalPrice) onComplete;

  @override
  State<CompleteWorkSection> createState() => _CompleteWorkSectionState();
}

class _CompleteWorkSectionState extends State<CompleteWorkSection> {
  final codeController = TextEditingController();
  late final TextEditingController priceController;

  @override
  void initState() {
    super.initState();
    priceController = TextEditingController(
      text: widget.acceptedPrice > 0 ? '${widget.acceptedPrice}' : '',
    );
  }

  @override
  void dispose() {
    codeController.dispose();
    priceController.dispose();
    super.dispose();
  }

  void submit() {
    final code = codeController.text.trim();
    final price = int.tryParse(priceController.text.trim());

    if (code.length != 6 || price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('أدخل كود إتمام من 6 أرقام وسعرًا نهائيًا صحيحًا.'),
        ),
      );
      return;
    }

    widget.onComplete(code, price);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'إتمام الخدمة',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text('اطلب كود الإتمام من العميل بعد ما الشغل يخلص.'),
        const SizedBox(height: 12),
        WorkerCompletePaymentSection(acceptedPrice: widget.acceptedPrice),
        const SizedBox(height: 12),
        TextField(
          controller: codeController,
          enabled: !widget.isCompleting,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'كود الإتمام',
            counterText: '',
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: priceController,
          enabled: !widget.isCompleting,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'المبلغ المستلم كاش (جنيه)',
            helperText: 'سجّل المبلغ الفعلي اللي استلمته من العميل',
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: widget.isCompleting ? null : submit,
          icon: widget.isCompleting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.task_alt_outlined),
          label: const Text('تأكيد الإتمام'),
        ),
      ],
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
    'on_the_way' => 'في الطريق',
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
                AppBadge(
                  label: request.priceRange,
                  variant: AppBadgeVariant.neutral,
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
    return const AppEmptyState(
      icon: Icons.assignment_turned_in_outlined,
      title: 'لا توجد طلبات مقبولة حتى الآن.',
      message:
          'عندما يقبل العميل عرضك ستظهر بياناته هنا للتواصل وتنفيذ الشغل.',
    );
  }
}

class EmptyWorkerRequestsCard extends StatelessWidget {
  const EmptyWorkerRequestsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppEmptyState(
      icon: Icons.search_off_rounded,
      title: 'لا توجد طلبات مناسبة الآن.',
      message: 'ستظهر هنا الطلبات الجديدة في نفس تخصصك ومنطقتك.',
    );
  }
}

class ErrorCard extends StatelessWidget {
  const ErrorCard({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.wifi_off_rounded,
      title: message,
      action: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('إعادة المحاولة'),
      ),
    );
  }
}
