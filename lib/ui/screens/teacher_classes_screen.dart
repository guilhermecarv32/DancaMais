import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/permissao_service.dart';
import '../../models/models.dart';

class TeacherClassesScreen extends StatefulWidget {
  const TeacherClassesScreen({super.key});

  @override
  State<TeacherClassesScreen> createState() => _TeacherClassesScreenState();
}

class _TeacherClassesScreenState extends State<TeacherClassesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this)
      ..addListener(() => setState(() => _tabIndex = _tabController.index));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color dark = AppTheme.secondary;

    return StreamBuilder<PerfilProfessor>(
      stream: PermissaoService.perfilStream(),
      builder: (context, perfilSnap) {
        final perfil = perfilSnap.data ??
            PerfilProfessor(isAdmin: false, modalidades: const []);

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(dark, context),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _TurmasTab(perfil: perfil),
                      _ModalidadesTab(),
                      _NiveisTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(Color dark, BuildContext context) {
    final labels = ['Nova Turma', 'Nova Modalidade', 'Novo Nível'];
    final actions = [
      () => _abrirSheet(context, _NovaTurmaSheet()),
      () => _abrirSheet(context, const _NovaModalidadeSheet()),
      () => _abrirSheet(context, const _NovoNivelSheet()),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Turmas',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: dark,
                        letterSpacing: -1)),
                const Text('Gerencie turmas, modalidades e níveis',
                    style: TextStyle(color: Colors.grey, fontSize: 15)),
              ],
            ),
          ),
          GestureDetector(
            onTap: actions[_tabIndex],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 6),
                  Text(labels[_tabIndex],
                      style: const TextStyle(
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

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 5, 25, 0),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: const [
          Tab(text: 'Turmas'),
          Tab(text: 'Modalidades'),
          Tab(text: 'Níveis'),
        ],
      ),
    );
  }

  void _abrirSheet(BuildContext context, Widget sheet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => sheet,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// ABA: TURMAS
// ─────────────────────────────────────────────────────────────────

class _TurmasTab extends StatelessWidget {
  final PerfilProfessor perfil;
  const _TurmasTab({required this.perfil});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('turmas')
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        var turmas = snap.data?.docs
                .map((d) => TurmaModel.fromFirestore(d))
                .toList() ??
            [];

        // Professor vê todas as turmas — filtragem apenas para edição
        if (turmas.isEmpty) {
          return _EmptyState(
            emoji: '🎓',
            titulo: 'Nenhuma turma criada.',
            subtitulo: 'Toque em "Nova Turma" para começar!',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(25, 15, 25, 30),
          itemCount: turmas.length,
          itemBuilder: (_, i) =>
              _TurmaCard(turma: turmas[i], perfil: perfil),
        );
      },
    );
  }
}

class _TurmaCard extends StatelessWidget {
  final TurmaModel turma;
  final PerfilProfessor perfil;
  const _TurmaCard({required this.turma, required this.perfil});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _mostrarOpcoes(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.groups_rounded, color: AppTheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(turma.nome,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.secondary)),
                      const SizedBox(height: 3),
                      Row(children: [
                        _Tag(turma.modalidade, Colors.grey),
                        const SizedBox(width: 6),
                        _Tag(turma.nivel, AppTheme.primary),
                      ]),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${turma.totalAlunos}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppTheme.primary)),
                    const Text('alunos',
                        style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ],
            ),
            if (turma.horariosDia.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF0F0F0)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8, runSpacing: 6,
                children: turma.horariosDia.map((h) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(h.dia, style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: AppTheme.secondary)),
                    const SizedBox(width: 6),
                    Text(h.horario, style: const TextStyle(
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

  void _mostrarOpcoes(BuildContext context) {
    final temPermissao = perfil.podeEditarModalidade(turma.modalidade);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(25, 20, 25, 35),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            Text(turma.nome,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    color: AppTheme.secondary)),
            Text('${turma.modalidade} · ${turma.nivel}',
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 20),

            // Passo da semana — só se tiver permissão
            if (temPermissao) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(children: [
                  const Icon(Icons.star_rounded, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Passo da semana',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(
                          turma.passoSemanaNome ?? 'Não definido',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: turma.passoSemanaNome != null
                                  ? AppTheme.secondary
                                  : Colors.grey[400]),
                        ),
                      ],
                    ),
                  ),
                  if (turma.passoSemanaNome != null)
                    GestureDetector(
                      onTap: () async {
                        await FirebaseFirestore.instance
                            .collection('turmas')
                            .doc(turma.id)
                            .update({'passoSemanaId': null, 'passoSemanaNome': null});
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                    ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => SeletorPassoSemanaSheet(turma: turma),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        turma.passoSemanaNome != null ? 'Trocar' : 'Definir',
                        style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
            ],

            // Ver alunos — sempre visível
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.people_outline_rounded,
                    color: Colors.blue, size: 20),
              ),
              title: const Text('Ver alunos',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => _AlunosTurmaSheet(turma: turma),
                );
              },
            ),

            // Editar e Excluir — só com permissão
            if (temPermissao) ...[
              const Divider(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.edit_rounded,
                      color: AppTheme.primary, size: 20),
                ),
                title: const Text('Editar',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => _EditarTurmaSheet(turma: turma),
                  );
                },
              ),
              const Divider(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent, size: 20),
                ),
                title: const Text('Excluir',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmarExcluir(context, turma);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmarExcluir(BuildContext context, TurmaModel turma) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Excluir turma?'),
        content: Text('A turma "${turma.nome}" será removida permanentemente.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('turmas')
                  .doc(turma.id)
                  .delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Sheet: Alunos da Turma ────────────────────────────────────────

class _AlunosTurmaSheet extends StatelessWidget {
  final TurmaModel turma;
  const _AlunosTurmaSheet({required this.turma});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 30),
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
          Text(turma.nome,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondary)),
          Text('${turma.modalidade} · ${turma.nivel}',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('inscricoes')
                .where('turmaId', isEqualTo: turma.id)
                .snapshots(),
            builder: (context, inscSnap) {
              final alunoIds = inscSnap.data?.docs
                      .map((d) =>
                          (d.data() as Map<String, dynamic>)['alunoId'] as String)
                      .toList() ??
                  [];
              if (alunoIds.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Column(children: [
                      Text('👥', style: TextStyle(fontSize: 40)),
                      SizedBox(height: 8),
                      Text('Nenhum aluno nesta turma.',
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                    ]),
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
                  return SizedBox(
                    height: 320,
                    child: ListView.builder(
                      itemCount: alunos.length,
                      itemBuilder: (_, i) {
                        final data = alunos[i].data() as Map<String, dynamic>;
                        final nome = data['nome'] ?? 'Aluno';
                        final nivel = data['nivel'] ?? 1;
                        final xp = data['xp'] ?? 0;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppTheme.primary.withOpacity(0.12),
                              child: Text(nome[0].toUpperCase(),
                                  style: const TextStyle(
                                      color: AppTheme.primary, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(nome,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: AppTheme.secondary)),
                            ),
                            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text('Nível $nivel',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: AppTheme.primary)),
                              Text('$xp XP',
                                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ]),
                          ]),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Sheet: Editar Turma ───────────────────────────────────────────

class _EditarTurmaSheet extends StatefulWidget {
  final TurmaModel turma;
  const _EditarTurmaSheet({required this.turma});

  @override
  State<_EditarTurmaSheet> createState() => _EditarTurmaSheetState();
}

class _EditarTurmaSheetState extends State<_EditarTurmaSheet> {
  late TextEditingController _nomeCtrl;
  String? _modalidade;
  String? _nivel;
  final Map<String, TextEditingController> _horarioControllers = {};
  bool _salvando = false;

  final _diasSemana = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.turma.nome);
    _modalidade = widget.turma.modalidade;
    _nivel = widget.turma.nivel;
    for (final h in widget.turma.horariosDia) {
      _horarioControllers[h.dia] = TextEditingController(text: h.horario);
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    for (final c in _horarioControllers.values) c.dispose();
    super.dispose();
  }

  void _toggleDia(String dia) {
    setState(() {
      if (_horarioControllers.containsKey(dia)) {
        _horarioControllers[dia]!.dispose();
        _horarioControllers.remove(dia);
      } else {
        _horarioControllers[dia] = TextEditingController();
      }
    });
  }

  Future<void> _salvar() async {
    if (_nomeCtrl.text.trim().isEmpty || _modalidade == null || _nivel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome, modalidade e nível.')),
      );
      return;
    }
    setState(() => _salvando = true);
    final horariosDia = _horarioControllers.entries
        .map((e) => HorarioDia(
            dia: e.key,
            horario: e.value.text.trim().isEmpty ? '—' : e.value.text.trim()))
        .toList();
    await FirebaseFirestore.instance
        .collection('turmas')
        .doc(widget.turma.id)
        .update({
      'nome': _nomeCtrl.text.trim(),
      'modalidade': _modalidade,
      'nivel': _nivel,
      'horariosDia': horariosDia.map((h) => h.toMap()).toList(),
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Container(
          padding: EdgeInsets.fromLTRB(25, 25, 25, 25 + bottom),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Alca(),
                const Text('Editar Turma',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
                const SizedBox(height: 20),
                _SheetLabel('Nome da turma'),
                _SheetInput(_nomeCtrl, 'Ex: Turma Iniciante 1'),
                const SizedBox(height: 14),
                _SheetLabel('Modalidade'),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('escola').doc('config').snapshots(),
                  builder: (context, snap) {
                    final data = snap.data?.data() as Map<String, dynamic>?;
                    final todas = List<String>.from(data?['modalidades'] ?? []);
                    if (todas.isEmpty) return _SheetAviso('Nenhuma modalidade cadastrada.');
                    return _SheetDropdown<String>(
                      value: todas.contains(_modalidade) ? _modalidade : null,
                      hint: 'Selecione a modalidade',
                      items: todas, label: (m) => m,
                      onChanged: (v) => setState(() => _modalidade = v),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _SheetLabel('Nível'),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('escola').doc('config').snapshots(),
                  builder: (context, snap) {
                    final data = snap.data?.data() as Map<String, dynamic>?;
                    final todos = List<String>.from(data?['niveis'] ?? []);
                    if (todos.isEmpty) return _SheetAviso('Nenhum nível cadastrado.');
                    return _SheetDropdown<String>(
                      value: todos.contains(_nivel) ? _nivel : null,
                      hint: 'Selecione o nível',
                      items: todos, label: (n) => n,
                      onChanged: (v) => setState(() => _nivel = v),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _SheetLabel('Dias e horários'),
                Column(
                  children: _diasSemana.map((dia) {
                    final selecionado = _horarioControllers.containsKey(dia);
                    return Column(children: [
                      GestureDetector(
                        onTap: () => _toggleDia(dia),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: selecionado ? AppTheme.primary.withOpacity(0.07) : AppTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selecionado ? AppTheme.primary : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 20, height: 20,
                              decoration: BoxDecoration(
                                color: selecionado ? AppTheme.primary : Colors.grey.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: selecionado
                                  ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Text(dia, style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: selecionado ? AppTheme.primary : Colors.grey[600])),
                          ]),
                        ),
                      ),
                      if (selecionado) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Row(children: [
                            const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                                ),
                                child: TextField(
                                  controller: _horarioControllers[dia],
                                  keyboardType: TextInputType.datetime,
                                  style: const TextStyle(fontSize: 13, color: AppTheme.secondary),
                                  decoration: const InputDecoration(
                                    hintText: 'Ex: 18:00 - 19:00',
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  ),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 8),
                    ]);
                  }).toList(),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _salvando
                        ? const SizedBox(height: 22, width: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Salvar',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Sheet: Seletor de Passo da Semana (PÚBLICO) ───────────────────

class SeletorPassoSemanaSheet extends StatelessWidget {
  final TurmaModel turma;
  const SeletorPassoSemanaSheet({super.key, required this.turma});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 30),
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
                  color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const Text('Passo da Semana',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
          const SizedBox(height: 4),
          Text('Selecione para "${turma.nome}"',
              style: const TextStyle(color: Colors.grey, fontSize: 13)),

          // Botão remover — só aparece se já tem passo definido
          if (turma.passoSemanaNome != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                await FirebaseFirestore.instance
                    .collection('turmas')
                    .doc(turma.id)
                    .update({'passoSemanaId': null, 'passoSemanaNome': null});
                if (context.mounted) Navigator.pop(context);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.close_rounded, size: 15, color: Colors.redAccent),
                    const SizedBox(width: 6),
                    Text(
                      'Remover "${turma.passoSemanaNome}"',
                      style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('movimentacoes')
                .where('modalidade', isEqualTo: turma.modalidade)
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final movs = snap.data?.docs ?? [];
              if (movs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'Nenhuma movimentação de ${turma.modalidade} cadastrada.',
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              return SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: movs.length,
                  itemBuilder: (_, i) {
                    final data = movs[i].data() as Map<String, dynamic>;
                    final nome = data['nome'] ?? '';
                    final tipo = data['tipo'] ?? '';
                    final isSelecionado = turma.passoSemanaId == movs[i].id;
                    return GestureDetector(
                      onTap: () async {
                        await FirebaseFirestore.instance
                            .collection('turmas')
                            .doc(turma.id)
                            .update({'passoSemanaId': movs[i].id, 'passoSemanaNome': nome});
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelecionado
                              ? AppTheme.primary.withOpacity(0.08)
                              : AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelecionado ? AppTheme.primary : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(children: [
                          Icon(
                            tipo == 'passo'
                                ? Icons.directions_walk_rounded
                                : Icons.queue_music_rounded,
                            color: isSelecionado ? AppTheme.primary : Colors.grey[400],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(nome,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: isSelecionado ? AppTheme.primary : AppTheme.secondary)),
                          ),
                          if (isSelecionado)
                            const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 18),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// ABA: MODALIDADES
// ─────────────────────────────────────────────────────────────────

class _ModalidadesTab extends StatelessWidget {
  const _ModalidadesTab();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('escola').doc('config').snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final todas = List<String>.from(data?['modalidades'] ?? []);
        if (todas.isEmpty) {
          return _EmptyState(
            emoji: '💃',
            titulo: 'Nenhuma modalidade cadastrada.',
            subtitulo: 'Toque em "Nova Modalidade" para adicionar!',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(25, 15, 25, 30),
          itemCount: todas.length,
          itemBuilder: (_, i) => _ItemRemovivel(
            emoji: '💃',
            label: todas[i],
            onRemover: () => _removerModalidade(context, uid, todas[i]),
          ),
        );
      },
    );
  }

  Future<void> _removerModalidade(BuildContext context, String uid, String modalidade) async {
    final confirmar = await _confirmarRemocao(context, modalidade);
    if (!confirmar) return;
    await FirebaseFirestore.instance.collection('escola').doc('config').update({
      'modalidades': FieldValue.arrayRemove([modalidade]),
    });
  }
}

// ─────────────────────────────────────────────────────────────────
// ABA: NÍVEIS
// ─────────────────────────────────────────────────────────────────

class _NiveisTab extends StatelessWidget {
  const _NiveisTab();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('escola').doc('config').snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final todos = List<String>.from(data?['niveis'] ?? []);
        if (todos.isEmpty) {
          return _EmptyState(
            emoji: '📊',
            titulo: 'Nenhum nível cadastrado.',
            subtitulo: 'Toque em "Novo Nível" para adicionar!',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(25, 15, 25, 30),
          itemCount: todos.length,
          itemBuilder: (_, i) => _ItemRemovivel(
            emoji: '📊',
            label: todos[i],
            onRemover: () => _removerNivel(context, uid, todos[i]),
          ),
        );
      },
    );
  }

  Future<void> _removerNivel(BuildContext context, String uid, String nivel) async {
    final confirmar = await _confirmarRemocao(context, nivel);
    if (!confirmar) return;
    await FirebaseFirestore.instance.collection('escola').doc('config').update({
      'niveis': FieldValue.arrayRemove([nivel]),
    });
  }
}

// ─────────────────────────────────────────────────────────────────
// WIDGETS REUTILIZÁVEIS
// ─────────────────────────────────────────────────────────────────

class _ItemRemovivel extends StatelessWidget {
  final String emoji;
  final String label;
  final VoidCallback onRemover;
  const _ItemRemovivel({required this.emoji, required this.label, required this.onRemover});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 14),
        Expanded(
          child: Text(label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.secondary)),
        ),
        GestureDetector(
          onTap: onRemover,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
          ),
        ),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String emoji;
  final String titulo;
  final String subtitulo;
  const _EmptyState({required this.emoji, required this.titulo, required this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(titulo,
                style: const TextStyle(color: Colors.grey, fontSize: 15, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(subtitulo,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

Future<bool> _confirmarRemocao(BuildContext context, String nome) async {
  return await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Confirmar remoção'),
          content: Text('"$nome" será removido. Turmas existentes não serão afetadas.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remover', style: TextStyle(color: Colors.red))),
          ],
        ),
      ) ??
      false;
}

// ─────────────────────────────────────────────────────────────────
// BOTTOM SHEET: NOVA TURMA
// ─────────────────────────────────────────────────────────────────

class _NovaTurmaSheet extends StatefulWidget {
  @override
  State<_NovaTurmaSheet> createState() => _NovaTurmaSheetState();
}

class _NovaTurmaSheetState extends State<_NovaTurmaSheet> {
  final _nomeCtrl = TextEditingController();
  String? _modalidade;
  String? _nivel;
  final Map<String, TextEditingController> _horarioControllers = {};
  bool _salvando = false;
  final _diasSemana = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];

  @override
  void dispose() {
    _nomeCtrl.dispose();
    for (final c in _horarioControllers.values) c.dispose();
    super.dispose();
  }

  void _toggleDia(String dia) {
    setState(() {
      if (_horarioControllers.containsKey(dia)) {
        _horarioControllers[dia]!.dispose();
        _horarioControllers.remove(dia);
      } else {
        _horarioControllers[dia] = TextEditingController();
      }
    });
  }

  Future<void> _salvar() async {
    if (_nomeCtrl.text.trim().isEmpty || _modalidade == null || _nivel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha nome, modalidade e nível.')),
      );
      return;
    }
    setState(() => _salvando = true);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final horariosDia = _horarioControllers.entries
        .map((e) => HorarioDia(
            dia: e.key, horario: e.value.text.trim().isEmpty ? '—' : e.value.text.trim()))
        .toList();
    final turma = TurmaModel(
      id: '', nome: _nomeCtrl.text.trim(), modalidade: _modalidade!,
      nivel: _nivel!, professorId: uid, dataCriacao: DateTime.now(), horariosDia: horariosDia,
    );
    await FirebaseFirestore.instance.collection('turmas').add(turma.toMap());
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
            _Alca(),
            const Text('Nova Turma',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
            const SizedBox(height: 20),
            _SheetLabel('Nome da turma'),
            _SheetInput(_nomeCtrl, 'Ex: Turma Iniciante 1'),
            const SizedBox(height: 14),
            _SheetLabel('Modalidade'),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('escola').doc('config').snapshots(),
              builder: (context, snap) {
                final data = snap.data?.data() as Map<String, dynamic>?;
                final todas = List<String>.from(data?['modalidades'] ?? []);
                if (todas.isEmpty) return _SheetAviso('Cadastre modalidades na aba "Modalidades" primeiro.');
                return _SheetDropdown<String>(
                  value: todas.contains(_modalidade) ? _modalidade : null,
                  hint: 'Selecione a modalidade', items: todas, label: (m) => m,
                  onChanged: (v) => setState(() => _modalidade = v),
                );
              },
            ),
            const SizedBox(height: 14),
            _SheetLabel('Nível'),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('escola').doc('config').snapshots(),
              builder: (context, snap) {
                final data = snap.data?.data() as Map<String, dynamic>?;
                final todos = List<String>.from(data?['niveis'] ?? []);
                if (todos.isEmpty) return _SheetAviso('Cadastre níveis na aba "Níveis" primeiro.');
                return _SheetDropdown<String>(
                  value: todos.contains(_nivel) ? _nivel : null,
                  hint: 'Selecione o nível', items: todos, label: (n) => n,
                  onChanged: (v) => setState(() => _nivel = v),
                );
              },
            ),
            const SizedBox(height: 14),
            _SheetLabel('Dias e horários (opcional)'),
            Column(
              children: _diasSemana.map((dia) {
                final selecionado = _horarioControllers.containsKey(dia);
                return Column(children: [
                  GestureDetector(
                    onTap: () => _toggleDia(dia),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: selecionado ? AppTheme.primary.withOpacity(0.07) : AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selecionado ? AppTheme.primary : Colors.transparent, width: 1.5),
                      ),
                      child: Row(children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 20, height: 20,
                          decoration: BoxDecoration(
                            color: selecionado ? AppTheme.primary : Colors.grey.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: selecionado
                              ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(dia, style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14,
                            color: selecionado ? AppTheme.primary : Colors.grey[600])),
                      ]),
                    ),
                  ),
                  if (selecionado) ...[
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Row(children: [
                        const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                            ),
                            child: TextField(
                              controller: _horarioControllers[dia],
                              keyboardType: TextInputType.datetime,
                              style: const TextStyle(fontSize: 13, color: AppTheme.secondary),
                              decoration: const InputDecoration(
                                hintText: 'Ex: 18:00 - 19:00', border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 8),
                ]);
              }).toList(),
            ),
            const SizedBox(height: 24),
            _BotaoSalvar(label: 'Criar Turma', salvando: _salvando, onTap: _salvar),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// BOTTOM SHEETS: NOVA MODALIDADE / NOVO NÍVEL
// ─────────────────────────────────────────────────────────────────

class _NovaModalidadeSheet extends StatefulWidget {
  const _NovaModalidadeSheet();
  @override
  State<_NovaModalidadeSheet> createState() => _NovaModalidadeSheetState();
}

class _NovaModalidadeSheetState extends State<_NovaModalidadeSheet> {
  final _nomeCtrl = TextEditingController();
  bool _salvando = false;
  @override
  void dispose() { _nomeCtrl.dispose(); super.dispose(); }

  Future<void> _salvar() async {
    final nome = _nomeCtrl.text.trim();
    if (nome.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe o nome.'))); return; }
    setState(() => _salvando = true);
    await FirebaseFirestore.instance.collection('escola').doc('config')
        .set({'modalidades': FieldValue.arrayUnion([nome])}, SetOptions(merge: true));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return _SheetBase(titulo: 'Nova Modalidade', bottom: bottom, child: Column(children: [
      _SheetLabel('Nome da modalidade'),
      _SheetInput(_nomeCtrl, 'Ex: Zouk, Tango, Pagode...'),
      const SizedBox(height: 24),
      _BotaoSalvar(label: 'Adicionar Modalidade', salvando: _salvando, onTap: _salvar),
    ]));
  }
}

class _NovoNivelSheet extends StatefulWidget {
  const _NovoNivelSheet();
  @override
  State<_NovoNivelSheet> createState() => _NovoNivelSheetState();
}

class _NovoNivelSheetState extends State<_NovoNivelSheet> {
  final _nomeCtrl = TextEditingController();
  bool _salvando = false;
  @override
  void dispose() { _nomeCtrl.dispose(); super.dispose(); }

  Future<void> _salvar() async {
    final nome = _nomeCtrl.text.trim();
    if (nome.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe o nome.'))); return; }
    setState(() => _salvando = true);
    await FirebaseFirestore.instance.collection('escola').doc('config')
        .set({'niveis': FieldValue.arrayUnion([nome])}, SetOptions(merge: true));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return _SheetBase(titulo: 'Novo Nível', bottom: bottom, child: Column(children: [
      _SheetLabel('Nome do nível'),
      _SheetInput(_nomeCtrl, 'Ex: Básico, Turma Especial...'),
      const SizedBox(height: 24),
      _BotaoSalvar(label: 'Adicionar Nível', salvando: _salvando, onTap: _salvar),
    ]));
  }
}

// ─────────────────────────────────────────────────────────────────
// WIDGETS AUXILIARES
// ─────────────────────────────────────────────────────────────────

class _SheetAviso extends StatelessWidget {
  final String texto;
  const _SheetAviso(this.texto);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.orange.withOpacity(0.08), borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.orange.withOpacity(0.3)),
    ),
    child: Row(children: [
      const Icon(Icons.info_outline_rounded, color: Colors.orange, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(texto, style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w500))),
    ]),
  );
}

class _SheetBase extends StatelessWidget {
  final String titulo;
  final double bottom;
  final Widget child;
  const _SheetBase({required this.titulo, required this.bottom, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(25, 25, 25, 25 + bottom),
    decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
    child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Alca(),
      Text(titulo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.secondary)),
      const SizedBox(height: 20),
      child,
    ])),
  );
}

class _Alca extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
    ),
  );
}

class _SheetLabel extends StatelessWidget {
  final String text;
  const _SheetLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.secondary)),
  );
}

class _SheetInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  const _SheetInput(this.controller, this.hint, {this.maxLines = 1, this.keyboardType});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
    child: TextField(
      controller: controller, maxLines: maxLines, keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    ),
  );
}

class _SheetDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<T> items;
  final String Function(T) label;
  final void Function(T?) onChanged;
  const _SheetDropdown({required this.value, required this.hint, required this.items, required this.label, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        hint: Text(hint, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        isExpanded: true,
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(label(i), style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: onChanged,
      ),
    ),
  );
}

class _BotaoSalvar extends StatelessWidget {
  final String label;
  final bool salvando;
  final VoidCallback onTap;
  const _BotaoSalvar({required this.label, required this.salvando, required this.onTap});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: salvando ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary, foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: salvando
          ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
    ),
  );
}