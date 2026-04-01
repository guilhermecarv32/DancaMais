import 'dart:async';

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
  StreamSubscription<QuerySnapshot>? _progressoSub;

  // Cache local: chave "uid|modalidade"
  final Map<String, _AprendizadosCount> _cacheCounts = {};
  final Map<String, Future<_AprendizadosCount>> _inFlight = {};

  String _modalidadeSelecionada = 'Todos';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Mantém o ranking atualizado: quando algum progresso "aprendido" muda,
    // limpamos o cache para forçar o recálculo das contagens.
    _progressoSub = FirebaseFirestore.instance
        .collection('progressoAluno')
        .where('status', whereIn: const ['aprendido', 'validado'])
        .snapshots()
        .listen((_) {
      if (!mounted) return;
      setState(() {
        _cacheCounts.clear();
        _inFlight.clear();
      });
    });
  }

  @override
  void dispose() {
    _progressoSub?.cancel();
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
        // "aprendido" e "validado" contam como aprendido.
        .where('status', whereIn: const ['aprendido', 'validado']);

    if (modalidade != null && modalidade.isNotEmpty && modalidade != 'Todos') {
      base = base.where('modalidade', isEqualTo: modalidade);
    }

    // Contagem por tipo: o doc de progresso não guarda o tipo,
    // então buscamos o tipo na coleção 'movimentacoes'.
    final snap = await base.get();

    final movIds = snap.docs
        .map((d) => (d.data()['movimentacaoId'] as String?)?.trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (movIds.isEmpty) {
      return const _AprendizadosCount(passos: 0, coreografias: 0);
    }

    // Firestore limita whereIn a 10 itens. Fazemos em lotes.
    final Map<String, String> tipoPorMovId = {};
    for (int i = 0; i < movIds.length; i += 10) {
      final chunk = movIds.sublist(i, (i + 10).clamp(0, movIds.length));
      final movSnap = await db
          .collection('movimentacoes')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final d in movSnap.docs) {
        final data = d.data();
        final tipo = (data['tipo'] as String?)?.toLowerCase();
        if (tipo != null && tipo.isNotEmpty) {
          tipoPorMovId[d.id] = tipo;
        }
      }
    }

    int passos = 0;
    int coreos = 0;
    for (final d in snap.docs) {
      final data = d.data();
      final movId = (data['movimentacaoId'] as String?)?.trim() ?? '';
      final tipo = tipoPorMovId[movId];
      if (tipo == 'passo') {
        passos++;
      } else if (tipo == 'coreografia') {
        coreos++;
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
                const SizedBox(height: 30),
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
            offset: const Offset(0, 10),
            child: _PodioCard(
              posicao: 2,
              entry: second,
              color: const Color(0xFFB0BEC5), // prata
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
                color: const Color(0xFFFFC107), // ouro vibrante (#FFC107)
                isVoce: first?.uid == currentUid,
                isDestaque: true,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Transform.translate(
            offset: const Offset(0, 10),
            child: _PodioCard(
              posicao: 3,
              entry: third,
              color: const Color(0xFFCD7F32), // bronze (#CD7F32)
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

    final base = TapEffect(
      onTap: semCompetidor
          ? null
          : () => _abrirDetalhesAluno(context, entry!, posicao),
      child: Container(
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
    final Color? medalColor = switch (posicao) {
      1 => const Color(0xFFFFC107),
      2 => const Color(0xFFB0BEC5),
      3 => const Color(0xFFCD7F32),
      _ => null,
    };

    final BoxBorder? border = isTop3 && medalColor != null
        ? Border.all(color: medalColor.withOpacity(0.75), width: 1.6)
        : (isVoce
            ? Border.all(
                color: AppTheme.primary.withOpacity(0.25),
                width: 1.2,
              )
            : null);

    return TapEffect(
      onTap: () => _abrirDetalhesAluno(context, entry, posicao),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
            return Row(
              children: [
                _PosicaoBadge(posicao: posicao, isTop3: isTop3),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: Colors.grey.withOpacity(0.14),
                        child: Icon(Icons.person_rounded,
                            size: 18, color: Colors.grey[500]),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _primeiroNome(entry.nome),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _ColNum(
                          width: 38,
                          value: entry.nivel.toString(),
                          emphasis: true),
                      _ColNum(width: 38, value: entry.xp.toString()),
                      _ColNum(width: 38, value: entry.passos.toString()),
                      _ColNum(width: 38, value: entry.coreografias.toString()),
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

  String _primeiroNome(String nome) {
    final t = nome.trim();
    if (t.isEmpty) return 'Aluno';
    final parts = t.split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : t;
  }
}

void _abrirDetalhesAluno(BuildContext context, _RankEntry entry, int posicao) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AlunoDetalhesSheet(entry: entry, posicao: posicao),
  );
}

class _AlunoDetalhesSheet extends StatelessWidget {
  final _RankEntry entry;
  final int posicao;
  const _AlunoDetalhesSheet({required this.entry, required this.posicao});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.8,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.fromLTRB(25, 12, 25, 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
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
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppTheme.primary.withOpacity(0.10),
                      child: const Icon(Icons.person_rounded,
                          color: AppTheme.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Nome completo',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entry.nome,
                            style: const TextStyle(
                              color: AppTheme.secondary,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _DetalheRow(label: 'Posição', value: '#$posicao'),
                _DetalheRow(label: 'Nível', value: entry.nivel.toString()),
                _DetalheRow(label: 'XP', value: entry.xp.toString()),
                _DetalheRow(
                    label: 'Passos aprendidos', value: entry.passos.toString()),
                _DetalheRow(
                    label: 'Coreografias aprendidas',
                    value: entry.coreografias.toString()),
                const SizedBox(height: 18),
                const Text(
                  'Turmas',
                  style: TextStyle(
                    color: AppTheme.secondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('inscricoes')
                      .where('alunoId', isEqualTo: entry.uid)
                      .snapshots(),
                  builder: (context, inscSnap) {
                    final docs = inscSnap.data?.docs ?? [];
                    final turmaIds = docs
                        .map((d) => (d.data() as Map<String, dynamic>)['turmaId']
                            as String?)
                        .whereType<String>()
                        .toSet()
                        .toList();
                    if (turmaIds.isEmpty) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          'Nenhuma turma encontrada para este aluno.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: turmaIds.map((turmaId) {
                        return StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('turmas')
                              .doc(turmaId)
                              .snapshots(),
                          builder: (context, turmaSnap) {
                            if (!turmaSnap.hasData || !turmaSnap.data!.exists) {
                              return const SizedBox.shrink();
                            }
                            final data =
                                turmaSnap.data!.data() as Map<String, dynamic>;
                            final nomeTurma = (data['nome'] ?? '').toString();
                            final modalidade =
                                (data['modalidade'] ?? '').toString();
                            final nivel = (data['nivel'] ?? '').toString();
                            return Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color:
                                          AppTheme.primary.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.groups_rounded,
                                      color: AppTheme.primary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nomeTurma.isEmpty
                                              ? 'Turma'
                                              : nomeTurma,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: AppTheme.secondary,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          [modalidade, nivel]
                                              .where((s) => s.trim().isNotEmpty)
                                              .join(' · '),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetalheRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetalheRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.secondary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
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
      return Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            TapEffect(
              onTap: () => _abrirLegendaHeader(context),
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'i',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const SizedBox(width: 28), // espaço do badge de posição (sem círculo)
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Aluno',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.secondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _ColIcon(
              width: 38,
              icon: Icons.trending_up_rounded,
              tooltip: 'Nível',
            ),
            _ColIcon(
              width: 38,
              icon: Icons.bolt_rounded,
              tooltip: 'XP',
            ),
            _ColIcon(
              width: 38,
              icon: Icons.directions_walk_rounded,
              tooltip: 'Passos',
            ),
            _ColIcon(
              width: 38,
              icon: Icons.queue_music_rounded,
              tooltip: 'Coreografias',
            ),
          ],
        ),
      );
    });
  }
}

void _abrirLegendaHeader(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _LegendaHeaderSheet(),
  );
}

class _LegendaHeaderSheet extends StatelessWidget {
  const _LegendaHeaderSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
            'Legenda',
            style: TextStyle(
              color: AppTheme.secondary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          const _LegendaItem(
            icon: Icons.trending_up_rounded,
            title: 'Nível',
            description: 'Nível atual do aluno.',
          ),
          const SizedBox(height: 10),
          const _LegendaItem(
            icon: Icons.bolt_rounded,
            title: 'XP',
            description: 'Experiência total acumulada.',
          ),
          const SizedBox(height: 10),
          const _LegendaItem(
            icon: Icons.directions_walk_rounded,
            title: 'Passos',
            description: 'Quantidade de passos aprendidos.',
          ),
          const SizedBox(height: 10),
          const _LegendaItem(
            icon: Icons.queue_music_rounded,
            title: 'Coreografias',
            description: 'Quantidade de coreografias aprendidas.',
          ),
          const SizedBox(height: 14),
          Text(
            'Ordem do ranking: Nível → XP → Passos → Coreografias',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendaItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _LegendaItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.secondary,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final double width;
  const _ColIcon({required this.width, required this.icon, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Align(
        alignment: Alignment.centerRight,
        child: Tooltip(
          message: tooltip,
          child: Icon(icon, size: 16, color: Colors.grey[700]),
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
    final Color color = isTop3 ? AppTheme.secondary : Colors.grey[600]!;
    return SizedBox(
      width: 24,
      child: Text(
        '#$posicao',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 12,
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