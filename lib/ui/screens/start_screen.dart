import 'package:flutter/material.dart';
import 'game_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF03030F),
          image: DecorationImage(
            // YENİ: Senin seçtiğin yerel görseli ekledik
            image: const AssetImage('assets/images/images.jpg'),
            fit: BoxFit.cover,
            // Resmi hafif karartarak öndeki yazının ve butonun ön plana çıkmasını sağlıyoruz
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.6), 
              BlendMode.darken,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 3),
            
            // Neon Parlama Efektli MATCH 3 Başlığı
            Text(
              'MATCH 3',
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 6,
                shadows: [
                  Shadow(
                    color: const Color(0xFFB14DFF).withOpacity(0.8), // Mor parlama
                    blurRadius: 30,
                  ),
                  Shadow(
                    color: const Color(0xFF00FFFF).withOpacity(0.8), // Mavi parlama
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            
            const Spacer(flex: 2),

            // Şık, Gölgeli Başla Butonu
            GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const GameScreen()), 
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00FFFF), Color(0xFFB14DFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFB14DFF).withOpacity(0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Text(
                  'BÖLÜME BAŞLA',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            
            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}