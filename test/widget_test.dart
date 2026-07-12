import 'package:flutter_test/flutter_test.dart';
import 'package:match3_game/main.dart';

void main() {
  testWidgets('app launches successfully', (WidgetTester tester) async {
    // Pump our own root widget instead of the default MyApp().
    await tester.pumpWidget(const UzayMacerasiApp());

    // Verify the app renders on screen without crashing.
    expect(find.byType(UzayMacerasiApp), findsOneWidget);
  });
}