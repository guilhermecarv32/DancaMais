import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo base para todos os perfis do sistema.
/// Corresponde à classe "Usuário" do diagrama de classes do TCC.
class UserModel {
  final String uid;
  final String nome;
  final String email;
  final String tipo; // 'aluno' ou 'professor'
  final DateTime dataCriacao;

  const UserModel({
    required this.uid,
    required this.nome,
    required this.email,
    required this.tipo,
    required this.dataCriacao,
  });

  /// Cria um UserModel a partir de um documento do Firestore.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      nome: data['nome'] ?? '',
      email: data['email'] ?? '',
      tipo: data['tipo'] ?? 'aluno',
      dataCriacao: (data['dataCriacao'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Converte o model para Map para salvar no Firestore.
  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'email': email,
      'tipo': tipo,
      'dataCriacao': FieldValue.serverTimestamp(),
    };
  }

  /// Retorna o primeiro nome do usuário.
  String get primeiroNome => nome.trim().split(' ').first;
}