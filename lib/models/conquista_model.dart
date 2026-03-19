import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de gatilho para conquistas automáticas.
/// O professor escolhe um desses ao criar uma conquista customizada.
enum TipoGatilho {
  passosAprendidos,   // Aluno aprendeu X movimentações no total
  nivelAtingido,      // Aluno atingiu o nível X
  passosModalidade,   // Aluno aprendeu X movimentações de uma modalidade específica
  passosValidados,    // Aluno teve X movimentações validadas pelo professor
  frequenciaSemanas,  // Aluno aprendeu pelo menos 1 passo por X semanas seguidas
  especial,           // Concedida manualmente pelo professor (sem gatilho automático)
}

/// Critério de disparo automático de uma conquista.
class CriterioConquista {
  final TipoGatilho gatilho;
  final int valor;              // Quantidade necessária (ex: 10 passos, nível 5)
  final String? modalidade;    // Usado apenas pelo gatilho passosModalidade

  const CriterioConquista({
    required this.gatilho,
    required this.valor,
    this.modalidade,
  });

  factory CriterioConquista.fromMap(Map<String, dynamic> map) {
    return CriterioConquista(
      gatilho: TipoGatilho.values.firstWhere(
        (g) => g.name == map['gatilho'],
        orElse: () => TipoGatilho.especial,
      ),
      valor: map['valor'] ?? 1,
      modalidade: map['modalidade'],
    );
  }

  Map<String, dynamic> toMap() => {
        'gatilho': gatilho.name,
        'valor': valor,
        if (modalidade != null) 'modalidade': modalidade,
      };

  /// Descrição legível do critério para exibir na UI.
  String get descricaoLegivel {
    switch (gatilho) {
      case TipoGatilho.passosAprendidos:
        return valor == 1
            ? 'Aprender 1 movimentação'
            : 'Aprender $valor movimentações';
      case TipoGatilho.nivelAtingido:
        return 'Atingir o nível $valor';
      case TipoGatilho.passosModalidade:
        final mod = modalidade != null ? ' de $modalidade' : '';
        return valor == 1
            ? 'Aprender 1 movimentação$mod'
            : 'Aprender $valor movimentações$mod';
      case TipoGatilho.passosValidados:
        return valor == 1
            ? 'Ter 1 movimentação validada pelo professor'
            : 'Ter $valor movimentações validadas pelo professor';
      case TipoGatilho.frequenciaSemanas:
        return valor == 1
            ? 'Aprender por 1 semana seguida'
            : 'Aprender por $valor semanas seguidas';
      case TipoGatilho.especial:
        return 'Concedida pelo professor';
    }
  }
}

/// Modelo de Conquista (Badge) — elemento central da gamificação.
/// Corresponde à classe "Conquista" do diagrama de classes do TCC.
class ConquistaModel {
  final String id;
  final String nome;
  final String descricao;
  final String icone;
  final int xpRecompensa;
  final DateTime? dataObtida;   // null = disponível mas não obtida

  /// Critério de disparo automático.
  /// null = conquista especial (professor concede manualmente).
  final CriterioConquista? criterio;

  /// UID do professor que criou (null = conquista do sistema).
  final String? professorId;

  const ConquistaModel({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.icone,
    required this.xpRecompensa,
    this.dataObtida,
    this.criterio,
    this.professorId,
  });

  bool get foiObtida => dataObtida != null;
  bool get isAutomatica =>
      criterio != null && criterio!.gatilho != TipoGatilho.especial;
  bool get isEspecial =>
      criterio == null || criterio!.gatilho == TipoGatilho.especial;

  factory ConquistaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ConquistaModel.fromMap({...data, 'id': doc.id});
  }

  factory ConquistaModel.fromMap(Map<String, dynamic> data) {
    return ConquistaModel(
      id: data['id'] ?? '',
      nome: data['nome'] ?? '',
      descricao: data['descricao'] ?? '',
      icone: data['icone'] ?? '🏅',
      xpRecompensa: data['xpRecompensa'] ?? 50,
      dataObtida: data['dataObtida'] != null
          ? (data['dataObtida'] as Timestamp).toDate()
          : null,
      criterio: data['criterio'] != null
          ? CriterioConquista.fromMap(
              Map<String, dynamic>.from(data['criterio']))
          : null,
      professorId: data['professorId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'icone': icone,
      'xpRecompensa': xpRecompensa,
      'dataObtida':
          dataObtida != null ? Timestamp.fromDate(dataObtida!) : null,
      if (criterio != null) 'criterio': criterio!.toMap(),
      if (professorId != null) 'professorId': professorId,
    };
  }

  ConquistaModel copyWith({DateTime? dataObtida}) {
    return ConquistaModel(
      id: id,
      nome: nome,
      descricao: descricao,
      icone: icone,
      xpRecompensa: xpRecompensa,
      dataObtida: dataObtida ?? this.dataObtida,
      criterio: criterio,
      professorId: professorId,
    );
  }
}