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
          // Background image asset.
          image: DecorationImage(
            image: const AssetImage('assets/images/images.jpg'),
            fit: BoxFit.cover,
            // Apply a dark overlay to ensure text readability and pop.
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
            
            // Neon glow effect for the title.
            Text(
              'MATCH 3',
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 6,
                shadows: [
                  Shadow(
                    color: const Color(0xFFB14DFF).withOpacity(0.8), // Purple glow.
                    blurRadius: 30,
                  ),
                  Shadow(
                    color: const Color(0xFF00FFFF).withOpacity(0.8), // Blue glow.
                    blurRadius: 10,
                  ),
                ],
              ),
            ),
            
            const Spacer(flex: 2),

            // Start button with gradient and shadow.
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