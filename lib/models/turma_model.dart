import 'package:cloud_firestore/cloud_firestore.dart';

/// Representa o horário de um dia específico da semana.
class HorarioDia {
  final String dia;       // Ex: 'Segunda'
  final String horario;   // Ex: '18:00 - 19:00'

  const HorarioDia({required this.dia, required this.horario});

  factory HorarioDia.fromMap(Map<String, dynamic> map) {
    return HorarioDia(
      dia: map['dia'] ?? '',
      horario: map['horario'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {'dia': dia, 'horario': horario};
}

/// Modelo de Turma.
/// Corresponde à classe "Turma" do diagrama de classes do TCC.
class TurmaModel {
  final String id;
  final String nome;
  final String modalidade;
  final String nivel;
  final String professorId;
  final DateTime dataCriacao;

  /// Passo/coreografia em destaque na semana
  final String? passoSemanaId;
  final String? passoSemanaNome; // Denormalizado para exibição rápida

  /// Horários individuais por dia da semana
  final List<HorarioDia> horariosDia;

  final int totalAlunos;

  /// Papéis possíveis para um aluno nesta turma (ex: ['Condutor', 'Conduzido'])

  /// Papéis possíveis para um aluno nesta turma (ex: ['Condutor', 'Conduzido'])
  final List<String> papeisAlunos;

  const TurmaModel({
    required this.id,
    required this.nome,
    required this.modalidade,
    required this.nivel,
    required this.professorId,
    required this.dataCriacao,
    this.passoSemanaId,
    this.passoSemanaNome,
    this.horariosDia = const [],
    this.totalAlunos = 0,
    this.papeisAlunos = const [],
  });

  /// Label formatada para exibição na agenda.
  String get labelAgenda => '$modalidade · $nivel';

  /// Dias da semana extraídos dos horários.
  List<String> get diasSemana => horariosDia.map((h) => h.dia).toList();

  /// Horário do dia atual, se existir.
  String? get horarioHoje {
    const dias = [
      'Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'
    ];
    final hoje = dias[DateTime.now().weekday - 1];
    final match = horariosDia.where((h) => h.dia == hoje);
    return match.isNotEmpty ? match.first.horario : null;
  }

  factory TurmaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Suporte a ambos os formatos: novo (horariosDia) e legado (diasSemana+horario)
    List<HorarioDia> horarios = [];
    if (data['horariosDia'] != null) {
      horarios = (data['horariosDia'] as List)
          .map((h) => HorarioDia.fromMap(Map<String, dynamic>.from(h)))
          .toList();
    } else if (data['diasSemana'] != null && data['horario'] != null) {
      // Migração automática do formato antigo
      for (final dia in List<String>.from(data['diasSemana'])) {
        horarios.add(HorarioDia(dia: dia, horario: data['horario']));
      }
    }

    return TurmaModel(
      id: doc.id,
      nome: data['nome'] ?? '',
      modalidade: data['modalidade'] ?? '',
      nivel: data['nivel'] ?? '',
      professorId: data['professorId'] ?? '',
      dataCriacao: (data['dataCriacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
      passoSemanaId: data['passoSemanaId'],
      passoSemanaNome: data['passoSemanaNome'],
      horariosDia: horarios,
      totalAlunos: data['totalAlunos'] ?? 0,
      papeisAlunos: List<String>.from(data['papeisAlunos'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'modalidade': modalidade,
      'nivel': nivel,
      'professorId': professorId,
      'dataCriacao': FieldValue.serverTimestamp(),
      if (passoSemanaId != null) 'passoSemanaId': passoSemanaId,
      if (passoSemanaNome != null) 'passoSemanaNome': passoSemanaNome,
      'horariosDia': horariosDia.map((h) => h.toMap()).toList(),
      'totalAlunos': totalAlunos,
      'papeisAlunos': papeisAlunos,
    };
  }

  TurmaModel copyWith({
    String? passoSemanaId,
    String? passoSemanaNome,
    List<String>? papeisAlunos,
  }) {
    return TurmaModel(
      id: id,
      nome: nome,
      modalidade: modalidade,
      nivel: nivel,
      professorId: professorId,
      dataCriacao: dataCriacao,
      passoSemanaId: passoSemanaId ?? this.passoSemanaId,
      passoSemanaNome: passoSemanaNome ?? this.passoSemanaNome,
      horariosDia: horariosDia,
      totalAlunos: totalAlunos,
      papeisAlunos: papeisAlunos ?? this.papeisAlunos,
    );
  }
}