import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Serviço central de permissões.
/// Professor só opera nas modalidades que leciona.
/// Admin tem acesso irrestrito.
class PermissaoService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Retorna os dados do professor logado: isAdmin e modalidades.
  static Future<PerfilProfessor> carregarPerfil() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final doc = await _db.collection('usuarios').doc(uid).get();
    final data = doc.data() as Map<String, dynamic>? ?? {};

    final isAdmin = data['isAdmin'] == true;
    final raw = data['modalidades'];
    final modalidades = raw is List
        ? List<String>.from(raw)
        : raw is String && raw.isNotEmpty
            ? raw.split(', ')
            : <String>[];

    return PerfilProfessor(isAdmin: isAdmin, modalidades: modalidades);
  }

  static Stream<PerfilProfessor> perfilStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return _db.collection('usuarios').doc(uid).snapshots().map((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final isAdmin = data['isAdmin'] == true;
      final raw = data['modalidades'];
      final modalidades = raw is List
          ? List<String>.from(raw)
          : raw is String && raw.isNotEmpty
              ? raw.split(', ')
              : <String>[];
      return PerfilProfessor(isAdmin: isAdmin, modalidades: modalidades);
    });
  }
}

class PerfilProfessor {
  final bool isAdmin;
  final List<String> modalidades;
  const PerfilProfessor({required this.isAdmin, required this.modalidades});

  List<String>? get filtroModalidades => isAdmin ? null : modalidades;

  bool podeEditarModalidade(String modalidade) =>
      isAdmin || modalidades.contains(modalidade);
}