import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../widgets/tap_effect.dart';

class StudentClassesScreen extends StatelessWidget {
  const StudentClassesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(child: _buildBody(context, uid)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(25, 25, 25, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Turmas',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.secondary,
                  letterSpacing: -1)),
          Text('Suas turmas e turmas disponíveis',
              style: TextStyle(color: Colors.grey, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('inscricoes')
          .where('alunoId', isEqualTo: uid)
          .snapshots(),
      builder: (context, inscSnap) {
        final inscricoes = inscSnap.data?.docs ?? [];
        final turmaIdsInscritas = inscricoes
            .map((d) => (d.data() as Map<String, dynamic>)['turmaId'] as String?)
            .whereType<String>()
            .toSet();

        // Mapa turmaId -> funcao para as inscritas
        final funcaoPorTurma = {
          for (final d in inscricoes)
            (d.data() as Map<String, dynamic>)['turmaId'] as String? ?? '':
                (d.data() as Map<String, dynamic>)['funcao'] as String?,
        };

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('turmas').snapshots(),
          builder: (context, turmasSnap) {
            final todasTurmas = turmasSnap.data?.docs
                    .map((d) => TurmaModel.fromFirestore(d))
                    .toList() ??
                [];

            final minhasTurmas = todasTurmas
                .where((t) => turmaIdsInscritas.contains(t.id))
                .toList();
            final disponiveis = todasTurmas
                .where((t) => !turmaIdsInscritas.contains(t.id))
                .toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(25, 10, 25, 120),
              children: [
                // ── Minhas Turmas ──────────────────────────────
                if (minhasTurmas.isEmpty)
                  _EmptySection(
                    emoji: '🎓',
                    texto: 'Você ainda não está em nenhuma turma.',
                  )
                else ...[
                  ...minhasTurmas.map((turma) => _TurmaCard(
                        turma: turma,
                        funcao: funcaoPorTurma[turma.id],
                        inscrita: true,
                        uid: uid,
                        onTap: () => _abrirDetalhes(
                            context, turma, funcaoPorTurma[turma.id], uid),
                      )),
                ],

                // ── Explorar ───────────────────────────────────
                const SizedBox(height: 8),
                _SectionTitle(
                  title: 'Explorar Turmas',
                  subtitle: 'Solicite entrada em uma nova turma',
                ),
                const SizedBox(height: 12),

                if (disponiveis.isEmpty)
                  _EmptySection(
                    emoji: '✅',
                    texto: 'Você está em todas as turmas disponíveis!',
                  )
                else
                  ...disponiveis.map((turma) => _TurmaCard(
                        turma: turma,
                        funcao: null,
                        inscrita: false,
                        uid: uid,
                        onTap: () =>
                            _abrirSolicitacao(context, turma, uid),
                      )),
              ],
            );
          },
        );
      },
    );
  }

  void _abrirDetalhes(
      BuildContext context, TurmaModel turma, String? funcao, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _TurmaDetalheSheet(turma: turma, funcao: funcao, uid: uid),
    );
  }

  void _abrirSolicitacao(
      BuildContext context, TurmaModel turma, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SolicitacaoSheet(turma: turma, uid: uid),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// CARD DA TURMA
// ─────────────────────────────────────────────────────────────────

class _TurmaCard extends StatelessWidget {
  final TurmaModel turma;
  final String? funcao;
  final bool inscrita;
  final String uid;
  final VoidCallback onTap;

  const _TurmaCard({
    required this.turma,
    required this.funcao,
    required this.inscrita,
    required this.uid,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapEffect(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: inscrita
              ? null
              : Border.all(color: Colors.grey.withOpacity(0.12), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(inscrita ? 0.04 : 0.02),
                blurRadius: 10)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: inscrita
                      ? AppTheme.primary.withOpacity(0.08)
                      : Colors.grey.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.groups_rounded,
                    color: inscrita ? AppTheme.primary : Colors.grey[400]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(turma.nome,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppTheme.secondary)),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Tag(turma.modalidade, Colors.grey),
                        _Tag(turma.nivel, AppTheme.primary),
                        if (funcao != null) _Tag(funcao!, AppTheme.secondary),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 46,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${turma.totalAlunos}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: inscrita
                              ? AppTheme.primary
                              : Colors.grey[400]),
                    ),
                    const Text('alunos',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ]),
            if (!inscrita) ...[
              const SizedBox(height: 12),
              // Status da solicitação
              _StatusSolicitacao(turmaId: turma.id, uid: uid),
            ],
            if (inscrita && turma.horariosDia.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 6,
                children: turma.horariosDia.map((h) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(10)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(h.dia,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: AppTheme.secondary)),
                    const SizedBox(width: 6),
                    Text(h.horario,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.grey)),
                  ]),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// STATUS DA SOLICITAÇÃO (inline no card)
// ─────────────────────────────────────────────────────────────────

class _StatusSolicitacao extends StatelessWidget {
  final String turmaId;
  final String uid;

  const _StatusSolicitacao({required this.turmaId, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('solicitacoes')
          .doc(turmaId)
          .collection('pendentes')
          .doc(uid)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) {
          return Row(children: [
            Icon(Icons.add_circle_outline_rounded,
                size: 14, color: Colors.grey[400]),
            const SizedBox(width: 6),
            Text('Toque para solicitar entrada',
                style: TextStyle(color: Colors.grey[400], fontSize: 12)),
          ]);
        }
        // Solicitação pendente
        return Row(children: [
          Icon(Icons.hourglass_top_rounded,
              size: 14, color: Colors.orange[400]),
          const SizedBox(width: 6),
          Text('Solicitação pendente',
              style: TextStyle(
                  color: Colors.orange[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ]);
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// BOTTOM SHEET: SOLICITAR ENTRADA
// ─────────────────────────────────────────────────────────────────

class _SolicitacaoSheet extends StatefulWidget {
  final TurmaModel turma;
  final String uid;

  const _SolicitacaoSheet({required this.turma, required this.uid});

  @override
  State<_SolicitacaoSheet> createState() => _SolicitacaoSheetState();
}

class _SolicitacaoSheetState extends State<_SolicitacaoSheet> {
  final _funcaoCtrl = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _funcaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviarSolicitacao() async {
    setState(() => _enviando = true);

    // Busca nome do aluno
    final userDoc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(widget.uid)
        .get();
    final nomeAluno =
        (userDoc.data() ?? {})['nome'] ?? '';

    await FirebaseFirestore.instance
        .collection('solicitacoes')
        .doc(widget.turma.id)
        .collection('pendentes')
        .doc(widget.uid)
        .set({
      'alunoId': widget.uid,
      'nomeAluno': nomeAluno,
      'turmaId': widget.turma.id,
      'nomeTurma': widget.turma.nome,
      'funcao': _funcaoCtrl.text.trim().isEmpty ? null : _funcaoCtrl.text.trim(),
      'dataSolicitacao': FieldValue.serverTimestamp(),
    });

    if (mounted) Navigator.pop(context);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('✅ Solicitação enviada! Aguarde a aprovação do professor.'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('solicitacoes')
          .doc(widget.turma.id)
          .collection('pendentes')
          .doc(widget.uid)
          .snapshots(),
      builder: (context, snap) {
        final jaSolicitou = snap.data?.exists ?? false;

        return Container(
          padding: EdgeInsets.fromLTRB(25, 25, 25, 25 + bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),

              // Info da turma
              Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.groups_rounded,
                      color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.turma.nome,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppTheme.secondary)),
                      Text(
                          '${widget.turma.modalidade} · ${widget.turma.nivel}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                    ])),
              ]),
              const SizedBox(height: 20),

              if (jaSolicitou) ...[
                // Já solicitou
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    Icon(Icons.hourglass_top_rounded,
                        color: Colors.orange[600], size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Solicitação enviada',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange[700],
                                  fontSize: 14)),
                          Text(
                              'Aguardando aprovação do professor da turma.',
                              style: TextStyle(
                                  color: Colors.orange[500],
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
                // Botão cancelar solicitação
                TapEffect(
                  onTap: () async {
                    await FirebaseFirestore.instance
                        .collection('solicitacoes')
                        .doc(widget.turma.id)
                        .collection('pendentes')
                        .doc(widget.uid)
                        .delete();
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.red.withOpacity(0.2)),
                    ),
                    child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close_rounded,
                              color: Colors.redAccent, size: 18),
                          SizedBox(width: 8),
                          Text('Cancelar solicitação',
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                        ]),
                  ),
                ),
              ] else ...[
                // Se a turma tem papéis definidos, mostra como chips
                if (widget.turma.papeisAlunos.isNotEmpty) ...[
                  Text('Qual será seu papel nesta turma?',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.grey[600])),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: widget.turma.papeisAlunos.map((papel) {
                      final sel = _funcaoCtrl.text == papel;
                      return TapEffect(
                        onTap: () => setState(() =>
                            _funcaoCtrl.text = sel ? '' : papel),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppTheme.primary.withOpacity(0.1)
                                : AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel
                                  ? AppTheme.primary
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            if (sel) ...[
                              const Icon(Icons.check_rounded,
                                  size: 14, color: AppTheme.primary),
                              const SizedBox(width: 4),
                            ],
                            Text(papel,
                                style: TextStyle(
                                    color: sel
                                        ? AppTheme.primary
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                ] else ...[
                  // Turma sem papéis definidos: campo livre opcional
                  Text('Qual sua função nesta turma? (opcional)',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(14)),
                    child: TextField(
                      controller: _funcaoCtrl,
                      decoration: InputDecoration(
                        hintText: 'Ex: Condutor, Conduzido, Ambos...',
                        hintStyle: TextStyle(
                            color: Colors.grey[400], fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                TapEffect(
                  onTap: _enviando ? null : _enviarSolicitacao,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: AppTheme.primary.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4)),
                      ],
                    ),
                    child: _enviando
                        ? const Center(
                            child: SizedBox(
                                height: 22, width: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2)))
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 8),
                              Text('Solicitar Entrada',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                            ]),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// BOTTOM SHEET: DETALHES DA TURMA (inscrita)
// ─────────────────────────────────────────────────────────────────

class _TurmaDetalheSheet extends StatefulWidget {
  final TurmaModel turma;
  final String? funcao;
  final String uid;

  const _TurmaDetalheSheet(
      {required this.turma, required this.funcao, required this.uid});

  @override
  State<_TurmaDetalheSheet> createState() => _TurmaDetalheSheetState();
}

class _TurmaDetalheSheetState extends State<_TurmaDetalheSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    final turma = widget.turma;
    final label = widget.funcao != null
        ? '${turma.modalidade} · ${widget.funcao}'
        : turma.modalidade;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(25, 0, 25, 0),
              child: Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.groups_rounded,
                      color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(turma.nome,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: AppTheme.secondary)),
                      Text(label,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                    ])),
              ]),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primary,
                unselectedLabelColor: Colors.grey,
                indicatorColor: AppTheme.primary,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(text: 'Passo da Semana'),
                  Tab(text: 'Alunos'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _PassoTab(turma: turma, uid: widget.uid),
                  _AlunosTab(turmaId: turma.id),
                ],
              ),
            ),
          ]),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// ABA: PASSO DA SEMANA
// ─────────────────────────────────────────────────────────────────

class _PassoTab extends StatelessWidget {
  final TurmaModel turma;
  final String uid;

  const _PassoTab({required this.turma, required this.uid});

  @override
  Widget build(BuildContext context) {
    if (turma.passoSemanaNome == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.hourglass_empty_rounded, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text('Nenhum passo definido ainda.',
                style: TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('O professor ainda não definiu o passo desta semana.',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
                textAlign: TextAlign.center),
          ]),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(25),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: AppTheme.surface, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Passo desta semana',
                style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.directions_walk_rounded, color: AppTheme.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(turma.passoSemanaNome!,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.secondary)),
              ),
            ]),
            const SizedBox(height: 20),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios').doc(uid)
                  .collection('aprendizados').doc(turma.passoSemanaId).snapshots(),
              builder: (context, snap) {
                final jaAprendeu = snap.data?.exists ?? false;
                if (jaAprendeu) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                      SizedBox(width: 8),
                      Text('Você já marcou como aprendido!',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                    ]),
                  );
                }
                return TapEffect(
                  onTap: () => _marcarAprendi(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
                    ),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.emoji_events_rounded, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Marcar como Aprendi!',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ]),
                  ),
                );
              },
            ),
          ]),
        ),
      ],
    );
  }

  Future<void> _marcarAprendi(BuildContext context) async {
    final db = FirebaseFirestore.instance;
    final batch = db.batch();
    batch.set(
      db.collection('usuarios').doc(uid).collection('aprendizados').doc(turma.passoSemanaId),
      {'passoId': turma.passoSemanaId, 'passoNome': turma.passoSemanaNome, 'turmaId': turma.id,
       'dataAprendizado': FieldValue.serverTimestamp(), 'validado': false},
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
// ABA: ALUNOS DA TURMA
// ─────────────────────────────────────────────────────────────────

class _AlunosTab extends StatelessWidget {
  final String turmaId;
  const _AlunosTab({required this.turmaId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('inscricoes').where('turmaId', isEqualTo: turmaId).snapshots(),
      builder: (context, inscSnap) {
        final alunoIds = inscSnap.data?.docs
                .map((d) => (d.data() as Map<String, dynamic>)['alunoId'] as String?)
                .whereType<String>().toList() ?? [];
        if (alunoIds.isEmpty) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('👥', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text('Nenhum aluno nesta turma.', style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold)),
          ]));
        }
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('usuarios').where(FieldPath.documentId, whereIn: alunoIds).snapshots(),
          builder: (context, alunosSnap) {
            final alunos = alunosSnap.data?.docs ?? [];
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(25, 16, 25, 30),
              itemCount: alunos.length,
              itemBuilder: (_, i) {
                final data = alunos[i].data() as Map<String, dynamic>;
                final nome = data['nome'] ?? 'Aluno';
                final nivel = data['nivel'] ?? 1;
                final xp = data['xp'] ?? 0;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.primary.withOpacity(0.12),
                      child: Text(nome[0].toUpperCase(),
                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(nome,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.secondary))),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('Nível $nivel', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primary)),
                      Text('$xp XP', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                    ]),
                  ]),
                );
              },
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// WIDGETS AUXILIARES
// ─────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionTitle({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
      if (subtitle != null)
        Text(subtitle!, style: TextStyle(color: Colors.grey[400], fontSize: 13)),
    ]);
  }
}

class _EmptySection extends StatelessWidget {
  final String emoji;
  final String texto;
  const _EmptySection({required this.emoji, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(child: Text(texto,
            style: TextStyle(color: Colors.grey[400], fontSize: 13))),
      ]),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}