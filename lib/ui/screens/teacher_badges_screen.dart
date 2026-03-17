import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';

class TeacherBadgesScreen extends StatelessWidget {
  const TeacherBadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color dark = AppTheme.secondary;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(dark, context),
            Expanded(child: _buildConquistasList(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color dark, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Conquistas',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: dark,
                        letterSpacing: -1)),
                const Text('Gerencie e conceda recompensas',
                    style: TextStyle(color: Colors.grey, fontSize: 15)),
              ],
            ),
          ),
          // Botão no cabeçalho — sempre visível, nunca coberto pelo dock
          GestureDetector(
            onTap: () => _abrirBottomSheetNovaConquista(context),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 6),
                  Text('Novo',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConquistasList(BuildContext context) {
    // Combina conquistas padrão do sistema com as customizadas salvas no Firestore
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('conquistasCustom')
          .snapshots(),
      builder: (context, snap) {
        final customList = snap.data?.docs
                .map((d) => ConquistaModel.fromFirestore(d))
                .toList() ??
            [];

        final todasConquistas = [
          ...ConquistaModel.conquistasPadrao,
          ...customList,
        ];

        if (todasConquistas.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(25, 10, 25, 120),
          itemCount: todasConquistas.length,
          itemBuilder: (_, i) =>
              _buildConquistaCard(context, todasConquistas[i]),
        );
      },
    );
  }

  Widget _buildConquistaCard(
      BuildContext context, ConquistaModel conquista) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 10)
        ],
      ),
      child: Row(
        children: [
          // Ícone
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(conquista.icone,
                  style: const TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 14),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(conquista.nome,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.secondary)),
                const SizedBox(height: 3),
                Text(conquista.descricao,
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 5),
                Row(children: [
                  const Icon(Icons.bolt_rounded,
                      size: 14, color: AppTheme.primary),
                  Text('+${conquista.xpRecompensa} XP',
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ]),
              ],
            ),
          ),

          // Botão conceder
          GestureDetector(
            onTap: () =>
                _abrirBottomSheetConceder(context, conquista),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Conceder',
                  style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🏅', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text('Nenhuma conquista cadastrada.',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            SizedBox(height: 4),
            Text('Toque em "Nova Conquista" para criar!',
                style: TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ─── BOTTOM SHEET: Conceder conquista a aluno da turma ──────────

  void _abrirBottomSheetConceder(
      BuildContext context, ConquistaModel conquista) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConcederConquistaSheet(conquista: conquista),
    );
  }

  // ─── BOTTOM SHEET: Nova conquista customizada ───────────────────

  void _abrirBottomSheetNovaConquista(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NovaConquistaSheet(),
    );
  }
}

// ─── SHEET: CONCEDER CONQUISTA ────────────────────────────────────

class _ConcederConquistaSheet extends StatefulWidget {
  final ConquistaModel conquista;
  const _ConcederConquistaSheet({required this.conquista});

  @override
  State<_ConcederConquistaSheet> createState() =>
      _ConcederConquistaSheetState();
}

class _ConcederConquistaSheetState
    extends State<_ConcederConquistaSheet> {
  String? _turmaSelecionadaId;
  String? _alunoSelecionadoId;
  String? _alunoSelecionadoNome;
  bool _concedendo = false;

  Future<void> _conceder() async {
    if (_alunoSelecionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione um aluno.')),
      );
      return;
    }

    setState(() => _concedendo = true);

    final conquistaObtida = ConquistaModel(
      id: widget.conquista.id,
      nome: widget.conquista.nome,
      descricao: widget.conquista.descricao,
      icone: widget.conquista.icone,
      tipo: widget.conquista.tipo,
      dataObtida: DateTime.now(),
      xpRecompensa: widget.conquista.xpRecompensa,
    );

    // Adiciona a conquista ao perfil do aluno e concede XP
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(_alunoSelecionadoId)
        .update({
      'conquistas':
          FieldValue.arrayUnion([conquistaObtida.toMap()]),
      'xp': FieldValue.increment(widget.conquista.xpRecompensa),
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '🏅 "${widget.conquista.nome}" concedida a $_alunoSelecionadoNome!'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final professorId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Container(
      padding: EdgeInsets.fromLTRB(25, 25, 25, 25 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),

            // Preview da conquista
            Row(children: [
              Text(widget.conquista.icone,
                  style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.conquista.nome,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppTheme.secondary)),
                      Text(widget.conquista.descricao,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                    ]),
              ),
            ]),
            const Divider(height: 28),

            // Passo 1: selecionar turma
            const Text('1. Selecione a turma',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.secondary)),
            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('turmas')
                  .where('professorId', isEqualTo: professorId)
                  .snapshots(),
              builder: (context, snap) {
                final turmas = snap.data?.docs
                        .map((d) => TurmaModel.fromFirestore(d))
                        .toList() ??
                    [];

                if (turmas.isEmpty) {
                  return const Text(
                      'Nenhuma turma cadastrada ainda.',
                      style: TextStyle(color: Colors.grey, fontSize: 13));
                }

                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: turmas.map((t) {
                    final sel = _turmaSelecionadaId == t.id;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _turmaSelecionadaId = t.id;
                        _alunoSelecionadoId = null;
                        _alunoSelecionadoNome = null;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppTheme.primary.withOpacity(0.1)
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: sel
                                ? AppTheme.primary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '${t.modalidade} · ${t.nivel}',
                          style: TextStyle(
                              color: sel
                                  ? AppTheme.primary
                                  : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            // Passo 2: selecionar aluno (aparece após turma ser selecionada)
            if (_turmaSelecionadaId != null) ...[
              const SizedBox(height: 20),
              const Text('2. Selecione o aluno',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppTheme.secondary)),
              const SizedBox(height: 10),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('inscricoes')
                    .where('turmaId', isEqualTo: _turmaSelecionadaId)
                    .snapshots(),
                builder: (context, inscSnap) {
                  final alunoIds = inscSnap.data?.docs
                          .map((d) =>
                              (d.data() as Map)['alunoId'] as String)
                          .toList() ??
                      [];

                  if (alunoIds.isEmpty) {
                    return const Text('Nenhum aluno nesta turma.',
                        style:
                            TextStyle(color: Colors.grey, fontSize: 13));
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('usuarios')
                        .where(FieldPath.documentId,
                            whereIn: alunoIds)
                        .snapshots(),
                    builder: (context, alunosSnap) {
                      final alunos = alunosSnap.data?.docs ?? [];

                      return Column(
                        children: alunos.map((doc) {
                          final data =
                              doc.data() as Map<String, dynamic>;
                          final nome = data['nome'] ?? 'Aluno';
                          final nivel = data['nivel'] ?? 1;
                          final sel = _alunoSelecionadoId == doc.id;

                          return GestureDetector(
                            onTap: () => setState(() {
                              _alunoSelecionadoId = doc.id;
                              _alunoSelecionadoNome = nome;
                            }),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 180),
                              margin:
                                  const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: sel
                                    ? AppTheme.primary
                                        .withOpacity(0.08)
                                    : AppTheme.surface,
                                borderRadius:
                                    BorderRadius.circular(14),
                                border: Border.all(
                                  color: sel
                                      ? AppTheme.primary
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: AppTheme.primary
                                      .withOpacity(0.15),
                                  child: Text(
                                    nome[0].toUpperCase(),
                                    style: const TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Text(nome,
                                        style: const TextStyle(
                                            fontWeight:
                                                FontWeight.w600,
                                            fontSize: 14))),
                                Text('Nível $nivel',
                                    style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12)),
                                if (sel) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppTheme.primary,
                                      size: 20),
                                ],
                              ]),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  );
                },
              ),
            ],

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_alunoSelecionadoId == null || _concedendo)
                    ? null
                    : _conceder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[200],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _concedendo
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Conceder Conquista',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SHEET: NOVA CONQUISTA CUSTOMIZADA ───────────────────────────

class _NovaConquistaSheet extends StatefulWidget {
  const _NovaConquistaSheet();

  @override
  State<_NovaConquistaSheet> createState() => _NovaConquistaSheetState();
}

class _NovaConquistaSheetState extends State<_NovaConquistaSheet> {
  final _nomeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _iconeCtrl = TextEditingController(text: '🏅');
  int _xp = 50;
  bool _salvando = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descCtrl.dispose();
    _iconeCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_nomeCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Preencha nome e descrição da conquista.')),
      );
      return;
    }

    setState(() => _salvando = true);

    final ref = FirebaseFirestore.instance.collection('conquistasCustom').doc();
    final conquista = ConquistaModel(
      id: ref.id,
      nome: _nomeCtrl.text.trim(),
      descricao: _descCtrl.text.trim(),
      icone: _iconeCtrl.text.trim().isEmpty ? '🏅' : _iconeCtrl.text.trim(),
      tipo: TipoConquista.especial,
      xpRecompensa: _xp,
    );

    await ref.set(conquista.toMap());

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(25, 25, 25, 25 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),

            const Text('Nova Conquista',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondary)),
            const SizedBox(height: 20),

            _buildLabel('Ícone (emoji)'),
            _buildInput(_iconeCtrl, '🏅'),
            const SizedBox(height: 14),

            _buildLabel('Nome'),
            _buildInput(_nomeCtrl, 'Ex: Mestre do Forró'),
            const SizedBox(height: 14),

            _buildLabel('Descrição'),
            _buildInput(_descCtrl,
                'Ex: Aprendeu todos os passos de Forró cadastrados.',
                maxLines: 2),
            const SizedBox(height: 14),

            _buildLabel('Recompensa de XP: $_xp XP'),
            Slider(
              value: _xp.toDouble(),
              min: 10,
              max: 200,
              divisions: 19,
              activeColor: AppTheme.primary,
              label: '$_xp XP',
              onChanged: (v) => setState(() => _xp = v.round()),
            ),
            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _salvando
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Criar Conquista',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppTheme.secondary)),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String hint,
      {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14)),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}