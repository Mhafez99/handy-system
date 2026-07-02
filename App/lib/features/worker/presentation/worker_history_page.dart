import 'package:flutter/material.dart';
import 'package:handy_app/core/widgets/app_ui.dart';
import 'package:handy_app/features/requests/domain/accepted_worker_request.dart';
import 'package:handy_app/features/requests/presentation/payment_summary_widgets.dart';
import 'package:handy_app/features/worker/domain/worker_history_filter.dart';
import 'package:handy_app/features/worker/presentation/worker_home_page.dart';

class WorkerHistoryPage extends StatefulWidget {
  const WorkerHistoryPage({
    required this.completedRequestsFuture,
    required this.onReload,
    super.key,
  });

  final Future<List<AcceptedWorkerRequest>> completedRequestsFuture;
  final VoidCallback onReload;

  @override
  State<WorkerHistoryPage> createState() => _WorkerHistoryPageState();
}

class _WorkerHistoryPageState extends State<WorkerHistoryPage>
    with SingleTickerProviderStateMixin {
  static const filters = WorkerHistoryFilter.values;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: filters.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  WorkerHistoryFilter get selectedFilter {
    return filters[_tabController.index];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Text(
            'سجل الأعمال',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(height: 8),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          onTap: (_) => setState(() {}),
          tabs: [
            for (final filter in filters) Tab(text: filter.label),
          ],
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => widget.onReload(),
            child: FutureBuilder<List<AcceptedWorkerRequest>>(
              future: widget.completedRequestsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(child: CircularProgressIndicator()),
                    ],
                  );
                }

                if (snapshot.hasError) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      ErrorCard(
                        message: 'تعذر تحميل سجل الأعمال.',
                        onRetry: widget.onReload,
                      ),
                    ],
                  );
                }

                final allRequests = snapshot.data ?? [];
                final filteredRequests = filterWorkerHistory(
                  allRequests,
                  selectedFilter,
                );

                if (filteredRequests.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      WorkerHistoryEmptyCard(filter: selectedFilter),
                    ],
                  );
                }

                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  itemCount: filteredRequests.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return CompletedWorkHistoryCard(
                      request: filteredRequests[index],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class CompletedWorkHistoryCard extends StatelessWidget {
  const CompletedWorkHistoryCard({required this.request, super.key});

  final AcceptedWorkerRequest request;

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
                  label: workerHistoryStatusLabel(request.status),
                  variant: request.status == 'complaint'
                      ? AppBadgeVariant.destructive
                      : AppBadgeVariant.success,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${request.categoryName} • ${request.area}'),
            const SizedBox(height: 6),
            Text('العميل: ${request.customerName}'),
            const SizedBox(height: 6),
            Text(
              'تاريخ الطلب: ${request.createdAt.day}/${request.createdAt.month}/${request.createdAt.year}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (request.finalPrice != null) ...[
              const SizedBox(height: 12),
              PaymentSummaryCard(
                status: request.status == 'complaint'
                    ? 'completed'
                    : request.status,
                acceptedPrice: request.acceptedPrice,
                finalPrice: request.finalPrice,
                paymentMethod: request.paymentMethod,
              ),
            ] else ...[
              const SizedBox(height: 8),
              Text('السعر المقبول: ${request.acceptedPrice} جنيه'),
            ],
            const SizedBox(height: 12),
            if (request.review != null)
              WorkerReviewSummaryCard(review: request.review!)
            else
              const PendingReviewCard(),
          ],
        ),
      ),
    );
  }
}

class PendingReviewCard extends StatelessWidget {
  const PendingReviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              Icons.hourglass_top_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'العميل لم يقيّم الخدمة بعد.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkerHistoryEmptyCard extends StatelessWidget {
  const WorkerHistoryEmptyCard({required this.filter, super.key});

  final WorkerHistoryFilter filter;

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      WorkerHistoryFilter.all =>
        'ستظهر هنا الأعمال اللي خلصتها بعد إتمام الطلبات.',
      WorkerHistoryFilter.reviewed =>
        'لا توجد أعمال حصلت على تقييم بعد.',
      WorkerHistoryFilter.pendingReview =>
        'كل أعمالك المكتملة حصلت على تقييم.',
    };

    return AppEmptyState(
      icon: Icons.history_rounded,
      title: filter == WorkerHistoryFilter.all
          ? 'لا توجد أعمال مكتملة بعد.'
          : 'مفيش نتائج في "${filter.label}".',
      message: message,
    );
  }
}
