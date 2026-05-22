import 'package:cloud_firestore/cloud_firestore.dart';
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
    final snap = await _db
        .collectionGroup('notificacoes')
        .where('refId', isEqualTo: feedbackId)
        .where('refTipo', isEqualTo: 'feedback')
        .get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }
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
        final chunk = alunoIds.sublist(i, (i + 10).clamp(0, alunoIds.length));
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

  /// Contagem para badge do professor (validações + solicitações).
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
