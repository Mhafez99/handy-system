import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:handy_app/features/offers/data/offers_repository.dart';
import 'package:handy_app/features/offers/domain/create_offer_data.dart';
import 'package:handy_app/features/requests/data/service_requests_repository.dart';
import 'package:handy_app/features/requests/domain/available_worker_request.dart';
import 'package:handy_app/features/requests/domain/request_image.dart';
import 'package:handy_app/features/requests/presentation/request_image_widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SendOfferPage extends StatefulWidget {
  const SendOfferPage({required this.request, super.key});

  final AvailableWorkerRequest request;

  @override
  State<SendOfferPage> createState() => _SendOfferPageState();
}

class _SendOfferPageState extends State<SendOfferPage> {
  final formKey = GlobalKey<FormState>();
  final repository = OffersRepository();
  final requestsRepository = ServiceRequestsRepository();
  final priceController = TextEditingController();
  final arrivalTimeController = TextEditingController(text: 'خلال ساعة');
  final noteController = TextEditingController();

  late Future<List<RequestImage>> imagesFuture;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    imagesFuture = requestsRepository.loadRequestImages(widget.request.id);
  }

  @override
  void dispose() {
    priceController.dispose();
    arrivalTimeController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    setState(() => isSubmitting = true);
    try {
      await repository.createOffer(
        CreateOfferData(
          requestId: widget.request.id,
          price: int.parse(priceController.text),
          arrivalTime: arrivalTimeController.text,
          note: noteController.text,
        ),
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إرسال العرض بنجاح.')));
      Navigator.of(context).pop(true);
    } on PostgrestException catch (error) {
      final message = error.code == '23505'
          ? 'أرسلت عرضًا لهذا الطلب من قبل.'
          : error.message;
      showError(message);
    } catch (_) {
      showError('تعذر إرسال العرض. حاول مرة أخرى.');
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
      appBar: AppBar(title: const Text('إرسال عرض سعر')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.request.serviceName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'نطاق السعر الاسترشادي: ${widget.request.priceRange}',
                        ),
                        const SizedBox(height: 8),
                        Text(widget.request.description),
                        const SizedBox(height: 12),
                        FutureBuilder<List<RequestImage>>(
                          future: imagesFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const LinearProgressIndicator();
                            }

                            if (snapshot.hasError) {
                              return const Text('تعذر تحميل صور الطلب.');
                            }

                            return RequestImagesGallery(
                              images: snapshot.data ?? const [],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'السعر النهائي بالجنيه',
                    prefixIcon: Icon(Icons.payments_outlined),
                  ),
                  validator: (value) {
                    final price = int.tryParse(value ?? '');
                    if (price == null || price <= 0) {
                      return 'اكتب سعرًا صحيحًا';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: arrivalTimeController,
                  decoration: const InputDecoration(
                    labelText: 'وقت الوصول المتوقع',
                    prefixIcon: Icon(Icons.schedule_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return 'اكتب وقت الوصول المتوقع';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: noteController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات اختيارية',
                    prefixIcon: Icon(Icons.notes_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: isSubmitting ? null : submit,
                  child: isSubmitting
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('إرسال العرض'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
