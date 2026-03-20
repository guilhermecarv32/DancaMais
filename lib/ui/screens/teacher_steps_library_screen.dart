import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/permissao_service.dart';
import '../../models/models.dart';

// =============================================================
// TELA PRINCIPAL
// =============================================================

class TeacherStepsLibraryScreen extends StatefulWidget {
  const TeacherStepsLibraryScreen({super.key});

  @override
  State<TeacherStepsLibraryScreen> createState() =>
      _TeacherStepsLibraryScreenState();
}

class _TeacherStepsLibraryScreenState
    extends State<TeacherStepsLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
    const Color dark = AppTheme.secondary;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<PerfilProfessor>(
      stream: PermissaoService.perfilStream(),
      builder: (context, perfilSnap) {
        final perfil = perfilSnap.data ??
            PerfilProfessor(isAdmin: false, modalidades: const []);

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('escola')
                  .doc('config')
                  .snapshots(),
              builder: (context, configSnap) {
                final data = configSnap.data?.data() as Map<String, dynamic>?;
                // Admin vê todas as modalidades; professor só as suas
                final todasModalidades =
                    List<String>.from(data?['modalidades'] ?? []);
                // Mostra todas as modalidades no filtro
                final modalidades = todasModalidades;

                if (_modalidadeSelecionada != 'Todos' &&
                    !modalidades.contains(_modalidadeSelecionada)) {
                  WidgetsBinding.instance.addPostFrameCallback(
                      (_) => setState(() => _modalidadeSelecionada = 'Todos'));
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(dark, context, modalidades),
                    _buildModalidadeFilter(modalidades),
                    _buildTabBar(),
                    Expanded(child: _buildTabContent(perfil)),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
      Color dark, BuildContext context, List<String> modalidades) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Biblioteca',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: dark,
                        letterSpacing: -1)),
                const Text('Gerencie passos e coreografias',
                    style: TextStyle(color: Colors.grey, fontSize: 15)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _abrirSheetNova(context, modalidades),
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

  Widget _buildModalidadeFilter(List<String> modalidades) {
    final todas = ['Todos', ...modalidades];
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 25),
        itemCount: todas.length,
        itemBuilder: (context, index) {
          final m = todas[index];
          final sel = m == _modalidadeSelecionada;
          return GestureDetector(
            onTap: () => setState(() => _modalidadeSelecionada = m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(
                  horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 6)
                ],
              ),
              child: Text(m,
                  style: TextStyle(
                      color: sel ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 0),
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppTheme.primary,
        indicatorSize: TabBarIndicatorSize.label,
        tabs: const [Tab(text: 'Passos'), Tab(text: 'Coreografias')],
      ),
    );
  }

  Widget _buildTabContent(PerfilProfessor perfil) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildLista(TipoMovimentacao.passo, perfil),
        _buildLista(TipoMovimentacao.coreografia, perfil),
      ],
    );
  }

  Widget _buildLista(TipoMovimentacao tipo, PerfilProfessor perfil) {
    Query query = FirebaseFirestore.instance
        .collection('movimentacoes')
        .where('tipo', isEqualTo: tipo.name);

    // Filtra por modalidade selecionada no filtro
    if (_modalidadeSelecionada != 'Todos') {
      query = query.where('modalidade', isEqualTo: _modalidadeSelecionada);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snap.data?.docs
                .map((d) => MovimentacaoModel.fromFirestore(d))
                .toList() ??
            [];

        if (items.isEmpty) return _buildEmptyState(tipo);

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(25, 15, 25, 120),
          itemCount: items.length,
          itemBuilder: (_, i) => _buildMovCard(items[i], perfil),
        );
      },
    );
  }

  Widget _buildMovCard(MovimentacaoModel mov, PerfilProfessor perfil) {
    return GestureDetector(
      onTap: () => _mostrarMenuOpcoes(mov, perfil),
      child: Container(
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
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                mov.isPasso
                    ? Icons.directions_walk_rounded
                    : Icons.queue_music_rounded,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mov.nome,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppTheme.secondary)),
                  const SizedBox(height: 3),
                  _Tag(mov.modalidade, Colors.grey),
                  if (mov.descricao.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(mov.descricao,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ],
                ],
              ),
            ),
            Column(
              children: [
                Text('${mov.totalAprenderam}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.primary)),
                const Text('alunos',
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarMenuOpcoes(MovimentacaoModel mov, PerfilProfessor perfil) {
    final temPermissao = perfil.podeEditarModalidade(mov.modalidade);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
            Text(mov.nome,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.secondary)),
            const SizedBox(height: 4),
            Text(
              '${mov.isPasso ? 'Passo' : 'Coreografia'} · ${mov.modalidade}',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),

            if (temPermissao) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit_rounded,
                      color: AppTheme.primary, size: 20),
                ),
                title: const Text('Editar',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                subtitle: const Text('Alterar nome, descrição ou música',
                    style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _abrirSheetEditar(mov);
                },
              ),
              const Divider(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.redAccent, size: 20),
                ),
                title: const Text('Excluir',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: Colors.redAccent)),
                subtitle: const Text('Remove permanentemente da biblioteca',
                    style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmarExcluir(mov);
                },
              ),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  const Icon(Icons.lock_outline_rounded,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Somente visualização — modalidade fora da sua área',
                      style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  void _abrirSheetEditar(MovimentacaoModel mov) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditarMovimentacaoSheet(mov: mov),
    );
  }

  void _confirmarExcluir(MovimentacaoModel mov) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Excluir movimentação?'),
        content: Text(
            '"${mov.nome}" será removida permanentemente da biblioteca.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('movimentacoes')
                  .doc(mov.id)
                  .delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Excluir',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(TipoMovimentacao tipo) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tipo == TipoMovimentacao.passo ? '🕺' : '🎵',
                style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text(
              tipo == TipoMovimentacao.passo
                  ? 'Nenhum passo cadastrado.'
                  : 'Nenhuma coreografia cadastrada.',
              style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text('Toque em "Novo" para começar!',
                style: TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  void _abrirSheetNova(
      BuildContext context, List<String> modalidades) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _NovaMovimentacaoSheet(modalidades: modalidades),
    );
  }
}

// ── Helper widget ─────────────────────────────────────────────

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
          borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }
}

// =============================================================
// BOTTOM SHEET: EDITAR MOVIMENTAÇÃO
// =============================================================

class _EditarMovimentacaoSheet extends StatefulWidget {
  final MovimentacaoModel mov;
  const _EditarMovimentacaoSheet({required this.mov});

  @override
  State<_EditarMovimentacaoSheet> createState() =>
      _EditarMovimentacaoSheetState();
}

class _EditarMovimentacaoSheetState
    extends State<_EditarMovimentacaoSheet> {
  late TextEditingController _nomeCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _musicaCtrl;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.mov.nome);
    _descCtrl = TextEditingController(text: widget.mov.descricao);
    _musicaCtrl = TextEditingController(text: widget.mov.musica ?? '');
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descCtrl.dispose();
    _musicaCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_nomeCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O nome não pode estar vazio.')),
      );
      return;
    }

    setState(() => _salvando = true);

    final updates = <String, dynamic>{
      'nome': _nomeCtrl.text.trim(),
      'descricao': _descCtrl.text.trim(),
    };

    if (widget.mov.isCoreografia) {
      updates['musica'] = _musicaCtrl.text.trim().isEmpty
          ? null
          : _musicaCtrl.text.trim();
    }

    await FirebaseFirestore.instance
        .collection('movimentacoes')
        .doc(widget.mov.id)
        .update(updates);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(25, 25, 25, 25 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(30)),
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

            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Editar Movimentação',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondary)),
                    Text(
                      '${widget.mov.isPasso ? 'Passo' : 'Coreografia'} · ${widget.mov.modalidade}',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 20),

            _label('Nome'),
            _input(_nomeCtrl, 'Nome da movimentação'),
            const SizedBox(height: 14),

            _label('Descrição (opcional)'),
            _input(_descCtrl, 'Descrição ou dica de execução',
                maxLines: 2),
            const SizedBox(height: 14),

            if (widget.mov.isCoreografia) ...[
              _label('Música (opcional)'),
              _input(_musicaCtrl, 'Ex: Evidências - Chitãozinho & Xororó'),
              const SizedBox(height: 14),
            ],

            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _salvando
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Salvar alterações',
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.secondary)),
      );

  Widget _input(TextEditingController ctrl, String hint,
      {int maxLines = 1}) =>
      Container(
        decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14)),
        child: TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: Colors.grey[400], fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
      );
}

// =============================================================
// BOTTOM SHEET: NOVA MOVIMENTAÇÃO
// =============================================================

class _NovaMovimentacaoSheet extends StatefulWidget {
  final List<String> modalidades;
  const _NovaMovimentacaoSheet({required this.modalidades});

  @override
  State<_NovaMovimentacaoSheet> createState() =>
      _NovaMovimentacaoSheetState();
}

class _NovaMovimentacaoSheetState
    extends State<_NovaMovimentacaoSheet> {
  final _nomeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _musicaCtrl = TextEditingController();

  TipoMovimentacao _tipo = TipoMovimentacao.passo;
  String? _modalidade;
  String? _turmaId;
  String? _turmaNome;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    if (widget.modalidades.isNotEmpty) {
      _modalidade = widget.modalidades.first;
    }
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descCtrl.dispose();
    _musicaCtrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    if (_nomeCtrl.text.trim().isEmpty) {
      _mostrarAviso('Informe o nome da movimentação.');
      return;
    }
    if (_modalidade == null) {
      _mostrarAviso(
          'Selecione uma modalidade ou cadastre uma primeiro.');
      return;
    }

    setState(() => _salvando = true);

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final mov = MovimentacaoModel(
      id: '',
      nome: _nomeCtrl.text.trim(),
      descricao: _descCtrl.text.trim(),
      modalidade: _modalidade!,
      tipo: _tipo,
      professorId: uid,
      dataCriacao: DateTime.now(),
      musica: _tipo == TipoMovimentacao.coreografia &&
              _musicaCtrl.text.trim().isNotEmpty
          ? _musicaCtrl.text.trim()
          : null,
    );

    final ref = await FirebaseFirestore.instance
        .collection('movimentacoes')
        .add(mov.toMap());

    if (_turmaId != null) {
      await FirebaseFirestore.instance
          .collection('conteudoDaTurma')
          .add({
        'turmaId': _turmaId,
        'turmaNome': _turmaNome,
        'movimentacaoId': ref.id,
        'movimentacaoNome': _nomeCtrl.text.trim(),
        'modalidade': _modalidade,
        'status': 'ativo',
        'dataCriacao': FieldValue.serverTimestamp(),
      });
    }

    if (mounted) Navigator.pop(context);
  }

  void _mostrarAviso(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Container(
      padding: EdgeInsets.fromLTRB(25, 25, 25, 25 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Alça
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

            const Text('Nova Movimentação',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondary)),
            const SizedBox(height: 20),

            _label('Tipo'),
            Row(children: [
              _tipoBtn('Passo', TipoMovimentacao.passo,
                  Icons.directions_walk_rounded),
              const SizedBox(width: 12),
              _tipoBtn('Coreografia', TipoMovimentacao.coreografia,
                  Icons.queue_music_rounded),
            ]),
            const SizedBox(height: 18),

            _label('Nome'),
            _input(_nomeCtrl, 'Ex: Giro Simples'),
            const SizedBox(height: 14),

            _label('Descrição (opcional)'),
            _input(_descCtrl,
                'Ex: Passo base com giro de conduzido',
                maxLines: 2),
            const SizedBox(height: 14),

            _label('Modalidade'),
            if (widget.modalidades.isEmpty)
              _infoBox(
                  'Cadastre modalidades em "Turmas > Modalidades" primeiro.')
            else
              _dropdownWidget<String>(
                value: _modalidade,
                hint: 'Selecione a modalidade',
                items: widget.modalidades,
                label: (m) => m,
                onChanged: (v) => setState(() {
                  _modalidade = v;
                  _turmaId = null;
                  _turmaNome = null;
                }),
              ),
            const SizedBox(height: 14),

            if (_tipo == TipoMovimentacao.coreografia) ...[
              _label('Música (opcional)'),
              _input(_musicaCtrl,
                  'Ex: Evidências - Chitãozinho & Xororó'),
              const SizedBox(height: 14),
            ],

            _label('Adicionar a uma turma (opcional)'),
            if (_modalidade == null)
              _infoBox(
                  'Selecione uma modalidade para ver as turmas.')
            else
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('turmas')
                    
                    .where('modalidade', isEqualTo: _modalidade)
                    .snapshots(),
                builder: (context, snap) {
                  final docs = snap.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return _infoBox(
                        'Nenhuma turma de $_modalidade cadastrada.');
                  }

                  final itemIds = ['', ...docs.map((d) => d.id)];

                  return _dropdownWidget<String>(
                    value: _turmaId ?? '',
                    hint: 'Nenhuma (só cadastrar)',
                    items: itemIds,
                    label: (id) {
                      if (id.isEmpty) return 'Nenhuma (só cadastrar)';
                      final match =
                          docs.where((d) => d.id == id);
                      if (match.isEmpty) return id;
                      return (match.first.data()
                              as Map<String, dynamic>)['nome'] ??
                          id;
                    },
                    onChanged: (v) => setState(() {
                      if (v == null || v.isEmpty) {
                        _turmaId = null;
                        _turmaNome = null;
                      } else {
                        _turmaId = v;
                        final match =
                            docs.where((d) => d.id == v);
                        if (match.isNotEmpty) {
                          _turmaNome = (match.first.data()
                              as Map<String, dynamic>)['nome'];
                        }
                      }
                    }),
                  );
                },
              ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _salvando
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Cadastrar',
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.secondary)),
      );

  Widget _infoBox(String texto) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.info_outline_rounded,
              color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(texto,
                style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
          ),
        ]),
      );

  Widget _input(TextEditingController ctrl, String hint,
      {int maxLines = 1}) =>
      Container(
        decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14)),
        child: TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: Colors.grey[400], fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
          ),
        ),
      );

  Widget _tipoBtn(
      String label, TipoMovimentacao tipo, IconData icon) {
    final sel = _tipo == tipo;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tipo = tipo),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel
                ? AppTheme.primary.withOpacity(0.1)
                : AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
                  sel ? AppTheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(children: [
            Icon(icon,
                color: sel
                    ? AppTheme.primary
                    : Colors.grey[400],
                size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: sel
                        ? AppTheme.primary
                        : Colors.grey[400],
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ]),
        ),
      ),
    );
  }

  Widget _dropdownWidget<T>({
    required T? value,
    required String hint,
    required List<T> items,
    required String Function(T) label,
    required void Function(T?) onChanged,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(14)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            hint: Text(hint,
                style: TextStyle(
                    color: Colors.grey[400], fontSize: 14)),
            isExpanded: true,
            items: items
                .map((i) => DropdownMenuItem(
                    value: i,
                    child: Text(label(i),
                        style: const TextStyle(
                            fontSize: 14))))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      );
}