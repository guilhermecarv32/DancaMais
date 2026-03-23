import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/auth_bloc/auth_bloc.dart';
import '../../logic/auth_bloc/auth_event.dart';
import '../../models/models.dart';
import '../widgets/tap_effect.dart';
import 'student_classes_screen.dart';

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
      const _ConquistasScreen(),
      const _HomeScreen(),
      const _RankingScreen(),
      const _PerfilScreen(),
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
              _buildDockItem(0, Icons.auto_stories_rounded),
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

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').doc(uid).snapshots(),
      builder: (context, userSnap) {
        final userData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
        final nome = (userData['nome'] ?? '').toString().trim().split(' ').first;
        final nivel = userData['nivel'] ?? 1;
        final xp = userData['xp'] ?? 0;
        final xpNivel = (100 * nivel * 1.5).round();
        final progresso = (xp / xpNivel).clamp(0.0, 1.0);

        return ListView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 150),
          children: [
            _buildHeader(context, nome, nivel, xp, xpNivel, progresso),
            const SizedBox(height: 24),
            _buildPassosSemana(uid),
            const SizedBox(height: 24),
            _buildConquistasRecentes(uid),
            const SizedBox(height: 24),
            _buildAgenda(uid),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, String nome, int nivel, int xp, int xpNivel, double progresso) {
    final now = DateTime.now();
    final meses = ['janeiro','fevereiro','março','abril','maio','junho','julho','agosto','setembro','outubro','novembro','dezembro'];
    final dias = ['Segunda-feira','Terça-feira','Quarta-feira','Quinta-feira','Sexta-feira','Sábado','Domingo'];
    final dataStr = '${dias[now.weekday - 1]}, ${now.day} de ${meses[now.month - 1]}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Olá, $nome!',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.secondary, letterSpacing: -0.5)),
                    Text(dataStr, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ],
                ),
              ),
              TapEffect(
                onTap: () => context.read<AuthBloc>().add(LogoutRequested()),
                child: Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.logout_rounded, size: 18, color: Colors.grey),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Nível + barra de progresso integrados no header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(18)),
            child: Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text('$nivel',
                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Nível atual',
                              style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
                          Text('$xp / $xpNivel XP',
                              style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progresso,
                          minHeight: 7,
                          backgroundColor: AppTheme.primary.withOpacity(0.12),
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${((1 - progresso) * xpNivel).round()} XP para o nível ${nivel + 1}',
                          style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
            ...inscricoes.map((insc) {
              final data = insc.data() as Map<String, dynamic>;
              final turmaId = data['turmaId'] as String? ?? '';
              final funcao = data['funcao'] as String?;
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('turmas').doc(turmaId).snapshots(),
                builder: (context, turmaSnap) {
                  if (!turmaSnap.hasData) return const SizedBox.shrink();
                  final turma = TurmaModel.fromFirestore(turmaSnap.data!);
                  return _PassoSemanaCard(turma: turma, funcao: funcao, uid: uid);
                },
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildConquistasRecentes(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios').doc(uid).collection('conquistas')
          .orderBy('dataConquista', descending: true).limit(3).snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Conquistas Recentes'),
            const SizedBox(height: 12),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 25, right: 10),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  return _ConquistaCard(icone: data['icone'] ?? '🏅', nome: data['nome'] ?? '', xp: data['xpRecompensa'] ?? 0);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAgenda(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('inscricoes').where('alunoId', isEqualTo: uid).snapshots(),
      builder: (context, inscSnap) {
        final turmaIds = inscSnap.data?.docs
                .map((d) => (d.data() as Map<String, dynamic>)['turmaId'] as String?)
                .whereType<String>().toList() ?? [];
        if (turmaIds.isEmpty) return const SizedBox.shrink();
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('turmas')
              .where(FieldPath.documentId, whereIn: turmaIds).snapshots(),
          builder: (context, turmasSnap) {
            final turmas = turmasSnap.data?.docs
                    .map((d) => TurmaModel.fromFirestore(d))
                    .where((t) => t.horariosDia.isNotEmpty).toList() ?? [];
            if (turmas.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Minha Agenda'),
                const SizedBox(height: 12),
                ...turmas.map((turma) => Padding(
                  padding: const EdgeInsets.fromLTRB(25, 0, 25, 12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.groups_rounded, color: AppTheme.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(turma.nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.secondary)),
                          Text('${turma.modalidade} · ${turma.nivel}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ])),
                      ]),
                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFF0F0F0)),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8, runSpacing: 6,
                        children: turma.horariosDia.map((h) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(10)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Text(h.dia, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.secondary)),
                            const SizedBox(width: 6),
                            Text(h.horario, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ]),
                        )).toList(),
                      ),
                    ]),
                  ),
                )),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 25),
    child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
  );
}

// ─────────────────────────────────────────────────────────────────
// CARD: PASSO DA SEMANA
// ─────────────────────────────────────────────────────────────────

class _PassoSemanaCard extends StatelessWidget {
  final TurmaModel turma;
  final String? funcao;
  final String uid;
  const _PassoSemanaCard({required this.turma, required this.funcao, required this.uid});

  @override
  Widget build(BuildContext context) {
    final label = funcao != null ? '${turma.modalidade} · $funcao' : turma.modalidade;
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 12),
      child: Container(
        padding: const EdgeInsets.all(18),
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
          const SizedBox(height: 12),
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
  const _BotaoAprendi({required this.turmaId, required this.passoId, required this.passoNome, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios').doc(uid).collection('aprendizados').doc(passoId).snapshots(),
      builder: (context, snap) {
        final jaAprendeu = snap.data?.exists ?? false;
        if (jaAprendeu) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withOpacity(0.3), width: 1),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check_rounded, size: 14, color: Colors.green),
              SizedBox(width: 4),
              Text('Aprendi!', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
            ]),
          );
        }
        return TapEffect(
          onTap: () => _marcarAprendi(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.emoji_events_rounded, size: 14, color: Colors.white),
              SizedBox(width: 4),
              Text('Aprendi!', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ]),
          ),
        );
      },
    );
  }

  Future<void> _marcarAprendi(BuildContext context) async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    batch.set(
      db.collection('usuarios').doc(uid).collection('aprendizados').doc(passoId),
      {'passoId': passoId, 'passoNome': passoNome, 'turmaId': turmaId, 'dataAprendizado': FieldValue.serverTimestamp(), 'validado': false},
    );
    batch.update(db.collection('usuarios').doc(uid), {'xp': FieldValue.increment(50)});
    await batch.commit();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('🎉 +50 XP! Continue assim!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }
}

// ─────────────────────────────────────────────────────────────────
// CARD: CONQUISTA RECENTE
// ─────────────────────────────────────────────────────────────────

class _ConquistaCard extends StatelessWidget {
  final String icone, nome;
  final int xp;
  const _ConquistaCard({required this.icone, required this.nome, required this.xp});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(icone, style: const TextStyle(fontSize: 28)),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(nome, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.secondary),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Row(children: [
            const Icon(Icons.bolt_rounded, size: 12, color: AppTheme.primary),
            Text('+$xp XP', style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// TELAS PLACEHOLDER
// ─────────────────────────────────────────────────────────────────

class _BibliotecaScreen extends StatelessWidget {
  const _BibliotecaScreen();
  @override
  Widget build(BuildContext context) => _Placeholder(icon: Icons.auto_stories_rounded, label: 'Meus Passos');
}

class _ConquistasScreen extends StatelessWidget {
  const _ConquistasScreen();
  @override
  Widget build(BuildContext context) => _Placeholder(icon: Icons.workspace_premium_rounded, label: 'Conquistas');
}

class _RankingScreen extends StatelessWidget {
  const _RankingScreen();
  @override
  Widget build(BuildContext context) => _Placeholder(icon: Icons.leaderboard_rounded, label: 'Ranking');
}

class _PerfilScreen extends StatelessWidget {
  const _PerfilScreen();
  @override
  Widget build(BuildContext context) => _Placeholder(icon: Icons.person_rounded, label: 'Perfil');
}

class _Placeholder extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Placeholder({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 48, color: Colors.grey[300]),
        const SizedBox(height: 12),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Em breve', style: TextStyle(color: Colors.grey[300], fontSize: 13)),
      ]),
    );
  }
}