import 'package:flutter/material.dart';
import 'package:handy_app/core/refresh/app_refresh_bus.dart';
import 'package:handy_app/core/refresh/auto_refresh_on_resume.dart';
import 'package:handy_app/features/auth/presentation/profile_page.dart';
import 'package:handy_app/features/requests/data/service_requests_repository.dart';
import 'package:handy_app/features/requests/domain/accepted_worker_request.dart';
import 'package:handy_app/features/requests/domain/available_worker_request.dart';
import 'package:handy_app/features/worker/data/workers_repository.dart';
import 'package:handy_app/features/worker/domain/worker_earnings.dart';
import 'package:handy_app/features/worker/presentation/worker_earnings_page.dart';
import 'package:handy_app/features/worker/presentation/worker_history_page.dart';
import 'package:handy_app/features/worker/presentation/worker_home_page.dart';

class WorkerShellPage extends StatefulWidget {
  const WorkerShellPage({
    required this.profile,
    required this.onSignOut,
    required this.onProfileChanged,
    super.key,
  });

  final Map<String, dynamic> profile;
  final Future<void> Function() onSignOut;
  final VoidCallback onProfileChanged;

  @override
  State<WorkerShellPage> createState() => _WorkerShellPageState();
}

class _WorkerShellPageState extends State<WorkerShellPage>
    with AutoRefreshOnResume<WorkerShellPage>, PeriodicRefresh<WorkerShellPage> {
  final repository = ServiceRequestsRepository();
  final workersRepository = WorkersRepository();
  late Future<List<AvailableWorkerRequest>> availableRequestsFuture;
  late Future<List<AcceptedWorkerRequest>> activeRequestsFuture;
  late Future<List<AcceptedWorkerRequest>> completedRequestsFuture;
  late Future<WorkerEarnings> earningsFuture;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    reloadRequests();
  }

  @override
  Stream<void>? get onRefreshRequested => AppRefreshBus.instance.stream;

  @override
  void onRefresh() {
    reloadRequests();
  }

  @override
  void onPeriodicRefresh() {
    reloadRequests();
  }

  void reloadRequests() {
    setState(() {
      availableRequestsFuture = repository.loadAvailableWorkerRequests();
      activeRequestsFuture = repository.loadActiveWorkerRequests();
      completedRequestsFuture = repository.loadCompletedWorkerRequests();
      earningsFuture = workersRepository.loadMyEarnings();
    });
  }

  Future<void> openProfile() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );

    if (updated == true) {
      widget.onProfileChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_selectedIndex) {
      0 => 'الشغل',
      1 => 'سجل الأعمال',
      _ => 'أرباحي',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
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
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          WorkerHomePage(
            profile: widget.profile,
            availableRequestsFuture: availableRequestsFuture,
            activeRequestsFuture: activeRequestsFuture,
            onReload: reloadRequests,
          ),
          WorkerHistoryPage(
            completedRequestsFuture: completedRequestsFuture,
            onReload: reloadRequests,
          ),
          WorkerEarningsPage(
            earningsFuture: earningsFuture,
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
            icon: Icon(Icons.handyman_outlined),
            selectedIcon: Icon(Icons.handyman_rounded),
            label: 'الشغل',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'السجل',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'أرباحي',
          ),
        ],
      ),
    );
  }
}
