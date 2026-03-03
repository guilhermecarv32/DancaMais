import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = AppTheme.primary;
    const Color darkColor = Color(0xFF6C2E21);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // 1. FORMAS DECORATIVAS (Identidade Visual)
          Positioned(
            top: -60,
            left: -80,
            child: _buildDecorShape(color: primaryColor, opacity: 0.05, size: 280),
          ),

          // 2. CONTEÚDO
          SafeArea(
            child: Column(
              children: [
                // HEADER: Saudação ao Aluno
                _buildHeader("Guilherme!", darkColor),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    children: [
                      const SizedBox(height: 30),

                      // SEÇÃO DE PROGRESSO (Gamificação Central)
                      _buildXPProgress(primaryColor, darkColor),

                      const SizedBox(height: 40),

                      // SEÇÃO: CONQUISTAS (Medalhas)
                      _buildSectionHeader("Suas Conquistas", darkColor),
                      const SizedBox(height: 15),
                      _buildMedalsGrid(),

                      const SizedBox(height: 30),

                      // SEÇÃO: PRÓXIMAS AULAS
                      _buildSectionHeader("Próximos Passos", darkColor),
                      const SizedBox(height: 15),
                      _buildLessonCard("Giro Simples", "Forró", "Hoje, 18:00", primaryColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(primaryColor),
    );
  }

  // --- COMPONENTES ---

  Widget _buildHeader(String name, Color color) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Olá, $name", 
                style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1)),
              const Text("Vamos dançar?", style: TextStyle(color: Colors.grey, fontSize: 18)),
            ],
          ),
          const CircleAvatar(
            radius: 25,
            backgroundColor: AppTheme.primary,
            child: Icon(Icons.person, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildXPProgress(Color primary, Color dark) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Row(
        children: [
          // Gráfico Circular de XP
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: 0.1, // Representando o início da jornada (XP 0)
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[200],
                  color: primary,
                ),
              ),
              const Text("1", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 25),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Nível 1", style: TextStyle(color: dark, fontSize: 22, fontWeight: FontWeight.bold)),
                const Text("0 / 100 XP", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text("Faltam 100 XP para o Nível 2!", style: TextStyle(fontSize: 12, color: AppTheme.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color));
  }

  Widget _buildMedalsGrid() {
    // Lista de conquistas (atualmente vazia no Firestore)
    return SizedBox(
      height: 100,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildMedalIcon("Iniciante", Icons.auto_awesome, Colors.amber),
          _buildMedalIcon("Ritmo", Icons.music_note, Colors.blue),
          _buildMedalIcon("Primeiro Passo", Icons.directions_walk, Colors.green),
        ],
      ),
    );
  }

  Widget _buildMedalIcon(String label, IconData icon, Color color) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 15),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 5),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildLessonCard(String title, String style, String date, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
            child: Icon(Icons.play_circle_fill, color: color),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("$style • $date", style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(Color color) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: color,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: "Início"),
        BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), label: "Ranking"),
        BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: "Aulas"),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Perfil"),
      ],
    );
  }

  Widget _buildDecorShape({required Color color, required double opacity, required double size}) {
    return Opacity(
      opacity: opacity,
      child: Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    );
  }
}