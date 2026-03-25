import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../widgets/tap_effect.dart';

class StudentConquistasScreen extends StatelessWidget {
  const StudentConquistasScreen({super.key});

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
            Expanded(
              child: _ConquistasBody(uid: uid),
            ),
          ],
        ),
      ),
    );
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
            'Conquistas',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppTheme.secondary,
              letterSpacing: -1,
            ),
          ),
          Text(
            'Acompanhe seu progresso e desbloqueie recompensas',
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _ConquistasBody extends StatelessWidget {
  final String uid;
  const _ConquistasBody({required this.uid});

  @override
  Widget build(BuildContext context) {
    if (uid.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final conquistasCatalogoStream =
        FirebaseFirestore.instance.collection('conquistasCustom').snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: conquistasCatalogoStream,
      builder: (context, catalogoSnap) {
        if (catalogoSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final catalogo = (catalogoSnap.data?.docs ?? [])
            .map((d) => ConquistaModel.fromFirestore(d))
            .toList();

        if (catalogo.isEmpty) {
          return const _EmptyState();
        }

        return FutureBuilder<_ConquistaStats>(
          future: _ConquistaStats.carregar(uid),
          builder: (context, statsSnap) {
            final stats = statsSnap.data ?? _ConquistaStats.vazio(uid);

            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('usuarios')
                  .doc(uid)
                  .snapshots(),
              builder: (context, userSnap) {
                final userData =
                    userSnap.data?.data() as Map<String, dynamic>? ?? {};
                final conquistasArray =
                    List<Map<String, dynamic>>.from(userData['conquistas'] ?? []);
                final obtidasPorArray = {
                  for (final c in conquistasArray)
                    (c['id'] ?? '').toString(): ConquistaModel.fromMap(c),
                };

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('usuarios')
                      .doc(uid)
                      .collection('conquistas')
                      .snapshots(),
                  builder: (context, obtidasSnap) {
                    final obtidasSub = (obtidasSnap.data?.docs ?? [])
                        .map((d) => ConquistaModel.fromFirestore(d))
                        .toList();
                    final obtidasPorSub = {
                      for (final c in obtidasSub) c.id: c,
                    };

                    final todas = catalogo
                        .map((c) => _mergeConquista(
                              base: c,
                              obtidaSub: obtidasPorSub[c.id],
                              obtidaArray: obtidasPorArray[c.id],
                            ))
                        .toList();

                    final obtidas = todas.where((c) => c.foiObtida).toList()
                      ..sort((a, b) {
                        final da = a.dataObtida ?? DateTime(1970);
                        final db = b.dataObtida ?? DateTime(1970);
                        return db.compareTo(da);
                      });

                    final bloqueadas = todas.where((c) => !c.foiObtida).toList()
                      ..sort((a, b) => a.nome.compareTo(b.nome));

                    final ordenadas = [...obtidas, ...bloqueadas];

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(25, 10, 25, 140),
                      itemCount: ordenadas.length,
                      itemBuilder: (_, i) => _ConquistaTile(
                        conquista: ordenadas[i],
                        stats: stats,
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  ConquistaModel _mergeConquista({
    required ConquistaModel base,
    ConquistaModel? obtidaSub,
    ConquistaModel? obtidaArray,
  }) {
    final picked = obtidaSub ?? obtidaArray;
    if (picked == null) return base;
    return ConquistaModel(
      id: base.id,
      nome: base.nome.isNotEmpty ? base.nome : picked.nome,
      descricao: base.descricao.isNotEmpty ? base.descricao : picked.descricao,
      icone: base.icone.isNotEmpty ? base.icone : picked.icone,
      xpRecompensa: base.xpRecompensa != 0 ? base.xpRecompensa : picked.xpRecompensa,
      dataObtida: picked.dataObtida ?? DateTime.now(),
      criterio: base.criterio ?? picked.criterio,
      professorId: base.professorId ?? picked.professorId,
    );
  }
}

class _ConquistaTile extends StatelessWidget {
  final ConquistaModel conquista;
  final _ConquistaStats stats;
  const _ConquistaTile({required this.conquista, required this.stats});

  @override
  Widget build(BuildContext context) {
    final obtida = conquista.foiObtida;
    final (atual, meta) = stats.progresso(conquista);
    final progresso = meta <= 0 ? (obtida ? 1.0 : 0.0) : (atual / meta).clamp(0.0, 1.0);

    final bg = obtida ? Colors.white : AppTheme.surface;
    final titleColor = obtida ? AppTheme.secondary : Colors.grey[600]!;
    final subColor = obtida ? Colors.grey[600]! : Colors.grey[500]!;

    final progressText = meta <= 0
        ? (conquista.criterio?.descricaoLegivel ?? 'Conquista')
        : '$atual/$meta';

    return TapEffect(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: obtida ? AppTheme.primary.withOpacity(0.15) : Colors.transparent,
          ),
          boxShadow: [
            if (obtida)
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: obtida
                    ? AppTheme.primary.withOpacity(0.10)
                    : Colors.grey.withOpacity(0.10),
              ),
              child: Center(
                child: Text(conquista.icone,
                    style: TextStyle(
                      fontSize: 26,
                      color: obtida ? null : Colors.grey[400],
                    )),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conquista.nome,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conquista.descricao.isNotEmpty
                        ? conquista.descricao
                        : (conquista.criterio?.descricaoLegivel ?? ''),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: subColor, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progresso,
                            minHeight: 7,
                            backgroundColor: Colors.black.withOpacity(0.05),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              obtida ? AppTheme.primary : Colors.grey[400]!,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        obtida ? 'OK' : progressText,
                        style: TextStyle(
                          color: obtida ? AppTheme.primary : Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 14,
                        color: obtida ? AppTheme.primary : Colors.grey[400],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '+${conquista.xpRecompensa} XP',
                        style: TextStyle(
                          color: obtida ? AppTheme.primary : Colors.grey[500],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (obtida && conquista.dataObtida != null)
                        Text(
                          _dataCurtinha(conquista.dataObtida!),
                          style: TextStyle(color: Colors.grey[400], fontSize: 11),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dataCurtinha(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.workspace_premium_rounded,
                size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text('Nenhuma conquista cadastrada.',
                style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('Peça ao professor para adicionar conquistas.',
                style: TextStyle(color: Colors.grey[350], fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _ConquistaStats {
  final String uid;
  final int nivel;
  final int totalAprendidos;
  final int totalValidados;
  final int semanasContinuas;
  final Map<String, int> porModalidade;

  const _ConquistaStats({
    required this.uid,
    required this.nivel,
    required this.totalAprendidos,
    required this.totalValidados,
    required this.semanasContinuas,
    required this.porModalidade,
  });

  static _ConquistaStats vazio(String uid) => _ConquistaStats(
        uid: uid,
        nivel: 1,
        totalAprendidos: 0,
        totalValidados: 0,
        semanasContinuas: 0,
        porModalidade: const {},
      );

  static Future<_ConquistaStats> carregar(String uid) async {
    final db = FirebaseFirestore.instance;
    final userSnap = await db.collection('usuarios').doc(uid).get();
    final userData = userSnap.data() ?? {};
    final nivel = userData['nivel'] ?? 1;

    final progressoSnap = await db
        .collection('progressoAluno')
        .where('alunoId', isEqualTo: uid)
        .where('status', whereIn: ['aprendido', 'validado'])
        .get();

    final totalAprendidos = progressoSnap.docs.length;
    final totalValidados = progressoSnap.docs
        .where((d) =>
            d.data()['status'] == 'validado')
        .length;

    final porModalidade = <String, int>{};
    final semanas = <int>{};
    for (final doc in progressoSnap.docs) {
      final data = doc.data();
      final mod = (data['modalidade'] as String?) ?? '';
      if (mod.isNotEmpty) {
        porModalidade[mod] = (porModalidade[mod] ?? 0) + 1;
      }
      final ts = data['dataAprendido'] as Timestamp?;
      if (ts != null) {
        final date = ts.toDate();
        final semana = date.difference(DateTime(2020)).inDays ~/ 7;
        semanas.add(semana);
      }
    }

    final semanasContinuas = _calcularSequencia(semanas);

    return _ConquistaStats(
      uid: uid,
      nivel: nivel,
      totalAprendidos: totalAprendidos,
      totalValidados: totalValidados,
      semanasContinuas: semanasContinuas,
      porModalidade: porModalidade,
    );
  }

  (int atual, int meta) progresso(ConquistaModel conquista) {
    final criterio = conquista.criterio;
    if (criterio == null || criterio.gatilho == TipoGatilho.especial) {
      return (conquista.foiObtida ? 1 : 0, 1);
    }

    final meta = criterio.valor;
    switch (criterio.gatilho) {
      case TipoGatilho.passosAprendidos:
        return (totalAprendidos, meta);
      case TipoGatilho.nivelAtingido:
        return (nivel, meta);
      case TipoGatilho.passosModalidade:
        final atual = porModalidade[criterio.modalidade ?? ''] ?? 0;
        return (atual, meta);
      case TipoGatilho.passosValidados:
        return (totalValidados, meta);
      case TipoGatilho.frequenciaSemanas:
        return (semanasContinuas, meta);
      case TipoGatilho.especial:
        return (conquista.foiObtida ? 1 : 0, 1);
    }
  }

  static int _calcularSequencia(Set<int> semanas) {
    if (semanas.isEmpty) return 0;
    final sorted = semanas.toList()..sort();
    var best = 1;
    var current = 1;
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i] == sorted[i - 1] + 1) {
        current++;
        if (current > best) best = current;
      } else if (sorted[i] != sorted[i - 1]) {
        current = 1;
      }
    }
    return best;
  }
}

