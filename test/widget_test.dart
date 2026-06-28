import 'package:flutter_test/flutter_test.dart';
import 'package:match3_game/main.dart'; // Senin projenin adı

void main() {
  testWidgets('Oyun başarıyla başlatılıyor mu testi', (WidgetTester tester) async {
    // Eski MyApp() yerine kendi ana sınıfımızı çağırıyoruz
    await tester.pumpWidget(const UzayMacerasiApp());

    // Uygulamanın çökmeden ekrana çizildiğini doğruluyoruz
    expect(find.byType(UzayMacerasiApp), findsOneWidget);
  });
}
