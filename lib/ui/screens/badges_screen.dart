import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    const Color dark = AppTheme.secondary;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, dark),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('usuarios')
                    .doc(uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final data =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final int nivel = data['nivel'] ?? 1;
                  final int xp = data['xp'] ?? 0;
                  final List conquistasRaw = data['conquistas'] ?? [];

                  final conquistasObtidas = conquistasRaw
                      .whereType<Map<String, dynamic>>()
                      .map((c) => ConquistaModel.fromMap(c))
                      .toList();

                  final idsObtidos =
                      conquistasObtidas.map((c) => c.id).toSet();

                  // Conquistas pendentes vêm do Firestore
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('conquistasCustom')
                        .snapshots(),
                    builder: (context, conquSnap) {
                      final todasCustom = conquSnap.data?.docs
                              .map((d) => ConquistaModel.fromFirestore(d))
                              .toList() ??
                          [];

                      final conquistasPendentes = todasCustom
                          .where((c) => !idsObtidos.contains(c.id))
                          .toList();

                      return ListView(
                        padding: const EdgeInsets.fromLTRB(25, 0, 25, 30),
                        children: [
                          _buildProgressCard(nivel, xp, dark),
                          const SizedBox(height: 30),

                          if (conquistasObtidas.isNotEmpty) ...[
                            _buildSectionTitle(
                                '🏅 Conquistadas (${conquistasObtidas.length})',
                                dark),
                            const SizedBox(height: 15),
                            ...conquistasObtidas.map(
                                (c) => _buildConquistaCard(c, obtida: true)),
                            const SizedBox(height: 30),
                          ],

                          if (conquistasPendentes.isNotEmpty) ...[
                            _buildSectionTitle(
                                '🔒 Em Progresso (${conquistasPendentes.length})',
                                dark),
                            const SizedBox(height: 15),
                            ...conquistasPendentes.map(
                                (c) => _buildConquistaCard(c, obtida: false)),
                          ],

                          if (conquistasObtidas.isEmpty &&
                              conquistasPendentes.isEmpty)
                            _buildEmptyState(),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color dark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Conquistas",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: dark,
              letterSpacing: -1,
            ),
          ),
          const Text(
            "Sua jornada em cada passo",
            style: TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(int nivel, int xp, Color dark) {
    final student = StudentModel(
      uid: '',
      nome: '',
      email: '',
      dataCriacao: DateTime.now(),
      nivel: nivel,
      xp: xp,
      conquistas: [],
    );

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, AppTheme.primary.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Círculo de nível
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  value: student.progressoXP == 0 ? 0.05 : student.progressoXP,
                  strokeWidth: 6,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                ),
              ),
              Text(
                '$nivel',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nível $nivel · ${student.nomeTitulo}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$xp XP acumulados',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: student.progressoXP,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${student.xpParaProximoNivel} XP para o próximo nível',
                  style:
                      const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color dark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: dark.withOpacity(0.8),
      ),
    );
  }

  Widget _buildConquistaCard(ConquistaModel conquista,
      {required bool obtida}) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: obtida ? 1.0 : 0.45,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: obtida
              ? Border.all(
                  color: AppTheme.primary.withOpacity(0.3), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            // Ícone da conquista
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: obtida
                    ? AppTheme.primary.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  conquista.icone,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(width: 15),

            // Informações
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          conquista.nome,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: obtida
                                ? AppTheme.secondary
                                : Colors.grey[600],
                          ),
                        ),
                      ),
                      if (obtida)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '✓ Obtida',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conquista.descricao,
                    style: TextStyle(
                        color: Colors.grey[500], fontSize: 12),
                  ),
                  if (obtida && conquista.dataObtida != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _formatarData(conquista.dataObtida!),
                      style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),

            // XP da conquista
            Column(
              children: [
                Text(
                  '+${conquista.xpRecompensa}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: obtida ? AppTheme.primary : Colors.grey[400],
                  ),
                ),
                const Text(
                  'XP',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          children: [
            Text('🎯', style: TextStyle(fontSize: 48)),
            SizedBox(height: 12),
            Text(
              'Nenhuma conquista ainda.',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey),
            ),
            SizedBox(height: 4),
            Text(
              'Aprenda seu primeiro passo para começar!',
              style: TextStyle(color: Colors.grey, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatarData(DateTime data) {
    return 'Obtida em ${data.day.toString().padLeft(2, '0')}/'
        '${data.month.toString().padLeft(2, '0')}/'
        '${data.year}';
  }
}