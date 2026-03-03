import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = AppTheme.primary;
    const Color darkColor = Color(0xFF6C2E21);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // 1. FORMAS DECORATIVAS (Mantendo a identidade das telas anteriores)
          Positioned(
            top: -50,
            right: -100,
            child: _buildDecorShape(color: primaryColor, opacity: 0.05, size: 250),
          ),

          // 2. CONTEÚDO PRINCIPAL
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER CUSTOMIZADO
                _buildHeader(darkColor),

                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    children: [
                      // SEÇÃO: ENGAJAMENTO
                      _buildSectionTitle("Engajamento", darkColor),
                      const SizedBox(height: 15),
                      SizedBox(
                        height: 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildEngagementCard(
                              "Aluno subiu para o nível 5!",
                              Icons.emoji_events_rounded,
                              primaryColor,
                            ),
                            _buildEngagementCard(
                              "12 alunos concluíram 'Giro Simples'",
                              Icons.school_rounded,
                              Colors.blueAccent,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // SEÇÃO: AULAS DE HOJE
                      _buildSectionTitle("Aulas de Hoje", darkColor),
                      const SizedBox(height: 15),
                      _buildClassCard(
                        "Forró pé-de-serra",
                        "Iniciante 1 e Iniciante 2",
                        "18:00",
                        primaryColor,
                      ),
                      _buildClassCard(
                        "Bachata",
                        "Geral",
                        "20:30",
                        darkColor,
                      ),

                      const SizedBox(height: 30),

                      // SEÇÃO: TURMAS
                      _buildSectionTitle("Turmas", darkColor),
                      const SizedBox(height: 15),
                      _buildTurmaCard(
                        "Forró pé-de-serra - Iniciante 1",
                        "Passo da Semana:",
                        "Definir Agora",
                        true,
                        primaryColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      // BOTTOM NAVIGATION conforme protótipo
      bottomNavigationBar: _buildBottomNav(primaryColor),
    );
  }

  // --- COMPONENTES DA INTERFACE ---

  Widget _buildHeader(Color color) {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(bottomRight: Radius.circular(40)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Olá, Professor!", 
                style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
              Text("Ter, 3 de Março de 2026", // Data atualizada para o contexto real
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16)),
            ],
          ),
          const Icon(Icons.notifications_active_outlined, color: Colors.white, size: 28),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(width: 5),
        const Icon(Icons.info_outline, size: 18, color: Colors.grey),
      ],
    );
  }

  Widget _buildEngagementCard(String text, IconData icon, Color color) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildClassCard(String title, String subtitle, String time, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(left: BorderSide(color: color, width: 5)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: Colors.grey)),
            ],
          ),
          Text(time, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildTurmaCard(String turma, String label, String btnText, bool isPending, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(turma, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: isPending ? color : Colors.white,
                foregroundColor: isPending ? Colors.white : color,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color)),
              ),
              child: Text(btnText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(Color color) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: color,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.style_outlined), label: "Cards"),
        BottomNavigationBarItem(icon: Icon(Icons.school_outlined), label: "Aulas"),
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