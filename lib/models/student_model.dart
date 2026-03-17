import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';
import 'conquista_model.dart';

/// Modelo do Aluno — especialização de UserModel.
/// Contém os dados de gamificação: nível, XP e conquistas.
/// Corresponde à classe "Aluno" do diagrama de classes do TCC.
class StudentModel extends UserModel {
  final int nivel;
  final int xp;
  final List<ConquistaModel> conquistas;

  // Melhoria: XP necessário por nível cresce progressivamente,
  // tornando a curva de progressão mais interessante.
  static const int xpBaseParaNivel = 100;
  static const double fatorCrescimento = 1.5;

  const StudentModel({
    required super.uid,
    required super.nome,
    required super.email,
    required super.dataCriacao,
    required this.nivel,
    required this.xp,
    required this.conquistas,
  }) : super(tipo: 'aluno');

  /// XP necessário para chegar ao próximo nível.
  int get xpParaProximoNivel =>
      (xpBaseParaNivel * (nivel * fatorCrescimento)).round();

  /// Progresso atual (0.0 a 1.0) para a barra de XP.
  double get progressoXP {
    final meta = xpParaProximoNivel;
    if (meta == 0) return 0;
    // XP é acumulativo; calculamos o progresso dentro do nível atual
    final xpNoNivelAtual = xp - _xpAcumuladoAteNivel(nivel - 1);
    return (xpNoNivelAtual / meta).clamp(0.0, 1.0);
  }

  /// XP total acumulado até o início de um determinado nível.
  int _xpAcumuladoAteNivel(int n) {
    if (n <= 0) return 0;
    int total = 0;
    for (int i = 1; i <= n; i++) {
      total += (xpBaseParaNivel * (i * fatorCrescimento)).round();
    }
    return total;
  }

  /// Nome do nível atual baseado no XP/nível (ex: "Iniciante", "Intermediário").
  String get nomeTitulo {
    if (nivel <= 2) return 'Iniciante';
    if (nivel <= 5) return 'Em Evolução';
    if (nivel <= 9) return 'Intermediário';
    if (nivel <= 14) return 'Avançado';
    return 'Mestre';
  }

  factory StudentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Conquistas podem estar embutidas no documento ou em subcoleção.
    // Aqui tratamos o caso em que são IDs (strings) armazenados no array.
    final List<dynamic> conquistasRaw = data['conquistas'] ?? [];
    final conquistas = conquistasRaw
        .whereType<Map<String, dynamic>>()
        .map((c) => ConquistaModel.fromMap(c))
        .toList();

    return StudentModel(
      uid: doc.id,
      nome: data['nome'] ?? '',
      email: data['email'] ?? '',
      dataCriacao: (data['dataCriacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
      nivel: data['nivel'] ?? 1,
      xp: data['xp'] ?? 0,
      conquistas: conquistas,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'nivel': nivel,
      'xp': xp,
      'conquistas': conquistas.map((c) => c.toMap()).toList(),
    };
  }

  /// Retorna uma cópia com campos atualizados (imutabilidade).
  StudentModel copyWith({
    int? nivel,
    int? xp,
    List<ConquistaModel>? conquistas,
  }) {
    return StudentModel(
      uid: uid,
      nome: nome,
      email: email,
      dataCriacao: dataCriacao,
      nivel: nivel ?? this.nivel,
      xp: xp ?? this.xp,
      conquistas: conquistas ?? this.conquistas,
    );
  }
}