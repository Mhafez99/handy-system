import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:handy_app/features/auth/data/auth_repository.dart';
import 'package:handy_app/features/auth/domain/account_role.dart';
import 'package:handy_app/features/auth/domain/registration_data.dart';
import 'package:handy_app/features/auth/presentation/login_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({required this.role, super.key});

  final AccountRole role;

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  static const professions = ['سباك', 'كهربائي', 'نجار', 'نقاش', 'فني تكييف'];

  final formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final governorateController = TextEditingController(text: 'القاهرة');
  final areaController = TextEditingController();
  final addressController = TextEditingController();
  final experienceController = TextEditingController();
  final bioController = TextEditingController();
  final repository = AuthRepository();

  String? selectedProfession;
  bool acceptedTerms = false;
  bool isSubmitting = false;
  bool obscurePassword = true;

  bool get isWorker => widget.role == AccountRole.worker;

  @override
  void dispose() {
    fullNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    governorateController.dispose();
    areaController.dispose();
    addressController.dispose();
    experienceController.dispose();
    bioController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    if (!acceptedTerms) {
      showError('يجب الموافقة على الشروط وسياسة الخصوصية.');
      return;
    }

    setState(() => isSubmitting = true);
    try {
      final requiresEmailConfirmation = await repository.signUp(
        RegistrationData(
          role: widget.role,
          fullName: fullNameController.text,
          phone: phoneController.text,
          email: emailController.text,
          password: passwordController.text,
          governorate: governorateController.text,
          area: areaController.text,
          address: addressController.text,
          profession: selectedProfession,
          yearsExperience: isWorker
              ? int.parse(experienceController.text)
              : null,
          bio: isWorker ? bioController.text : null,
        ),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => RegistrationSuccessPage(
            role: widget.role,
            requiresEmailConfirmation: requiresEmailConfirmation,
          ),
        ),
      );
    } on AuthException catch (error) {
      showError(error.message);
    } on PostgrestException catch (error) {
      showError(error.message);
    } catch (_) {
      showError('تعذر إنشاء الحساب. حاول مرة أخرى.');
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  void showError(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isWorker ? 'إنشاء حساب صنايعي' : 'إنشاء حساب عميل'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isWorker
                      ? 'سجّل بياناتك لاستقبال طلبات الشغل'
                      : 'سجّل بياناتك لطلب الخدمات',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                if (isWorker) ...[
                  const SizedBox(height: 8),
                  Text(
                    'الحساب يظل قيد المراجعة حتى اعتماده يدويًا.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                buildTextField(
                  controller: fullNameController,
                  label: 'الاسم بالكامل',
                  icon: Icons.person_outline_rounded,
                  validator: requiredValidator('اكتب الاسم بالكامل'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                buildTextField(
                  controller: phoneController,
                  label: 'رقم الموبايل',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: validatePhone,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                buildTextField(
                  controller: emailController,
                  label: 'البريد الإلكتروني',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  validator: validateEmail,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                buildPasswordField(),
                const SizedBox(height: 16),
                buildTextField(
                  controller: confirmPasswordController,
                  label: 'تأكيد كلمة المرور',
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                  textDirection: TextDirection.ltr,
                  validator: (value) {
                    if (value != passwordController.text) {
                      return 'كلمتا المرور غير متطابقتين';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                buildTextField(
                  controller: governorateController,
                  label: 'المحافظة',
                  icon: Icons.location_city_outlined,
                  validator: requiredValidator('اكتب المحافظة'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                buildTextField(
                  controller: areaController,
                  label: 'المنطقة',
                  icon: Icons.place_outlined,
                  validator: requiredValidator('اكتب المنطقة'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                buildTextField(
                  controller: addressController,
                  label: isWorker ? 'العنوان أو عنوان الورشة' : 'العنوان',
                  icon: Icons.home_outlined,
                  validator: requiredValidator('اكتب العنوان'),
                  textInputAction: TextInputAction.next,
                ),
                if (isWorker) ...[
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedProfession,
                    decoration: const InputDecoration(
                      labelText: 'التخصص',
                      prefixIcon: Icon(Icons.handyman_outlined),
                    ),
                    items: professions
                        .map(
                          (profession) => DropdownMenuItem(
                            value: profession,
                            child: Text(profession),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => selectedProfession = value);
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'اختر التخصص';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  buildTextField(
                    controller: experienceController,
                    label: 'سنوات الخبرة',
                    icon: Icons.workspace_premium_outlined,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: validateExperience,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  buildTextField(
                    controller: bioController,
                    label: 'نبذة عن خبرتك',
                    icon: Icons.notes_rounded,
                    maxLines: 4,
                    validator: requiredValidator('اكتب نبذة قصيرة عن خبرتك'),
                  ),
                ],
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: acceptedTerms,
                  onChanged: (value) {
                    setState(() => acceptedTerms = value ?? false);
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('أوافق على شروط الاستخدام وسياسة الخصوصية'),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: isSubmitting ? null : submit,
                  child: isSubmitting
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('إنشاء الحساب'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  TextFormField buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      obscureText: obscurePassword,
      textDirection: TextDirection.ltr,
      decoration: InputDecoration(
        labelText: 'كلمة المرور',
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() => obscurePassword = !obscurePassword);
          },
          icon: Icon(
            obscurePassword
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
      validator: (value) {
        if (value == null || value.length < 8) {
          return 'كلمة المرور يجب أن تكون 8 أحرف على الأقل';
        }
        return null;
      },
      textInputAction: TextInputAction.next,
    );
  }

  TextFormField buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextDirection? textDirection,
    List<TextInputFormatter>? inputFormatters,
    TextInputAction? textInputAction,
    bool obscureText = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textDirection: textDirection,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      obscureText: obscureText,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        alignLabelWithHint: maxLines > 1,
      ),
      validator: validator,
    );
  }
}

class RegistrationSuccessPage extends StatelessWidget {
  const RegistrationSuccessPage({
    required this.role,
    required this.requiresEmailConfirmation,
    super.key,
  });

  final AccountRole role;
  final bool requiresEmailConfirmation;

  @override
  Widget build(BuildContext context) {
    final isWorker = role == AccountRole.worker;
    final message = requiresEmailConfirmation
        ? 'تم إنشاء الحساب. افتح رسالة التأكيد في بريدك الإلكتروني ثم سجّل الدخول.'
        : isWorker
        ? 'تم إنشاء الحساب وهو الآن قيد مراجعة الإدارة.'
        : 'تم إنشاء الحساب بنجاح.';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('تم إنشاء الحساب'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  if (requiresEmailConfirmation) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute<void>(
                        builder: (context) => const LoginPage(),
                      ),
                      (route) => false,
                    );
                    return;
                  }

                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: Text(
                  requiresEmailConfirmation
                      ? 'تسجيل الدخول'
                      : 'الدخول إلى الحساب',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String? Function(String?) requiredValidator(String message) {
  return (value) {
    if (value == null || value.trim().isEmpty) {
      return message;
    }
    return null;
  };
}

String? validatePhone(String? value) {
  final phone = value?.trim() ?? '';
  if (phone.length != 11 || !phone.startsWith('01')) {
    return 'اكتب رقم موبايل مصري صحيحًا';
  }
  return null;
}

String? validateExperience(String? value) {
  final years = int.tryParse(value ?? '');
  if (years == null || years < 0 || years > 70) {
    return 'اكتب عدد سنوات خبرة صحيحًا';
  }
  return null;
}
