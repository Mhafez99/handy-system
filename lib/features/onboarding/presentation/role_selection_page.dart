import 'package:flutter/material.dart';
import 'package:handy_app/features/auth/domain/account_role.dart';
import 'package:handy_app/features/auth/presentation/login_page.dart';
import 'package:handy_app/features/auth/presentation/registration_page.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  AccountRole? selectedRole;

  void continueToRegistration() {
    final role = selectedRole;
    if (role == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => RegistrationPage(role: role),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height - 48,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Icon(
                    Icons.home_repair_service_rounded,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Handy',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'خدمات منزلية موثوقة داخل منطقتك',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'إنشاء حساب جديد',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RoleCard(
                    title: 'حساب عميل',
                    subtitle: 'اطلب صنايعي لتنفيذ خدمة منزلية',
                    icon: Icons.person_outline_rounded,
                    isSelected: selectedRole == AccountRole.customer,
                    onTap: () {
                      setState(() => selectedRole = AccountRole.customer);
                    },
                  ),
                  const SizedBox(height: 12),
                  RoleCard(
                    title: 'حساب صنايعي',
                    subtitle: 'استقبل طلبات شغل في منطقتك',
                    icon: Icons.handyman_outlined,
                    isSelected: selectedRole == AccountRole.worker,
                    onTap: () {
                      setState(() => selectedRole = AccountRole.worker);
                    },
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: selectedRole == null
                        ? null
                        : continueToRegistration,
                    child: const Text('ابدأ إنشاء الحساب'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: const Text('عندي حساب بالفعل'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RoleCard extends StatelessWidget {
  const RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: colorScheme.surface,
                child: Icon(icon, color: colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected ? colorScheme.primary : colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
