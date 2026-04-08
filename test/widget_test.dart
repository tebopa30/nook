import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nook/main.dart';

void main() {
  testWidgets('Nook app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: NookApp()));

    // Verify that the initial screen (SplashScreen) is shown.
    expect(find.text('Nook'), findsOneWidget);
    expect(find.text('想いを包む、デジタル文房具'), findsOneWidget);

    // Wait for the splash screen timer to finish
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
