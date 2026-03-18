import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/auth_bloc/auth_bloc.dart';
import '../../logic/auth_bloc/auth_event.dart';
import '../../models/models.dart';
import 'teacher_steps_library_screen.dart';
import 'teacher_badges_screen.dart';
import 'teacher_classes_screen.dart';
import 'teacher_profile_screen.dart';

// =============================================================
// AGENDA STACKED SCROLL — vinda do Firestore
// =============================================================

class AgendaStackedScroll extends StatefulWidget {
  final Color primary;
  final Color dark;
  final String professorId;

  const AgendaStackedScroll({
    super.key,
    required this.primary,
    required this.dark,
    required this.professorId,
  });

  @override
  State<AgendaStackedScroll> createState() => _AgendaStackedScrollState();
}

class _AgendaStackedScrollState extends State<AgendaStackedScroll> {
  final ScrollController _scrollController = ScrollController();
  List<_AulaHoje> _aulas = [];

  static const double _heroHeight = 110.0;
  static const double _subHeight = 64.0;
  static const double _peekOffset = 20.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Escuta Firestore separadamente — não interfere no scroll
    FirebaseFirestore.instance
        .collection('turmas')
        
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      final turmas =
          snap.docs.map((d) => TurmaModel.fromFirestore(d)).toList();
      setState(() => _aulas = _extrairAulasHoje(turmas));
    });
  }

  void _onScroll() {
    if (mounted) setState(() {}); // só atualiza posição dos cards
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  List<_AulaHoje> _extrairAulasHoje(List<TurmaModel> turmas) {
    const diasPt = [
      'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'
    ];
    final diaHoje = diasPt[DateTime.now().weekday - 1];
    final aulas = <_AulaHoje>[];
    for (final turma in turmas) {
      for (final h in turma.horariosDia) {
        if (h.dia == diaHoje) {
          aulas.add(_AulaHoje(turma: turma, horario: h.horario));
        }
      }
    }
    aulas.sort((a, b) {
      final hA = a.horario.split(':').first.padLeft(2, '0');
      final hB = b.horario.split(':').first.padLeft(2, '0');
      return hA.compareTo(hB);
    });
    return aulas;
  }

  double _getCardTop(int index) {
    double top = 0;
    for (int i = 0; i < index; i++) {
      top += (i == 0 ? _heroHeight : _subHeight) + _peekOffset;
    }
    return top;
  }

  @override
  Widget build(BuildContext context) {
    if (_aulas.isEmpty) {
      return Container(
        height: 80,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04), blurRadius: 10)
          ],
        ),
        child: Row(children: [
          const Text('🎉', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Text('Nenhuma aula hoje!',
              style: TextStyle(
                  color: widget.dark.withOpacity(0.5),
                  fontWeight: FontWeight.w600,
                  fontSize: 15)),
        ]),
      );
    }

    final scrollOffset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;
    final totalStack = _getCardTop(_aulas.length - 1) +
        (_aulas.length == 1 ? _heroHeight : _subHeight);
    final visibleHeight = _heroHeight + (_peekOffset * 2) + 32;

    return NotificationListener<ScrollNotification>(
      onNotification: (_) => true, // impede propagação para ListView pai
      child: SizedBox(
        height: visibleHeight,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          child: SizedBox(
            height: totalStack + 20,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (int i = _aulas.length - 1; i >= 0; i--)
                  _buildStackedCard(i, _aulas[i], scrollOffset),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStackedCard(
      int index, _AulaHoje aula, double scrollOffset) {
    final naturalTop = _getCardTop(index);
    final top = (naturalTop - scrollOffset).clamp(0.0, naturalTop);
    final depth = (index - (scrollOffset / (_subHeight + _peekOffset)))
        .clamp(0.0, 10.0);

    return Positioned(
      top: top,
      left: depth * 7.0,
      right: depth * 7.0,
      child: Transform.scale(
        scale: 1.0 - (depth * 0.025).clamp(0.0, 0.07),
        alignment: Alignment.topCenter,
        child: Opacity(
          opacity: (1.0 - depth * 0.08).clamp(0.75, 1.0),
          child: index == 0
              ? _buildHeroCard(aula)
              : _buildSubCard(aula, depth),
        ),
      ),
    );
  }

  Widget _buildHeroCard(_AulaHoje aula) => Container(
        height: _heroHeight,
        padding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        decoration: BoxDecoration(
          color: widget.primary,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
                color: widget.primary.withOpacity(0.35),
                blurRadius: 18,
                offset: const Offset(0, 8))
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    aula.turma.modalidade.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5),
                  ),
                  const SizedBox(height: 4),
                  Text(aula.turma.nome,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(14)),
              child: Text(aula.horario,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );

  Widget _buildSubCard(_AulaHoje aula, double depth) => Container(
        height: _subHeight,
        padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05), blurRadius: 10)
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.07)),
        ),
        child: Row(children: [
          Text(aula.horario,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: widget.dark.withOpacity(0.45))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(aula.turma.nome,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                Text(aula.turma.nivel,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ]),
      );
}

/// Dado auxiliar para a agenda do dia.
class _AulaHoje {
  final TurmaModel turma;
  final String horario;
  const _AulaHoje({required this.turma, required this.horario});
}

// =============================================================
// TEACHER DASHBOARD
// =============================================================

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  int _selectedIndex = 2;

  String _dataFormatada() {
    const diasSemana = [
      'Segunda-feira', 'Terça-feira', 'Quarta-feira',
      'Quinta-feira', 'Sexta-feira', 'Sábado', 'Domingo',
    ];
    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
    ];
    final now = DateTime.now();
    return '${diasSemana[now.weekday - 1]}, ${now.day} de ${meses[now.month - 1]} de ${now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final Color primaryColor = AppTheme.primary;
    const Color darkColor = AppTheme.secondary;

    final screens = [
      const TeacherClassesScreen(),
      const TeacherStepsLibraryScreen(),
      _buildHomeScreen(user, primaryColor, darkColor),
      const TeacherBadgesScreen(),
      const TeacherProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          screens[_selectedIndex],
          // Fade atrás do dock — suaviza a transição do conteúdo para o menu
          Align(
            alignment: Alignment.bottomCenter,
            child: IgnorePointer(
              child: Container(
                height: 130,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0),
                      Colors.white.withOpacity(0.85),
                      Colors.white,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ),
          _buildFloatingDock(primaryColor),
        ],
      ),
    );
  }

  // ── Dock flutuante ────────────────────────────────────────────

  Widget _buildFloatingDock(Color primary) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        child: Container(
          height: 75,
          decoration: BoxDecoration(
            // Fade na parte de trás do dock
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.95),
                Colors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 25,
                  offset: const Offset(0, 10)),
              // Sombra difusa para efeito de fade nas bordas
              BoxShadow(
                  color: Colors.white.withOpacity(0.9),
                  blurRadius: 20,
                  spreadRadius: -5,
                  offset: const Offset(0, -8)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDockItem(0, Icons.groups_rounded),
              _buildDockItem(1, Icons.auto_stories_rounded),
              // Botão Home com logo customizada
              GestureDetector(
                onTap: () => setState(() => _selectedIndex = 2),
                child: Container(
                  // Hitbox ampliada
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: _selectedIndex == 2
                        ? primary.withOpacity(0.1)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _selectedIndex == 2
                        ? Image.asset(
                            'assets/logo_color.png',
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                          )
                        : Image.asset(
                            'assets/logodm_cinza_btn.png',
                            width: 32,
                            height: 32,
                            fit: BoxFit.contain,
                          ),
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
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      // Hitbox ampliada — não precisa clicar exatamente no ícone
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 52,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 26,
                color: isSelected ? AppTheme.primary : Colors.grey[400]),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                    color: AppTheme.primary, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Home screen ───────────────────────────────────────────────

  Widget _buildHomeScreen(User? user, Color primary, Color dark) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final userData =
            snapshot.data!.data() as Map<String, dynamic>;
        final String primeiroNome =
            (userData['nome'] ?? 'Professor').trim().split(' ').first;

        return Column(
          children: [
            _buildSidebarHeader(primeiroNome, primary, dark),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 120),
                children: [
                  _buildAgendaSection(user?.uid ?? '', primary, dark),
                  const SizedBox(height: 35),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 25),
                    child: _buildSectionHeader('Atalhos', dark),
                  ),
                  const SizedBox(height: 15),
                  _buildGamificationBento(primary, dark),
                  const SizedBox(height: 40),
                  _buildTurmasSection(
                      user?.uid ?? '', primary, dark),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Header ────────────────────────────────────────────────────

  Widget _buildSidebarHeader(
      String name, Color primary, Color dark) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(25, 20, 25, 20),
        child: Row(children: [
          Container(
            width: 5,
            height: 50,
            decoration: BoxDecoration(
                color: primary,
                borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Olá, $name!',
                    style: TextStyle(
                        color: dark,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1)),
                Text(_dataFormatada(),
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
          IconButton(
            onPressed: () =>
                context.read<AuthBloc>().add(LogoutRequested()),
            icon: Icon(Icons.logout_rounded, color: Colors.grey[400]),
          ),
        ]),
      ),
    );
  }

  // ── Agenda de hoje — vinda do Firestore ───────────────────────

  Widget _buildAgendaSection(
      String uid, Color primary, Color dark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Agenda de Hoje', dark),
          const SizedBox(height: 15),
          AgendaStackedScroll(
            primary: primary,
            dark: dark,
            professorId: uid,
          ),
        ],
      ),
    );
  }

  // ── Atalhos (bento) ───────────────────────────────────────────

  Widget _buildGamificationBento(Color primary, Color dark) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Row(children: [
          Expanded(
            child: _buildBigBentoCard(
              'Recompensar Aluno',
              Icons.workspace_premium_rounded,
              Colors.amber[700]!,
              () => setState(() => _selectedIndex = 3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(children: [
              _buildSmallBentoCard(
                'Biblioteca',
                Icons.auto_stories_rounded,
                primary,
                () => setState(() => _selectedIndex = 1),
              ),
              const SizedBox(height: 8),
              _buildSmallBentoCard(
                'Nova Turma',
                Icons.add_home_work_rounded,
                Colors.purple[400]!,
                () => setState(() => _selectedIndex = 0),
              ),
            ]),
          ),
        ]),
      );

  Widget _buildBigBentoCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
                backgroundColor: color,
                radius: 22,
                child: Icon(icon, color: Colors.white, size: 24)),
            Text(title,
                style: const TextStyle(
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    height: 1.1)),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallBentoCard(
      String title, IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 6)),
            ],
          ),
          child: Row(children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis),
            ),
          ]),
        ),
      );

  // ── Turmas — vindas do Firestore ──────────────────────────────

  Widget _buildTurmasSection(
      String uid, Color primary, Color dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Row(children: [
            Text('Turmas',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: dark)),
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _selectedIndex = 0),
              child: Text('Ver Tudo >>',
                  style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
          ]),
        ),
        const SizedBox(height: 15),

        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('turmas')
              
              .limit(5) // Mostra no máximo 5 no dashboard
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final turmas = snap.data?.docs
                    .map((d) => TurmaModel.fromFirestore(d))
                    .toList() ??
                [];

            if (turmas.isEmpty) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 25),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10)
                    ],
                  ),
                  child: Row(children: [
                    const Text('🎓',
                        style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Text('Nenhuma turma criada ainda.',
                        style: TextStyle(
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500)),
                  ]),
                ),
              );
            }

            return SizedBox(
              height: 165,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 25, right: 10),
                itemCount: turmas.length,
                itemBuilder: (_, i) =>
                    _buildTurmaCard(turmas[i], primary, dark),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTurmaCard(
      TurmaModel turma, Color primary, Color dark) {
    final temPasso = turma.passoSemanaNome != null;

    return Container(
      width: 210,
      margin: const EdgeInsets.only(right: 15, top: 6, bottom: 4),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(turma.nome,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: dark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text('${turma.modalidade} · ${turma.nivel}',
              style: const TextStyle(
                  color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          // Alunos matriculados
          Row(children: [
            Icon(Icons.people_outline_rounded,
                size: 13, color: Colors.grey[400]),
            const SizedBox(width: 4),
            Text('${turma.totalAlunos} aluno${turma.totalAlunos != 1 ? 's' : ''}',
                style: TextStyle(
                    color: Colors.grey[400], fontSize: 12)),
          ]),
          Text(
            'Passo da semana:',
            style: TextStyle(
                color: dark.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          _PassoSemanaButton(
            turma: turma,
            primary: primary,
            onTap: () => setState(() => _selectedIndex = 0),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color dark) => Text(
        title,
        style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: dark.withOpacity(0.8)),
      );
}

// ── Botão animado do passo da semana ──────────────────────────────

class _PassoSemanaButton extends StatefulWidget {
  final TurmaModel turma;
  final Color primary;
  final VoidCallback onTap;

  const _PassoSemanaButton({
    required this.turma,
    required this.primary,
    required this.onTap,
  });

  @override
  State<_PassoSemanaButton> createState() => _PassoSemanaButtonState();
}

class _PassoSemanaButtonState extends State<_PassoSemanaButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.06,
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final temPasso = widget.turma.passoSemanaNome != null;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: double.infinity,
          height: 40,
          decoration: BoxDecoration(
            color: temPasso ? widget.primary : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: widget.primary, width: 1.5),
          ),
          child: Center(
            child: Text(
              temPasso ? widget.turma.passoSemanaNome! : 'Definir passo',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: temPasso ? Colors.white : widget.primary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}