import 'package:flutter/material.dart';
import '../widgets/glass_container.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1C1C28), Color(0xFF232334), Color(0xFF2A2A3E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Title + back
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 12, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new,
                          color: Colors.white.withOpacity(0.85)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "NASIL OYNANIR",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    // ---------------- OBJECTIVE ----------------
                    _section(
                      title: "AMAÇ",
                      subtitle: "Hamlelerin bitmeden bölümün hedefini tamamla.",
                      items: [
                        _item(
                          icon: Icons.palette,
                          color: const Color(0xFFB14DFF),
                          title: "Renk Topla",
                          desc:
                              "Üstteki çubukta gösterilen renklerden yeterince eşleştir. Sayaç dolunca ✓ olur.",
                        ),
                        _item(
                          icon: Icons.grid_view_rounded,
                          color: const Color(0xFF8D6E4A),
                          title: "Engelleri Temizle",
                          desc:
                              "\"KALAN ENGEL\" sayısını sıfıra indir. Her engelin kırılma yolu farklı (aşağı bak).",
                        ),
                        _item(
                          icon: Icons.emoji_events,
                          color: const Color(0xFFFFB74D),
                          title: "Hedef Skor",
                          desc:
                              "Bazı bölümlerde belirli bir skora ulaşman gerekir.",
                        ),
                      ],
                    ),

                    // ---------------- OBSTACLES ----------------
                    _section(
                      title: "ENGELLER",
                      subtitle: "Her biri farklı şekilde kırılır — karıştırma!",
                      items: [
                        _item(
                          icon: Icons.inventory_2,
                          color: const Color(0xFF8D6E4A),
                          title: "Kutu",
                          desc:
                              "SADECE yanında eşleşme yapınca kırılır. Roket/bomba patlamaları işlemez.",
                        ),
                        _item(
                          icon: Icons.dashboard,
                          color: const Color(0xFF90A4AE),
                          title: "Taş Blok",
                          desc:
                              "İki katmanlı ve serttir. Hem komşu eşleşme hem de patlamalarla kırılır.",
                        ),
                        _item(
                          icon: Icons.ac_unit,
                          color: const Color(0xFF4FC3F7),
                          title: "Buz",
                          desc:
                              "Taşın üstünde durur, taşı kilitlemez. Her tür hasar bir katman kırar.",
                        ),
                        _item(
                          icon: Icons.hexagon,
                          color: const Color(0xFFFFC107),
                          title: "Bal",
                          desc:
                              "Altındaki taşı KİLİTLER — orada eşleşme yapamazsın. Komşu eşleşme veya patlamayla kır.",
                        ),
                        _item(
                          icon: Icons.blur_on,
                          color: const Color(0xFFEC407A),
                          title: "Jöle",
                          desc:
                              "Taşın altında saklıdır. Üstündeki taşı eşleştirince silinir.",
                        ),
                      ],
                    ),

                    // ---------------- POWER-UPS ----------------
                    _section(
                      title: "GÜÇLENDİRİCİLER",
                      subtitle: "Alttaki çubuktan seç, sonra tahtada kullan.",
                      items: [
                        _item(
                          icon: Icons.gavel,
                          color: Colors.brown,
                          title: "Çekiç",
                          desc:
                              "Seçtiğin TEK bir kareyi yok eder. Kutu, taş, bal — hepsini kırar.",
                        ),
                        _item(
                          icon: Icons.arrow_forward,
                          color: Colors.blue,
                          title: "Ok (Yatay)",
                          desc: "Seçtiğin taşın bütün SATIRINI süpürür.",
                        ),
                        _item(
                          icon: Icons.swap_vert,
                          color: Colors.red,
                          title: "Top (Dikey)",
                          desc: "Seçtiğin taşın bütün SÜTUNUNU süpürür.",
                        ),
                        _item(
                          icon: Icons.face,
                          color: Colors.purple,
                          title: "Şapka",
                          desc:
                              "Serbest taşları karıştırır. Hamle kalmadığında can kurtarır (kilitli taşlar yerinde kalır).",
                        ),
                      ],
                    ),

                    // ---------------- TIP ----------------
                    _tip(
                      "Ok ve Top patlamayla çalışır — kutuları KIRAMAZ! "
                      "Kutular sadece yanlarında yapılan eşleşmeyle ya da çekiçle kırılır.",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- helper components ----

  Widget _section({
    required String title,
    required String subtitle,
    required List<Widget> items,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF4DB6AC),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Colors.white.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 12),
              ...items,
            ],
          ),
        ),
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required Color color,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.22),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tip(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFB74D).withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFB74D).withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb, color: Color(0xFFFFB74D), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}