import 'package:flutter/material.dart';
import 'package:handy_app/core/refresh/app_refresh_bus.dart';
import 'package:handy_app/core/refresh/auto_refresh_on_resume.dart';
import 'package:handy_app/features/auth/presentation/profile_page.dart';
import 'package:handy_app/features/requests/data/service_requests_repository.dart';
import 'package:handy_app/features/requests/domain/accepted_worker_request.dart';
import 'package:handy_app/features/requests/domain/available_worker_request.dart';
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
    with AutoRefreshOnResume<WorkerShellPage> {
  final repository = ServiceRequestsRepository();
  late Future<List<AvailableWorkerRequest>> availableRequestsFuture;
  late Future<List<AcceptedWorkerRequest>> activeRequestsFuture;
  late Future<List<AcceptedWorkerRequest>> completedRequestsFuture;
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

  void reloadRequests() {
    setState(() {
      availableRequestsFuture = repository.loadAvailableWorkerRequests();
      activeRequestsFuture = repository.loadActiveWorkerRequests();
      completedRequestsFuture = repository.loadCompletedWorkerRequests();
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
    final isWorkTab = _selectedIndex == 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(isWorkTab ? 'الشغل' : 'سجل الأعمال'),
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
        ],
      ),
    );
  }
}
