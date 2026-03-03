import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'steps_library_screen.dart';
import 'badges_screen.dart';

class AulaItem {
  final String label;
  final String title;
  final String time;
  final String? level;
  final bool isHero;
  const AulaItem({required this.title, required this.time, this.label = '', this.level, this.isHero = false});
}

// =============================================================
// AGENDA COM EFEITO 3D
// =============================================================
class AgendaStackedScroll extends StatefulWidget {
  final Color primary;
  final Color dark;
  const AgendaStackedScroll({super.key, required this.primary, required this.dark});

  @override
  State<AgendaStackedScroll> createState() => _AgendaStackedScrollState();
}

class _AgendaStackedScrollState extends State<AgendaStackedScroll> {
  final ScrollController _scrollController = ScrollController();
  final List<AulaItem> _aulas = const [
    AulaItem(label: "FORRÓ PÉ-DE-SERRA", title: "Iniciante 1", time: "18:00", isHero: true),
    AulaItem(title: "Samba de Gafieira", time: "19:30", level: "Intermediário"),
    AulaItem(title: "K-Pop", time: "21:00", level: "Geral"),
  ];

  static const double _heroHeight = 110.0;
  static const double _subHeight = 64.0;
  static const double _peekOffset = 20.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() => setState(() {}));
  }

  @override
  void dispose() { _scrollController.dispose(); super.dispose(); }

  double _getCardTop(int index) {
    double top = 0;
    for (int i = 0; i < index; i++) {
      top += _aulas[i].isHero ? _heroHeight : _subHeight;
      top += _peekOffset;
    }
    return top;
  }

  @override
  Widget build(BuildContext context) {
    final double scrollOffset = _scrollController.hasClients ? _scrollController.offset : 0;
    final double totalStackHeight = _getCardTop(_aulas.length - 1) + (_aulas.last.isHero ? _heroHeight : _subHeight);
    final double visibleHeight = _heroHeight + (_peekOffset * 2) + 32;

    return SizedBox(
      height: visibleHeight,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          height: totalStackHeight + 20,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = _aulas.length - 1; i >= 0; i--)
                _buildStackedCard(i, scrollOffset),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStackedCard(int index, double scrollOffset) {
    final aula = _aulas[index];
    final double naturalTop = _getCardTop(index);
    final double top = (naturalTop - scrollOffset).clamp(0.0, naturalTop);
    final double stackDepth = (index - (scrollOffset / (_subHeight + _peekOffset))).clamp(0.0, _aulas.length.toDouble());
    
    return Positioned(
      top: top, left: stackDepth * 7.0, right: stackDepth * 7.0,
      child: Transform.scale(
        scale: 1.0 - (stackDepth * 0.025).clamp(0.0, 0.07),
        alignment: Alignment.topCenter,
        child: Opacity(
          opacity: (1.0 - stackDepth * 0.08).clamp(0.75, 1.0),
          child: aula.isHero ? _buildHeroCard(aula) : _buildSubCard(aula, stackDepth),
        ),
      ),
    );
  }

  Widget _buildHeroCard(AulaItem aula) => Container(
    height: _heroHeight, padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
    decoration: BoxDecoration(
      color: widget.primary, borderRadius: BorderRadius.circular(28),
      boxShadow: [BoxShadow(color: widget.primary.withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8))],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(aula.label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            const SizedBox(height: 4),
            Text(aula.title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          ],
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(14)),
          child: Text(aula.time, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );

  Widget _buildSubCard(AulaItem aula, double depth) => Container(
    height: _subHeight, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(22),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      border: Border.all(color: Colors.grey.withOpacity(0.07)),
    ),
    child: Row(children: [
      Text(aula.time, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: widget.dark.withOpacity(0.45))),
      const SizedBox(width: 14),
      Expanded(child: Column(
        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(aula.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
          if (aula.level != null) Text(aula.level!, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      )),
    ]),
  );
}

// =============================================================
// DASHBOARD PRINCIPAL
// =============================================================
class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 2;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final Color primaryColor = AppTheme.primary;
    const Color darkColor = AppTheme.secondary;

    final List<Widget> _screens = [
      const Center(child: Text("Minhas Turmas")),
      const StepsLibraryScreen(),
      _buildHomeScreen(user, primaryColor, darkColor),
      const BadgesScreen(),
      const Center(child: Text("Perfil")),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          _screens[_selectedIndex],
          _buildFloatingDock(primaryColor),
        ],
      ),
    );
  }

  Widget _buildFloatingDock(Color primary) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        child: Container(
          height: 75,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 25, offset: const Offset(0, 10))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDockItem(0, Icons.groups_rounded),
              _buildDockItem(1, Icons.auto_stories_rounded),
              GestureDetector(
                onTap: () => setState(() => _selectedIndex = 2),
                child: Container(
                  height: 55, width: 55,
                  decoration: BoxDecoration(
                    color: _selectedIndex == 2 ? primary.withOpacity(0.1) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _selectedIndex == 2 ? Icons.home_rounded : Icons.home_outlined,
                    size: 32, color: _selectedIndex == 2 ? primary : Colors.grey[400],
                  ),
                ),
              ),
              _buildDockItem(3, Icons.workspace_premium_rounded),
              _buildDockItem(4, Icons.person_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDockItem(int index, IconData icon) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: isSelected ? AppTheme.primary : Colors.grey[300]),
          if (isSelected) Container(margin: const EdgeInsets.only(top: 4), width: 4, height: 4, decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
        ],
      ),
    );
  }

  Widget _buildHomeScreen(User? user, Color primary, Color dark) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final String primeiroNome = (userData['nome'] ?? "Professor").trim().split(' ').first;

        return Column(
          children: [
            _buildSidebarHeader(primeiroNome, primary, dark),
            Expanded(child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 120),
              children: [
                _buildAgendaSection(primary, dark),
                const SizedBox(height: 35),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 25), child: _buildSectionHeader("Atalhos", dark)),
                const SizedBox(height: 15),
                _buildGamificationBento(primary, dark),
                const SizedBox(height: 40),
                _buildTurmasSection(primary, dark),
              ],
            )),
          ],
        );
      },
    );
  }

  Widget _buildSidebarHeader(String name, Color primary, Color dark) => SafeArea(
    bottom: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 20),
      child: Row(children: [
        Container(width: 5, height: 50, decoration: BoxDecoration(color: primary, borderRadius: BorderRadius.circular(10))),
        const SizedBox(width: 20),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Olá, $name!", style: TextStyle(color: dark, fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -1)),
            const Text("Terça-feira, 3 de Março de 2026", style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        )),
        IconButton(onPressed: () => FirebaseAuth.instance.signOut(), icon: Icon(Icons.logout_rounded, color: Colors.grey[400])),
      ]),
    ),
  );

  Widget _buildGamificationBento(Color primary, Color dark) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 25),
    child: Row(children: [
      Expanded(child: _buildBigBentoCard("Recompensar Aluno", Icons.workspace_premium_rounded, Colors.amber[700]!, () {})),
      const SizedBox(width: 15),
      Expanded(child: Column(children: [
        _buildSmallBentoCard("Nova Badge", Icons.military_tech_rounded, Colors.purple[400]!),
        const SizedBox(height: 12),
        _buildSmallBentoCard("Nova Turma", Icons.add_home_work_rounded, primary),
      ])),
    ]),
  );

  Widget _buildBigBentoCard(String title, IconData icon, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 140, padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(28), border: Border.all(color: color.withOpacity(0.12))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        CircleAvatar(backgroundColor: color, radius: 22, child: Icon(icon, color: Colors.white, size: 26)),
        Text(title, style: TextStyle(color: color.withOpacity(0.9), fontWeight: FontWeight.w900, fontSize: 17, height: 1.1)),
      ]),
    ),
  );

  Widget _buildSmallBentoCard(String title, IconData icon, Color color) => Container(
    height: 64, padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
    child: Row(children: [Icon(icon, color: color, size: 22), const SizedBox(width: 12), Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis))]),
  );

  Widget _buildTurmasSection(Color primary, Color dark) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 25), child: Row(children: [
        Text("Turmas", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: dark)),
        const Spacer(), Text("Ver Tudo >>", style: TextStyle(color: primary, fontWeight: FontWeight.bold, fontSize: 14)),
      ])),
      const SizedBox(height: 15),
      SizedBox(height: 160, child: ListView( // Aumentado para 205px para evitar overflow vertical
        scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(left: 25, right: 10),
        children: [
          _buildTurmaCard("Forró pé-de-serra", "Iniciante 1", "Definir Agora", true, primary, dark),
          _buildTurmaCard("Forró pé-de-serra", "Iniciante 2", "Manivela", false, primary, dark),
        ],
      )),
    ],
  );

  // --- CORREÇÃO DO TEXTO DO BOTÃO ---
  Widget _buildTurmaCard(String t, String s, String b, bool p, Color pr, Color d) => Container(
    width: 210, margin: const EdgeInsets.only(right: 15), padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(t, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: d), maxLines: 1, overflow: TextOverflow.ellipsis),
      Text(s, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      const SizedBox(height: 12),
      Text("Passo da Semana:", style: TextStyle(color: d.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold)),
      const Spacer(),
      SizedBox(width: double.infinity, height: 48, child: ElevatedButton( // Altura aumentada para 48px
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: p ? pr : Colors.white, 
          foregroundColor: p ? Colors.white : pr, 
          elevation: 0, 
          padding: EdgeInsets.zero, // Padding zero para não encolher o texto internamente
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: pr, width: 1.5)),
        ),
        // Removido o FittedBox para o texto manter o tamanho original
        child: Text(b, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)), 
      )),
    ]),
  );

  Widget _buildAgendaSection(Color primary, Color dark) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 25),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildSectionHeader("Agenda de Hoje", dark),
      const SizedBox(height: 15),
      AgendaStackedScroll(primary: primary, dark: dark),
    ]),
  );

  Widget _buildSectionHeader(String title, Color dark) => Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: dark.withOpacity(0.8)));
}