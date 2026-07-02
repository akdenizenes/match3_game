import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/screens/start_screen.dart'; 

void main() {
  // Initialize Flutter bindings and lock device orientation to portrait for optimal UX.
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
      // Hides the debug banner.
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        // Applies a dark theme fitting the space atmosphere.
        brightness: Brightness.dark, 
        // Deep space background color.
        scaffoldBackgroundColor: const Color(0xFF03030F), 
        // Neon blue accent color.
        primaryColor: const Color(0xFF00FFFF), 
        useMaterial3: true,
      ),
      // Entry point: StartScreen.
      home: const StartScreen(), 
    );
  }
}