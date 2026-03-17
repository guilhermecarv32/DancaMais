import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

/// Modelo do Professor — especialização de UserModel.
/// Corresponde à classe "Professor" do diagrama de classes do TCC.
class TeacherModel extends UserModel {
  final String modalidade; // Ex: 'Forró', 'Bachata', 'Samba'

  const TeacherModel({
    required super.uid,
    required super.nome,
    required super.email,
    required super.dataCriacao,
    required this.modalidade,
  }) : super(tipo: 'professor');

  factory TeacherModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TeacherModel(
      uid: doc.id,
      nome: data['nome'] ?? '',
      email: data['email'] ?? '',
      dataCriacao: (data['dataCriacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
      modalidade: data['modalidade'] ?? '',
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'modalidade': modalidade,
    };
  }
}