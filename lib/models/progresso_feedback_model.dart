import 'package:cloud_firestore/cloud_firestore.dart';

/// Status de aprendizado de uma movimentação.
enum StatusProgresso {
  naoAprendido,  // Ainda não visto
  emProgresso,   // Praticando
  aprendido,     // Marcado pelo próprio aluno → ganha XP base
  validado,      // Confirmado pelo professor → ganha XP bônus adicional
}

/// Recompensas de XP para cada transição de status.
class XPRecompensa {
  static const int marcarAprendido = 50;   // Aluno marca como aprendido
  static const int validadoProfessor = 25; // Professor confirma a aprendizagem
  static const int conquistaObtida = 30;   // Bônus ao desbloquear uma conquista
}

/// Modelo de Progresso do Aluno em uma Movimentação específica.
/// Corresponde à classe "ProgressoAluno" do diagrama do TCC.
class ProgressoAlunoModel {
  final String id;
  final String alunoId;
  final String movimentacaoId;
  final String movimentacaoNome;    // Denormalizado para evitar joins
  final String modalidade;          // Denormalizado para filtros rápidos
  final StatusProgresso status;
  final DateTime? dataAprendido;    // Quando o aluno marcou como aprendido
  final DateTime? dataValidado;     // Quando o professor validou
  final String? professorValidouId; // UID do professor que validou
  final int xpGanhoAluno;           // XP recebido ao marcar como aprendido
  final int xpGanhoValidacao;       // XP bônus recebido ao ser validado

  const ProgressoAlunoModel({
    required this.id,
    required this.alunoId,
    required this.movimentacaoId,
    required this.movimentacaoNome,
    required this.modalidade,
    required this.status,
    this.dataAprendido,
    this.dataValidado,
    this.professorValidouId,
    this.xpGanhoAluno = 0,
    this.xpGanhoValidacao = 0,
  });

  bool get foiAprendido =>
      status == StatusProgresso.aprendido ||
      status == StatusProgresso.validado;

  bool get foiValidado => status == StatusProgresso.validado;

  /// XP total ganho com esta movimentação (base + bônus de validação).
  int get xpTotalGanho => xpGanhoAluno + xpGanhoValidacao;

  factory ProgressoAlunoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProgressoAlunoModel(
      id: doc.id,
      alunoId: data['alunoId'] ?? '',
      movimentacaoId: data['movimentacaoId'] ?? '',
      movimentacaoNome: data['movimentacaoNome'] ?? '',
      modalidade: data['modalidade'] ?? '',
      status: StatusProgresso.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => StatusProgresso.naoAprendido,
      ),
      dataAprendido: data['dataAprendido'] != null
          ? (data['dataAprendido'] as Timestamp).toDate()
          : null,
      dataValidado: data['dataValidado'] != null
          ? (data['dataValidado'] as Timestamp).toDate()
          : null,
      professorValidouId: data['professorValidouId'],
      xpGanhoAluno: data['xpGanhoAluno'] ?? 0,
      xpGanhoValidacao: data['xpGanhoValidacao'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'alunoId': alunoId,
      'movimentacaoId': movimentacaoId,
      'movimentacaoNome': movimentacaoNome,
      'modalidade': modalidade,
      'status': status.name,
      if (dataAprendido != null)
        'dataAprendido': Timestamp.fromDate(dataAprendido!),
      if (dataValidado != null)
        'dataValidado': Timestamp.fromDate(dataValidado!),
      if (professorValidouId != null)
        'professorValidouId': professorValidouId,
      'xpGanhoAluno': xpGanhoAluno,
      'xpGanhoValidacao': xpGanhoValidacao,
    };
  }

  /// Retorna uma cópia marcada como aprendida pelo aluno.
  ProgressoAlunoModel marcarComoAprendido() {
    return ProgressoAlunoModel(
      id: id,
      alunoId: alunoId,
      movimentacaoId: movimentacaoId,
      movimentacaoNome: movimentacaoNome,
      modalidade: modalidade,
      status: StatusProgresso.aprendido,
      dataAprendido: DateTime.now(),
      dataValidado: dataValidado,
      professorValidouId: professorValidouId,
      xpGanhoAluno: XPRecompensa.marcarAprendido,
      xpGanhoValidacao: xpGanhoValidacao,
    );
  }

  /// Retorna uma cópia validada pelo professor.
  ProgressoAlunoModel validarComoProfessor(String professorId) {
    return ProgressoAlunoModel(
      id: id,
      alunoId: alunoId,
      movimentacaoId: movimentacaoId,
      movimentacaoNome: movimentacaoNome,
      modalidade: modalidade,
      status: StatusProgresso.validado,
      dataAprendido: dataAprendido,
      dataValidado: DateTime.now(),
      professorValidouId: professorId,
      xpGanhoAluno: xpGanhoAluno,
      xpGanhoValidacao: XPRecompensa.validadoProfessor,
    );
  }
}

/// Modelo de Feedback — avaliação qualitativa do professor sobre o aluno.
/// Corresponde à classe "Feedback" do diagrama de classes do TCC.
/// O feedback pode opcionalmente validar uma movimentação e conceder XP bônus.
class FeedbackModel {
  final String id;
  final String professorId;
  final String professorNome;   // Denormalizado para exibição
  final String alunoId;
  final String texto;
  final DateTime data;

  // Feedback pode ser vinculado a uma movimentação específica
  final String? movimentacaoId;
  final String? movimentacaoNome;

  // Se true, este feedback também valida a movimentação e concede XP bônus
  final bool validaMovimentacao;

  const FeedbackModel({
    required this.id,
    required this.professorId,
    required this.professorNome,
    required this.alunoId,
    required this.texto,
    required this.data,
    this.movimentacaoId,
    this.movimentacaoNome,
    this.validaMovimentacao = false,
  });

  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FeedbackModel(
      id: doc.id,
      professorId: data['professorId'] ?? '',
      professorNome: data['professorNome'] ?? 'Professor',
      alunoId: data['alunoId'] ?? '',
      texto: data['texto'] ?? '',
      data: (data['data'] as Timestamp?)?.toDate() ?? DateTime.now(),
      movimentacaoId: data['movimentacaoId'],
      movimentacaoNome: data['movimentacaoNome'],
      validaMovimentacao: data['validaMovimentacao'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'professorId': professorId,
      'professorNome': professorNome,
      'alunoId': alunoId,
      'texto': texto,
      'data': FieldValue.serverTimestamp(),
      if (movimentacaoId != null) 'movimentacaoId': movimentacaoId,
      if (movimentacaoNome != null) 'movimentacaoNome': movimentacaoNome,
      'validaMovimentacao': validaMovimentacao,
    };
  }
}