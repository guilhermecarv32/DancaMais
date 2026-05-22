import 'package:cloud_firestore/cloud_firestore.dart';
import '../../logic/streak/streak_service.dart';
import '../../models/models.dart';
import '../../models/notificacao_model.dart';
import '../../models/turma_model.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _notifs(String uid) =>
      _db.collection('usuarios').doc(uid).collection('notificacoes');

  Future<void> criar({
    required String usuarioId,
    required NotificacaoTipo tipo,
    required String titulo,
    required String corpo,
    String? refId,
    String? refTipo,
  }) async {
    await _notifs(usuarioId).add({
      'tipo': notificacaoTipoParaFirestore(tipo),
      'titulo': titulo,
      'corpo': corpo,
      'data': FieldValue.serverTimestamp(),
      'lido': false,
      'oculto': false,
      if (refId != null) 'refId': refId,
      if (refTipo != null) 'refTipo': refTipo,
    });
  }

  Stream<int> contagemNaoLidas(String uid) {
    return _notifs(uid).snapshots().map((s) {
      return s.docs.where((d) {
        final data = d.data();
        return data['lido'] != true && data['oculto'] != true;
      }).length;
    });
  }

  Stream<List<NotificacaoModel>> streamParaUsuario(String uid) {
    return _notifs(uid)
        .orderBy('data', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs
            .map(NotificacaoModel.fromFirestore)
            .where((n) => !n.oculto)
            .toList());
  }

  Future<void> marcarLido(String uid, String notifId) async {
    await _notifs(uid).doc(notifId).update({'lido': true});
  }

  Future<void> ocultar(String uid, String notifId) async {
    await _notifs(uid).doc(notifId).update({'oculto': true, 'lido': true});
  }

  Future<void> removerPorFeedback(String feedbackId) async {
    await removerPorRef(refId: feedbackId, refTipo: 'feedback');
  }

  Future<void> removerPorRef({
    required String refId,
    required String refTipo,
  }) async {
    final snap = await _db
        .collectionGroup('notificacoes')
        .where('refId', isEqualTo: refId)
        .where('refTipo', isEqualTo: refTipo)
        .get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }
  }

  Future<void> limparTodasVisiveis(String uid) async {
    final snap = await _notifs(uid).where('oculto', isEqualTo: false).get();
    if (snap.docs.isEmpty) return;
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {'oculto': true, 'lido': true});
    }
    await batch.commit();
  }

  List<String> _modalidadesDe(Map<String, dynamic> data) {
    final raw = data['modalidades'];
    if (raw is List) return List<String>.from(raw);
    if (raw is String && raw.isNotEmpty) return raw.split(', ');
    return [];
  }

  Future<Set<String>> _professorUidsParaTurma(TurmaModel turma) async {
    final uids = <String>{};
    if (turma.professorId.isNotEmpty) uids.add(turma.professorId);

    final profs =
        await _db.collection('usuarios').where('tipo', isEqualTo: 'professor').get();
    for (final d in profs.docs) {
      final data = d.data();
      if (data['isAdmin'] == true) {
        uids.add(d.id);
      } else if (_modalidadesDe(data).contains(turma.modalidade)) {
        uids.add(d.id);
      }
    }
    return uids;
  }

  Future<bool> _notificacaoExiste({
    required String usuarioId,
    required String refId,
    required String refTipo,
  }) async {
    final snap = await _notifs(usuarioId)
        .where('refId', isEqualTo: refId)
        .where('refTipo', isEqualTo: refTipo)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Cria notificação para professores quando aluno marca passo como aprendido.
  Future<void> notificarValidacaoPendente({
    required String progressoId,
    required String alunoId,
    required String alunoNome,
    required String movimentacaoId,
    required String movimentacaoNome,
    required String modalidade,
  }) async {
    final turmasSnap = await _db
        .collection('turmas')
        .where('passoSemanaId', isEqualTo: movimentacaoId)
        .get();

    final primeiroNome = alunoNome.trim().split(RegExp(r'\s+')).first;
    final titulo = '$primeiroNome — $movimentacaoNome';
    final corpo = 'Validar passo da semana';

    final notificados = <String>{};

    for (final tDoc in turmasSnap.docs) {
      final turma = TurmaModel.fromFirestore(tDoc);
      if (turma.modalidade != modalidade) continue;

      for (final profUid in await _professorUidsParaTurma(turma)) {
        if (!notificados.add(profUid)) continue;
        if (await _notificacaoExiste(
          usuarioId: profUid,
          refId: progressoId,
          refTipo: 'validacao_pendente',
        )) {
          continue;
        }
        await criar(
          usuarioId: profUid,
          tipo: NotificacaoTipo.validacaoPendente,
          titulo: titulo,
          corpo: '$corpo · ${turma.nome}',
          refId: progressoId,
          refTipo: 'validacao_pendente',
        );
      }
    }
  }

  /// Cria notificação quando aluno solicita entrada na turma.
  Future<void> notificarSolicitacaoEntrada({
    required String turmaId,
    required String turmaNome,
    required String modalidade,
    required String alunoId,
    required String alunoNome,
  }) async {
    final refId = 'sol_${turmaId}_$alunoId';
    final turmaDoc = await _db.collection('turmas').doc(turmaId).get();
    if (!turmaDoc.exists) return;
    final turma = TurmaModel.fromFirestore(turmaDoc);

    for (final profUid in await _professorUidsParaTurma(turma)) {
      if (await _notificacaoExiste(
        usuarioId: profUid,
        refId: refId,
        refTipo: 'solicitacao',
      )) {
        continue;
      }
      await criar(
        usuarioId: profUid,
        tipo: NotificacaoTipo.solicitacao,
        titulo: alunoNome,
        corpo: 'Solicitação de entrada · $turmaNome',
        refId: refId,
        refTipo: 'solicitacao',
      );
    }
  }

  /// Alertas de streak viram notificações na subcoleção do professor (dá para limpar uma a uma).
  Future<void> sincronizarAlertasStreak({
    required String professorUid,
    required List<String>? modalidadesFiltro,
  }) async {
    if (professorUid.isEmpty) return;

    final streakSvc = StreakService();
    final alertas = await streakSvc.listarAlertasProfessor(
      modalidadesFiltro: modalidadesFiltro,
    );
    final alunoIdsAtivos = <String>{};

    for (final a in alertas) {
      alunoIdsAtivos.add(a.alunoId);
      if (await _notificacaoExiste(
        usuarioId: professorUid,
        refId: a.alunoId,
        refTipo: 'streak_alerta',
      )) {
        continue;
      }
      await criar(
        usuarioId: professorUid,
        tipo: NotificacaoTipo.streakAlerta,
        titulo: a.tituloExibicao,
        corpo: a.resumoNotificacao,
        refId: a.alunoId,
        refTipo: 'streak_alerta',
      );
    }

    final snap = await _notifs(professorUid)
        .where('refTipo', isEqualTo: 'streak_alerta')
        .where('oculto', isEqualTo: false)
        .get();
    for (final d in snap.docs) {
      final alunoId = d.data()['refId'] as String?;
      if (alunoId != null && !alunoIdsAtivos.contains(alunoId)) {
        await d.reference.update({'oculto': true, 'lido': true});
      }
    }
  }

  /// Garante notificações para pendências já existentes (ex.: antes do deploy).
  Future<void> sincronizarPendenciasProfessor({
    required String professorUid,
    required List<String>? modalidadesFiltro,
  }) async {
    final validacoes = await listarValidacoesPendentes(
      modalidadesFiltro: modalidadesFiltro,
    );
    for (final v in validacoes) {
      await notificarValidacaoPendente(
        progressoId: '${v.alunoId}_${v.movimentacaoId}',
        alunoId: v.alunoId,
        alunoNome: v.alunoNome,
        movimentacaoId: v.movimentacaoId,
        movimentacaoNome: v.movimentacaoNome ?? 'Passo da semana',
        modalidade: await _modalidadeDaTurma(v.turmaId),
      );
    }

    final solicitacoes = await listarSolicitacoesPendentes(
      modalidadesFiltro: modalidadesFiltro,
    );
    for (final s in solicitacoes) {
      await notificarSolicitacaoEntrada(
        turmaId: (s['turmaId'] as String?) ?? '',
        turmaNome: (s['nomeTurma'] as String?) ?? 'Turma',
        modalidade: (s['modalidade'] as String?) ?? '',
        alunoId: (s['alunoId'] as String?) ?? '',
        alunoNome: (s['nomeAluno'] as String?) ?? 'Aluno',
      );
    }

    await sincronizarAlertasStreak(
      professorUid: professorUid,
      modalidadesFiltro: modalidadesFiltro,
    );
  }

  Future<String> _modalidadeDaTurma(String turmaId) async {
    final doc = await _db.collection('turmas').doc(turmaId).get();
    return (doc.data()?['modalidade'] as String?) ?? '';
  }

  /// Validações pendentes: aluno marcou aprendido, professor ainda não validou.
  Future<List<ValidacaoPendenteItem>> listarValidacoesPendentes({
    required List<String>? modalidadesFiltro,
  }) async {
    final turmasSnap = await _db.collection('turmas').get();
    final turmas = <TurmaModel>[];
    for (final d in turmasSnap.docs) {
      final t = TurmaModel.fromFirestore(d);
      if (t.passoSemanaId == null || t.passoSemanaId!.isEmpty) continue;
      if (modalidadesFiltro != null &&
          !modalidadesFiltro.contains(t.modalidade)) {
        continue;
      }
      turmas.add(t);
    }
    if (turmas.isEmpty) return [];

    final itens = <ValidacaoPendenteItem>[];

    for (final turma in turmas) {
      final passoId = turma.passoSemanaId!;
      final inscSnap = await _db
          .collection('inscricoes')
          .where('turmaId', isEqualTo: turma.id)
          .get();
      final alunoIds = inscSnap.docs
          .map((d) => (d.data()['alunoId'] as String?) ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      if (alunoIds.isEmpty) continue;

      for (int i = 0; i < alunoIds.length; i += 10) {
        final end = i + 10 < alunoIds.length ? i + 10 : alunoIds.length;
        final chunk = alunoIds.sublist(i, end);
        final progSnap = await _db
            .collection('progressoAluno')
            .where('movimentacaoId', isEqualTo: passoId)
            .where('status', isEqualTo: StatusProgresso.aprendido.name)
            .where('alunoId', whereIn: chunk)
            .get();

        for (final p in progSnap.docs) {
          final data = p.data();
          final alunoId = (data['alunoId'] as String?) ?? '';
          if (alunoId.isEmpty) continue;
          final alunoDoc = await _db.collection('usuarios').doc(alunoId).get();
          final nome =
              (alunoDoc.data()?['nome'] as String?) ?? 'Aluno';
          itens.add(ValidacaoPendenteItem(
            alunoId: alunoId,
            alunoNome: nome,
            movimentacaoId: passoId,
            movimentacaoNome: turma.passoSemanaNome,
            turmaId: turma.id,
            turmaNome: turma.nome,
          ));
        }
      }
    }

    itens.sort((a, b) => a.alunoNome.compareTo(b.alunoNome));
    return itens;
  }

  /// Solicitações de entrada pendentes nas turmas do professor.
  Future<List<Map<String, dynamic>>> listarSolicitacoesPendentes({
    required List<String>? modalidadesFiltro,
  }) async {
    final turmasSnap = await _db.collection('turmas').get();
    final result = <Map<String, dynamic>>[];

    for (final tDoc in turmasSnap.docs) {
      final turma = TurmaModel.fromFirestore(tDoc);
      if (modalidadesFiltro != null &&
          !modalidadesFiltro.contains(turma.modalidade)) {
        continue;
      }
      final pendSnap = await _db
          .collection('solicitacoes')
          .doc(turma.id)
          .collection('pendentes')
          .get();
      for (final p in pendSnap.docs) {
        final data = p.data();
        result.add({
          ...data,
          'turmaId': turma.id,
          'nomeTurma': turma.nome,
          'modalidade': turma.modalidade,
          'solicitacaoDocId': p.id,
        });
      }
    }
    return result;
  }

  /// Contagem para badge do professor (notificações não lidas em tempo real).
  Stream<int> streamBadgeProfessor(String uid) => contagemNaoLidas(uid);

  /// Contagem legada (consulta direta, sem subcoleção de notificações).
  Future<int> contagemPendenciasProfessor({
    required List<String>? modalidadesFiltro,
  }) async {
    final v = await listarValidacoesPendentes(
      modalidadesFiltro: modalidadesFiltro,
    );
    final s = await listarSolicitacoesPendentes(
      modalidadesFiltro: modalidadesFiltro,
    );
    return v.length + s.length;
  }
}
