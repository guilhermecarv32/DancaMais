import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AulaItem {
  final String label;
  final String title;
  final String time;
  final String? level;
  final bool isHero;

  const AulaItem({
    required this.title,
    required this.time,
    this.label = '',
    this.level,
    this.isHero = false,
  });
}

// =============================================================
// PILHA COM SCROLL LIVRE
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
    AulaItem(label: "PRÓXIMA AULA", title: "Forró Iniciante", time: "18:00", isHero: true),
    AulaItem(title: "Samba de Gafieira", time: "19:30", level: "Intermediário"),
    AulaItem(title: "Zouk", time: "21:00", level: "Geral"),
  ];

  static const double _heroHeight = 110.0;
  static const double _subHeight = 56.0;
  static const double _peekOffset = 20.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
    final double scrollOffset =
        _scrollController.hasClients ? _scrollController.offset : 0;

    final double totalStackHeight = _getCardTop(_aulas.length - 1) +
        (_aulas.last.isHero ? _heroHeight : _subHeight);

    final double visibleHeight = _heroHeight + (_peekOffset * 2) + 24;

    return SizedBox(
      height: visibleHeight,
      child: NotificationListener<ScrollNotification>(
        onNotification: (_) => true,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            height: totalStackHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (int i = _aulas.length - 1; i >= 0; i--)
                  _buildStackedCard(i, scrollOffset),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStackedCard(int index, double scrollOffset) {
    final aula = _aulas[index];
    final double naturalTop = _getCardTop(index);

    final double top = (naturalTop - scrollOffset).clamp(0.0, naturalTop);

    final double cardsAbove =
        (scrollOffset / (_subHeight + _peekOffset)).clamp(0.0, index.toDouble());
    final double stackDepth =
        (index - cardsAbove).clamp(0.0, _aulas.length.toDouble());
    final double lateralInset = stackDepth * 7.0;
    final double scale = 1.0 - (stackDepth * 0.025).clamp(0.0, 0.07);
    final double opacity = (1.0 - stackDepth * 0.08).clamp(0.75, 1.0);

    return Positioned(
      top: top,
      left: lateralInset,
      right: lateralInset,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.topCenter,
        child: Opacity(
          opacity: opacity,
          child: aula.isHero
              ? _buildHeroCard(aula)
              : _buildSubCard(aula, stackDepth),
        ),
      ),
    );
  }

  Widget _buildHeroCard(AulaItem aula) {
    return SizedBox(
      height: _heroHeight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        decoration: BoxDecoration(
          color: widget.primary,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: widget.primary.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 8)),
            BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 12)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Wrap em Flexible para nunca estourar horizontalmente
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min, // <-- corrige o overflow
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aula.label,
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    aula.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(14)),
              child: Text(
                aula.time,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubCard(AulaItem aula, double depth) {
    final double shadowBlur = 8 + depth * 6;
    final double shadowOpacity = 0.05 + depth * 0.04;

    return SizedBox(
      height: _subHeight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(shadowOpacity),
              blurRadius: shadowBlur,
              offset: Offset(0, 4 + depth * 2),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.07)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              aula.time,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: widget.dark.withOpacity(0.45)),
            ),
            const SizedBox(width: 14),
            Container(
                width: 1, height: 16, color: Colors.grey.withOpacity(0.18)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(aula.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                  if (aula.level != null)
                    Text(aula.level!,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================
// DASHBOARD PRINCIPAL
// =============================================================
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
        stream: FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

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

  Widget _buildSidebarHeader(
      String name, Color primary, Color dark, BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(25, 20, 25, 20),
        child: Row(
          children: [
            Container(
                width: 5,
                height: 50,
                decoration: BoxDecoration(
                    color: primary,
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min, // <-- corrige o overflow
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Olá, $name!",
                      style: TextStyle(
                          color: dark,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1)),
                  const Text("Terça-feira, 3 de Março de 2026",
                      style: TextStyle(color: Colors.grey, fontSize: 14)),
                ],
              ),
            ),
            IconButton(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: Icon(Icons.logout_rounded, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  Widget _buildAgendaSection(Color primary, Color dark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Agenda de Hoje", dark),
          const SizedBox(height: 15),
          AgendaStackedScroll(primary: primary, dark: dark),
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
              Text("Turmas",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: dark)),
              const Spacer(),
              Text("Ver Tudo >>",
                  style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
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
              _buildTurmaCard("Forró pé-de-serra", "Iniciante 1",
                  "Definir Agora", true, primary, dark),
              _buildTurmaCard("Forró pé-de-serra", "Iniciante 2",
                  "Manivela", false, primary, dark),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTurmaCard(
      String t, String s, String b, bool p, Color pr, Color d) {
    return Container(
      width: 210,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 17, color: d)),
          Text(s,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: pr)),
              ),
              child: Text(b,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color dark) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Text(title,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: dark.withOpacity(0.8))),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20)),
              child: Icon(i, color: c, size: 28)),
          const SizedBox(height: 8),
          Text(l,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      );

  Widget _buildBottomNav(Color c) => BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: c,
        unselectedItemColor: Colors.grey[300],
        showSelectedLabels: false,
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded, size: 28), label: ""),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_rounded, size: 28), label: ""),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_rounded, size: 40), label: ""),
          BottomNavigationBarItem(
              icon: Icon(Icons.message_rounded, size: 28), label: ""),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded, size: 28), label: ""),
        ],
      );
}