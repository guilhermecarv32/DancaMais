import 'package:cloud_firestore/cloud_firestore.dart';

/// Tipos de conquista disponíveis no sistema.
/// Melhoria: enum tipado evita strings mágicas espalhadas pelo código.
enum TipoConquista {
  primeiroPasso,    // Aprendeu o primeiro passo
  sequencia,        // Aprendeu X passos seguidos
  nivel,            // Atingiu um determinado nível
  modalidade,       // Aprendeu todos os passos de uma modalidade
  frequencia,       // Acessou o app X dias seguidos
  especial,         // Concedida manualmente pelo professor
}

/// Modelo de Conquista (Badge) — elemento central da gamificação.
/// Corresponde à classe "Conquista" do diagrama de classes do TCC.
class ConquistaModel {
  final String id;
  final String nome;
  final String descricao;
  final String icone;         // Nome do ícone ou emoji representativo
  final TipoConquista tipo;
  final DateTime? dataObtida; // Null = conquista disponível mas não obtida
  final int xpRecompensa;     // Melhoria: conquistas também concedem XP

  const ConquistaModel({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.icone,
    required this.tipo,
    this.dataObtida,
    this.xpRecompensa = 50,
  });

  bool get foiObtida => dataObtida != null;

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
      tipo: TipoConquista.values.firstWhere(
        (t) => t.name == data['tipo'],
        orElse: () => TipoConquista.especial,
      ),
      dataObtida: data['dataObtida'] != null
          ? (data['dataObtida'] as Timestamp).toDate()
          : null,
      xpRecompensa: data['xpRecompensa'] ?? 50,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'icone': icone,
      'tipo': tipo.name,
      'dataObtida': dataObtida != null ? Timestamp.fromDate(dataObtida!) : null,
      'xpRecompensa': xpRecompensa,
    };
  }

  /// Conquistas padrão do sistema — usadas na inicialização do Firestore.
  static List<ConquistaModel> get conquistasPadrao => [
    const ConquistaModel(
      id: 'primeiro_passo',
      nome: 'Primeiro Passo!',
      descricao: 'Aprendeu sua primeira movimentação.',
      icone: '👣',
      tipo: TipoConquista.primeiroPasso,
      xpRecompensa: 30,
    ),
    const ConquistaModel(
      id: 'inicio_da_caminhada',
      nome: 'Início da Caminhada',
      descricao: 'Aprendeu 10 passos.',
      icone: '🚶',
      tipo: TipoConquista.sequencia,
      xpRecompensa: 80,
    ),
    const ConquistaModel(
      id: 'pegando_fogo',
      nome: 'Pegando Fogo!',
      descricao: 'Aprendeu 3 passos em menos de 3 semanas.',
      icone: '🔥',
      tipo: TipoConquista.frequencia,
      xpRecompensa: 100,
    ),
    const ConquistaModel(
      id: 'dancarino_versatil',
      nome: 'Dançarino Versátil',
      descricao: 'Aprendeu passos em 3 modalidades diferentes.',
      icone: '🎭',
      tipo: TipoConquista.modalidade,
      xpRecompensa: 150,
    ),
  ];
}