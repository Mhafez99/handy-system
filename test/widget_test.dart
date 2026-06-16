import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handy_app/features/auth/domain/account_role.dart';
import 'package:handy_app/features/auth/presentation/registration_page.dart';
import 'package:handy_app/features/onboarding/presentation/role_selection_page.dart';

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
}

class TestApp extends StatelessWidget {
  const TestApp({this.child = const RoleSelectionPage(), super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: child);
  }
}
