import 'package:flutter/material.dart';
import 'package:handy_app/features/customer/domain/customer_request_filter.dart';
import 'package:handy_app/features/customer/presentation/customer_request_widgets.dart';
import 'package:handy_app/features/requests/domain/customer_request.dart';
import 'package:handy_app/features/requests/presentation/request_details_page.dart';

class CustomerRequestsPage extends StatefulWidget {
  const CustomerRequestsPage({
    required this.requestsFuture,
    required this.onReload,
    super.key,
  });

  final Future<List<CustomerRequest>> requestsFuture;
  final VoidCallback onReload;

  @override
  State<CustomerRequestsPage> createState() => _CustomerRequestsPageState();
}

class _CustomerRequestsPageState extends State<CustomerRequestsPage>
    with SingleTickerProviderStateMixin {
  static const filters = CustomerRequestFilter.values;

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

  CustomerRequestFilter get selectedFilter {
    return filters[_tabController.index];
  }

  Future<void> openRequestDetails(CustomerRequest request) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => RequestDetailsPage(requestId: request.id),
      ),
    );

    widget.onReload();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Text(
            'سجل الطلبات',
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
            child: FutureBuilder<List<CustomerRequest>>(
              future: widget.requestsFuture,
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
                      CustomerRequestsErrorCard(
                        message: 'تعذر تحميل الطلبات.',
                        onRetry: widget.onReload,
                      ),
                    ],
                  );
                }

                final allRequests = snapshot.data ?? [];
                final filteredRequests = filterCustomerRequests(
                  allRequests,
                  selectedFilter,
                );

                if (filteredRequests.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      CustomerRequestsEmptyCard(filter: selectedFilter),
                    ],
                  );
                }

                return ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  itemCount: filteredRequests.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final request = filteredRequests[index];
                    return CustomerRequestCard(
                      request: request,
                      onOpen: () => openRequestDetails(request),
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
