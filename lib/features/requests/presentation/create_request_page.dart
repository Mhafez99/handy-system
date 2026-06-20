import 'package:flutter/material.dart';
import 'package:handy_app/features/requests/data/service_requests_repository.dart';
import 'package:handy_app/features/requests/domain/create_service_request_data.dart';
import 'package:handy_app/features/requests/domain/service_category.dart';
import 'package:handy_app/features/requests/domain/service_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateRequestPage extends StatefulWidget {
  const CreateRequestPage({required this.profile, super.key});

  final Map<String, dynamic> profile;

  @override
  State<CreateRequestPage> createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends State<CreateRequestPage> {
  final formKey = GlobalKey<FormState>();
  final repository = ServiceRequestsRepository();
  final descriptionController = TextEditingController();
  final governorateController = TextEditingController();
  final areaController = TextEditingController();
  final addressController = TextEditingController();
  final preferredTimeController = TextEditingController(text: 'في أقرب وقت');

  late Future<List<ServiceCategory>> categoriesFuture;
  List<ServiceItem> services = [];
  ServiceCategory? selectedCategory;
  ServiceItem? selectedService;
  bool isLoadingServices = false;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    categoriesFuture = repository.loadCategories();
    governorateController.text = widget.profile['governorate'] as String? ?? '';
    areaController.text = widget.profile['area'] as String? ?? '';
    addressController.text = widget.profile['address'] as String? ?? '';
  }

  @override
  void dispose() {
    descriptionController.dispose();
    governorateController.dispose();
    areaController.dispose();
    addressController.dispose();
    preferredTimeController.dispose();
    super.dispose();
  }

  Future<void> selectCategory(ServiceCategory? category) async {
    if (category == null) {
      return;
    }

    setState(() {
      selectedCategory = category;
      selectedService = null;
      services = [];
      isLoadingServices = true;
    });

    try {
      final loadedServices = await repository.loadServices(category.id);
      if (!mounted) {
        return;
      }
      setState(() {
        services = loadedServices;
      });
    } on PostgrestException catch (error) {
      showError(error.message);
    } catch (_) {
      showError('تعذر تحميل الخدمات.');
    } finally {
      if (mounted) {
        setState(() => isLoadingServices = false);
      }
    }
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    final category = selectedCategory;
    final service = selectedService;
    if (category == null || service == null) {
      showError('اختر التخصص والخدمة.');
      return;
    }

    setState(() => isSubmitting = true);
    try {
      await repository.createRequest(
        CreateServiceRequestData(
          categoryId: category.id,
          serviceId: service.id,
          description: descriptionController.text,
          governorate: governorateController.text,
          area: areaController.text,
          address: addressController.text,
          preferredTime: preferredTimeController.text,
        ),
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إنشاء الطلب بنجاح.')));
      Navigator.of(context).pop(true);
    } on PostgrestException catch (error) {
      showError(error.message);
    } catch (_) {
      showError('تعذر إنشاء الطلب. حاول مرة أخرى.');
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
      appBar: AppBar(title: const Text('إنشاء طلب خدمة')),
      body: SafeArea(
        child: FutureBuilder<List<ServiceCategory>>(
          future: categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('تعذر تحميل التخصصات.'),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            categoriesFuture = repository.loadCategories();
                          });
                        },
                        child: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final categories = snapshot.data ?? [];
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'اكتب تفاصيل المشكلة',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ServiceCategory>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'التخصص',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category.name),
                            ),
                          )
                          .toList(),
                      onChanged: isSubmitting ? null : selectCategory,
                      validator: (value) =>
                          value == null ? 'اختر التخصص' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ServiceItem>(
                      initialValue: selectedService,
                      decoration: InputDecoration(
                        labelText: 'الخدمة',
                        prefixIcon: const Icon(Icons.build_outlined),
                        helperText: selectedService == null
                            ? 'اختر الخدمة لمعرفة نطاق السعر'
                            : 'نطاق السعر: ${selectedService!.priceRange}',
                      ),
                      items: services
                          .map(
                            (service) => DropdownMenuItem(
                              value: service,
                              child: Text(service.name),
                            ),
                          )
                          .toList(),
                      onChanged: isLoadingServices || isSubmitting
                          ? null
                          : (value) {
                              setState(() => selectedService = value);
                            },
                      validator: (value) =>
                          value == null ? 'اختر الخدمة' : null,
                    ),
                    if (isLoadingServices) ...[
                      const SizedBox(height: 8),
                      const LinearProgressIndicator(),
                    ],
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'وصف المشكلة',
                        prefixIcon: Icon(Icons.description_outlined),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 10) {
                          return 'اكتب وصفًا واضحًا لا يقل عن 10 أحرف';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: governorateController,
                      decoration: const InputDecoration(
                        labelText: 'المحافظة',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                      validator: requiredValidator('اكتب المحافظة'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: areaController,
                      decoration: const InputDecoration(
                        labelText: 'المنطقة',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                      validator: requiredValidator('اكتب المنطقة'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'العنوان بالتفصيل',
                        prefixIcon: Icon(Icons.home_outlined),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 5) {
                          return 'اكتب عنوانًا واضحًا';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: preferredTimeController,
                      decoration: const InputDecoration(
                        labelText: 'الوقت المناسب',
                        prefixIcon: Icon(Icons.schedule_outlined),
                      ),
                      validator: requiredValidator('اكتب الوقت المناسب'),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isSubmitting ? null : submit,
                      child: isSubmitting
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('إنشاء الطلب'),
                    ),
                  ],
                ),
              ),
            );
          },
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
