import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de notificação na subcoleção `usuarios/{uid}/notificacoes`.
enum NotificacaoTipo {
  feedback,
  streakAlerta,
  validacaoPendente,
  solicitacao,
  streaksPausados,
}

NotificacaoTipo notificacaoTipoDe(String? s) => switch (s) {
      'feedback' => NotificacaoTipo.feedback,
      'streak_alerta' => NotificacaoTipo.streakAlerta,
      'validacao_pendente' => NotificacaoTipo.validacaoPendente,
      'solicitacao' => NotificacaoTipo.solicitacao,
      'streaks_pausados' => NotificacaoTipo.streaksPausados,
      _ => NotificacaoTipo.feedback,
    };

String notificacaoTipoParaFirestore(NotificacaoTipo t) => switch (t) {
      NotificacaoTipo.feedback => 'feedback',
      NotificacaoTipo.streakAlerta => 'streak_alerta',
      NotificacaoTipo.validacaoPendente => 'validacao_pendente',
      NotificacaoTipo.solicitacao => 'solicitacao',
      NotificacaoTipo.streaksPausados => 'streaks_pausados',
    };

class NotificacaoModel {
  final String id;
  final NotificacaoTipo tipo;
  final String titulo;
  final String corpo;
  final DateTime data;
  final bool lido;
  final bool oculto;
  final String? refId;
  final String? refTipo;

  const NotificacaoModel({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.corpo,
    required this.data,
    this.lido = false,
    this.oculto = false,
    this.refId,
    this.refTipo,
  });

  factory NotificacaoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return NotificacaoModel(
      id: doc.id,
      tipo: notificacaoTipoDe(data['tipo'] as String?),
      titulo: (data['titulo'] as String?) ?? '',
      corpo: (data['corpo'] as String?) ?? '',
      data: (data['data'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lido: data['lido'] == true,
      oculto: data['oculto'] == true,
      refId: data['refId'] as String?,
      refTipo: data['refTipo'] as String?,
    );
  }
}

/// Item derivado (validação pendente) — não persiste em Firestore.
class ValidacaoPendenteItem {
  final String alunoId;
  final String alunoNome;
  final String movimentacaoId;
  final String? movimentacaoNome;
  final String turmaId;
  final String turmaNome;

  const ValidacaoPendenteItem({
    required this.alunoId,
    required this.alunoNome,
    required this.movimentacaoId,
    this.movimentacaoNome,
    required this.turmaId,
    required this.turmaNome,
  });

  String get tituloExibicao {
    final passo = movimentacaoNome ?? 'passo';
    final primeiro = alunoNome.trim().split(RegExp(r'\s+')).first;
    return '$primeiro — $passo';
  }
}
