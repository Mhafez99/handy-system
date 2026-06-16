import 'package:flutter/material.dart';
import 'package:handy_app/features/auth/data/auth_repository.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حسابي'),
        actions: [
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: repository.signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('تعذر تحميل بيانات الحساب.'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          profileFuture = repository.loadCurrentProfile();
                        });
                      },
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
            );
          }

          final profile = snapshot.data!;
          final isWorker = profile['role'] == 'worker';
          final isPending = profile['status'] == 'pending';

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              CircleAvatar(
                radius: 38,
                child: Icon(
                  isWorker
                      ? Icons.handyman_outlined
                      : Icons.person_outline_rounded,
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                profile['full_name'] as String? ?? '',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isWorker ? 'حساب صنايعي' : 'حساب عميل',
                textAlign: TextAlign.center,
              ),
              if (isPending) ...[
                const SizedBox(height: 24),
                Card(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.hourglass_top_rounded),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'حسابك قيد المراجعة. ستتمكن من استقبال الطلبات بعد الاعتماد.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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
          );
        },
      ),
    );
  }
}
