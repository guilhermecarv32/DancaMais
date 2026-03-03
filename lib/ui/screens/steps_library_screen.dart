import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StepItem {
  final String name;
  final String category;
  final String level;
  final IconData icon;

  const StepItem({required this.name, required this.category, required this.level, this.icon = Icons.directions_run_rounded});
}

class StepsLibraryScreen extends StatelessWidget {
  const StepsLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color darkColor = AppTheme.secondary;
    final Color primaryColor = AppTheme.primary;

    // Dados Mockados para a Biblioteca
    final List<StepItem> _steps = [
      const StepItem(name: "Manivela", category: "Forró", level: "Iniciante"),
      const StepItem(name: "Giro Simples", category: "Forró", level: "Iniciante"),
      const StepItem(name: "Romário", category: "Samba de Gafieira", level: "Intermediário"),
      const StepItem(name: "Gancho", category: "Samba de Gafieira", level: "Iniciante"),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text("Biblioteca de Passos", style: TextStyle(color: darkColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {}, // Lógica para adicionar novo passo
            icon: Icon(Icons.add_circle_outline_rounded, color: primaryColor, size: 28),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // Barra de Pesquisa
          Padding(
            padding: const EdgeInsets.all(20),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Pesquisar passo...",
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                final step = _steps[index];
                return _buildStepCard(step, darkColor, primaryColor);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(StepItem step, Color dark, Color primary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(step.icon, color: primary),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: dark)),
                Text("${step.category} • ${step.level}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[300]),
        ],
      ),
    );
  }
}