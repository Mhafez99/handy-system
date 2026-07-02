import 'package:flutter/material.dart';
import 'package:handy_app/core/widgets/app_ui.dart';
import 'package:handy_app/features/auth/data/auth_repository.dart';
import 'package:handy_app/features/auth/presentation/profile_page.dart';
import 'package:handy_app/features/customer/presentation/customer_shell_page.dart';
import 'package:handy_app/features/worker/presentation/worker_shell_page.dart';

class AccountHomePage extends StatefulWidget {
  const AccountHomePage({super.key});

  @override
  State<AccountHomePage> createState() => _AccountHomePageState();
}

class _AccountHomePageState extends State<AccountHomePage> {
  final repository = AuthRepository();
  late Future<Map<String, dynamic>> profileFuture;

  @override
  void initState() {
    super.initState();
    profileFuture = repository.loadCurrentProfile();
  }

  Future<void> reloadProfile() async {
    setState(() {
      profileFuture = repository.loadCurrentProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('حسابي')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: AppEmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'تعذر تحميل بيانات الحساب.',
                  message: 'تأكد من اتصالك بالإنترنت وحاول مرة أخرى.',
                  action: OutlinedButton.icon(
                    onPressed: reloadProfile,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('إعادة المحاولة'),
                  ),
                ),
              ),
            ),
          );
        }

        final profile = snapshot.data!;
        if (profile['role'] == 'customer') {
          return CustomerShellPage(
            profile: profile,
            onSignOut: repository.signOut,
            onProfileChanged: reloadProfile,
          );
        }

        if (profile['status'] == 'active') {
          return WorkerShellPage(
            profile: profile,
            onSignOut: repository.signOut,
            onProfileChanged: reloadProfile,
          );
        }

        return WorkerWaitingPage(
          profile: profile,
          onSignOut: repository.signOut,
          onProfileChanged: reloadProfile,
        );
      },
    );
  }
}

class WorkerWaitingPage extends StatelessWidget {
  const WorkerWaitingPage({
    required this.profile,
    required this.onSignOut,
    required this.onProfileChanged,
    super.key,
  });

  final Map<String, dynamic> profile;
  final Future<void> Function() onSignOut;
  final VoidCallback onProfileChanged;

  Future<void> openProfile(BuildContext context) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );

    if (updated == true) {
      onProfileChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        actions: [
          IconButton(
            tooltip: 'الملف الشخصي',
            onPressed: () => openProfile(context),
            icon: const Icon(Icons.person_outline_rounded),
          ),
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const CircleAvatar(
            radius: 38,
            child: Icon(Icons.handyman_outlined, size: 38),
          ),
          const SizedBox(height: 16),
          Text(
            profile['full_name'] as String? ?? '',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Center(
            child: AppBadge(
              label: 'حساب صنايعي',
              variant: AppBadgeVariant.primary,
              icon: Icons.handyman_outlined,
            ),
          ),
          const SizedBox(height: 24),
          AppCard(
            child: Row(
              children: [
                Icon(
                  Icons.hourglass_top_rounded,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'حسابك قيد المراجعة. ستتمكن من استقبال الطلبات بعد الاعتماد.',
                  ),
                ),
                const SizedBox(width: 8),
                const AppBadge(
                  label: 'قيد المراجعة',
                  variant: AppBadgeVariant.warning,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ListTile(
            leading: const Icon(Icons.phone_outlined),
            title: const Text('رقم الموبايل'),
            subtitle: Text(profile['phone'] as String? ?? ''),
          ),
          ListTile(
            leading: const Icon(Icons.place_outlined),
            title: const Text('المنطقة'),
            subtitle: Text(
              '${profile['governorate'] ?? ''} - ${profile['area'] ?? ''}',
            ),
          ),
        ],
      ),
    );
  }
}
