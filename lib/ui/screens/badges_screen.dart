import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class BadgeItem {
  final String name;
  final String description;
  final int xpReward;
  final IconData icon;
  final Color color;

  const BadgeItem({
    required this.name,
    required this.description,
    required this.xpReward,
    required this.icon,
    required this.color,
  });
}

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color darkColor = AppTheme.secondary;
    final Color primaryColor = AppTheme.primary;

    // Lista de Badges Mockadas
    final List<BadgeItem> _badges = [
      BadgeItem(name: "Rei do Giro", description: "Completou 10 giros sem perder o eixo.", xpReward: 50, icon: Icons.cached_rounded, color: Colors.orange),
      BadgeItem(name: "Ritmo Perfeito", description: "Manteve a cadência durante toda a música.", xpReward: 30, icon: Icons.music_note_rounded, color: Colors.blue),
      BadgeItem(name: "Primeiros Passos", description: "Concluiu sua primeira aula experimental.", xpReward: 100, icon: Icons.auto_awesome_rounded, color: Colors.purple),
      BadgeItem(name: "Dançarino Assíduo", description: "Frequência 100% no último mês.", xpReward: 80, icon: Icons.calendar_today_rounded, color: Colors.green),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text("Conquistas & Badges", style: TextStyle(color: darkColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {}, // Lógica para cadastrar nova badge
            icon: Icon(Icons.add_moderator_rounded, color: primaryColor, size: 28),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 colunas para medalhas
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 0.85,
        ),
        itemCount: _badges.length,
        itemBuilder: (context, index) {
          return _buildBadgeCard(_badges[index], darkColor);
        },
      ),
    );
  }

  Widget _buildBadgeCard(BadgeItem badge, Color dark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: badge.color.withOpacity(0.15),
            child: Icon(badge.icon, color: badge.color, size: 30),
          ),
          const SizedBox(height: 12),
          Text(badge.name, 
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: dark),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text("${badge.xpReward} XP", 
            style: TextStyle(color: badge.color, fontWeight: FontWeight.w800, fontSize: 12)
          ),
          const SizedBox(height: 8),
          Text(badge.description, 
            style: const TextStyle(color: Colors.grey, fontSize: 10),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}