import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class TeacherDashboard extends StatelessWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final Color primaryColor = AppTheme.primary;
    // Usando a cor secundária (marrom) para os textos de destaque
    const Color darkColor = AppTheme.secondary; 

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final String nomeCompleto = userData['nome'] ?? "Professor";
          // Lógica do primeiro nome que combinamos
          final String primeiroNome = nomeCompleto.trim().split(' ').first;

          return Column(
            children: [
              // 1. NOVO CABEÇALHO: CLEAN COM DESTAQUE LATERAL
              _buildSidebarHeader(primeiroNome, primaryColor, darkColor, context),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                  children: [
                    // 2. HERO CARD
                    _buildHeroCard("Próxima Aula", "Forró Iniciante", "18:00", primaryColor),

                    const SizedBox(height: 35),

                    // 3. AÇÕES RÁPIDAS
                    const Text(
                      "O que vamos fazer?",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildQuickAction(Icons.checklist_rtl_rounded, "Presença", Colors.blue),
                        _buildQuickAction(Icons.stars_rounded, "Dar XP", Colors.amber),
                        _buildQuickAction(Icons.chat_bubble_rounded, "Avisos", Colors.purple),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // 4. ALUNOS RECENTES (Ex: Guilherme)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Alunos Recentes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(onPressed: () {}, child: const Text("Ver todos")),
                      ],
                    ),
                    _buildRecentStudent("Guilherme Carvalho", "Nível 1", "0 XP"),
                    _buildRecentStudent("Ana Silva", "Nível 3", "240 XP"),
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

  // --- O NOVO COMPONENTE DE CABEÇALHO ---

  Widget _buildSidebarHeader(String name, Color primary, Color dark, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(25, 70, 25, 30),
      decoration: BoxDecoration(
        color: AppTheme.background, // Fundo limpo sem fade
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.05), width: 1),
        ),
      ),
      child: Row(
        children: [
          // BARRA LATERAL DE DESTAQUE (Substitui o Fade)
          Container(
            width: 5,
            height: 50,
            decoration: BoxDecoration(
              color: primary,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Olá, $name!",
                  style: TextStyle(color: dark, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -1),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Data mantida para o dia do projeto
                const Text(
                  "Terça-feira, 3 de Março de 2026",
                  style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: Icon(Icons.logout_rounded, color: Colors.grey[400], size: 22),
          ),
        ],
      ),
    );
  }

  // --- RESTANTE DOS WIDGETS (HeroCard, QuickAction, RecentStudent) ---
  // (Mantenha os métodos conforme as versões anteriores que você gostou)

  Widget _buildHeroCard(String label, String title, String time, Color color) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          Text(time, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 70, height: 70,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 15)],
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildRecentStudent(String name, String level, String xp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: Colors.grey[100], child: const Icon(Icons.person, color: Colors.grey)),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text("$level • $xp", style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildBottomNav(Color color) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: color,
      unselectedItemColor: Colors.grey[300],
      showSelectedLabels: false,
      elevation: 0,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: ""),
        BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: ""),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle_rounded, size: 40), label: ""),
        BottomNavigationBarItem(icon: Icon(Icons.message_rounded), label: ""),
        BottomNavigationBarItem(icon: Icon(Icons.settings_rounded), label: ""),
      ],
    );
  }
}