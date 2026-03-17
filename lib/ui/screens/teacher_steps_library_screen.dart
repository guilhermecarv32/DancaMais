import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';

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

  final List<String> _modalidades = [
    'Todos', 'Forró', 'Bachata', 'Samba', 'K-Pop',
  ];

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

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(dark, context),
            _buildModalidadeFilter(),
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
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
          // Botão no cabeçalho — sempre visível, nunca coberto pelo dock
          GestureDetector(
            onTap: () => _abrirBottomSheetNova(context),
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

  Widget _buildModalidadeFilter() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 25),
        itemCount: _modalidades.length,
        itemBuilder: (context, index) {
          final m = _modalidades[index];
          final sel = m == _modalidadeSelecionada;
          return GestureDetector(
            onTap: () => setState(() => _modalidadeSelecionada = m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: sel ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 6)
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

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildLista(TipoMovimentacao.passo),
        _buildLista(TipoMovimentacao.coreografia),
      ],
    );
  }

  Widget _buildLista(TipoMovimentacao tipo) {
    Query query = FirebaseFirestore.instance
        .collection('movimentacoes')
        .where('tipo', isEqualTo: tipo.name);

    if (_modalidadeSelecionada != 'Todos') {
      query =
          query.where('modalidade', isEqualTo: _modalidadeSelecionada);
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
          itemBuilder: (_, i) => _buildMovCard(items[i]),
        );
      },
    );
  }

  Widget _buildMovCard(MovimentacaoModel mov) {
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
                Row(children: [
                  _buildTag(mov.modalidade, Colors.grey),
                  if (mov.nivel != null) ...[
                    const SizedBox(width: 6),
                    _buildTag(_nivelLabel(mov.nivel!),
                        _nivelCor(mov.nivel!)),
                  ],
                ]),
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
          // Contador de alunos que aprenderam
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
    );
  }

  Widget _buildTag(String label, Color color) {
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
            const Text('Toque em "Nova Movimentação" para começar!',
                style: TextStyle(color: Colors.grey, fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ─── BOTTOM SHEET: Nova Movimentação ──────────────────────────

  void _abrirBottomSheetNova(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NovaMovimentacaoSheet(),
    );
  }

  String _nivelLabel(NivelMovimentacao n) {
    switch (n) {
      case NivelMovimentacao.iniciante:
        return 'Iniciante';
      case NivelMovimentacao.intermediario:
        return 'Intermediário';
      case NivelMovimentacao.avancado:
        return 'Avançado';
    }
  }

  Color _nivelCor(NivelMovimentacao n) {
    switch (n) {
      case NivelMovimentacao.iniciante:
        return Colors.green;
      case NivelMovimentacao.intermediario:
        return Colors.orange;
      case NivelMovimentacao.avancado:
        return Colors.red;
    }
  }
}

// ─── BOTTOM SHEET WIDGET ─────────────────────────────────────────

class _NovaMovimentacaoSheet extends StatefulWidget {
  const _NovaMovimentacaoSheet();

  @override
  State<_NovaMovimentacaoSheet> createState() =>
      _NovaMovimentacaoSheetState();
}

class _NovaMovimentacaoSheetState extends State<_NovaMovimentacaoSheet> {
  final _nomeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  TipoMovimentacao _tipo = TipoMovimentacao.passo;
  String _modalidade = 'Forró';
  NivelMovimentacao _nivel = NivelMovimentacao.iniciante;
  final _musicaCtrl = TextEditingController();
  bool _salvando = false;

  final List<String> _modalidades = ['Forró', 'Bachata', 'Samba', 'K-Pop'];

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
        const SnackBar(content: Text('Informe o nome da movimentação.')),
      );
      return;
    }

    setState(() => _salvando = true);

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final mov = MovimentacaoModel(
      id: '',
      nome: _nomeCtrl.text.trim(),
      descricao: _descCtrl.text.trim(),
      modalidade: _modalidade,
      tipo: _tipo,
      professorId: uid,
      dataCriacao: DateTime.now(),
      nivel: _tipo == TipoMovimentacao.passo ? _nivel : null,
      musica: _tipo == TipoMovimentacao.coreografia &&
              _musicaCtrl.text.trim().isNotEmpty
          ? _musicaCtrl.text.trim()
          : null,
    );

    await FirebaseFirestore.instance
        .collection('movimentacoes')
        .add(mov.toMap());

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

            // Tipo: Passo ou Coreografia
            _buildLabel('Tipo'),
            Row(children: [
              _buildTipoBtn(
                  'Passo', TipoMovimentacao.passo, Icons.directions_walk_rounded),
              const SizedBox(width: 12),
              _buildTipoBtn('Coreografia', TipoMovimentacao.coreografia,
                  Icons.queue_music_rounded),
            ]),
            const SizedBox(height: 18),

            // Nome
            _buildLabel('Nome'),
            _buildInput(_nomeCtrl, 'Ex: Giro Simples'),
            const SizedBox(height: 14),

            // Descrição
            _buildLabel('Descrição (opcional)'),
            _buildInput(_descCtrl, 'Ex: Passo base com giro de conduzido',
                maxLines: 2),
            const SizedBox(height: 14),

            // Modalidade
            _buildLabel('Modalidade'),
            _buildDropdown<String>(
              value: _modalidade,
              items: _modalidades,
              label: (m) => m,
              onChanged: (v) => setState(() => _modalidade = v!),
            ),
            const SizedBox(height: 14),

            // Nível (só para Passo)
            if (_tipo == TipoMovimentacao.passo) ...[
              _buildLabel('Nível'),
              _buildDropdown<NivelMovimentacao>(
                value: _nivel,
                items: NivelMovimentacao.values,
                label: (n) => _nivelLabel(n),
                onChanged: (v) => setState(() => _nivel = v!),
              ),
              const SizedBox(height: 14),
            ],

            // Música (só para Coreografia)
            if (_tipo == TipoMovimentacao.coreografia) ...[
              _buildLabel('Música (opcional)'),
              _buildInput(_musicaCtrl, 'Ex: Evidências - Chitãozinho & Xororó'),
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
                    : const Text('Cadastrar',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.bold)),
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
        borderRadius: BorderRadius.circular(14),
      ),
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

  Widget _buildTipoBtn(
      String label, TipoMovimentacao tipo, IconData icon) {
    final sel = _tipo == tipo;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tipo = tipo),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? AppTheme.primary.withOpacity(0.1) : AppTheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: sel ? AppTheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(children: [
            Icon(icon,
                color: sel ? AppTheme.primary : Colors.grey[400], size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: sel ? AppTheme.primary : Colors.grey[400],
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ]),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) label,
    required void Function(T?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items
              .map((i) => DropdownMenuItem(
                  value: i,
                  child: Text(label(i),
                      style: const TextStyle(fontSize: 14))))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  String _nivelLabel(NivelMovimentacao n) {
    switch (n) {
      case NivelMovimentacao.iniciante:
        return 'Iniciante';
      case NivelMovimentacao.intermediario:
        return 'Intermediário';
      case NivelMovimentacao.avancado:
        return 'Avançado';
    }
  }
}