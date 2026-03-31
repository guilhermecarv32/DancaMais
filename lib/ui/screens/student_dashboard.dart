import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/auth_bloc/auth_bloc.dart';
import '../../logic/auth_bloc/auth_event.dart';
import '../../logic/gamification/gamification_service.dart' as gamif;
import '../../models/models.dart';
import '../widgets/tap_effect.dart';
import 'student_classes_screen.dart';
import 'student_badges_screen.dart';
import '../widgets/student_events_sheet.dart';
import 'student_profile_screen.dart';
import 'student_ranking_screen.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _selectedIndex = 2; // Home no meio

  @override
  Widget build(BuildContext context) {
    final screens = [
      const StudentClassesScreen(),
      const StudentConquistasScreen(),
      const _HomeScreen(),
      const StudentRankingScreen(),
      const StudentProfileScreen(),
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
            _buildDock(),
          ],
        ),
      ),
    );
  }

  Widget _buildDock() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        child: Container(
          height: 75,
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(color: AppTheme.primary.withOpacity(0.35), width: 1.2),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 30, offset: const Offset(0, 10)),
              BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDockItem(0, Icons.groups_rounded),
              _buildDockItem(1, Icons.workspace_premium_rounded),
              // Home com logo
              TapEffect(
                onTap: () => setState(() => _selectedIndex = 2),
                child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: _selectedIndex == 2 ? AppTheme.primary.withOpacity(0.1) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: _selectedIndex == 2
                        ? Image.asset('assets/logo_color.png', width: 32, height: 32, fit: BoxFit.contain)
                        : Image.asset('assets/logodm_cinza_btn.png', width: 32, height: 32, fit: BoxFit.contain),
                  ),
                ),
              ),
              _buildDockItem(3, Icons.leaderboard_rounded),
              _buildDockItem(4, Icons.person_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDockItem(int index, IconData icon) {
    final isSelected = _selectedIndex == index;
    return TapEffect(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 52, height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: isSelected ? AppTheme.primary : Colors.grey[400]),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(width: 4, height: 4,
                  decoration: BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// HOME SCREEN
// ─────────────────────────────────────────────────────────────────

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

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

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').doc(uid).snapshots(),
      builder: (context, userSnap) {
        final userData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
        final nome = (userData['nome'] ?? '').toString().trim().split(' ').first;
        final nivel = (userData['nivel'] as num?)?.toInt() ?? 1;
        final xp = (userData['xp'] as num?)?.toInt() ?? 0;
        int _xpAcumuladoAntesDoNivel(int nivelAtual) {
          const base = 100;
          const fator = 1.5;
          int total = 0;
          for (int n = 1; n < nivelAtual; n++) {
            total += (base * (n * fator)).round();
          }
          return total;
        }

        final xpParaSubir = (100 * nivel * 1.5).round(); // custo do nível atual → próximo
        final xpNoNivel = (xp - _xpAcumuladoAntesDoNivel(nivel)).clamp(0, xpParaSubir);
        final progresso = xpParaSubir > 0 ? (xpNoNivel / xpParaSubir).clamp(0.0, 1.0) : 0.0;

        return ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 150),
          children: [
            _buildHeader(context, nome, nivel, xpNoNivel, xpParaSubir, progresso),
            const SizedBox(height: 2),
            _buildAgenda(uid),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 20, 25, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TapEffect(
                  onTap: () => showStudentEventsSheet(context),
                  child: Text(
                    'Ver calendário de eventos →',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            _buildPassosSemana(uid),
            const SizedBox(height: 24),
            _buildConquistasRecentes(uid),
          ],
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String nome,
    int nivel,
    int xp,
    int xpNivel,
    double progresso,
  ) {
    final now = DateTime.now();
    final meses = ['janeiro','fevereiro','março','abril','maio','junho','julho','agosto','setembro','outubro','novembro','dezembro'];
    final dias = ['Segunda-feira','Terça-feira','Quarta-feira','Quinta-feira','Sexta-feira','Sábado','Domingo'];
    final dataStr = '${dias[now.weekday - 1]}, ${now.day} de ${meses[now.month - 1]}';

    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(25, 30, 25, 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 10, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 5,
                height: 50,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Olá, $nome!',
                      style: const TextStyle(
                        color: AppTheme.secondary,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_rounded,
                            size: 12, color: Colors.grey[400]),
                        const SizedBox(width: 5),
                        Text(dataStr,
                            style: const TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(
                              'Seu progresso',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                children: [
                                  TextSpan(
                                    text: '$xp',
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' / $xpNivel XP',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded,
                                    size: 12, color: Colors.amber[700]),
                                const SizedBox(width: 3),
                                Text(
                                  'Nível $nivel',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final fillW = constraints.maxWidth * progresso;
                                  return Container(
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 450),
                                        curve: Curves.easeOutCubic,
                                        width: fillW,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                            colors: [
                                              Color(0xFFFFC98A),
                                              AppTheme.primary,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Nível ${nivel + 1}',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(Icons.star_rounded,
                                    size: 12, color: Colors.amber[700]),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    ),
                  ],
                ),
              ),
              TapEffect(
                onTap: () async {
                  final ok = await _confirmarLogout(context);
                  if (!ok) return;
                  if (context.mounted) {
                    context.read<AuthBloc>().add(LogoutRequested());
                  }
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.logout_rounded, color: Colors.grey[500], size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPassosSemana(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('inscricoes').where('alunoId', isEqualTo: uid).snapshots(),
      builder: (context, inscSnap) {
        final inscricoes = inscSnap.data?.docs ?? [];
        if (inscricoes.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Passo da Semana'),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 25),
                itemCount: inscricoes.length,
                itemBuilder: (_, i) {
                  final data = inscricoes[i].data() as Map<String, dynamic>;
                  final turmaId = data['turmaId'] as String? ?? '';
                  final funcao = data['funcao'] as String?;
                  return StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('turmas')
                        .doc(turmaId)
                        .snapshots(),
                    builder: (context, turmaSnap) {
                      if (!turmaSnap.hasData) return const SizedBox.shrink();
                      final turma = TurmaModel.fromFirestore(turmaSnap.data!);
                      return _PassoSemanaCard(
                        turma: turma,
                        funcao: funcao,
                        uid: uid,
                        compact: true,
                        compactUseAccent: i.isEven,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConquistasRecentes(String uid) {
    final userRef = FirebaseFirestore.instance.collection('usuarios').doc(uid);
    final subRef = userRef.collection('conquistas');

    return StreamBuilder<DocumentSnapshot>(
      stream: userRef.snapshots(),
      builder: (context, userSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: subRef.snapshots(),
          builder: (context, subSnap) {
            final porId = <String, Map<String, dynamic>>{};

            final userData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
            final conquistasArray = (userData['conquistas'] as List?) ?? const [];
            for (final item in conquistasArray) {
              if (item is! Map) continue;
              final m = Map<String, dynamic>.from(item);
              final id = (m['id'] as String?) ?? '';
              if (id.isEmpty) continue;
              porId[id] = m;
            }

            final docs = subSnap.data?.docs ?? [];
            for (final d in docs) {
              final m = d.data() as Map<String, dynamic>;
              porId[d.id] = {...m, 'id': d.id};
            }

            DateTime _parseData(Map<String, dynamic> m) {
              final raw = m['dataObtida'] ?? m['dataConquista'] ?? m['data'];
              if (raw is Timestamp) return raw.toDate();
              if (raw is String) return DateTime.tryParse(raw) ?? DateTime.fromMillisecondsSinceEpoch(0);
              return DateTime.fromMillisecondsSinceEpoch(0);
            }

            final lista = porId.values.toList()
              ..sort((a, b) => _parseData(b).compareTo(_parseData(a)));

            final ultimas = lista.take(3).toList();
            if (ultimas.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Últimas conquistas'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 92,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 25, right: 10),
                    itemCount: ultimas.length,
                    itemBuilder: (_, i) {
                      final data = ultimas[i];
                      const palette = <Color>[
                        AppTheme.third,
                        AppTheme.primary,
                        AppTheme.secondary,
                        AppTheme.accent,
                      ];
                      final base = palette[i % palette.length];
                      return TapEffect(
                        onTap: () => showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => _ConquistaDetalhesSheet(conquista: data),
                        ),
                        child: _ConquistaBadge(
                          icone: (data['icone'] as String?) ?? '🏅',
                          xp: (data['xpRecompensa'] as num?)?.toInt() ?? 0,
                          bg: base.withOpacity(0.16),
                          hexColor: base,
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAgenda(String uid) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Minha Agenda'),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: AlunoAgendaStackedScroll(uid: uid),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 25),
    child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
  );
}

class _ConquistaBadge extends StatelessWidget {
  final String icone;
  final int xp;
  final Color bg;
  final Color hexColor;

  const _ConquistaBadge({
    required this.icone,
    required this.xp,
    required this.bg,
    required this.hexColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 86,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(
            alignment: Alignment.center,
            child: ClipPath(
              clipper: _HexClipper(),
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      hexColor.withOpacity(0.95),
                      hexColor.withOpacity(0.75),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    icone,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                '+$xp',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.50, 0)
      ..lineTo(w, h * 0.25)
      ..lineTo(w, h * 0.75)
      ..lineTo(w * 0.50, h)
      ..lineTo(0, h * 0.75)
      ..lineTo(0, h * 0.25)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _ConquistaDetalhesSheet extends StatelessWidget {
  final Map<String, dynamic> conquista;
  const _ConquistaDetalhesSheet({required this.conquista});

  DateTime? _parseData() {
    final raw = conquista['dataObtida'] ?? conquista['dataConquista'] ?? conquista['data'];
    if (raw is Timestamp) return raw.toDate();
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final nome = (conquista['nome'] as String?) ?? '';
    final icone = (conquista['icone'] as String?) ?? '🏅';
    final xp = (conquista['xpRecompensa'] as num?)?.toInt() ?? 0;
    final desc = (conquista['descricao'] as String?) ??
        (conquista['descricaoLonga'] as String?) ??
        '';
    final data = _parseData();

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
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(child: Text(icone, style: const TextStyle(fontSize: 28))),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nome.isEmpty ? 'Conquista' : nome,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: AppTheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '+$xp XP',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          if (data != null) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey[400]),
                            const SizedBox(width: 6),
                            Text(
                              '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ]
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (desc.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                desc.trim(),
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AlunoAgendaStackedScroll extends StatefulWidget {
  final String uid;
  const AlunoAgendaStackedScroll({super.key, required this.uid});

  @override
  State<AlunoAgendaStackedScroll> createState() => _AlunoAgendaStackedScrollState();
}

class _AlunoAgendaStackedScrollState extends State<AlunoAgendaStackedScroll> {
  final ScrollController _scrollController = ScrollController();
  final List<StreamSubscription> _subs = [];
  Set<String> _turmaIds = <String>{};
  List<_AgendaItemAluno> _itens = [];
  List<_AgendaItemAluno> _eventosHoje = [];

  static const double _heroHeight = 110.0;
  static const double _subHeight = 64.0;
  static const double _peekOffset = 20.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    _subs.add(
      FirebaseFirestore.instance
          .collection('inscricoes')
          .where('alunoId', isEqualTo: widget.uid)
          .snapshots()
          .listen((snap) {
        final ids = snap.docs
            .map((d) => (d.data()['turmaId'] as String?) ?? '')
            .where((id) => id.isNotEmpty)
            .toSet();
        _turmaIds = ids;
        _rebuildAulasFromTurmasCache();
      }),
    );

    _subs.add(
      FirebaseFirestore.instance.collection('turmas').snapshots().listen((snap) {
        final turmas = snap.docs.map((d) => TurmaModel.fromFirestore(d)).toList();
        _turmasCache = turmas;
        _rebuildAulasFromTurmasCache();
      }),
    );

    // Eventos do dia — aparecem na agenda do aluno também
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _subs.add(
      FirebaseFirestore.instance
          .collection('eventos')
          .where('dataHora', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('dataHora', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('dataHora')
          .snapshots()
          .listen((snap) {
        if (!mounted) return;
        _eventosHoje = snap.docs.map((d) {
          final m = d.data();
          final nome = (m['nome'] as String?)?.trim() ?? '';
          final ts = m['dataHora'] as Timestamp?;
          final dt = ts?.toDate();
          final h = dt == null
              ? '—'
              : '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          return _AgendaItemAluno.evento(
            id: d.id,
            nome: nome.isEmpty ? 'Evento' : nome,
            horario: h,
          );
        }).toList();
        _rebuildAulasFromTurmasCache();
      }),
    );
  }

  List<TurmaModel> _turmasCache = [];

  void _onScroll() {
    if (mounted) setState(() {});
  }

  void _rebuildAulasFromTurmasCache() {
    if (!mounted) return;
    final filtradas = _turmasCache.where((t) => _turmaIds.contains(t.id)).toList();
    final aulas = _extrairAulasHoje(filtradas);
    final todos = [...aulas, ..._eventosHoje]
      ..sort((a, b) => a.sortKey.compareTo(b.sortKey));
    setState(() => _itens = todos);
  }

  List<_AgendaItemAluno> _extrairAulasHoje(List<TurmaModel> turmas) {
    const diasPt = [
      'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'
    ];
    final diaHoje = diasPt[DateTime.now().weekday - 1];
    final aulas = <_AgendaItemAluno>[];
    for (final turma in turmas) {
      for (final h in turma.horariosDia) {
        if (h.dia == diaHoje) {
          aulas.add(_AgendaItemAluno.aula(turma: turma, horario: h.horario));
        }
      }
    }
    aulas.sort((a, b) => a.sortKey.compareTo(b.sortKey));
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
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_itens.isEmpty) {
      return Container(
        height: 80,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
        ),
        child: Row(children: [
          const Text('🎉', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Text(
            'Nenhuma aula hoje!',
            style: TextStyle(
              color: AppTheme.secondary.withOpacity(0.5),
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ]),
      );
    }

    final scrollOffset =
        _scrollController.hasClients ? _scrollController.offset : 0.0;
    final totalStack =
        _getCardTop(_itens.length - 1) + (_itens.length == 1 ? _heroHeight : _subHeight);
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
                for (int i = _itens.length - 1; i >= 0; i--)
                  _buildStackedCard(i, _itens[i], scrollOffset),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStackedCard(int index, _AgendaItemAluno item, double scrollOffset) {
    final naturalTop = _getCardTop(index);
    final top = (naturalTop - scrollOffset).clamp(0.0, naturalTop);
    final depth = (index - (scrollOffset / (_subHeight + _peekOffset))).clamp(0.0, 10.0);

    return Positioned(
      top: top,
      left: depth * 7.0,
      right: depth * 7.0,
      child: Transform.scale(
        scale: 1.0 - (depth * 0.025).clamp(0.0, 0.07),
        alignment: Alignment.topCenter,
        child: Opacity(
          opacity: (1.0 - depth * 0.08).clamp(0.75, 1.0),
          child: index == 0 ? _buildHeroCard(item) : _buildSubCard(item),
        ),
      ),
    );
  }

  Widget _buildHeroCard(_AgendaItemAluno item) => Container(
        height: _heroHeight,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            )
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
                    item.kindLabel.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                item.horario,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildSubCard(_AgendaItemAluno item) => Container(
        height: _subHeight,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            )
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.07)),
        ),
        child: Row(children: [
          Text(item.horario,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.secondary.withOpacity(0.45))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                Text(item.subtitle,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ]),
      );
}

class _AgendaItemAluno {
  final String kind; // 'aula' | 'evento'
  final String horario;
  final String sortKey;
  final TurmaModel? turma;
  final String? nomeEvento;
  final String? eventoId;

  _AgendaItemAluno._({
    required this.kind,
    required this.horario,
    required this.sortKey,
    this.turma,
    this.nomeEvento,
    this.eventoId,
  });

  factory _AgendaItemAluno.aula({required TurmaModel turma, required String horario}) {
    return _AgendaItemAluno._(
      kind: 'aula',
      horario: horario,
      sortKey: _horaSort(horario),
      turma: turma,
    );
  }

  factory _AgendaItemAluno.evento({required String id, required String nome, required String horario}) {
    return _AgendaItemAluno._(
      kind: 'evento',
      horario: horario,
      sortKey: _horaSort(horario),
      nomeEvento: nome,
      eventoId: id,
    );
  }

  static String _horaSort(String horario) {
    final m = RegExp(r'(\d{1,2}):?(\d{2})').firstMatch(horario);
    if (m == null) return '99:99';
    final h = int.tryParse(m.group(1) ?? '') ?? 99;
    final min = int.tryParse(m.group(2) ?? '') ?? 99;
    return '${h.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';
  }

  String get kindLabel => kind == 'evento' ? 'Evento' : (turma?.modalidade ?? 'Aula');
  String get title => kind == 'evento' ? (nomeEvento ?? 'Evento') : (turma?.nome ?? '');
  String get subtitle => kind == 'evento' ? 'Evento' : (turma?.modalidade ?? '');
}

// ─────────────────────────────────────────────────────────────────
// CARD: PASSO DA SEMANA
// ─────────────────────────────────────────────────────────────────

class _PassoSemanaCard extends StatelessWidget {
  final TurmaModel turma;
  final String? funcao;
  final String uid;
  final bool compact;
  final bool compactUseAccent;
  const _PassoSemanaCard({
    required this.turma,
    required this.funcao,
    required this.uid,
    this.compact = false,
    this.compactUseAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = funcao != null ? '${turma.modalidade} · $funcao' : turma.modalidade;
    if (compact) {
      final passoId = turma.passoSemanaId;
      final passoNome = turma.passoSemanaNome;

      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: SizedBox(
          width: 250,
          height: 140,
          child: (passoId == null || passoNome == null)
              ? Container(
                  height: 140,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.hourglass_empty_rounded, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'Nenhum passo definido.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      )
                    ],
                  ),
                )
              : StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('progressoAluno')
                      .doc('${uid}_$passoId')
                      .snapshots(),
                  builder: (context, snap) {
                    final data =
                        snap.data?.data() as Map<String, dynamic>? ?? {};
                    final status = (data['status'] as String?) ?? '';
                    final dataAprendido = data['dataAprendido'];

                    final isValidado = status == StatusProgresso.validado.name;
                    final isAprendido = status == StatusProgresso.aprendido.name;
                    final isPraticado = status == StatusProgresso.emProgresso.name;
                    final isVisto =
                        status == StatusProgresso.naoAprendido.name &&
                            dataAprendido != null;

                    final stage = isValidado || isAprendido
                        ? 3
                        : isPraticado
                            ? 2
                            : isVisto
                                ? 1
                                : 0;

                    final circleValue = stage / 3.0;
                    final papel = (funcao?.trim().isNotEmpty ?? false)
                        ? funcao!.trim()
                        : 'Aluno';

                    return Container(
                      decoration: BoxDecoration(
                        color: compactUseAccent
                            ? AppTheme.secondary
                            : AppTheme.third,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned(
                            left: 12,
                            top: 10,
                            child: StreamBuilder<DocumentSnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('movimentacoes')
                                  .doc(passoId)
                                  .snapshots(),
                              builder: (context, movSnap) {
                                final movData =
                                    movSnap.data?.data() as Map<String, dynamic>?;
                                final tipo = (movData?['tipo'] as String?) ?? '';
                                final isCoreografia = tipo == 'coreografia';

                                return Icon(
                                  isCoreografia
                                      ? Icons.directions_run_rounded
                                      : Icons.directions_walk_rounded,
                                  size: 20,
                                  color: Colors.white,
                                );
                              },
                            ),
                          ),
                          Positioned(
                            right: 12,
                            top: 8,
                            child: SizedBox(
                              width: 36,
                              height: 36,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value: circleValue,
                                    strokeWidth: 4,
                                    backgroundColor:
                                        Colors.grey.withOpacity(0.35),
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '$stage/3',
                                    style: TextStyle(
                                      color: stage == 0
                                          ? Colors.grey[200]
                                          : Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            left: 12,
                            right: 12,
                            top: 34,
                            bottom: 44,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  passoNome,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  turma.nome,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  turma.modalidade,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  papel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            left: 12,
                            right: 12,
                            bottom: 8,
                            child: SizedBox(
                              height: 36,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 36,
                                    height: 36,
                                    child: TapEffect(
                                      onTap: stage <= 0
                                          ? null
                                          : () async {
                                              if (isValidado) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Este passo já foi validado pelo professor.'),
                                                  ),
                                                );
                                                return;
                                              }

                                              final db =
                                                  FirebaseFirestore.instance;
                                              final docId = '${uid}_$passoId';
                                              final progRef = db
                                                  .collection('progressoAluno')
                                                  .doc(docId);

                                              // Helpers locais (mesma lógica do GamificationService)
                                              int _calcularNivel(int xpTotal) {
                                                const base = 100;
                                                const fator = 1.5;
                                                int nivel = 1;
                                                int xpAcumulado = 0;
                                                while (nivel < 99) {
                                                  final xpNivel =
                                                      (base * (nivel * fator))
                                                          .round();
                                                  if (xpAcumulado + xpNivel >
                                                      xpTotal) break;
                                                  xpAcumulado += xpNivel;
                                                  nivel++;
                                                }
                                                return nivel;
                                              }

                                              if (stage == 1) {
                                                // 1 → 0: remove progresso (volta ao início)
                                                await progRef.delete();
                                              } else if (stage == 2) {
                                                // 2 → 1: volta para "visto"
                                                await progRef.update({
                                                  'status': StatusProgresso
                                                      .naoAprendido.name,
                                                  'dataAprendido': FieldValue
                                                      .serverTimestamp(),
                                                  'xpGanhoAluno': 0,
                                                  'xpGanhoValidacao': 0,
                                                });
                                              } else if (stage == 3) {
                                                // 3 → 2: desfaz "aprendido" (remove XP do aprendizado)
                                                await db.runTransaction((tx) async {
                                                  final alunoRef = db
                                                      .collection('usuarios')
                                                      .doc(uid);
                                                  final alunoSnap =
                                                      await tx.get(alunoRef);
                                                  final alunoData = alunoSnap
                                                          .data() ??
                                                      <String, dynamic>{};
                                                  final xpAtual =
                                                      (alunoData['xp'] as num?)
                                                              ?.toInt() ??
                                                          0;
                                                  final novoXP = (xpAtual -
                                                          gamif.XPRecompensa
                                                              .marcarAprendido)
                                                      .clamp(0, 1 << 31)
                                                      .toInt();
                                                  final novoNivel =
                                                      _calcularNivel(novoXP);

                                                  tx.update(progRef, {
                                                    'status': StatusProgresso
                                                        .emProgresso.name,
                                                    'xpGanhoAluno': 0,
                                                    'xpGanhoValidacao': 0,
                                                  });
                                                  tx.update(alunoRef, {
                                                    'xp': novoXP,
                                                    'nivel': novoNivel,
                                                  });
                                                  tx.update(
                                                    db
                                                        .collection(
                                                            'movimentacoes')
                                                        .doc(passoId),
                                                    {
                                                      'totalAprenderam':
                                                          FieldValue.increment(
                                                              -1),
                                                    },
                                                  );
                                                });
                                              }
                                            },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.14),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: Colors.white
                                                .withOpacity(0.25),
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.undo_rounded,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TapEffect(
                                      onTap: stage >= 3
                                          ? null
                                          : () async {
                                              if (stage == 0) {
                                                final docId = '${uid}_$passoId';
                                                final novo = ProgressoAlunoModel(
                                                  id: docId,
                                                  alunoId: uid,
                                                  movimentacaoId: passoId,
                                                  movimentacaoNome: passoNome,
                                                  modalidade: turma.modalidade,
                                                  status: StatusProgresso.naoAprendido,
                                                  dataAprendido: DateTime.now(),
                                                  xpGanhoAluno: 0,
                                                  xpGanhoValidacao: 0,
                                                );
                                                await FirebaseFirestore.instance
                                                    .collection('progressoAluno')
                                                    .doc(docId)
                                                    .set(novo.toMap());
                                              } else if (stage == 1) {
                                                await FirebaseFirestore.instance
                                                    .collection('progressoAluno')
                                                    .doc('${uid}_$passoId')
                                                    .update({
                                                  'status': StatusProgresso.emProgresso.name,
                                                  'dataAprendido': FieldValue.serverTimestamp(),
                                                  'xpGanhoAluno': 0,
                                                  'xpGanhoValidacao': 0,
                                                });
                                              } else if (stage == 2) {
                                                final movSnap = await FirebaseFirestore
                                                    .instance
                                                    .collection('movimentacoes')
                                                    .doc(passoId)
                                                    .get();
                                                if (!movSnap.exists) return;
                                                final mov = MovimentacaoModel.fromFirestore(movSnap);
                                                await gamif.GamificationService().registrarAprendizado(
                                                  alunoId: uid,
                                                  movimentacao: mov,
                                                );
                                              }
                                            },
                                      child: Container(
                                        height: 36,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          color: stage == 0
                                              ? Colors.white
                                              : stage == 3
                                                  ? AppTheme.detail
                                                  : stage == 2
                                                      ? AppTheme.primary
                                                      : AppTheme.primary
                                                          .withOpacity(0.12),
                                          border: Border.all(
                                            color: stage == 0
                                                ? Colors.grey
                                                    .withOpacity(0.25)
                                                : stage == 2
                                                    ? AppTheme.primary
                                                        .withOpacity(0.2)
                                                    : stage == 3
                                                        ? AppTheme.detail
                                                            .withOpacity(
                                                                0.35)
                                                        : AppTheme.primary
                                                            .withOpacity(
                                                                0.15),
                                            width: 1,
                                          ),
                                        ),
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 7,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              stage == 0
                                                  ? Icons.visibility_outlined
                                                  : stage == 1
                                                      ? Icons
                                                          .play_arrow_rounded
                                                      : stage == 2
                                                          ? Icons
                                                              .emoji_events_rounded
                                                          : Icons
                                                              .check_rounded,
                                              size: 16,
                                              color: (stage == 2 ||
                                                      stage == 3)
                                                  ? Colors.white
                                                  : AppTheme.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              stage == 0
                                                  ? 'Visto'
                                                  : stage == 1
                                                      ? 'Praticado'
                                                      : stage == 2
                                                          ? 'Aprender'
                                                          : 'Aprendido',
                                              style: TextStyle(
                                                color: (stage == 2 ||
                                                        stage == 3)
                                                    ? Colors.white
                                                    : AppTheme.primary,
                                                fontWeight:
                                                    FontWeight.w900,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      );
    }

    return Padding(
      padding: compact
          ? const EdgeInsets.only(right: 12)
          : const EdgeInsets.fromLTRB(25, 0, 25, 12),
      child: Container(
        width: compact ? 250 : null,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 12 : 18,
          vertical: compact ? 8 : 18,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12)],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(label, style: const TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: 8),
            Text(turma.nome, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ]),
          SizedBox(height: compact ? 8 : 12),
          if (turma.passoSemanaNome == null)
            Row(children: [
              Icon(Icons.hourglass_empty_rounded, size: 16, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Text('Nenhum passo definido ainda.', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
            ])
          else
            Row(children: [
              Expanded(child: Row(children: [
                const Icon(Icons.directions_walk_rounded, size: 18, color: AppTheme.secondary),
                const SizedBox(width: 8),
                Expanded(child: Text(turma.passoSemanaNome!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.secondary))),
              ])),
              const SizedBox(width: 12),
              _BotaoAprendi(turmaId: turma.id, passoId: turma.passoSemanaId!, passoNome: turma.passoSemanaNome!, uid: uid),
            ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// BOTÃO APRENDI
// ─────────────────────────────────────────────────────────────────

class _BotaoAprendi extends StatelessWidget {
  final String turmaId, passoId, passoNome, uid;
  const _BotaoAprendi({
    required this.turmaId,
    required this.passoId,
    required this.passoNome,
    required this.uid,
  });

  int _calcularNivel(int xpTotal) {
    const base = 100;
    const fator = 1.5;
    int nivel = 1;
    int xpAcumulado = 0;
    while (nivel < 99) {
      final xpNivel = (base * (nivel * fator)).round();
      if (xpAcumulado + xpNivel > xpTotal) break;
      xpAcumulado += xpNivel;
      nivel++;
    }
    return nivel;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('progressoAluno')
          .doc('${uid}_$passoId')
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>? ?? {};
        final status = (data['status'] as String?) ?? '';
        final dataAprendido = data['dataAprendido'];

        final isValidado = status == StatusProgresso.validado.name;
        final isAprendido = status == StatusProgresso.aprendido.name;
        final isPraticado = status == StatusProgresso.emProgresso.name;
        final isVisto =
            status == StatusProgresso.naoAprendido.name && dataAprendido != null;

        final stage = isValidado || isAprendido
            ? 3
            : isPraticado
                ? 2
                : isVisto
                    ? 1
                    : 0;

        Future<void> avancar() async {
          final db = FirebaseFirestore.instance;
          final docId = '${uid}_$passoId';

          if (stage == 0) {
            final novo = ProgressoAlunoModel(
              id: docId,
              alunoId: uid,
              movimentacaoId: passoId,
              movimentacaoNome: passoNome,
              modalidade: '',
              status: StatusProgresso.naoAprendido,
              dataAprendido: DateTime.now(),
              xpGanhoAluno: 0,
              xpGanhoValidacao: 0,
            );
            await db.collection('progressoAluno').doc(docId).set(novo.toMap());
            return;
          }

          if (stage == 1) {
            await db.collection('progressoAluno').doc(docId).update({
              'status': StatusProgresso.emProgresso.name,
              'dataAprendido': FieldValue.serverTimestamp(),
              'xpGanhoAluno': 0,
              'xpGanhoValidacao': 0,
            });
            return;
          }

          if (stage == 2) {
            final movSnap = await db.collection('movimentacoes').doc(passoId).get();
            if (!movSnap.exists) return;
            final mov = MovimentacaoModel.fromFirestore(movSnap);
            await gamif.GamificationService().registrarAprendizado(
              alunoId: uid,
              movimentacao: mov,
            );
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('🎉 +50 XP! Continue assim!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
            }
          }
        }

        Future<void> voltar() async {
          if (stage <= 0) return;
          if (isValidado) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Este passo já foi validado pelo professor.'),
              ),
            );
            return;
          }

          final db = FirebaseFirestore.instance;
          final docId = '${uid}_$passoId';
          final progRef = db.collection('progressoAluno').doc(docId);

          if (stage == 1) {
            await progRef.delete();
            return;
          }

          if (stage == 2) {
            await progRef.update({
              'status': StatusProgresso.naoAprendido.name,
              'dataAprendido': FieldValue.serverTimestamp(),
              'xpGanhoAluno': 0,
              'xpGanhoValidacao': 0,
            });
            return;
          }

          if (stage == 3) {
            await db.runTransaction((tx) async {
              final alunoRef = db.collection('usuarios').doc(uid);
              final alunoSnap = await tx.get(alunoRef);
              final alunoData = alunoSnap.data() ?? <String, dynamic>{};
              final xpAtual = (alunoData['xp'] as num?)?.toInt() ?? 0;
              final novoXP = (xpAtual - gamif.XPRecompensa.marcarAprendido)
                  .clamp(0, 1 << 31)
                  .toInt();
              final novoNivel = _calcularNivel(novoXP);

              tx.update(progRef, {
                'status': StatusProgresso.emProgresso.name,
                'xpGanhoAluno': 0,
                'xpGanhoValidacao': 0,
              });
              tx.update(alunoRef, {'xp': novoXP, 'nivel': novoNivel});
              tx.update(db.collection('movimentacoes').doc(passoId), {
                'totalAprenderam': FieldValue.increment(-1),
              });
            });
          }
        }

        final mainText = stage == 0
            ? 'Visto'
            : stage == 1
                ? 'Praticado'
                : stage == 2
                    ? 'Aprender'
                    : (isValidado ? 'Validado' : 'Aprendido');

        final mainIcon = stage == 0
            ? Icons.visibility_outlined
            : stage == 1
                ? Icons.play_arrow_rounded
                : stage == 2
                    ? Icons.emoji_events_rounded
                    : Icons.check_rounded;

        final mainBg = stage == 0
            ? Colors.white
            : stage == 3
                ? AppTheme.detail
                : stage == 2
                    ? AppTheme.primary
                    : AppTheme.primary.withOpacity(0.12);

        final mainFg = (stage == 2 || stage == 3) ? Colors.white : AppTheme.primary;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: TapEffect(
                onTap: stage <= 0 ? null : voltar,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.18)),
                  ),
                  child: const Center(
                    child: Icon(Icons.undo_rounded, size: 18, color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            TapEffect(
              onTap: stage >= 3 ? null : avancar,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: mainBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: stage == 0
                        ? Colors.grey.withOpacity(0.25)
                        : stage == 3
                            ? AppTheme.detail.withOpacity(0.35)
                            : AppTheme.primary.withOpacity(0.20),
                    width: 1,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(mainIcon, size: 14, color: mainFg),
                  const SizedBox(width: 6),
                  Text(
                    mainText,
                    style: TextStyle(
                      color: mainFg,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// CARD: CONQUISTA RECENTE
// ─────────────────────────────────────────────────────────────────
