import 'package:flutter_test/flutter_test.dart';
import 'package:efbd/app.dart';

void main() {
  testWidgets('Smoke test - App builds', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Note: This might fail in a real CI environment because Firebase.initializeApp() is called in main.
    // In a real test, you'd mock Firebase or use a different entry point.
    // For now, we just ensure it references EFBDApp correctly.
    await tester.pumpWidget(EFBDApp());

    expect(find.byType(EFBDApp), findsOneWidget);
  });
}
