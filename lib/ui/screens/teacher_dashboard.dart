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
    const Color darkColor = AppTheme.secondary;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('usuarios').doc(user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final String nomeCompleto = userData['nome'] ?? "Professor";
          final String primeiroNome = nomeCompleto.trim().split(' ').first;

          return Column(
            children: [
              _buildSidebarHeader(primeiroNome, primaryColor, darkColor, context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  children: [
                    _buildAgendaSection(primaryColor, darkColor),
                    const SizedBox(height: 35),
                    _buildSectionHeader("Ações Rápidas", darkColor),
                    const SizedBox(height: 20),
                    _buildQuickActionsRow(),
                    const SizedBox(height: 40),
                    _buildTurmasSection(primaryColor, darkColor),
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

  Widget _buildSidebarHeader(String name, Color primary, Color dark, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(25, 70, 25, 30),
      child: Row(
        children: [
          Container(width: 5, height: 50, decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(10))),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Olá, $name!", style: TextStyle(color: dark, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -1)),
                const Text("Terça-feira, 3 de Março de 2026", style: TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
          IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: Icon(Icons.logout_rounded, color: Colors.grey[400])),
        ],
      ),
    );
  }

  // --- AGENDA COM EFEITO EMPILHADO ---
  Widget _buildAgendaSection(Color primary, Color dark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Agenda de Hoje", dark),
          const SizedBox(height: 15),
          _buildStackedCards(primary, dark),
        ],
      ),
    );
  }

  Widget _buildStackedCards(Color primary, Color dark) {
    const double heroHeight = 110.0;
    const double peekAmount = 28.0;

    final subcards = [
      {"title": "Samba de Gafieira", "level": "Intermediário", "time": "19:30"},
      {"title": "Zouk", "level": "Geral", "time": "21:00"},
    ];

    final double totalHeight = heroHeight + (subcards.length * peekAmount);

    return SizedBox(
      height: totalHeight,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Subcards embaixo (renderizados primeiro = atrás)
          for (int i = subcards.length - 1; i >= 0; i--)
            Positioned(
              top: heroHeight - 20 + ((i + 1) * peekAmount) - peekAmount,
              left: (i + 1) * 6.0,
              right: (i + 1) * 6.0,
              child: _buildSubClassCardStacked(
                subcards[i]["title"]!,
                subcards[i]["level"]!,
                subcards[i]["time"]!,
                dark,
              ),
            ),

          // Hero card por cima
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHeroCard("PRÓXIMA AULA", "Forró Iniciante", "18:00", primary),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(String label, String title, String time, Color color) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1)),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(15)),
            child: Text(time, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubClassCardStacked(String title, String level, String time, Color dark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Text(time, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: dark.withOpacity(0.5))),
          const SizedBox(width: 14),
          Container(width: 1, height: 16, color: Colors.grey.withOpacity(0.2)),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(level, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTurmasSection(Color primary, Color dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Row(
            children: [
              Text("Turmas", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: dark)),
              const Spacer(),
              Text("Ver Tudo >>", style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 175,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 25, right: 10),
            children: [
              _buildTurmaCard("Forró pé-de-serra", "Iniciante 1", "Definir Agora", true, primary, dark),
              _buildTurmaCard("Forró pé-de-serra", "Iniciante 2", "Manivela", false, primary, dark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTurmaCard(String t, String s, String b, bool p, Color pr, Color d) {
    return Container(
      width: 210,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: d)),
          Text(s, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: p ? pr : Colors.white,
                foregroundColor: p ? Colors.white : pr,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: pr)),
              ),
              child: Text(b, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color dark) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 25),
    child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: dark.withOpacity(0.8))),
  );

  Widget _buildQuickActionsRow() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 25),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem(Icons.checklist_rounded, "Presença", Colors.blue),
        _buildActionItem(Icons.stars_rounded, "Dar XP", Colors.amber),
        _buildActionItem(Icons.campaign_rounded, "Aviso", Colors.purple),
      ],
    ),
  );

  Widget _buildActionItem(IconData i, String l, Color c) => Column(
    children: [
      Container(width: 65, height: 65, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: Icon(i, color: c, size: 28)),
      const SizedBox(height: 8),
      Text(l, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    ],
  );

  Widget _buildBottomNav(Color c) => BottomNavigationBar(
    type: BottomNavigationBarType.fixed,
    selectedItemColor: c,
    unselectedItemColor: Colors.grey[300],
    showSelectedLabels: false,
    elevation: 0,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded, size: 28), label: ""),
      BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded, size: 28), label: ""),
      BottomNavigationBarItem(icon: Icon(Icons.add_circle_rounded, size: 40), label: ""),
      BottomNavigationBarItem(icon: Icon(Icons.message_rounded, size: 28), label: ""),
      BottomNavigationBarItem(icon: Icon(Icons.settings_rounded, size: 28), label: ""),
    ],
  );
}