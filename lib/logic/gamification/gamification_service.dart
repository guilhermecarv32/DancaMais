import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';

/// Recompensas de XP para cada transição de status.
class XPRecompensa {
  static const int marcarAprendido = 50;
  static const int validadoProfessor = 25;
}

/// Serviço central de gamificação.
/// Fluxo conforme Diagrama de Sequência do TCC:
/// Aluno marca aprendido → atualiza Firestore → verifica conquistas → notifica UI.
class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── AÇÃO DO ALUNO: Marcar como aprendido ────────────────────────

  Future<List<ConquistaModel>> registrarAprendizado({
    required String alunoId,
    required MovimentacaoModel movimentacao,
  }) async {
    final progressoRef = _firestore
        .collection('progressoAluno')
        .doc('${alunoId}_${movimentacao.id}');

    final progressoSnap = await progressoRef.get();
    if (progressoSnap.exists) {
      final p = ProgressoAlunoModel.fromFirestore(progressoSnap);
      if (p.foiAprendido) return [];
    }

    final novoProgresso = ProgressoAlunoModel(
      id: '${alunoId}_${movimentacao.id}',
      alunoId: alunoId,
      movimentacaoId: movimentacao.id,
      movimentacaoNome: movimentacao.nome,
      modalidade: movimentacao.modalidade,
      status: StatusProgresso.aprendido,
      dataAprendido: DateTime.now(),
      xpGanhoAluno: XPRecompensa.marcarAprendido,
      xpGanhoValidacao: 0,
    );

    await _firestore.runTransaction((transaction) async {
      final alunoRef = _firestore.collection('usuarios').doc(alunoId);
      final alunoSnap = await transaction.get(alunoRef);
      final alunoData = alunoSnap.data() as Map<String, dynamic>;

      final int xpAtual = alunoData['xp'] ?? 0;
      final int novoXP = xpAtual + XPRecompensa.marcarAprendido;
      final int novoNivel = _calcularNivel(novoXP);

      transaction.set(progressoRef, novoProgresso.toMap());
      transaction.update(alunoRef, {'xp': novoXP, 'nivel': novoNivel});
      transaction.update(
        _firestore.collection('movimentacoes').doc(movimentacao.id),
        {'totalAprenderam': FieldValue.increment(1)},
      );
    });

    return _verificarConquistas(alunoId);
  }

  // ─── AÇÃO DO PROFESSOR: Validar aprendizado ──────────────────────

  Future<void> validarAprendizado({
    required String professorId,
    required String alunoId,
    required String movimentacaoId,
    String? feedbackTexto,
    String? feedbackMovimentacaoNome,
  }) async {
    final progressoId = '${alunoId}_$movimentacaoId';
    final progressoRef =
        _firestore.collection('progressoAluno').doc(progressoId);

    final snap = await progressoRef.get();
    if (!snap.exists) return;

    final progresso = ProgressoAlunoModel.fromFirestore(snap);
    if (progresso.foiValidado) return;

    await _firestore.runTransaction((transaction) async {
      final alunoRef = _firestore.collection('usuarios').doc(alunoId);
      final alunoSnap = await transaction.get(alunoRef);
      final alunoData = alunoSnap.data() as Map<String, dynamic>;

      final int xpAtual = alunoData['xp'] ?? 0;
      final int novoXP = xpAtual + XPRecompensa.validadoProfessor;
      final int novoNivel = _calcularNivel(novoXP);

      transaction.update(progressoRef, {
        'status': StatusProgresso.validado.name,
        'dataValidado': FieldValue.serverTimestamp(),
        'professorValidouId': professorId,
        'xpGanhoValidacao': XPRecompensa.validadoProfessor,
      });

      transaction.update(alunoRef, {'xp': novoXP, 'nivel': novoNivel});

      if (feedbackTexto != null && feedbackTexto.isNotEmpty) {
        final feedbackRef = _firestore.collection('feedbacks').doc();
        transaction.set(feedbackRef, {
          'professorId': professorId,
          'alunoId': alunoId,
          'texto': feedbackTexto,
          'data': FieldValue.serverTimestamp(),
          'movimentacaoId': movimentacaoId,
          if (feedbackMovimentacaoNome != null)
            'movimentacaoNome': feedbackMovimentacaoNome,
          'validaMovimentacao': true,
        });
      }
    });

    // Verifica conquistas após validação também
    await _verificarConquistas(alunoId);
  }

  // ─── VERIFICAÇÃO DE CONQUISTAS ───────────────────────────────────

  /// Verifica todas as conquistas cadastradas no Firestore (coleção
  /// `conquistasCustom`) e dispara as que o aluno ainda não tem
  /// e cujos critérios foram atendidos.
  Future<List<ConquistaModel>> _verificarConquistas(
      String alunoId) async {
    final conquistasDesbloqueadas = <ConquistaModel>[];

    // Busca o perfil do aluno
    final alunoSnap =
        await _firestore.collection('usuarios').doc(alunoId).get();
    final alunoData = alunoSnap.data() as Map<String, dynamic>;
    final int nivelAtual = alunoData['nivel'] ?? 1;

    // IDs de conquistas que o aluno já possui
    final List conquistasAtuais = alunoData['conquistas'] ?? [];
    final idsJaObtidos =
        conquistasAtuais.map((c) => c['id'] as String).toSet();

    // Busca progresso do aluno
    final progressoSnap = await _firestore
        .collection('progressoAluno')
        .where('alunoId', isEqualTo: alunoId)
        .where('status', whereIn: [
          StatusProgresso.aprendido.name,
          StatusProgresso.validado.name,
        ])
        .get();

    final totalAprendidos = progressoSnap.docs.length;

    // Total de movimentações validadas
    final totalValidados = progressoSnap.docs
        .where((d) =>
            (d.data() as Map)['status'] ==
            StatusProgresso.validado.name)
        .length;

    // Agrupa por modalidade
    final porModalidade = <String, int>{};
    for (final doc in progressoSnap.docs) {
      final m = (doc.data() as Map<String, dynamic>)['modalidade']
          as String? ??
          '';
      porModalidade[m] = (porModalidade[m] ?? 0) + 1;
    }

    // Verifica frequência semanal
    final semanasContinuas =
        await _calcularSemanasContinuas(progressoSnap.docs);

    // Busca todas as conquistas cadastradas pelo professor
    final conquistasSnap = await _firestore
        .collection('conquistasCustom')
        .get();

    for (final doc in conquistasSnap.docs) {
      final conquista = ConquistaModel.fromFirestore(doc);

      // Pula se já obtida ou se é especial (professor concede manualmente)
      if (idsJaObtidos.contains(conquista.id)) continue;
      if (conquista.isEspecial) continue;

      final criterio = conquista.criterio!;
      bool desbloqueou = false;

      switch (criterio.gatilho) {
        case TipoGatilho.passosAprendidos:
          desbloqueou = totalAprendidos >= criterio.valor;
        case TipoGatilho.nivelAtingido:
          desbloqueou = nivelAtual >= criterio.valor;
        case TipoGatilho.passosModalidade:
          final qtdModalidade =
              porModalidade[criterio.modalidade ?? ''] ?? 0;
          desbloqueou = qtdModalidade >= criterio.valor;
        case TipoGatilho.passosValidados:
          desbloqueou = totalValidados >= criterio.valor;
        case TipoGatilho.frequenciaSemanas:
          desbloqueou = semanasContinuas >= criterio.valor;
        case TipoGatilho.especial:
          break;
      }

      if (desbloqueou) {
        final conquistaObtida = conquista.copyWith(
          dataObtida: DateTime.now(),
        );

        await _firestore
            .collection('usuarios')
            .doc(alunoId)
            .update({
          'conquistas':
              FieldValue.arrayUnion([conquistaObtida.toMap()]),
          'xp': FieldValue.increment(conquista.xpRecompensa),
        });

        conquistasDesbloqueadas.add(conquistaObtida);
      }
    }

    return conquistasDesbloqueadas;
  }

  // ─── HELPERS ─────────────────────────────────────────────────────

  int _calcularNivel(int xpTotal) {
    const base = 100;
    const fator = 1.5;
    int nivel = 1;
    int xpAcumulado = 0;
    while (nivel < 99) {
      final xpNivel = (base * (nivel * fator)).round();
      if (xpAcumulado + xpNivel > xpTotal) break;
      xpAcumulado += xpNivel;
      nivel++;
    }
    return nivel;
  }

  /// Calcula quantas semanas seguidas o aluno aprendeu pelo menos 1 passo.
  Future<int> _calcularSemanasContinuas(
      List<QueryDocumentSnapshot> docs) async {
    if (docs.isEmpty) return 0;

    // Agrupa as datas por número de semana do ano
    final semanas = <int>{};
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = data['dataAprendido'] as Timestamp?;
      if (ts == null) continue;
      final date = ts.toDate();
      // Número de semanas desde uma data fixa de referência
      final semana = date.difference(DateTime(2020)).inDays ~/ 7;
      semanas.add(semana);
    }

    if (semanas.isEmpty) return 0;

    final sorted = semanas.toList()..sort();
    int maxContinuas = 1;
    int atual = 1;

    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i] == sorted[i - 1] + 1) {
        atual++;
        if (atual > maxContinuas) maxContinuas = atual;
      } else if (sorted[i] != sorted[i - 1]) {
        atual = 1;
      }
    }

    return maxContinuas;
  }
}