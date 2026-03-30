import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/tap_effect.dart';

class StudentRankingScreen extends StatefulWidget {
  const StudentRankingScreen({super.key});

  @override
  State<StudentRankingScreen> createState() => _StudentRankingScreenState();
}

class _StudentRankingScreenState extends State<StudentRankingScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Cache local: chave "uid|modalidade"
  final Map<String, _AprendizadosCount> _cacheCounts = {};
  final Map<String, Future<_AprendizadosCount>> _inFlight = {};

  String _modalidadeSelecionada = 'Todos';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Header(),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 10, 25, 0),
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.primary,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(text: 'Geral'),
                  Tab(text: 'Por Modalidade'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _RankingTab(
                    currentUid: uid,
                    modalidade: null,
                    carregarCounts: _carregarCountsPara,
                  ),
                  _RankingPorModalidadeTab(
                    currentUid: uid,
                    modalidadeSelecionada: _modalidadeSelecionada,
                    onChangedModalidade: (m) =>
                        setState(() => _modalidadeSelecionada = m),
                    carregarCounts: _carregarCountsPara,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<_AprendizadosCount> _carregarCountsPara(
    String alunoId, {
    String? modalidade,
  }) {
    final key = '${alunoId}|${modalidade ?? 'Todos'}';
    final cached = _cacheCounts[key];
    if (cached != null) return Future.value(cached);

    final inflight = _inFlight[key];
    if (inflight != null) return inflight;

    final future = _buscarCounts(alunoId, modalidade: modalidade).then((c) {
      _cacheCounts[key] = c;
      _inFlight.remove(key);
      return c;
    });
    _inFlight[key] = future;
    return future;
  }

  Future<_AprendizadosCount> _buscarCounts(
    String alunoId, {
    String? modalidade,
  }) async {
    final db = FirebaseFirestore.instance;

    Query<Map<String, dynamic>> base = db
        .collection('progressoAluno')
        .where('alunoId', isEqualTo: alunoId)
        .where('status', isEqualTo: 'aprendido');

    if (modalidade != null && modalidade.isNotEmpty && modalidade != 'Todos') {
      base = base.where('modalidade', isEqualTo: modalidade);
    }

    // Contagem por tipo requer olhar os docs (sem count aggregation).
    final snap = await base.get();

    int passos = 0;
    int coreos = 0;
    for (final d in snap.docs) {
      final data = d.data();
      final isPasso = (data['movimentacaoTipo'] == 'passo') ||
          (data['tipo'] == 'passo') ||
          (data['movimentacaoIsPasso'] == true);
      final isCoreo = (data['movimentacaoTipo'] == 'coreografia') ||
          (data['tipo'] == 'coreografia') ||
          (data['movimentacaoIsCoreografia'] == true);

      // Fallback: se não tiver tipo salvo, tenta inferir pela existência de campos.
      if (isPasso) {
        passos++;
      } else if (isCoreo) {
        coreos++;
      } else {
        // Sem tipo: não incrementa (evita distorcer). Pode ajustar quando padronizar o schema.
      }
    }

    return _AprendizadosCount(passos: passos, coreografias: coreos);
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ranking',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppTheme.secondary,
              letterSpacing: -1,
            ),
          ),
          Text('Veja sua posição e evolua',
              style: TextStyle(color: Colors.grey[600], fontSize: 15)),
        ],
      ),
    );
  }
}

typedef CarregarCounts = Future<_AprendizadosCount> Function(
  String alunoId, {
  String? modalidade,
});

class _RankingTab extends StatelessWidget {
  final String currentUid;
  final String? modalidade;
  final CarregarCounts carregarCounts;
  final Set<String>? allowedUids;

  const _RankingTab({
    required this.currentUid,
    required this.modalidade,
    required this.carregarCounts,
    this.allowedUids,
  });

  @override
  Widget build(BuildContext context) {
    final q = FirebaseFirestore.instance
        .collection('usuarios')
        .where('tipo', isEqualTo: 'aluno');

    return StreamBuilder<QuerySnapshot>(
      stream: q.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data?.docs ?? [];
        final filtered = allowedUids == null
            ? docs
            : docs.where((d) => allowedUids!.contains(d.id)).toList();

        if (filtered.isEmpty) {
          return const _EmptyRanking();
        }

        return FutureBuilder<List<_RankEntry>>(
          future: _montarRanking(filtered),
          builder: (context, rankingSnap) {
            if (!rankingSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final ranking = rankingSnap.data ?? [];
            if (ranking.isEmpty) return const _EmptyRanking();

            return ListView(
              padding: const EdgeInsets.fromLTRB(25, 14, 25, 140),
              children: [
                _Podio(
                  entries: ranking.take(3).toList(),
                  currentUid: currentUid,
                ),
                const SizedBox(height: 12),
                const _TabelaHeader(),
                const SizedBox(height: 16),
                ...ranking.asMap().entries.map((e) {
                  final pos = e.key + 1;
                  final entry = e.value;
                  return _RankTile(
                    posicao: pos,
                    entry: entry,
                    isVoce: entry.uid == currentUid,
                    isTop3: pos <= 3,
                  );
                }),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<_RankEntry>> _montarRanking(List<QueryDocumentSnapshot> docs) async {
    final entries = await Future.wait(docs.map((d) async {
      final data = d.data() as Map<String, dynamic>;
      final uid = d.id;
      final nome = (data['nome'] ?? 'Aluno').toString();
      final nivel = (data['nivel'] ?? 1) as int;
      final xp = (data['xp'] ?? 0) as int;
      final counts = await carregarCounts(uid, modalidade: modalidade);
      return _RankEntry(
        uid: uid,
        nome: nome,
        nivel: nivel,
        xp: xp,
        passos: counts.passos,
        coreografias: counts.coreografias,
      );
    }));

    entries.sort((a, b) {
      final byNivel = b.nivel.compareTo(a.nivel);
      if (byNivel != 0) return byNivel;
      final byXp = b.xp.compareTo(a.xp);
      if (byXp != 0) return byXp;
      final byPassos = b.passos.compareTo(a.passos);
      if (byPassos != 0) return byPassos;
      final byCoreo = b.coreografias.compareTo(a.coreografias);
      if (byCoreo != 0) return byCoreo;
      return a.nome.toLowerCase().compareTo(b.nome.toLowerCase());
    });

    return entries;
  }
}

class _RankingPorModalidadeTab extends StatelessWidget {
  final String currentUid;
  final String modalidadeSelecionada;
  final ValueChanged<String> onChangedModalidade;
  final CarregarCounts carregarCounts;

  const _RankingPorModalidadeTab({
    required this.currentUid,
    required this.modalidadeSelecionada,
    required this.onChangedModalidade,
    required this.carregarCounts,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('escola')
          .doc('config')
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final mods = ['Todos', ...List<String>.from(data?['modalidades'] ?? [])];
        final selected =
            mods.contains(modalidadeSelecionada) ? modalidadeSelecionada : 'Todos';

        final dropdown = Padding(
          padding: const EdgeInsets.fromLTRB(25, 14, 25, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selected,
                isExpanded: true,
                items: mods
                    .map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(m, style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  onChangedModalidade(v);
                },
              ),
            ),
          ),
        );

        // "Todos" => comportamento igual ao Geral
        if (selected == 'Todos') {
          return Column(
            children: [
              dropdown,
              const SizedBox(height: 6),
              Expanded(
                child: _RankingTab(
                  currentUid: currentUid,
                  modalidade: null,
                  carregarCounts: carregarCounts,
                ),
              ),
            ],
          );
        }

        // Modalidade específica: alunos precisam estar inscritos em turmas dessa modalidade
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('turmas')
              .where('modalidade', isEqualTo: selected)
              .snapshots(),
          builder: (context, turmasSnap) {
            final turmaIds = (turmasSnap.data?.docs ?? []).map((d) => d.id).toSet();
            if (turmaIds.isEmpty) {
              return Column(
                children: [
                  dropdown,
                  const SizedBox(height: 16),
                  const Expanded(child: _EmptyRanking()),
                ],
              );
            }

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('inscricoes').snapshots(),
              builder: (context, inscSnap) {
                final inscDocs = inscSnap.data?.docs ?? [];
                final alunoIds = <String>{};
                for (final d in inscDocs) {
                  final data = d.data() as Map<String, dynamic>;
                  final turmaId = (data['turmaId'] as String?) ?? '';
                  if (!turmaIds.contains(turmaId)) continue;
                  final alunoId = (data['alunoId'] as String?) ?? '';
                  if (alunoId.isEmpty) continue;
                  alunoIds.add(alunoId);
                }

                return Column(
                  children: [
                    dropdown,
                    const SizedBox(height: 6),
                    Expanded(
                      child: _RankingTab(
                        currentUid: currentUid,
                        modalidade: selected,
                        carregarCounts: carregarCounts,
                        allowedUids: alunoIds,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _Podio extends StatelessWidget {
  final List<_RankEntry> entries;
  final String currentUid;
  const _Podio({required this.entries, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    final first = entries.length > 0 ? entries[0] : null;
    final second = entries.length > 1 ? entries[1] : null;
    final third = entries.length > 2 ? entries[2] : null;

    return Row(
      children: [
        Expanded(
          child: Transform.translate(
            offset: const Offset(0, 6),
            child: _PodioCard(
              posicao: 2,
              entry: second,
              color: const Color(0xFF90A4AE), // prata (cinza azulado)
              isVoce: second?.uid == currentUid,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Transform.translate(
            offset: const Offset(0, -14),
            child: Transform.scale(
              scale: 1.14,
              child: _PodioCard(
                posicao: 1,
                entry: first,
                color: const Color(0xFFFFC107), // ouro (amarelo vibrante)
                isVoce: first?.uid == currentUid,
                isDestaque: true,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Transform.translate(
            offset: const Offset(0, 6),
            child: _PodioCard(
              posicao: 3,
              entry: third,
              color: const Color(0xFFD17A22), // bronze (laranja acobreado)
              isVoce: third?.uid == currentUid,
            ),
          ),
        ),
      ],
    );
  }
}

class _PodioCard extends StatelessWidget {
  final int posicao;
  final _RankEntry? entry;
  final Color color;
  final bool isVoce;
  final bool isDestaque;

  const _PodioCard({
    required this.posicao,
    required this.entry,
    required this.color,
    required this.isVoce,
    this.isDestaque = false,
  });

  @override
  Widget build(BuildContext context) {
    final nome = entry?.nome ?? 'Aguardando competidor';
    final bool semCompetidor = entry == null;

    final base = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: (isVoce && !semCompetidor)
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primary.withOpacity(0.10),
                  Colors.white,
                ],
              )
            : null,
        color: (isVoce && !semCompetidor) ? null : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isVoce && !semCompetidor
              ? AppTheme.primary.withOpacity(0.55)
              : Colors.grey.withOpacity(semCompetidor ? 0.18 : 0),
          width: isVoce && !semCompetidor ? 2.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (isVoce && !semCompetidor)
                ? AppTheme.primary.withOpacity(0.10)
                : Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.55),
              ),
              child: Center(
                child: Text(
                  '$posicao',
                  style: TextStyle(
                    color: AppTheme.secondary.withOpacity(0.9),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const Spacer(),
            if (isVoce)
              const Icon(Icons.person_rounded,
                  size: 18, color: AppTheme.primary),
          ]),
          const SizedBox(height: 10),
          Text(
            nome,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: semCompetidor ? Colors.grey[500] : AppTheme.secondary,
            ),
          ),
          if (entry != null)
            Row(
              children: [
                const Icon(Icons.trending_up_rounded,
                    size: 12, color: AppTheme.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Nível ${entry!.nivel}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11),
                  ),
                ),
              ],
            )
        ],
      ),
    );

    if (!semCompetidor) return base;
    return Opacity(opacity: 0.60, child: base);
  }
}

class _RankTile extends StatelessWidget {
  final int posicao;
  final _RankEntry entry;
  final bool isVoce;
  final bool isTop3;

  const _RankTile({
    required this.posicao,
    required this.entry,
    required this.isVoce,
    required this.isTop3,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isVoce ? AppTheme.primary.withOpacity(0.08) : Colors.white;
    final border = isVoce
        ? Border.all(color: AppTheme.primary.withOpacity(0.25), width: 1.2)
        : null;

    return TapEffect(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
          border: border,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final available = c.maxWidth;
            final colW =
                ((available - 44 - 12 - 90 - 12) / 4).clamp(46.0, 62.0);
            return Row(
              children: [
                _PosicaoBadge(posicao: posicao, isTop3: isTop3),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _ColNum(
                          width: colW,
                          value: entry.nivel.toString(),
                          emphasis: true),
                      _ColNum(width: colW, value: entry.xp.toString()),
                      _ColNum(width: colW, value: entry.passos.toString()),
                      _ColNum(width: colW, value: entry.coreografias.toString()),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TabelaHeader extends StatelessWidget {
  const _TabelaHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final available = c.maxWidth;
      final colW =
          ((available - 44 - 12 - 90 - 12) / 4).clamp(46.0, 62.0);
      return Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withOpacity(0.12)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 44), // espaço do badge de posição
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Aluno',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _ColLabel(width: colW, text: 'NÍVEL'),
            _ColLabel(width: colW, text: 'XP'),
            _ColLabel(width: colW, text: 'PASSOS'),
            _ColLabel(width: colW, text: 'COREOS'),
          ],
        ),
      );
    });
  }
}

class _ColLabel extends StatelessWidget {
  final String text;
  final double width;
  const _ColLabel({required this.width, required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        textAlign: TextAlign.right,
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _ColNum extends StatelessWidget {
  final String value;
  final bool emphasis;
  final double width;
  const _ColNum({required this.width, required this.value, this.emphasis = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        textAlign: TextAlign.right,
        style: TextStyle(
          color: emphasis ? AppTheme.primary : Colors.grey[700],
          fontSize: 13,
          fontWeight: emphasis ? FontWeight.w900 : FontWeight.w700,
        ),
      ),
    );
  }
}

class _PosicaoBadge extends StatelessWidget {
  final int posicao;
  final bool isTop3;
  const _PosicaoBadge({required this.posicao, required this.isTop3});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (posicao == 1) {
      color = const Color(0xFFFFD54F);
    } else if (posicao == 2) {
      color = const Color(0xFFB0BEC5);
    } else if (posicao == 3) {
      color = const Color(0xFFFFAB91);
    } else {
      color = Colors.grey[400]!;
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: (isTop3 ? color : Colors.grey[200]!).withOpacity(0.35),
      ),
      child: Center(
        child: Text(
          '#$posicao',
          style: TextStyle(
            color: isTop3 ? AppTheme.secondary : Colors.grey[600],
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _EmptyRanking extends StatelessWidget {
  const _EmptyRanking();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.leaderboard_rounded, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text('Nenhum aluno encontrado.',
              style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Assim que houver alunos cadastrados, o ranking aparece aqui.',
              style: TextStyle(color: Colors.grey[350], fontSize: 13),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _RankEntry {
  final String uid;
  final String nome;
  final int nivel;
  final int xp;
  final int passos;
  final int coreografias;

  const _RankEntry({
    required this.uid,
    required this.nome,
    required this.nivel,
    required this.xp,
    required this.passos,
    required this.coreografias,
  });
}

class _AprendizadosCount {
  final int passos;
  final int coreografias;
  const _AprendizadosCount({required this.passos, required this.coreografias});
}

