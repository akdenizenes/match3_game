import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_screen.dart';
import 'how_to_play_screen.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  int _currentLevel = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLevelData();
  }

  // Fetches the saved level from device storage
  Future<void> _loadLevelData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLevel = prefs.getInt('current_level') ?? 1;
      _isLoading = false;
    });
  }

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
        child: Stack(
          children: [
            // ---- Column artık Positioned.fill ile TAM GENİŞLİK alıyor ----
            // Böylece crossAxisAlignment.center (varsayılan) tekrar ortalıyor.
            Positioned.fill(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  Text(
                    'MATCH 3',
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 6,
                      shadows: [
                        Shadow(
                          color: const Color(0xFFB14DFF).withOpacity(0.8),
                          blurRadius: 30,
                        ),
                        Shadow(
                          color: const Color(0xFF00FFFF).withOpacity(0.8),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 2),
                  GestureDetector(
                    onTap: () {
                      if (_isLoading) return;
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const GameScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 48, vertical: 18),
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
                      child: Text(
                        _isLoading ? 'LOADING...' : 'PLAY LEVEL $_currentLevel',
                        style: const TextStyle(
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

            // ---- sağ üstte "?" bilgi butonu ----
           // ---- sağ üstte "?" bilgi butonu (garanti görünür) ----
            Positioned(
              top: 8,
              right: 8,
              child: SafeArea(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.35),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.7),
                      width: 1.5,
                    ),
                  ),
                  child: IconButton(
                    iconSize: 30,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.help_outline, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HowToPlayScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}