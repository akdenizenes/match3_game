import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/screens/game_screen.dart';

void main() {
  // Flutter motorunu başlat ve oyunu dikey ekrana sabitle (mobilde en iyi deneyim için)
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  runApp(const UzayMacerasiApp());
}

class UzayMacerasiApp extends StatelessWidget {
  const UzayMacerasiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uzay Match-3',
      debugShowCheckedModeBanner: false, // Sağ üstteki o çirkin kırmızı "DEBUG" şeridini kaldırır
      theme: ThemeData(
        brightness: Brightness.dark, // Tüm projeyi uzay temasına uygun karanlık moda alır
        scaffoldBackgroundColor: const Color(0xFF03030F), // Derin uzay arka plan rengi
        primaryColor: const Color(0xFF00FFFF), // Neon mavi detay rengi
        useMaterial3: true,
      ),
      home: const GameScreen(), // Oyunu direkt olarak GameScreen'den başlatır
    );
  }
}