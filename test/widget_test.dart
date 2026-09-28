import 'package:flutter_test/flutter_test.dart';
import 'package:sylverscreen_scan/main.dart';

void main() {
  testWidgets('shows application name', (tester) async {
    await tester.pumpWidget(const SylverScreenScanApp());
    expect(find.text('Connexion agent'), findsOneWidget);
  });
}

