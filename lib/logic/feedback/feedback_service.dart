import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/notificacao_model.dart';
import '../gamification/gamification_service.dart';
import '../notifications/notification_service.dart';

class FeedbackService {
  static const int maxCaracteres = 500;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notifs = NotificationService();
  final GamificationService _gamif = GamificationService();

  Future<String?> _nomeProfessor(String professorId) async {
    final doc = await _db.collection('usuarios').doc(professorId).get();
    return (doc.data()?['nome'] as String?) ?? 'Professor';
  }

  Future<String> _criarFeedbackDoc(Map<String, dynamic> data) async {
    final ref = await _db.collection('feedbacks').add({
      ...data,
      'data': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> _notificarAluno({
    required String alunoId,
    required String titulo,
    required String corpo,
    required String feedbackId,
  }) async {
    await _notifs.criar(
      usuarioId: alunoId,
      tipo: NotificacaoTipo.feedback,
      titulo: titulo,
      corpo: corpo,
      refId: feedbackId,
      refTipo: 'feedback',
    );
  }

  /// Feedback com passo (opcional validar no mesmo fluxo).
  Future<String?> enviarPorMovimentacao({
    required String alunoId,
    required String movimentacaoId,
    String? movimentacaoNome,
    required String texto,
    bool tambemValidar = false,
  }) async {
    final t = texto.trim();
    if (t.isEmpty) return 'Digite o feedback.';
    if (t.length > maxCaracteres) {
      return 'Máximo de $maxCaracteres caracteres.';
    }

    final professorId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (professorId.isEmpty) return 'Sessão inválida.';

    final professorNome = await _nomeProfessor(professorId) ?? 'Professor';

    final feedbackId = await _criarFeedbackDoc({
      'professorId': professorId,
      'professorNome': professorNome,
      'alunoId': alunoId,
      'texto': t,
      'tipo': 'movimentacao',
      'movimentacaoId': movimentacaoId,
      if (movimentacaoNome != null) 'movimentacaoNome': movimentacaoNome,
      'validaMovimentacao': tambemValidar,
    });

    final passo = movimentacaoNome ?? 'passo';
    await _notificarAluno(
      alunoId: alunoId,
      titulo: 'Feedback — $passo',
      corpo: t,
      feedbackId: feedbackId,
    );

    if (tambemValidar) {
      await _gamif.validarAprendizado(
        professorId: professorId,
        alunoId: alunoId,
        movimentacaoId: movimentacaoId,
        feedbackMovimentacaoNome: movimentacaoNome,
      );
    }

    return null;
  }

  /// Feedback geral para um aluno da turma.
  Future<String?> enviarParaAluno({
    required String alunoId,
    required String turmaId,
    required String turmaNome,
    required String texto,
  }) async {
    final t = texto.trim();
    if (t.isEmpty) return 'Digite o feedback.';
    if (t.length > maxCaracteres) {
      return 'Máximo de $maxCaracteres caracteres.';
    }

    final professorId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (professorId.isEmpty) return 'Sessão inválida.';

    final professorNome = await _nomeProfessor(professorId) ?? 'Professor';

    final feedbackId = await _criarFeedbackDoc({
      'professorId': professorId,
      'professorNome': professorNome,
      'alunoId': alunoId,
      'texto': t,
      'tipo': 'aluno',
      'turmaId': turmaId,
      'turmaNome': turmaNome,
      'validaMovimentacao': false,
    });

    await _notificarAluno(
      alunoId: alunoId,
      titulo: 'Feedback — $turmaNome',
      corpo: t,
      feedbackId: feedbackId,
    );

    return null;
  }

  /// Feedback para todos os inscritos na turma.
  Future<String?> enviarParaTurma({
    required String turmaId,
    required String turmaNome,
    required String texto,
  }) async {
    final t = texto.trim();
    if (t.isEmpty) return 'Digite o feedback.';
    if (t.length > maxCaracteres) {
      return 'Máximo de $maxCaracteres caracteres.';
    }

    final professorId = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (professorId.isEmpty) return 'Sessão inválida.';

    final professorNome = await _nomeProfessor(professorId) ?? 'Professor';

    final inscSnap = await _db
        .collection('inscricoes')
        .where('turmaId', isEqualTo: turmaId)
        .get();
    final alunoIds = inscSnap.docs
        .map((d) => (d.data()['alunoId'] as String?) ?? '')
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (alunoIds.isEmpty) return 'Nenhum aluno na turma.';

    final feedbackId = await _criarFeedbackDoc({
      'professorId': professorId,
      'professorNome': professorNome,
      'texto': t,
      'tipo': 'turma',
      'turmaId': turmaId,
      'turmaNome': turmaNome,
      'validaMovimentacao': false,
    });

    for (final alunoId in alunoIds) {
      await _notificarAluno(
        alunoId: alunoId,
        titulo: 'Feedback da turma — $turmaNome',
        corpo: t,
        feedbackId: feedbackId,
      );
    }

    return null;
  }

  Future<void> excluir(String feedbackId) async {
    await _db.collection('feedbacks').doc(feedbackId).delete();
    await _notifs.removerPorFeedback(feedbackId);
  }

  Future<Map<String, dynamic>?> buscar(String feedbackId) async {
    final doc = await _db.collection('feedbacks').doc(feedbackId).get();
    return doc.data();
  }
}
