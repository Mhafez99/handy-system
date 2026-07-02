import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:handy_app/core/widgets/app_ui.dart';
import 'package:handy_app/features/areas/domain/area.dart';
import 'package:handy_app/features/areas/presentation/area_picker_fields.dart';
import 'package:handy_app/features/auth/data/auth_repository.dart';
import 'package:handy_app/features/auth/domain/update_profile_data.dart';
import 'package:handy_app/features/auth/presentation/registration_page.dart';
import 'package:handy_app/features/legal/presentation/legal_links_row.dart';
import 'package:handy_app/features/requests/data/service_requests_repository.dart';
import 'package:handy_app/features/requests/domain/service_category.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final repository = AuthRepository();
  final catalogRepository = ServiceRequestsRepository();
  final formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final experienceController = TextEditingController();
  final bioController = TextEditingController();

  late Future<_ProfileViewData> profileFuture;
  late Future<List<ServiceCategory>> categoriesFuture;
  bool isEditing = false;
  bool isSaving = false;
  Area? selectedArea;
  String? selectedProfession;

  @override
  void initState() {
    super.initState();
    profileFuture = _loadProfile();
    categoriesFuture = catalogRepository.loadCategories();
  }

  Future<_ProfileViewData> _loadProfile() async {
    final profile = await repository.loadCurrentProfile();
    final workerProfile = profile['role'] == 'worker'
        ? await repository.loadWorkerProfile()
        : null;

    return _ProfileViewData(
      profile: profile,
      workerProfile: workerProfile,
      email: repository.currentUserEmail ?? '',
    );
  }

  void reloadProfile() {
    setState(() {
      profileFuture = _loadProfile();
      isEditing = false;
    });
  }

  void populateForm(_ProfileViewData data) {
    final profile = data.profile;
    final workerProfile = data.workerProfile;

    fullNameController.text = profile['full_name'] as String? ?? '';
    phoneController.text = profile['phone'] as String? ?? '';
    addressController.text = profile['address'] as String? ?? '';
    selectedArea = null;
    selectedProfession = workerProfile?['profession'] as String?;
    experienceController.text =
        workerProfile?['years_experience']?.toString() ?? '';
    bioController.text = workerProfile?['bio'] as String? ?? '';
  }

  void startEditing(_ProfileViewData data) {
    populateForm(data);
    setState(() => isEditing = true);
  }

  Future<void> saveProfile(_ProfileViewData data) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final area = selectedArea;
    if (area == null) {
      showMessage('اختر المحافظة والمنطقة.');
      return;
    }

    final isWorker = data.profile['role'] == 'worker';
    if (isWorker && selectedProfession == null) {
      showMessage('اختر التخصص.');
      return;
    }

    setState(() => isSaving = true);

    try {
      await repository.updateProfile(
        UpdateProfileData(
          fullName: fullNameController.text,
          phone: phoneController.text,
          governorate: area.governorate,
          area: area.name,
          areaId: area.id,
          address: addressController.text,
          profession: isWorker ? selectedProfession : null,
          yearsExperience: isWorker
              ? int.parse(experienceController.text)
              : null,
          bio: isWorker ? bioController.text : null,
        ),
      );

      if (!mounted) {
        return;
      }

      showMessage('تم حفظ التعديلات بنجاح.');
      reloadProfile();
      Navigator.of(context).pop(true);
    } on PostgrestException catch (error) {
      showMessage(error.message);
    } catch (_) {
      showMessage('تعذر حفظ التعديلات. حاول مرة أخرى.');
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    experienceController.dispose();
    bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الملف الشخصي'),
        actions: [
          FutureBuilder<_ProfileViewData>(
            future: profileFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData || isEditing) {
                return const SizedBox.shrink();
              }

              return IconButton(
                tooltip: 'تعديل الملف',
                onPressed: () => startEditing(snapshot.data!),
                icon: const Icon(Icons.edit_outlined),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<_ProfileViewData>(
        future: profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text('تعذر تحميل الملف الشخصي.'),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: reloadProfile,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            );
          }

          final data = snapshot.data!;
          if (isEditing) {
            return _buildEditForm(context, data);
          }

          return _buildView(context, data);
        },
      ),
    );
  }

  Widget _buildView(BuildContext context, _ProfileViewData data) {
    final profile = data.profile;
    final workerProfile = data.workerProfile;
    final isWorker = profile['role'] == 'worker';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const CircleAvatar(
          radius: 42,
          child: Icon(Icons.person_outline_rounded, size: 42),
        ),
        const SizedBox(height: 16),
        Text(
          profile['full_name'] as String? ?? '',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          isWorker ? 'حساب صنايعي' : 'حساب عميل',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (isWorker) ...[
          const SizedBox(height: 12),
          ProfileStatusChip(status: profile['status'] as String? ?? ''),
        ],
        const SizedBox(height: 24),
        ProfileInfoCard(
          children: [
            ProfileInfoTile(
              icon: Icons.email_outlined,
              label: 'البريد الإلكتروني',
              value: data.email,
              ltr: true,
            ),
            ProfileInfoTile(
              icon: Icons.phone_outlined,
              label: 'رقم الموبايل',
              value: profile['phone'] as String? ?? '',
              ltr: true,
            ),
            ProfileInfoTile(
              icon: Icons.place_outlined,
              label: 'المنطقة',
              value:
                  '${profile['governorate'] ?? ''} - ${profile['area'] ?? ''}',
            ),
            ProfileInfoTile(
              icon: Icons.home_outlined,
              label: 'العنوان',
              value: profile['address'] as String? ?? '',
            ),
          ],
        ),
        if (workerProfile != null) ...[
          const SizedBox(height: 16),
          ProfileInfoCard(
            title: 'البيانات المهنية',
            children: [
              ProfileInfoTile(
                icon: Icons.handyman_outlined,
                label: 'التخصص',
                value: workerProfile['profession'] as String? ?? '',
              ),
              ProfileInfoTile(
                icon: Icons.workspace_premium_outlined,
                label: 'سنوات الخبرة',
                value: '${workerProfile['years_experience'] ?? 0} سنة',
              ),
              ProfileInfoTile(
                icon: Icons.notes_rounded,
                label: 'نبذة عن الخبرة',
                value: workerProfile['bio'] as String? ?? '',
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        const LegalMenuCard(),
      ],
    );
  }

  Widget _buildEditForm(BuildContext context, _ProfileViewData data) {
    final isWorker = data.profile['role'] == 'worker';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'تعديل البيانات',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: fullNameController,
              decoration: const InputDecoration(
                labelText: 'الاسم بالكامل',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: requiredValidator('اكتب الاسم بالكامل'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'رقم الموبايل',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: validatePhone,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            AreaPickerFields(
              selectedArea: selectedArea,
              initialAreaId: parseAreaId(data.profile['area_id']),
              initialGovernorate: data.profile['governorate'] as String?,
              initialAreaName: data.profile['area'] as String?,
              onAreaChanged: (area) {
                setState(() => selectedArea = area);
              },
              enabled: !isSaving,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: addressController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: isWorker ? 'العنوان أو عنوان الورشة' : 'العنوان',
                prefixIcon: const Icon(Icons.home_outlined),
                alignLabelWithHint: true,
              ),
              validator: requiredValidator('اكتب العنوان'),
            ),
            if (isWorker) ...[
              const SizedBox(height: 16),
              FutureBuilder<List<ServiceCategory>>(
                future: categoriesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }
                  if (snapshot.hasError) {
                    return const Text('تعذر تحميل التخصصات.');
                  }

                  final categories = snapshot.data ?? const [];
                  if (categories.isEmpty) {
                    return const Text('لا توجد تخصصات متاحة حاليًا.');
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: selectedProfession,
                    decoration: const InputDecoration(
                      labelText: 'التخصص',
                      prefixIcon: Icon(Icons.handyman_outlined),
                    ),
                    items: categories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category.name,
                            child: Text(category.name),
                          ),
                        )
                        .toList(),
                    onChanged: isSaving
                        ? null
                        : (value) {
                            setState(() => selectedProfession = value);
                          },
                    validator: (value) =>
                        value == null ? 'اختر التخصص' : null,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: experienceController,
                decoration: const InputDecoration(
                  labelText: 'سنوات الخبرة',
                  prefixIcon: Icon(Icons.workspace_premium_outlined),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: validateExperience,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: bioController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'نبذة عن خبرتك',
                  prefixIcon: Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
                validator: requiredValidator('اكتب نبذة قصيرة عن خبرتك'),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isSaving ? null : () => saveProfile(data),
              child: isSaving
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('حفظ التعديلات'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: isSaving
                  ? null
                  : () {
                      setState(() => isEditing = false);
                    },
              child: const Text('إلغاء'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileViewData {
  const _ProfileViewData({
    required this.profile,
    required this.workerProfile,
    required this.email,
  });

  final Map<String, dynamic> profile;
  final Map<String, dynamic>? workerProfile;
  final String email;
}

class ProfileInfoCard extends StatelessWidget {
  const ProfileInfoCard({
    required this.children,
    this.title,
    super.key,
  });

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Divider(height: 24),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

class ProfileInfoTile extends StatelessWidget {
  const ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.ltr = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(value, textDirection: ltr ? TextDirection.ltr : null),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileStatusChip extends StatelessWidget {
  const ProfileStatusChip({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'active' => 'حساب نشط',
      'pending' => 'قيد المراجعة',
      'suspended' => 'موقوف',
      _ => status,
    };

    final variant = switch (status) {
      'active' => AppBadgeVariant.success,
      'pending' => AppBadgeVariant.warning,
      'suspended' => AppBadgeVariant.destructive,
      _ => AppBadgeVariant.neutral,
    };

    return Center(
      child: AppBadge(
        label: label,
        variant: variant,
        icon: Icons.circle,
      ),
    );
  }
}

int? parseAreaId(dynamic value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return null;
}
