import 'package:flutter_test/flutter_test.dart';
import 'package:handy_app/app/app.dart';

void main() {
  testWidgets('customer can select a role and continue', (tester) async {
    await tester.pumpWidget(const HandyApp());

    expect(find.text('أنا عميل'), findsOneWidget);
    expect(find.text('أنا صنايعي'), findsOneWidget);

    await tester.tap(find.text('أنا عميل'));
    await tester.pump();
    await tester.tap(find.text('متابعة'));
    await tester.pumpAndSettle();

    expect(find.text('حساب العميل'), findsOneWidget);
  });
}
