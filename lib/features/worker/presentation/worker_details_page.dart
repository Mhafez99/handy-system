import 'package:flutter/material.dart';
import 'package:handy_app/features/reviews/domain/service_review.dart';
import 'package:handy_app/features/worker/data/workers_repository.dart';
import 'package:handy_app/features/worker/domain/worker_public_details.dart';

class WorkerDetailsPage extends StatefulWidget {
  const WorkerDetailsPage({
    required this.workerId,
    required this.fallbackName,
    super.key,
  });

  final String workerId;
  final String fallbackName;

  @override
  State<WorkerDetailsPage> createState() => _WorkerDetailsPageState();
}

class _WorkerDetailsPageState extends State<WorkerDetailsPage> {
  final repository = WorkersRepository();
  late Future<WorkerPublicDetails> detailsFuture;

  @override
  void initState() {
    super.initState();
    detailsFuture = repository.loadWorkerPublicDetails(widget.workerId);
  }

  void reloadDetails() {
    setState(() {
      detailsFuture = repository.loadWorkerPublicDetails(widget.workerId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.fallbackName)),
      body: SafeArea(
        child: FutureBuilder<WorkerPublicDetails>(
          future: detailsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Text('تعذر تحميل بيانات الصنايعي.'),
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
                WorkerHeaderCard(details: details),
                const SizedBox(height: 16),
                WorkerBioCard(details: details),
                const SizedBox(height: 24),
                Text(
                  'آخر التقييمات',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if (details.reviews.isEmpty)
                  const EmptyWorkerReviewsCard()
                else
                  for (final review in details.reviews)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: WorkerReviewCard(review: review),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class WorkerHeaderCard extends StatelessWidget {
  const WorkerHeaderCard({required this.details, super.key});

  final WorkerPublicDetails details;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 34,
              child: Text(
                details.fullName.isEmpty
                    ? 'ص'
                    : details.fullName.characters.first,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              details.fullName,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '${details.profession} • ${details.area}، ${details.governorate}',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.star_rounded, color: Colors.amber.shade700),
                const SizedBox(width: 6),
                Text(
                  details.averageRating == null || details.reviewCount == 0
                      ? 'لا توجد تقييمات بعد'
                      : '${details.averageRating!.toStringAsFixed(1)} من 5 (${details.reviewCount} تقييم)',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WorkerBioCard extends StatelessWidget {
  const WorkerBioCard({required this.details, super.key});

  final WorkerPublicDetails details;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'نبذة وخبرة',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text('${details.yearsExperience} سنة خبرة'),
            if (details.bio.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(details.bio),
            ],
          ],
        ),
      ),
    );
  }
}

class WorkerReviewCard extends StatelessWidget {
  const WorkerReviewCard({required this.review, super.key});

  final ServiceReview review;

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
                for (var index = 1; index <= 5; index++)
                  Icon(
                    index <= review.rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: Colors.amber.shade700,
                    size: 20,
                  ),
                const SizedBox(width: 8),
                Text('${review.rating}/5'),
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review.comment),
            ],
          ],
        ),
      ),
    );
  }
}

class EmptyWorkerReviewsCard extends StatelessWidget {
  const EmptyWorkerReviewsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 44,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'لا توجد تقييمات لهذا الصنايعي بعد.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
