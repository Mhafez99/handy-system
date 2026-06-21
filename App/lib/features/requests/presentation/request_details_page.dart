import 'package:flutter/material.dart';
import 'package:handy_app/core/realtime/service_requests_realtime.dart';
import 'package:handy_app/features/complaints/data/complaints_repository.dart';
import 'package:handy_app/features/complaints/domain/create_complaint_data.dart';
import 'package:handy_app/features/complaints/domain/service_complaint.dart';
import 'package:handy_app/features/offers/data/offers_repository.dart';
import 'package:handy_app/features/offers/domain/service_offer.dart';
import 'package:handy_app/features/requests/data/service_requests_repository.dart';
import 'package:handy_app/features/requests/domain/service_request_details.dart';
import 'package:handy_app/features/reviews/data/reviews_repository.dart';
import 'package:handy_app/features/reviews/domain/create_review_data.dart';
import 'package:handy_app/features/requests/presentation/payment_summary_widgets.dart';
import 'package:handy_app/features/requests/presentation/request_image_widgets.dart';
import 'package:handy_app/features/reviews/domain/service_review.dart';
import 'package:handy_app/features/worker/presentation/worker_details_page.dart';

class RequestDetailsPage extends StatefulWidget {
  const RequestDetailsPage({required this.requestId, super.key});

  final String requestId;

  @override
  State<RequestDetailsPage> createState() => _RequestDetailsPageState();
}

class _RequestDetailsPageState extends State<RequestDetailsPage> {
  final repository = ServiceRequestsRepository();
  final offersRepository = OffersRepository();
  final reviewsRepository = ReviewsRepository();
  final complaintsRepository = ComplaintsRepository();
  final reviewCommentController = TextEditingController();
  final _realtime = ServiceRequestsRealtime();
  late Future<ServiceRequestDetails> detailsFuture;
  String? acceptingOfferId;
  bool isCancelling = false;
  bool isSubmittingReview = false;
  bool isSubmittingComplaint = false;
  int selectedRating = 5;

  @override
  void initState() {
    super.initState();
    detailsFuture = repository.loadCustomerRequestDetails(widget.requestId);
    _realtime.subscribeToRequest(
      requestId: widget.requestId,
      onChange: reloadDetails,
    );
  }

  void reloadDetails() {
    setState(() {
      detailsFuture = repository.loadCustomerRequestDetails(widget.requestId);
    });
  }

  @override
  void dispose() {
    _realtime.unsubscribe();
    reviewCommentController.dispose();
    super.dispose();
  }

  Future<void> acceptOffer(ServiceOffer offer) async {
    setState(() => acceptingOfferId = offer.id);

    try {
      await offersRepository.acceptOffer(offer.id);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم قبول العرض بنجاح.')));
      reloadDetails();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر قبول العرض. حاول مرة أخرى.')),
      );
    } finally {
      if (mounted) {
        setState(() => acceptingOfferId = null);
      }
    }
  }

  Future<void> confirmAndCancelRequest() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء الطلب'),
        content: const Text(
          'هل أنت متأكد من إلغاء هذا الطلب؟ لن تستطيع استقبال عروض جديدة بعد الإلغاء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('تراجع'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('إلغاء الطلب'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => isCancelling = true);

    try {
      await repository.cancelRequest(widget.requestId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم إلغاء الطلب بنجاح.')));
      reloadDetails();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر إلغاء الطلب. حاول مرة أخرى.')),
      );
    } finally {
      if (mounted) {
        setState(() => isCancelling = false);
      }
    }
  }

  Future<void> submitComplaint(
    ServiceRequestDetails details,
    String category,
    String description,
  ) async {
    setState(() => isSubmittingComplaint = true);

    try {
      await complaintsRepository.submitComplaint(
        CreateComplaintData(
          requestId: details.id,
          category: category,
          description: description,
        ),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الشكوى. فريق الإدارة هيراجعها.')),
      );
      reloadDetails();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر إرسال الشكوى. حاول مرة أخرى.')),
      );
    } finally {
      if (mounted) {
        setState(() => isSubmittingComplaint = false);
      }
    }
  }

  Future<void> submitReview(ServiceRequestDetails details) async {
    setState(() => isSubmittingReview = true);

    try {
      await reviewsRepository.submitReview(
        CreateReviewData(
          requestId: details.id,
          rating: selectedRating,
          comment: reviewCommentController.text,
        ),
      );
      if (!mounted) {
        return;
      }
      reviewCommentController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تم حفظ تقييمك بنجاح.')));
      reloadDetails();
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ التقييم. حاول مرة أخرى.')),
      );
    } finally {
      if (mounted) {
        setState(() => isSubmittingReview = false);
      }
    }
  }

  void openWorkerDetails(ServiceOffer offer) {
    if (offer.workerId.isEmpty) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WorkerDetailsPage(
          workerId: offer.workerId,
          fallbackName: offer.workerName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل الطلب')),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => reloadDetails(),
          child: FutureBuilder<ServiceRequestDetails>(
            future: detailsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const Text('تعذر تحميل تفاصيل الطلب.'),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: reloadDetails,
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                );
              }

              final details = snapshot.data!;
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    details.serviceName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${details.categoryName} • ${details.area}'),
                  const SizedBox(height: 16),
                  DetailCard(details: details),
                  const SizedBox(height: 12),
                  OnTheWayStatusCard(status: details.status),
                  const SizedBox(height: 12),
                  PaymentSummaryCard(
                    status: details.status,
                    acceptedPrice: details.acceptedOfferPrice,
                    finalPrice: details.finalPrice,
                    paymentMethod: details.paymentMethod,
                  ),
                  const SizedBox(height: 12),
                  CancelActionCard(
                    status: details.status,
                    isCancelling: isCancelling,
                    onCancel: confirmAndCancelRequest,
                  ),
                  const SizedBox(height: 12),
                  CompletionCodeCard(
                    status: details.status,
                    completionCode: details.completionCode,
                  ),
                  const SizedBox(height: 12),
                  ReviewActionCard(
                    status: details.status,
                    review: details.review,
                    selectedRating: selectedRating,
                    commentController: reviewCommentController,
                    isSubmitting: isSubmittingReview,
                    onRatingChanged: (rating) {
                      setState(() => selectedRating = rating);
                    },
                    onSubmit: () => submitReview(details),
                  ),
                  const SizedBox(height: 12),
                  ComplaintActionCard(
                    status: details.status,
                    complaint: details.complaint,
                    isSubmitting: isSubmittingComplaint,
                    onSubmit: (category, description) =>
                        submitComplaint(details, category, description),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'العروض الواردة',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (details.offers.isEmpty)
                    const EmptyOffersCard()
                  else
                    for (final offer in details.offers)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: OfferCard(
                          offer: offer,
                          requestStatus: details.status,
                          isAccepting: acceptingOfferId == offer.id,
                          onAccept: () => acceptOffer(offer),
                          onOpenWorkerDetails: () => openWorkerDetails(offer),
                        ),
                      ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class DetailCard extends StatelessWidget {
  const DetailCard({required this.details, super.key});

  final ServiceRequestDetails details;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 6),
                Text('حالة الطلب: ${requestStatusLabel(details.status)}'),
              ],
            ),
            const Divider(height: 28),
            Text('الوصف', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(details.description),
            if (details.images.isNotEmpty) ...[
              const Divider(height: 28),
              Text('الصور', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              RequestImagesGallery(images: details.images),
            ],
            const Divider(height: 28),
            Text('العنوان: ${details.governorate} - ${details.area}'),
            const SizedBox(height: 6),
            Text(details.address),
            const SizedBox(height: 10),
            Text('الوقت المناسب: ${details.preferredTime}'),
            const SizedBox(height: 10),
            Text('نطاق السعر الاسترشادي: ${details.priceRange}'),
          ],
        ),
      ),
    );
  }
}

class OnTheWayStatusCard extends StatelessWidget {
  const OnTheWayStatusCard({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    if (status != 'on_the_way') {
      return const SizedBox.shrink();
    }

    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.directions_walk_outlined),
            SizedBox(width: 10),
            Expanded(child: Text('الصنايعي في الطريق إليك.')),
          ],
        ),
      ),
    );
  }
}

class CancelActionCard extends StatelessWidget {
  const CancelActionCard({
    required this.status,
    required this.isCancelling,
    required this.onCancel,
    super.key,
  });

  final String status;
  final bool isCancelling;
  final VoidCallback onCancel;

  bool get canCancel => status == 'new' || status == 'offered';

  @override
  Widget build(BuildContext context) {
    if (status == 'cancelled') {
      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.cancel_outlined),
              SizedBox(width: 10),
              Expanded(child: Text('تم إلغاء هذا الطلب.')),
            ],
          ),
        ),
      );
    }

    if (!canCancel) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('لو مش محتاج الخدمة دلوقتي، تقدر تلغي الطلب من هنا.'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: isCancelling ? null : onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
              icon: isCancelling
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.cancel_outlined),
              label: const Text('إلغاء الطلب'),
            ),
          ],
        ),
      ),
    );
  }
}

class CompletionCodeCard extends StatelessWidget {
  const CompletionCodeCard({
    required this.status,
    required this.completionCode,
    super.key,
  });

  final String status;
  final String? completionCode;

  @override
  Widget build(BuildContext context) {
    if (status == 'completed') {
      return Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.verified_outlined),
              SizedBox(width: 10),
              Expanded(child: Text('تم إتمام الخدمة بنجاح.')),
            ],
          ),
        ),
      );
    }

    if (status != 'in_progress' ||
        completionCode == null ||
        completionCode!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'بعد ما الشغل يخلص، ادّي الكود ده للصنايعي عشان يأكد الإتمام.',
            ),
            const SizedBox(height: 16),
            Text(
              completionCode!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ComplaintActionCard extends StatefulWidget {
  const ComplaintActionCard({
    required this.status,
    required this.complaint,
    required this.isSubmitting,
    required this.onSubmit,
    super.key,
  });

  final String status;
  final ServiceComplaint? complaint;
  final bool isSubmitting;
  final void Function(String category, String description) onSubmit;

  @override
  State<ComplaintActionCard> createState() => _ComplaintActionCardState();
}

class _ComplaintActionCardState extends State<ComplaintActionCard> {
  String selectedCategory = 'poor_quality';
  final descriptionController = TextEditingController();

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  void submit() {
    widget.onSubmit(selectedCategory, descriptionController.text);
  }

  @override
  Widget build(BuildContext context) {
    final currentComplaint = widget.complaint;

    if (currentComplaint != null || widget.status == 'complaint') {
      if (currentComplaint == null) {
        return Card(
          color: Theme.of(context).colorScheme.errorContainer,
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.report_outlined),
                SizedBox(width: 10),
                Expanded(child: Text('تم تسجيل شكوى على هذا الطلب.')),
              ],
            ),
          ),
        );
      }

      return Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'شكواك',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text('السبب: ${currentComplaint.categoryLabel}'),
              const SizedBox(height: 6),
              Text('الحالة: ${currentComplaint.statusLabel}'),
              const SizedBox(height: 8),
              Text(currentComplaint.description),
            ],
          ),
        ),
      );
    }

    if (widget.status != 'completed') {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'إرسال شكوى',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'لو فيه مشكلة في الخدمة، ابعت شكوى وفريق الإدارة هيراجعها.',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(labelText: 'سبب الشكوى'),
              items: complaintCategories.entries
                  .map(
                    (entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(growable: false),
              onChanged: widget.isSubmitting
                  ? null
                  : (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() => selectedCategory = value);
                    },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              enabled: !widget.isSubmitting,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'وصف المشكلة',
                alignLabelWithHint: true,
                helperText: 'اكتب 10 أحرف على الأقل',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: widget.isSubmitting ? null : submit,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
              icon: widget.isSubmitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.report_outlined),
              label: const Text('إرسال الشكوى'),
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewActionCard extends StatelessWidget {
  const ReviewActionCard({
    required this.status,
    required this.review,
    required this.selectedRating,
    required this.commentController,
    required this.isSubmitting,
    required this.onRatingChanged,
    required this.onSubmit,
    super.key,
  });

  final String status;
  final ServiceReview? review;
  final int selectedRating;
  final TextEditingController commentController;
  final bool isSubmitting;
  final ValueChanged<int> onRatingChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    if (status != 'completed') {
      return const SizedBox.shrink();
    }

    final currentReview = review;
    if (currentReview != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'تقييمك للخدمة',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              StarRatingLabel(rating: currentReview.rating),
              if (currentReview.comment.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(currentReview.comment),
              ],
            ],
          ),
        ),
      );
    }

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'قيّم الخدمة',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text('التقييم يساعد العملاء يعرفوا الصنايعية الكويسة.'),
            const SizedBox(height: 12),
            StarRatingInput(rating: selectedRating, onChanged: onRatingChanged),
            const SizedBox(height: 12),
            TextField(
              controller: commentController,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'تعليق اختياري',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              icon: isSubmitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.star_outline),
              label: const Text('إرسال التقييم'),
            ),
          ],
        ),
      ),
    );
  }
}

class StarRatingInput extends StatelessWidget {
  const StarRatingInput({
    required this.rating,
    required this.onChanged,
    super.key,
  });

  final int rating;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 1; index <= 5; index++)
          IconButton(
            tooltip: '$index نجوم',
            onPressed: () => onChanged(index),
            icon: Icon(
              index <= rating ? Icons.star_rounded : Icons.star_border_rounded,
              color: Colors.amber.shade700,
            ),
          ),
      ],
    );
  }
}

class StarRatingLabel extends StatelessWidget {
  const StarRatingLabel({required this.rating, super.key});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 1; index <= 5; index++)
          Icon(
            index <= rating ? Icons.star_rounded : Icons.star_border_rounded,
            color: Colors.amber.shade700,
            size: 22,
          ),
        const SizedBox(width: 8),
        Text('$rating/5'),
      ],
    );
  }
}

String requestStatusLabel(String status) {
  return switch (status) {
    'offered' => 'به عروض',
    'accepted' => 'مقبول',
    'on_the_way' => 'في الطريق',
    'in_progress' => 'قيد التنفيذ',
    'completed' => 'مكتمل',
    'cancelled' => 'ملغي',
    'complaint' => 'شكوى',
    _ => 'جديد',
  };
}

class OfferCard extends StatelessWidget {
  const OfferCard({
    required this.offer,
    required this.requestStatus,
    required this.isAccepting,
    required this.onAccept,
    required this.onOpenWorkerDetails,
    super.key,
  });

  final ServiceOffer offer;
  final String requestStatus;
  final bool isAccepting;
  final VoidCallback onAccept;
  final VoidCallback onOpenWorkerDetails;

  @override
  Widget build(BuildContext context) {
    final canAccept =
        offer.status == 'pending' &&
        (requestStatus == 'new' || requestStatus == 'offered');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    offer.workerName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Chip(
                  label: Text('${offer.price} جنيه'),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            OfferStatusLabel(status: offer.status),
            const SizedBox(height: 8),
            WorkerOfferRatingLabel(
              averageRating: offer.averageRating,
              reviewCount: offer.reviewCount,
            ),
            const SizedBox(height: 8),
            Text('وقت الوصول: ${offer.arrivalTime}'),
            if (offer.status == 'accepted' && offer.workerPhone.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('رقم التواصل: ${offer.workerPhone}'),
            ],
            if (offer.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(offer.note),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: offer.workerId.isEmpty ? null : onOpenWorkerDetails,
              icon: const Icon(Icons.person_search_outlined),
              label: const Text('تفاصيل الصنايعي'),
            ),
            const SizedBox(height: 8),
            if (canAccept)
              FilledButton.icon(
                onPressed: isAccepting ? null : onAccept,
                icon: isAccepting
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: const Text('قبول العرض'),
              )
            else if (offer.status == 'accepted')
              FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('تم قبول هذا العرض'),
              ),
          ],
        ),
      ),
    );
  }
}

class WorkerOfferRatingLabel extends StatelessWidget {
  const WorkerOfferRatingLabel({
    required this.averageRating,
    required this.reviewCount,
    super.key,
  });

  final double? averageRating;
  final int reviewCount;

  @override
  Widget build(BuildContext context) {
    if (averageRating == null || reviewCount == 0) {
      return Row(
        children: [
          Icon(
            Icons.star_border_rounded,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            'لا توجد تقييمات بعد',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Icon(Icons.star_rounded, size: 20, color: Colors.amber.shade700),
        const SizedBox(width: 6),
        Text('${averageRating!.toStringAsFixed(1)} من 5'),
        const SizedBox(width: 6),
        Text(
          '($reviewCount تقييم)',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class OfferStatusLabel extends StatelessWidget {
  const OfferStatusLabel({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      'accepted' => 'مقبول',
      'rejected' => 'مرفوض',
      'withdrawn' => 'مسحوب',
      _ => 'بانتظار ردك',
    };

    final color = switch (status) {
      'accepted' => Colors.green,
      'rejected' => Theme.of(context).colorScheme.outline,
      'withdrawn' => Theme.of(context).colorScheme.outline,
      _ => Theme.of(context).colorScheme.primary,
    };

    return Row(
      children: [
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

class EmptyOffersCard extends StatelessWidget {
  const EmptyOffersCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text('لم تصلك عروض بعد.', textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(
              'عندما يرسل الصنايعية عروضهم ستظهر هنا.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
