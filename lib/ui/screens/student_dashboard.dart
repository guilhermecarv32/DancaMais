import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    const Color primaryColor = AppTheme.primary;
    const Color darkColor = Color(0xFF6C2E21);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: StreamBuilder<DocumentSnapshot>(
        // Escuta os dados do aluno no Firestore em tempo real
        stream: FirebaseFirestore.instance.collection('usuarios').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Erro ao carregar progresso."));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final String nome = userData['nome'] ?? "Aluno";
          final int nivel = userData['nivel'] ?? 1;
          final int xp = userData['xp'] ?? 0;
          final List conquistas = userData['conquistas'] ?? [];

          // Cálculo para o progresso circular (supondo 100 XP por nível)
          double progresso = (xp % 100) / 100;

          return Stack(
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
                    // HEADER: Saudação e Logout
                    _buildHeader(nome.split(' ')[0], darkColor, context),

                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 25),
                        children: [
                          const SizedBox(height: 20),

                          // SEÇÃO DE PROGRESSO (Gamificação Dinâmica)
                          _buildXPProgress(nivel, xp, progresso, primaryColor, darkColor),

                          const SizedBox(height: 40),

                          // SEÇÃO: CONQUISTAS (Medalhas Reais do Firestore)
                          _buildSectionHeader("Suas Conquistas", darkColor),
                          const SizedBox(height: 15),
                          conquistas.isEmpty 
                            ? _buildEmptyConquests() 
                            : _buildMedalsGrid(conquistas),

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
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(primaryColor),
    );
  }

  // --- COMPONENTES ---

  Widget _buildHeader(String firstName, Color color, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Olá, $firstName", 
                style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1)),
              const Text("Vamos dançar?", style: TextStyle(color: Colors.grey, fontSize: 18)),
            ],
          ),
          // Botão de Sair para trocar de conta
          GestureDetector(
            onTap: () => _showLogoutDialog(context),
            child: CircleAvatar(
              radius: 25,
              backgroundColor: AppTheme.primary.withOpacity(0.1),
              child: const Icon(Icons.logout_rounded, color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sair"),
        content: const Text("Deseja voltar para a tela de login?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut(); // O AuthWrapper detecta o nulo e redireciona
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Sair", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildXPProgress(int nivel, int xp, double progresso, Color primary, Color dark) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: progresso == 0 ? 0.05 : progresso, // Garante que a borda apareça mesmo com 0 XP
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[200],
                  color: primary,
                ),
              ),
              Text("$nivel", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(width: 25),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Nível $nivel", style: TextStyle(color: dark, fontSize: 22, fontWeight: FontWeight.bold)),
                Text("$xp / 100 XP", style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text("Quase lá para o próximo nível!", style: TextStyle(fontSize: 12, color: AppTheme.primary)),
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

  Widget _buildEmptyConquests() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Text("Você ainda não tem medalhas. Participe das aulas para ganhar!", 
        style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
    );
  }

  Widget _buildMedalsGrid(List conquistas) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: conquistas.length,
        itemBuilder: (context, index) {
          return _buildMedalIcon(conquistas[index], Icons.emoji_events, Colors.amber);
        },
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
          Text(label, textAlign: TextAlign.center, 
            maxLines: 2, 
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, overflow: TextOverflow.ellipsis)),
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