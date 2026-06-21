import 'package:flutter/material.dart';
import 'package:handy_app/core/refresh/app_refresh_bus.dart';
import 'package:handy_app/core/refresh/auto_refresh_on_resume.dart';
import 'package:handy_app/features/auth/presentation/profile_page.dart';
import 'package:handy_app/features/customer/presentation/customer_home_page.dart';
import 'package:handy_app/features/customer/presentation/customer_requests_page.dart';
import 'package:handy_app/features/requests/data/service_requests_repository.dart';
import 'package:handy_app/features/requests/domain/customer_request.dart';
import 'package:handy_app/features/requests/presentation/create_request_page.dart';
import 'package:handy_app/features/requests/presentation/request_details_page.dart';

class CustomerShellPage extends StatefulWidget {
  const CustomerShellPage({
    required this.profile,
    required this.onSignOut,
    required this.onProfileChanged,
    super.key,
  });

  final Map<String, dynamic> profile;
  final Future<void> Function() onSignOut;
  final VoidCallback onProfileChanged;

  @override
  State<CustomerShellPage> createState() => _CustomerShellPageState();
}

class _CustomerShellPageState extends State<CustomerShellPage>
    with AutoRefreshOnResume<CustomerShellPage> {
  final repository = ServiceRequestsRepository();
  late Future<List<CustomerRequest>> requestsFuture;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    requestsFuture = repository.loadCustomerRequests();
  }

  @override
  Stream<void>? get onRefreshRequested => AppRefreshBus.instance.stream;

  @override
  void onRefresh() {
    reloadRequests();
  }

  void reloadRequests() {
    setState(() {
      requestsFuture = repository.loadCustomerRequests();
    });
  }

  void openRequestsTab() {
    setState(() => _selectedIndex = 1);
  }

  Future<void> openProfile() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );

    if (updated == true) {
      widget.onProfileChanged();
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
    final isHome = _selectedIndex == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isHome ? 'الرئيسية' : 'طلباتي'),
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
      floatingActionButton: isHome
          ? FloatingActionButton.extended(
              onPressed: openCreateRequest,
              icon: const Icon(Icons.add_rounded),
              label: const Text('طلب خدمة'),
            )
          : null,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          CustomerHomePage(
            profile: widget.profile,
            requestsFuture: requestsFuture,
            onReload: reloadRequests,
            onOpenAllRequests: openRequestsTab,
            onOpenCreateRequest: openCreateRequest,
            onOpenRequestDetails: openRequestDetails,
          ),
          CustomerRequestsPage(
            requestsFuture: requestsFuture,
            onReload: reloadRequests,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
          reloadRequests();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt_rounded),
            label: 'طلباتي',
          ),
        ],
      ),
    );
  }
}
