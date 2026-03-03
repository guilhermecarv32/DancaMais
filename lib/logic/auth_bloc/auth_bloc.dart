import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../data/services/auth_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthBloc(this.authService) : super(AuthInitial()) {
    // ... lógica do LoginRequested ...

    on<RegisterRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        // 1. Cria o utilizador no Firebase Authentication
        final user = await authService.registerWithEmail(event.email, event.password);
        
        if (user != null) {
          // 2. Guarda os dados adicionais no Firestore
          await _firestore.collection('usuarios').doc(user.uid).set({
            'nome': event.nome,
            'email': event.email,
            'tipo': event.tipo, // 'aluno' ou 'professor'
            'dataCriacao': FieldValue.serverTimestamp(),
            // Atributos de gamificação iniciais para alunos
            'nivel': event.tipo == 'aluno' ? 1 : null,
            'xp': event.tipo == 'aluno' ? 0 : null,
            'conquistas': event.tipo == 'aluno' ? [] : null,
          });
          
          emit(Authenticated(user.uid));
        } else {
          emit(AuthError("Não foi possível criar a conta."));
        }
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });
  }
}