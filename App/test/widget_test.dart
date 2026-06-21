import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handy_app/features/areas/domain/area.dart';
import 'package:handy_app/features/auth/domain/account_role.dart';
import 'package:handy_app/features/auth/presentation/forgot_password_page.dart';
import 'package:handy_app/features/auth/presentation/login_page.dart';
import 'package:handy_app/features/auth/presentation/profile_page.dart';
import 'package:handy_app/features/auth/presentation/registration_page.dart';
import 'package:handy_app/features/offers/domain/service_offer.dart';
import 'package:handy_app/features/offers/presentation/send_offer_page.dart';
import 'package:handy_app/features/onboarding/presentation/role_selection_page.dart';
import 'package:handy_app/features/requests/domain/accepted_worker_request.dart';
import 'package:handy_app/features/requests/domain/available_worker_request.dart';
import 'package:handy_app/features/requests/domain/customer_request.dart';
import 'package:handy_app/features/requests/presentation/create_request_page.dart';
import 'package:handy_app/features/customer/presentation/customer_requests_page.dart';
import 'package:handy_app/features/complaints/domain/service_complaint.dart';
import 'package:handy_app/features/requests/presentation/payment_summary_widgets.dart';
import 'package:handy_app/features/requests/presentation/request_details_page.dart';
import 'package:handy_app/features/requests/presentation/request_image_widgets.dart';
import 'package:handy_app/features/reviews/domain/service_review.dart';
import 'package:handy_app/features/worker/domain/worker_public_details.dart';
import 'package:handy_app/features/worker/presentation/worker_details_page.dart';
import 'package:handy_app/features/worker/presentation/worker_history_page.dart';
import 'package:handy_app/features/worker/presentation/worker_home_page.dart';

void main() {
  testWidgets('area model parses json', (tester) async {
    final area = Area.fromJson({
      'id': 1,
      'governorate': 'القاهرة',
      'name': 'مدينة نصر',
    });

    expect(area.id, 1);
    expect(area.governorate, 'القاهرة');
    expect(area.name, 'مدينة نصر');
  });

  testWidgets('login page shows forgot password link', (tester) async {
    await tester.pumpWidget(const TestApp(child: LoginPage()));

    expect(find.text('نسيت كلمة المرور؟'), findsOneWidget);
  });

  testWidgets('forgot password page shows email form', (tester) async {
    await tester.pumpWidget(const TestApp(child: ForgotPasswordPage()));

    expect(find.text('استعادة كلمة المرور'), findsOneWidget);
    expect(find.text('إرسال رابط الاستعادة'), findsOneWidget);
  });

  testWidgets('profile page shows loading state', (tester) async {
    await tester.pumpWidget(const TestApp(child: ProfilePage()));

    expect(find.text('الملف الشخصي'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

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

  testWidgets('request image gallery shows empty message', (tester) async {
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: RequestImagesGallery(images: const []),
        ),
      ),
    );

    expect(find.text('لا توجد صور مرفقة.'), findsOneWidget);
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
          availableRequestsFuture: Future.value([]),
          activeRequestsFuture: Future.value([]),
          onReload: () {},
        ),
      ),
    );

    expect(find.text('طلباتي المقبولة'), findsOneWidget);
    expect(find.text('الطلبات المتاحة'), findsOneWidget);
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

  testWidgets('new request shows cancel action', (tester) async {
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: CancelActionCard(
            status: 'new',
            isCancelling: false,
            onCancel: () {},
          ),
        ),
      ),
    );

    expect(find.text('إلغاء الطلب'), findsOneWidget);
    expect(
      find.text('لو مش محتاج الخدمة دلوقتي، تقدر تلغي الطلب من هنا.'),
      findsOneWidget,
    );
  });

  testWidgets('offered request shows cancel action', (tester) async {
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: CancelActionCard(
            status: 'offered',
            isCancelling: false,
            onCancel: () {},
          ),
        ),
      ),
    );

    expect(find.text('إلغاء الطلب'), findsOneWidget);
  });

  testWidgets('cancelled request shows cancelled message', (tester) async {
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: CancelActionCard(
            status: 'cancelled',
            isCancelling: false,
            onCancel: () {},
          ),
        ),
      ),
    );

    expect(find.text('تم إلغاء هذا الطلب.'), findsOneWidget);
    expect(find.text('إلغاء الطلب'), findsNothing);
  });

  testWidgets('accepted request hides cancel action', (tester) async {
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: CancelActionCard(
            status: 'accepted',
            isCancelling: false,
            onCancel: () {},
          ),
        ),
      ),
    );

    expect(find.text('إلغاء الطلب'), findsNothing);
    expect(find.text('تم إلغاء هذا الطلب.'), findsNothing);
  });

  testWidgets('in progress request shows completion code', (tester) async {
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: CompletionCodeCard(
            status: 'in_progress',
            completionCode: '123456',
          ),
        ),
      ),
    );

    expect(find.text('123456'), findsOneWidget);
    expect(
      find.text(
        'بعد ما الشغل يخلص، ادّي الكود ده للصنايعي عشان يأكد الإتمام.',
      ),
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

  testWidgets('on the way request shows start work action', (tester) async {
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
              status: 'on_the_way',
              customerName: 'محمد العميل',
              customerPhone: '01000000000',
              customerAddress: 'عنوان العميل',
              acceptedPrice: 300,
              arrivalTime: 'خلال ساعة',
              createdAt: DateTime(2026, 6, 20),
              review: null,
            ),
            isMarkingOnTheWay: false,
            isStarting: false,
            isCompleting: false,
            onMarkOnTheWay: () {},
            onStartWork: () {},
            onCompleteWork: (code, price) {},
          ),
        ),
      ),
    );

    expect(find.widgetWithText(FilledButton, 'بدأت الشغل'), findsOneWidget);
  });

  testWidgets('on the way status card is visible for customer', (tester) async {
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: OnTheWayStatusCard(status: 'on_the_way'),
        ),
      ),
    );

    expect(find.text('الصنايعي في الطريق إليك.'), findsOneWidget);
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
            isMarkingOnTheWay: false,
            isCompleting: false,
            onMarkOnTheWay: () {},
            onStartWork: () {},
            onCompleteWork: (code, price) {},
          ),
        ),
      ),
    );

    expect(find.text('بيانات العميل'), findsOneWidget);
    expect(find.text('محمد العميل'), findsOneWidget);
    expect(find.text('01000000000'), findsOneWidget);
    expect(find.text('في الطريق'), findsOneWidget);
    expect(find.text('تقييم العميل'), findsOneWidget);
    expect(find.text('شغل ممتاز'), findsOneWidget);
  });

  testWidgets('completed payment summary shows final price and cash', (
    tester,
  ) async {
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: PaymentSummaryCard(
            status: 'completed',
            acceptedPrice: 300,
            finalPrice: 350,
            paymentMethod: 'cash',
          ),
        ),
      ),
    );

    expect(find.text('ملخص الدفع'), findsOneWidget);
    expect(find.text('350 جنيه'), findsOneWidget);
    expect(find.text('تم الدفع كاش'), findsOneWidget);
    expect(find.text('السعر المتفق عليه'), findsOneWidget);
  });

  testWidgets('pending payment summary shows agreed price and cash note', (
    tester,
  ) async {
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: PaymentSummaryCard(
            status: 'in_progress',
            acceptedPrice: 300,
          ),
        ),
      ),
    );

    expect(find.text('تفاصيل الدفع'), findsOneWidget);
    expect(find.text('300 جنيه'), findsOneWidget);
    expect(find.text('الدفع كاش عند إتمام الشغل'), findsOneWidget);
  });

  testWidgets('completed request shows complaint form', (tester) async {
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: ComplaintActionCard(
            status: 'completed',
            complaint: null,
            isSubmitting: false,
            onSubmit: (category, description) {},
          ),
        ),
      ),
    );

    expect(find.text('إرسال الشكوى'), findsOneWidget);
    expect(find.text('سبب الشكوى'), findsOneWidget);
  });

  testWidgets('submitted complaint shows complaint details', (tester) async {
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: ComplaintActionCard(
            status: 'complaint',
            complaint: ServiceComplaint(
              id: 'complaint-1',
              category: 'overcharge',
              description: 'الصنايعي طلب مبلغ أعلى من المتفق عليه.',
              status: 'open',
              createdAt: DateTime(2026, 6, 20),
            ),
            isSubmitting: false,
            onSubmit: (category, description) {},
          ),
        ),
      ),
    );

    expect(find.text('شكواك'), findsOneWidget);
    expect(find.textContaining('زيادة في السعر'), findsOneWidget);
    expect(find.textContaining('جديدة'), findsOneWidget);
  });

  testWidgets('customer requests page shows status tabs', (tester) async {
    final requests = Future.value([
      CustomerRequest(
        id: 'request-1',
        serviceName: 'تركيب خلاط',
        categoryName: 'سباك',
        area: 'مدينة نصر',
        status: 'completed',
        offerCount: 2,
        createdAt: DateTime(2026, 6, 20),
        finalPrice: 300,
        paymentMethod: 'cash',
      ),
      CustomerRequest(
        id: 'request-2',
        serviceName: 'تصليح كهرباء',
        categoryName: 'كهربائي',
        area: 'مدينة نصر',
        status: 'new',
        offerCount: 0,
        createdAt: DateTime(2026, 6, 19),
      ),
    ]);

    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: CustomerRequestsPage(
            requestsFuture: requests,
            onReload: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('سجل الطلبات'), findsOneWidget);
    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('نشطة'), findsOneWidget);
    expect(find.text('مكتملة'), findsOneWidget);
    expect(find.text('تركيب خلاط'), findsOneWidget);
    expect(find.text('تصليح كهرباء'), findsOneWidget);

    await tester.tap(find.text('مكتملة'));
    await tester.pumpAndSettle();

    expect(find.text('تركيب خلاط'), findsOneWidget);
    expect(find.text('تصليح كهرباء'), findsNothing);
  });

  testWidgets('worker history page shows review tabs', (tester) async {
    final requests = Future.value([
      AcceptedWorkerRequest(
        id: 'request-1',
        serviceName: 'تركيب خلاط',
        categoryName: 'سباك',
        description: 'محتاج تركيب خلاط',
        governorate: 'القاهرة',
        area: 'مدينة نصر',
        address: 'شارع 1',
        preferredTime: 'بكرة',
        status: 'completed',
        customerName: 'محمد',
        customerPhone: '01000000000',
        customerAddress: 'عنوان',
        acceptedPrice: 300,
        arrivalTime: 'ساعة',
        createdAt: DateTime(2026, 6, 20),
        review: ServiceReview(
          id: 'review-1',
          rating: 5,
          comment: 'شغل ممتاز',
          createdAt: DateTime(2026, 6, 20),
        ),
        finalPrice: 300,
        paymentMethod: 'cash',
      ),
      AcceptedWorkerRequest(
        id: 'request-2',
        serviceName: 'تصليح كهرباء',
        categoryName: 'كهربائي',
        description: 'عطل في الأسلاك',
        governorate: 'القاهرة',
        area: 'مدينة نصر',
        address: 'شارع 2',
        preferredTime: 'النهارده',
        status: 'completed',
        customerName: 'أحمد',
        customerPhone: '01000000001',
        customerAddress: 'عنوان 2',
        acceptedPrice: 200,
        arrivalTime: 'ساعتين',
        createdAt: DateTime(2026, 6, 19),
        review: null,
        finalPrice: 200,
        paymentMethod: 'cash',
      ),
    ]);

    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: WorkerHistoryPage(
            completedRequestsFuture: requests,
            onReload: () {},
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('سجل الأعمال'), findsOneWidget);
    expect(find.text('بها تقييم'), findsOneWidget);
    expect(find.text('تركيب خلاط'), findsOneWidget);

    await tester.tap(find.text('بها تقييم'));
    await tester.pumpAndSettle();

    expect(find.text('تركيب خلاط'), findsOneWidget);
    expect(find.text('شغل ممتاز'), findsOneWidget);

    await tester.tap(find.text('بدون تقييم'));
    await tester.pumpAndSettle();

    expect(find.text('تصليح كهرباء'), findsOneWidget);
    expect(find.text('العميل لم يقيّم الخدمة بعد.'), findsOneWidget);
  });

  testWidgets('in progress worker request shows completion form', (
    tester,
  ) async {
    await tester.pumpWidget(
      TestApp(
        child: Scaffold(
          body: SingleChildScrollView(
            child: AcceptedRequestCard(
              request: AcceptedWorkerRequest(
                id: 'request-1',
                serviceName: 'تركيب خلاط',
                categoryName: 'سباك',
                description: 'محتاج تركيب خلاط جديد',
                governorate: 'القاهرة',
                area: 'مدينة نصر',
                address: 'شارع رئيسي',
                preferredTime: 'بكرة صباحًا',
                status: 'in_progress',
                customerName: 'محمد العميل',
                customerPhone: '01000000000',
                customerAddress: 'عنوان العميل',
                acceptedPrice: 300,
                arrivalTime: 'خلال ساعة',
                createdAt: DateTime(2026, 6, 20),
                review: null,
              ),
              isMarkingOnTheWay: false,
              isStarting: false,
              isCompleting: false,
              onMarkOnTheWay: () {},
              onStartWork: () {},
              onCompleteWork: (code, price) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('تأكيد الإتمام'), findsOneWidget);
    expect(find.text('كود الإتمام'), findsOneWidget);
    expect(find.text('المبلغ المستلم كاش (جنيه)'), findsOneWidget);
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
