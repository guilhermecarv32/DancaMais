import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/permissao_service.dart';
import '../../logic/auth_bloc/auth_bloc.dart';
import '../../logic/auth_bloc/auth_event.dart';
import '../../logic/gamification/gamification_service.dart' as gamif;
import '../../models/models.dart';
import 'teacher_steps_library_screen.dart';
import 'teacher_badges_screen.dart';
import 'teacher_classes_screen.dart';
import 'teacher_profile_screen.dart';
import '../widgets/tap_effect.dart';

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
    if (mounted) setState(() {});
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
      onNotification: (_) => true,
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
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
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
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
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
                    style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ]),
      );
}

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
    final Color darkColor = AppTheme.secondary;

    final screens = [
      const TeacherClassesScreen(),
      const TeacherStepsLibraryScreen(),
      _buildHomeScreen(user, primaryColor, darkColor),
      const TeacherBadgesScreen(),
      const TeacherProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: true,
        child: Stack(
          children: [
            screens[_selectedIndex],
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
                        const Color(0xFFF5F5F5).withOpacity(0.85),
                        const Color(0xFFF5F5F5),
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
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(
              color: AppTheme.primary.withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 30,
                  offset: const Offset(0, 10)),
              BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDockItem(0, Icons.groups_rounded,
                  activeColor: AppTheme.primary,
                  inactiveColor: Colors.grey[400]!),
              _buildDockItem(1, Icons.auto_stories_rounded,
                  activeColor: AppTheme.primary,
                  inactiveColor: Colors.grey[400]!),
              // Botão Home com logo
              TapEffect(
                onTap: () => setState(() => _selectedIndex = 2),
                child: Container(
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
                        ? Image.asset('assets/logo_color.png',
                            width: 32, height: 32, fit: BoxFit.contain)
                        : Image.asset('assets/logodm_cinza_btn.png',
                            width: 32, height: 32, fit: BoxFit.contain),
                  ),
                ),
              ),
              _buildDockItem(3, Icons.workspace_premium_rounded,
                  activeColor: AppTheme.primary,
                  inactiveColor: Colors.grey[400]!),
              _buildDockItem(4, Icons.person_rounded,
                  activeColor: AppTheme.primary,
                  inactiveColor: Colors.grey[400]!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDockItem(int index, IconData icon, {
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final isSelected = _selectedIndex == index;
    return TapEffect(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 52,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 26,
                color: isSelected ? activeColor : inactiveColor),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                    color: activeColor, shape: BoxShape.circle),
              ),
            ],
          ],
        ),
      ),
    );
  }

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
        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final String primeiroNome =
            (userData['nome'] ?? 'Professor').trim().split(' ').first;

        return Column(
          children: [
            _buildSidebarHeader(primeiroNome, primary, dark),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 150),
                children: [
                  _buildAgendaSection(user?.uid ?? '', primary, dark),
                  const SizedBox(height: 35),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: _buildSectionHeader('Atalhos', dark),
                  ),
                  const SizedBox(height: 15),
                  _buildGamificationBento(primary, dark),
                  const SizedBox(height: 40),
                  _buildTurmasSection(user?.uid ?? '', primary, dark),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _confirmarLogout(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Sair da conta?'),
            content: const Text('Você tem certeza que deseja sair?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sair'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildSidebarHeader(String name, Color primary, Color dark) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(25, 20, 25, 20),
        child: Row(children: [
          Container(
            width: 5,
            height: 50,
            decoration: BoxDecoration(
                color: primary, borderRadius: BorderRadius.circular(10)),
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
                    style: const TextStyle(color: Colors.grey, fontSize: 14)),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final ok = await _confirmarLogout(context);
              if (!ok) return;
              if (context.mounted) {
                context.read<AuthBloc>().add(LogoutRequested());
              }
            },
            icon: Icon(Icons.logout_rounded, color: Colors.grey[400]),
          ),
        ]),
      ),
    );
  }

  Widget _buildAgendaSection(String uid, Color primary, Color dark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Agenda de Hoje', dark),
          const SizedBox(height: 15),
          AgendaStackedScroll(primary: primary, dark: dark, professorId: uid),
        ],
      ),
    );
  }

  Widget _buildGamificationBento(Color primary, Color dark) => Padding(
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
                'Solicitações',
                Icons.notifications_active_rounded,
                Colors.orange[800]!,
                () => _abrirHubSolicitacoes(context),
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

  void _abrirHubSolicitacoes(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StreamBuilder<PerfilProfessor>(
        stream: PermissaoService.perfilStream(),
        builder: (context, snap) {
          final perfil = snap.data ??
              PerfilProfessor(isAdmin: false, modalidades: const []);
          return _SolicitacoesHubSheet(perfil: perfil);
        },
      ),
    );
  }

  Widget _buildBigBentoCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return TapEffect(
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
      TapEffect(
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

  Widget _buildTurmasSection(String uid, Color primary, Color dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Row(children: [
            Text('Turmas',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: dark)),
            const Spacer(),
            TapEffect(
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
              .limit(5)
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator()));
            }

            final turmas = snap.data?.docs
                    .map((d) => TurmaModel.fromFirestore(d))
                    .toList() ??
                [];

            if (turmas.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25),
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
                    const Text('🎓', style: TextStyle(fontSize: 24)),
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
                itemBuilder: (ctx, i) =>
                    _buildTurmaCard(ctx, turmas[i], primary, dark),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTurmaCard(BuildContext context, TurmaModel turma, Color primary, Color dark) {
    return StreamBuilder<PerfilProfessor>(
      stream: PermissaoService.perfilStream(),
      builder: (context, perfilSnap) {
        final perfil = perfilSnap.data ??
            PerfilProfessor(isAdmin: false, modalidades: const []);
        final temPermissao = perfil.podeEditarModalidade(turma.modalidade);

        return TapEffect(
          onTap: () => setState(() => _selectedIndex = 0),
          behavior: HitTestBehavior.translucent,
          child: Container(
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
                        fontWeight: FontWeight.bold, fontSize: 16, color: dark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('${turma.modalidade} · ${turma.nivel}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                Row(children: [
                  Icon(Icons.people_outline_rounded,
                      size: 13, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                      '${turma.totalAlunos} aluno${turma.totalAlunos != 1 ? 's' : ''}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                ]),
                Text('Passo da semana:',
                    style: TextStyle(
                        color: dark.withOpacity(0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                _PassoSemanaButton(
                  turma: turma,
                  primary: primary,
                  habilitado: temPermissao,
                  onTap: temPermissao
                      ? () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) =>
                                SeletorPassoSemanaSheet(turma: turma),
                          )
                      : null,
                ),
              ],
            ),
          ),
        );
      },
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

// ─────────────────────────────────────────────────────────────────
// HUB: SOLICITAÇÕES (dashboard)
// ─────────────────────────────────────────────────────────────────

class _SolicitacoesHubSheet extends StatelessWidget {
  final PerfilProfessor perfil;
  const _SolicitacoesHubSheet({required this.perfil});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 35),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Text(
              'Solicitações',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(height: 12),
            TapEffect(
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _SelecionarTurmaSheet(
                    perfil: perfil,
                    titulo: 'Validar passo da semana',
                    apenasComPassoSemana: true,
                    builder: (t) => _ValidarPassoSemanaSheetDash(turma: t),
                  ),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.verified_rounded,
                        color: Colors.green, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Validar passo da semana',
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        Text(
                          '+${gamif.XPRecompensa.validadoProfessor} XP (toggle validar/desvalidar)',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            const Divider(height: 8),
            TapEffect(
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _SelecionarTurmaSheet(
                    perfil: perfil,
                    titulo: 'Solicitações de entrada',
                    apenasComPassoSemana: false,
                    builder: (t) => _SolicitacoesTurmaSheetDash(turma: t),
                  ),
                );
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.person_add_alt_1_rounded,
                        color: Colors.orange[800], size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Solicitações de entrada em turma',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SelecionarTurmaSheet extends StatelessWidget {
  final PerfilProfessor perfil;
  final String titulo;
  final bool apenasComPassoSemana;
  final Widget Function(TurmaModel turma) builder;

  const _SelecionarTurmaSheet({
    required this.perfil,
    required this.titulo,
    required this.apenasComPassoSemana,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 35),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(
              titulo,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('turmas').snapshots(),
              builder: (context, snap) {
                final docs = snap.data?.docs ?? [];
                var turmas =
                    docs.map((d) => TurmaModel.fromFirestore(d)).toList();
                turmas = turmas
                    .where((t) =>
                        perfil.isAdmin || perfil.podeEditarModalidade(t.modalidade))
                    .toList();
                if (apenasComPassoSemana) {
                  turmas = turmas.where((t) => t.passoSemanaId != null).toList();
                }
                if (turmas.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Nenhuma turma disponível.',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }

                return SizedBox(
                  height: 360,
                  child: ListView.builder(
                    itemCount: turmas.length,
                    itemBuilder: (_, i) {
                      final t = turmas[i];
                      return TapEffect(
                        onTap: () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => builder(t),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.nome,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppTheme.secondary,
                                    ),
                                  ),
                                  Text(
                                    '${t.modalidade} · ${t.nivel}',
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: Colors.grey),
                          ]),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// SHEET: SOLICITAÇÕES DE ENTRADA (dashboard)
// ─────────────────────────────────────────────────────────────────

class _SolicitacoesTurmaSheetDash extends StatelessWidget {
  final TurmaModel turma;
  const _SolicitacoesTurmaSheetDash({required this.turma});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 35),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text('Solicitações — ${turma.nome}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: AppTheme.secondary)),
            Text('${turma.modalidade} · ${turma.nivel}',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('solicitacoes')
                  .doc(turma.id)
                  .collection('pendentes')
                  .snapshots(),
              builder: (context, snap) {
                final pendentes = snap.data?.docs ?? [];
                if (pendentes.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text('Nenhuma solicitação pendente.',
                          style: TextStyle(
                              color: Colors.grey[400],
                              fontWeight: FontWeight.w500)),
                    ),
                  );
                }
                return Column(
                  children: pendentes.map((sol) {
                    final data = sol.data() as Map<String, dynamic>;
                    final nomeAluno = data['nomeAluno'] ?? 'Aluno';
                    final funcao = data['funcao'] as String?;
                    final alunoId = data['alunoId'] as String? ?? sol.id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(16)),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primary.withOpacity(0.12),
                          child: Text(
                              nomeAluno.isNotEmpty
                                  ? nomeAluno[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nomeAluno,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppTheme.secondary)),
                              if (funcao != null)
                                Row(children: [
                                  const Icon(Icons.label_outline_rounded,
                                      size: 12, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(funcao,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                ]),
                            ],
                          ),
                        ),
                        TapEffect(
                          onTap: () => _responder(
                              context, sol.id, alunoId, funcao, false, nomeAluno),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.redAccent, size: 18),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TapEffect(
                          onTap: () => _responder(
                              context, sol.id, alunoId, funcao, true, nomeAluno),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.check_rounded,
                                color: Colors.green, size: 18),
                          ),
                        ),
                      ]),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _responder(BuildContext context, String solId, String alunoId,
      String? funcao, bool aprovar, String nomeAluno) async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();

    if (aprovar) {
      batch.set(db.collection('inscricoes').doc(), {
        'alunoId': alunoId,
        'turmaId': turma.id,
        'funcao': funcao,
        'dataInscricao': FieldValue.serverTimestamp(),
      });
      batch.update(db.collection('turmas').doc(turma.id),
          {'totalAlunos': FieldValue.increment(1)});
    }

    batch.delete(db
        .collection('solicitacoes')
        .doc(turma.id)
        .collection('pendentes')
        .doc(solId));

    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(aprovar
            ? '✅ $nomeAluno adicionado à turma!'
            : '❌ Solicitação recusada.'),
        backgroundColor: aprovar ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// SHEET: VALIDAR PASSO DA SEMANA (dashboard)
// ─────────────────────────────────────────────────────────────────

class _ValidarPassoSemanaSheetDash extends StatelessWidget {
  final TurmaModel turma;
  const _ValidarPassoSemanaSheetDash({required this.turma});

  @override
  Widget build(BuildContext context) {
    final passoId = turma.passoSemanaId;
    if (passoId == null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(25, 20, 25, 35),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: const SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Nenhum passo definido para esta turma.'),
            ],
          ),
        ),
      );
    }

    final professorId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Container(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 35),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text('Validar — ${turma.nome}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: AppTheme.secondary)),
            Text(
              '${turma.passoSemanaNome ?? '—'} · +${gamif.XPRecompensa.validadoProfessor} XP',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('inscricoes')
                  .where('turmaId', isEqualTo: turma.id)
                  .snapshots(),
              builder: (context, inscSnap) {
                final inscricoes = inscSnap.data?.docs ?? [];
                final alunoIds = <String>[];
                for (final d in inscricoes) {
                  final data = d.data() as Map<String, dynamic>;
                  final alunoId = (data['alunoId'] as String?) ?? '';
                  if (alunoId.isEmpty) continue;
                  alunoIds.add(alunoId);
                }
                if (alunoIds.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'Nenhum aluno nesta turma.',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('usuarios')
                      .where(FieldPath.documentId, whereIn: alunoIds)
                      .snapshots(),
                  builder: (context, alunosSnap) {
                    final alunos = alunosSnap.data?.docs ?? [];
                    final porId = <String, Map<String, dynamic>>{};
                    for (final d in alunos) {
                      porId[d.id] = (d.data() as Map<String, dynamic>);
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('progressoAluno')
                          .where('movimentacaoId', isEqualTo: passoId)
                          .where('status', whereIn: [
                            StatusProgresso.aprendido.name,
                            StatusProgresso.validado.name,
                          ])
                          .where('alunoId', whereIn: alunoIds)
                          .snapshots(),
                      builder: (context, progressoSnap) {
                        final itens = progressoSnap.data?.docs ?? [];
                        if (itens.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 28),
                            child: Center(
                              child: Text(
                                'Nada para validar aqui ainda.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        }

                        return SizedBox(
                          height: 360,
                          child: ListView.builder(
                            itemCount: itens.length,
                            itemBuilder: (_, i) {
                              final p = itens[i].data() as Map<String, dynamic>;
                              final alunoId = (p['alunoId'] as String?) ?? '';
                              final status = (p['status'] as String?) ?? '';
                              final isValidado =
                                  status == StatusProgresso.validado.name;

                              final aluno =
                                  porId[alunoId] ?? const <String, dynamic>{};
                              final nome = (aluno['nome'] as String?) ?? 'Aluno';

                              return TapEffect(
                                onTap: null,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isValidado
                                        ? Colors.green.withOpacity(0.08)
                                        : AppTheme.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isValidado
                                          ? Colors.green.withOpacity(0.25)
                                          : Colors.transparent,
                                    ),
                                  ),
                                  child: Row(children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor:
                                          AppTheme.primary.withOpacity(0.12),
                                      child: Text(
                                        nome.isNotEmpty
                                            ? nome[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nome,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: AppTheme.secondary,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            isValidado ? 'Validado' : 'Pendente',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: isValidado
                                                  ? Colors.green[700]
                                                  : Colors.orange[800],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    TapEffect(
                                      onTap: () async {
                                        if (professorId.isEmpty ||
                                            alunoId.isEmpty) return;
                                        if (isValidado) {
                                          await gamif.GamificationService()
                                              .desvalidarAprendizado(
                                            professorId: professorId,
                                            alunoId: alunoId,
                                            movimentacaoId: passoId,
                                          );
                                        } else {
                                          await gamif.GamificationService()
                                              .validarAprendizado(
                                            professorId: professorId,
                                            alunoId: alunoId,
                                            movimentacaoId: passoId,
                                            feedbackMovimentacaoNome:
                                                turma.passoSemanaNome,
                                          );
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: (isValidado
                                                  ? Colors.red
                                                  : Colors.green)
                                              .withOpacity(0.10),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: (isValidado
                                                    ? Colors.red
                                                    : Colors.green)
                                                .withOpacity(0.25),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isValidado
                                                  ? Icons.undo_rounded
                                                  : Icons.verified_rounded,
                                              size: 16,
                                              color: isValidado
                                                  ? Colors.red
                                                  : Colors.green,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              isValidado
                                                  ? 'Desvalidar'
                                                  : 'Validar',
                                              style: TextStyle(
                                                color: isValidado
                                                    ? Colors.red
                                                    : Colors.green,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ]),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Botão animado do passo da semana ──────────────────────────────

class _PassoSemanaButton extends StatefulWidget {
  final TurmaModel turma;
  final Color primary;
  final bool habilitado;
  final VoidCallback? onTap;

  const _PassoSemanaButton({
    required this.turma,
    required this.primary,
    required this.onTap,
    this.habilitado = true,
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
    final habilitado = widget.habilitado;

    return GestureDetector(
      onTapDown: habilitado ? (_) => _controller.forward() : null,
      onTapUp: habilitado
          ? (_) {
              _controller.reverse();
              widget.onTap?.call();
            }
          : null,
      onTapCancel: habilitado ? () => _controller.reverse() : null,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          width: double.infinity,
          height: 40,
          decoration: BoxDecoration(
            color: !habilitado
                ? Colors.grey[100]
                : temPasso
                    ? widget.primary
                    : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: habilitado ? widget.primary : Colors.grey[300]!,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!habilitado) ...[
                Icon(Icons.lock_outline_rounded,
                    size: 11, color: Colors.grey[400]),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  temPasso
                      ? widget.turma.passoSemanaNome!
                      : habilitado
                          ? 'Definir passo'
                          : 'Sem permissão',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: !habilitado
                          ? Colors.grey[400]
                          : temPasso
                              ? Colors.white
                              : widget.primary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}