import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipo de movimentação — diferencia Passo de Coreografia.
enum TipoMovimentacao { passo, coreografia }

/// Nível de dificuldade de uma movimentação.
enum NivelMovimentacao { iniciante, intermediario, avancado }

/// Modelo base de Movimentação (Passo ou Coreografia).
/// Corresponde à classe "Movimentacao" e suas subclasses do TCC.
/// Melhoria: unificado em um único model com campos opcionais,
/// evitando duplicação de código entre Passo e Coreografia.
class MovimentacaoModel {
  final String id;
  final String nome;
  final String descricao;
  final String modalidade;       // Ex: 'Forró', 'Bachata'
  final TipoMovimentacao tipo;
  final String professorId;      // UID do professor que cadastrou
  final DateTime dataCriacao;

  // Campos específicos de Passo
  final NivelMovimentacao? nivel;

  // Campos específicos de Coreografia
  final String? musica;
  final List<String>? passosIds;  // IDs dos passos que compõem a coreografia

  // Melhoria: suporte a vídeo demonstrativo
  final String? videoUrl;

  // Melhoria: contador de alunos que aprenderam (útil para ranking)
  final int totalAprenderam;

  const MovimentacaoModel({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.modalidade,
    required this.tipo,
    required this.professorId,
    required this.dataCriacao,
    this.nivel,
    this.musica,
    this.passosIds,
    this.videoUrl,
    this.totalAprenderam = 0,
  });

  bool get isPasso => tipo == TipoMovimentacao.passo;
  bool get isCoreografia => tipo == TipoMovimentacao.coreografia;

  factory MovimentacaoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MovimentacaoModel(
      id: doc.id,
      nome: data['nome'] ?? '',
      descricao: data['descricao'] ?? '',
      modalidade: data['modalidade'] ?? '',
      tipo: TipoMovimentacao.values.firstWhere(
        (t) => t.name == data['tipo'],
        orElse: () => TipoMovimentacao.passo,
      ),
      professorId: data['professorId'] ?? '',
      dataCriacao: (data['dataCriacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
      nivel: data['nivel'] != null
          ? NivelMovimentacao.values.firstWhere(
              (n) => n.name == data['nivel'],
              orElse: () => NivelMovimentacao.iniciante,
            )
          : null,
      musica: data['musica'],
      passosIds: data['passosIds'] != null
          ? List<String>.from(data['passosIds'])
          : null,
      videoUrl: data['videoUrl'],
      totalAprenderam: data['totalAprenderam'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'descricao': descricao,
      'modalidade': modalidade,
      'tipo': tipo.name,
      'professorId': professorId,
      'dataCriacao': FieldValue.serverTimestamp(),
      if (nivel != null) 'nivel': nivel!.name,
      if (musica != null) 'musica': musica,
      if (passosIds != null) 'passosIds': passosIds,
      if (videoUrl != null) 'videoUrl': videoUrl,
      'totalAprenderam': totalAprenderam,
    };
  }
}