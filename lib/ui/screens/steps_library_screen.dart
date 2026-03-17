import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../logic/gamification/gamification_service.dart';

class StepsLibraryScreen extends StatefulWidget {
  const StepsLibraryScreen({super.key});

  @override
  State<StepsLibraryScreen> createState() => _StepsLibraryScreenState();
}

class _StepsLibraryScreenState extends State<StepsLibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _modalidadeSelecionada = 'Todos';
  final GamificationService _gamificationService = GamificationService();

  final List<String> _modalidades = [
    'Todos',
    'Forró',
    'Bachata',
    'Samba',
    'K-Pop',
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
            _buildHeader(dark),
            _buildModalidadeFilter(),
            _buildTabBar(),
            Expanded(child: _buildTabContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color dark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Biblioteca",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: dark,
              letterSpacing: -1,
            ),
          ),
          const Text(
            "Passos e coreografias da escola",
            style: TextStyle(color: Colors.grey, fontSize: 15),
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
          final selecionado = m == _modalidadeSelecionada;
          return GestureDetector(
            onTap: () => setState(() => _modalidadeSelecionada = m),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: selecionado ? AppTheme.primary : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Text(
                m,
                style: TextStyle(
                  color:
                      selecionado ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
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
        tabs: const [
          Tab(text: 'Passos'),
          Tab(text: 'Coreografias'),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildMovimentacoesList(TipoMovimentacao.passo),
        _buildMovimentacoesList(TipoMovimentacao.coreografia),
      ],
    );
  }

  Widget _buildMovimentacoesList(TipoMovimentacao tipo) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    Query query = FirebaseFirestore.instance
        .collection('movimentacoes')
        .where('tipo', isEqualTo: tipo.name);

    if (_modalidadeSelecionada != 'Todos') {
      query =
          query.where('modalidade', isEqualTo: _modalidadeSelecionada);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, movSnap) {
        if (movSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final movimentacoes = movSnap.data?.docs
                .map((d) => MovimentacaoModel.fromFirestore(d))
                .toList() ??
            [];

        if (movimentacoes.isEmpty) {
          return _buildEmptyState(tipo);
        }

        // Busca o progresso do aluno para saber quais já foram aprendidos
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('progressoAluno')
              .where('alunoId', isEqualTo: uid)
              .snapshots(),
          builder: (context, progSnap) {
            final progressoMap = <String, StatusProgresso>{};
            for (final doc in progSnap.data?.docs ?? []) {
              final data = doc.data() as Map<String, dynamic>;
              final movId = data['movimentacaoId'] as String?;
              final status = StatusProgresso.values.firstWhere(
                (s) => s.name == data['status'],
                orElse: () => StatusProgresso.naoAprendido,
              );
              if (movId != null) progressoMap[movId] = status;
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(25, 15, 25, 100),
              itemCount: movimentacoes.length,
              itemBuilder: (context, index) {
                final mov = movimentacoes[index];
                final status = progressoMap[mov.id] ??
                    StatusProgresso.naoAprendido;
                return _buildMovimentacaoCard(
                    mov, status, uid ?? '');
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMovimentacaoCard(
      MovimentacaoModel mov, StatusProgresso status, String uid) {
    final bool aprendido = status == StatusProgresso.aprendido ||
        status == StatusProgresso.validado;
    final bool validado = status == StatusProgresso.validado;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: aprendido
            ? Border.all(
                color: AppTheme.primary.withOpacity(0.25), width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Ícone do tipo de movimentação
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: aprendido
                    ? AppTheme.primary.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                mov.isPasso
                    ? Icons.directions_walk_rounded
                    : Icons.queue_music_rounded,
                color: aprendido ? AppTheme.primary : Colors.grey[400],
              ),
            ),
            const SizedBox(width: 14),

            // Informações
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mov.nome,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _buildTag(mov.modalidade, Colors.grey),
                      if (mov.nivel != null) ...[
                        const SizedBox(width: 6),
                        _buildTag(
                          _nivelLabel(mov.nivel!),
                          _nivelCor(mov.nivel!),
                        ),
                      ],
                    ],
                  ),
                  if (validado) ...[
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(Icons.verified_rounded,
                            size: 12, color: Colors.green),
                        SizedBox(width: 3),
                        Text(
                          'Validado pelo professor',
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Botão de marcar como aprendido
            if (!aprendido)
              GestureDetector(
                onTap: () => _marcarAprendido(mov, uid),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Aprendi!',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
            else
              const Icon(Icons.check_circle_rounded,
                  color: AppTheme.primary, size: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
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
            Text(
              tipo == TipoMovimentacao.passo ? '🕺' : '🎵',
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              tipo == TipoMovimentacao.passo
                  ? 'Nenhum passo cadastrado ainda.'
                  : 'Nenhuma coreografia cadastrada ainda.',
              style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'O professor adicionará conteúdo em breve!',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _marcarAprendido(
      MovimentacaoModel mov, String uid) async {
    final conquistasNovas = await _gamificationService.registrarAprendizado(
      alunoId: uid,
      movimentacao: mov,
    );

    if (!mounted) return;

    // Feedback visual de XP ganho
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('🎉 '),
            Expanded(
              child: Text(
                '+${XPRecompensa.marcarAprendido} XP! "${mov.nome}" aprendido!',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    // Mostra cada conquista desbloqueada
    for (final conquista in conquistasNovas) {
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 500));
      _mostrarConquistaDialog(conquista);
    }
  }

  void _mostrarConquistaDialog(ConquistaModel conquista) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(conquista.icone,
                  style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              const Text(
                '🏅 Nova Conquista!',
                style: TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                conquista.nome,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                conquista.descricao,
                style:
                    const TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '+${conquista.xpRecompensa} XP bônus!',
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Incrível!'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _nivelLabel(NivelMovimentacao nivel) {
    switch (nivel) {
      case NivelMovimentacao.iniciante:
        return 'Iniciante';
      case NivelMovimentacao.intermediario:
        return 'Intermediário';
      case NivelMovimentacao.avancado:
        return 'Avançado';
    }
  }

  Color _nivelCor(NivelMovimentacao nivel) {
    switch (nivel) {
      case NivelMovimentacao.iniciante:
        return Colors.green;
      case NivelMovimentacao.intermediario:
        return Colors.orange;
      case NivelMovimentacao.avancado:
        return Colors.red;
    }
  }
}