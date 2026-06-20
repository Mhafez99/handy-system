import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handy_app/features/auth/domain/account_role.dart';
import 'package:handy_app/features/auth/presentation/registration_page.dart';
import 'package:handy_app/features/offers/domain/service_offer.dart';
import 'package:handy_app/features/offers/presentation/send_offer_page.dart';
import 'package:handy_app/features/onboarding/presentation/role_selection_page.dart';
import 'package:handy_app/features/requests/domain/accepted_worker_request.dart';
import 'package:handy_app/features/requests/domain/available_worker_request.dart';
import 'package:handy_app/features/requests/presentation/create_request_page.dart';
import 'package:handy_app/features/requests/presentation/request_details_page.dart';
import 'package:handy_app/features/reviews/domain/service_review.dart';
import 'package:handy_app/features/worker/domain/worker_public_details.dart';
import 'package:handy_app/features/worker/presentation/worker_details_page.dart';
import 'package:handy_app/features/worker/presentation/worker_home_page.dart';

void main() {
  testWidgets('account role choices are visible', (tester) async {
    await tester.pumpWidget(const TestApp());

    expect(find.text('حساب عميل'), findsOneWidget);
    expect(find.text('حساب صنايعي'), findsOneWidget);
    expect(find.text('عندي حساب بالفعل'), findsOneWidget);
  });

  testWidgets('customer registration only shows customer fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      const TestApp(child: RegistrationPage(role: AccountRole.customer)),
    );

    expect(find.text('إنشاء حساب عميل'), findsOneWidget);
    expect(find.text('التخصص'), findsNothing);
    expect(find.text('سنوات الخبرة'), findsNothing);
  });

  testWidgets('worker registration shows professional fields', (tester) async {
    await tester.pumpWidget(
      const TestApp(child: RegistrationPage(role: AccountRole.worker)),
    );

    expect(find.text('إنشاء حساب صنايعي'), findsOneWidget);
    expect(find.text('التخصص'), findsOneWidget);
    expect(find.text('سنوات الخبرة'), findsOneWidget);
  });

  testWidgets('create request page shows loading state', (tester) async {
    await tester.pumpWidget(
      const TestApp(
        child: CreateRequestPage(
          profile: {
            'governorate': 'القاهرة',
            'area': 'مدينة نصر',
            'address': 'شارع رئيسي',
          },
        ),
      ),
    );

    expect(find.text('إنشاء طلب خدمة'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('worker home page shows available requests loading state', (
    tester,
  ) async {
    await tester.pumpWidget(
      TestApp(
        child: WorkerHomePage(
          profile: const {
            'full_name': 'أحمد الفني',
            'governorate': 'القاهرة',
            'area': 'مدينة نصر',
          },
          onSignOut: () async {},
        ),
      ),
    );

    expect(find.text('طلبات متاحة'), findsOneWidget);
    expect(find.text('طلباتي المقبولة'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
  });

  testWidgets('send offer page shows offer form fields', (tester) async {
    await tester.pumpWidget(
      TestApp(
        child: SendOfferPage(
          request: AvailableWorkerRequest(
            id: 'request-1',
            serviceName: 'تسليك صرف',
            categoryName: 'سباكة',
            priceRange: '150 - 300 جنيه',
            description: 'الحوض مسدود',
            area: 'مدينة نصر',
            address: 'شارع رئيسي',
            preferredTime: 'اليوم مساءً',
            status: 'new',
            createdAt: DateTime(2026, 6, 20),
          ),
        ),
      ),
    );

    expect(find.text('إرسال عرض سعر'), findsOneWidget);
    expect(find.text('السعر النهائي بالجنيه'), findsOneWidget);
    expect(find.text('وقت الوصول المتوقع'), findsOneWidget);
  });

  testWidgets('request details page shows loading state', (tester) async {
    await tester.pumpWidget(
      const TestApp(child: RequestDetailsPage(requestId: 'request-1')),
    );

    expect(find.text('تفاصيل الطلب'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('pending offer card shows accept button', (tester) async {
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: OfferCard(
            offer: ServiceOffer(
              id: 'offer-1',
              workerId: 'worker-1',
              workerName: 'أحمد الفني',
              workerPhone: '01000000000',
              price: 250,
              arrivalTime: 'خلال ساعة',
              note: 'السعر شامل المعاينة',
              status: 'pending',
              createdAt: DateTime(2026, 6, 20),
              averageRating: 4.6,
              reviewCount: 12,
            ),
            requestStatus: 'offered',
            isAccepting: false,
            onAccept: () {},
            onOpenWorkerDetails: () {},
          ),
        ),
      ),
    );

    expect(find.text('قبول العرض'), findsOneWidget);
    expect(find.text('بانتظار ردك'), findsOneWidget);
    expect(find.text('4.6 من 5'), findsOneWidget);
    expect(find.text('(12 تقييم)'), findsOneWidget);
    expect(find.text('تفاصيل الصنايعي'), findsOneWidget);
  });

  testWidgets('worker public details header shows rating', (tester) async {
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: WorkerHeaderCard(
            details: WorkerPublicDetails(
              workerId: 'worker-1',
              fullName: 'أحمد الفني',
              governorate: 'القاهرة',
              area: 'مدينة نصر',
              profession: 'سباك',
              yearsExperience: 8,
              bio: 'خبرة في السباكة المنزلية',
              averageRating: 4.8,
              reviewCount: 20,
              reviews: const [],
            ),
          ),
        ),
      ),
    );

    expect(find.text('أحمد الفني'), findsOneWidget);
    expect(find.text('4.8 من 5 (20 تقييم)'), findsOneWidget);
  });

  testWidgets('in progress request shows completion action', (tester) async {
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: CompletionActionCard(
            status: 'in_progress',
            isCompleting: false,
            onComplete: () {},
          ),
        ),
      ),
    );

    expect(find.text('تأكيد إتمام الخدمة'), findsOneWidget);
    expect(
      find.text('لو الخدمة خلصت تمام، أكد الإتمام من هنا.'),
      findsOneWidget,
    );
  });

  testWidgets('completed request shows review form', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: ReviewActionCard(
            status: 'completed',
            review: null,
            selectedRating: 5,
            commentController: controller,
            isSubmitting: false,
            onRatingChanged: (_) {},
            onSubmit: () {},
          ),
        ),
      ),
    );

    expect(find.text('قيّم الخدمة'), findsOneWidget);
    expect(find.text('إرسال التقييم'), findsOneWidget);
  });

  testWidgets('accepted worker request card shows customer details', (
    tester,
  ) async {
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: AcceptedRequestCard(
            request: AcceptedWorkerRequest(
              id: 'request-1',
              serviceName: 'تركيب خلاط',
              categoryName: 'سباك',
              description: 'محتاج تركيب خلاط جديد',
              governorate: 'القاهرة',
              area: 'مدينة نصر',
              address: 'شارع رئيسي',
              preferredTime: 'بكرة صباحًا',
              status: 'accepted',
              customerName: 'محمد العميل',
              customerPhone: '01000000000',
              customerAddress: 'عنوان العميل',
              acceptedPrice: 300,
              arrivalTime: 'خلال ساعة',
              createdAt: DateTime(2026, 6, 20),
              review: ServiceReview(
                id: 'review-1',
                rating: 5,
                comment: 'شغل ممتاز',
                createdAt: DateTime(2026, 6, 20),
              ),
            ),
            isStarting: false,
            onStartWork: () {},
          ),
        ),
      ),
    );

    expect(find.text('بيانات العميل'), findsOneWidget);
    expect(find.text('محمد العميل'), findsOneWidget);
    expect(find.text('01000000000'), findsOneWidget);
    expect(find.text('بدأت الشغل'), findsOneWidget);
    expect(find.text('تقييم العميل'), findsOneWidget);
    expect(find.text('شغل ممتاز'), findsOneWidget);
  });
}

class TestApp extends StatelessWidget {
  const TestApp({this.child = const RoleSelectionPage(), super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: child);
  }
}
