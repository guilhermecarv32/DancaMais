import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../data/services/auth_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthBloc(this.authService) : super(AuthInitial()) {
    
    // --- 1. MANIPULADOR DE LOGIN ---
    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        // Tenta realizar o login via AuthService
        final user = await authService.signInWithEmail(event.email, event.password);
        
        if (user != null) {
          // Se o login for bem-sucedido, emite o estado Authenticated com o UID
          emit(Authenticated(user.uid));
        } else {
          emit(AuthError("E-mail ou senha incorretos."));
        }
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    // --- 2. MANIPULADOR DE CADASTRO ---
    on<RegisterRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        // 1. Cria o utilizador no Firebase Authentication
        final user = await authService.registerWithEmail(event.email, event.password);
        
        if (user != null) {
          // 2. Guarda os dados no Firestore conforme sua estrutura
          await _firestore.collection('usuarios').doc(user.uid).set({
            'nome': event.nome,
            'email': event.email,
            'tipo': event.tipo, // 'aluno' ou 'professor'
            'dataCriacao': FieldValue.serverTimestamp(), // Carimbado em 3 de março de 2026
            
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

    // --- 3. MANIPULADOR DE LOGOUT ---
    on<LogoutRequested>((event, emit) async {
      try {
        await authService.signOut();
        emit(AuthInitial()); // Volta para o estado inicial para o AuthWrapper agir
      } catch (e) {
        emit(AuthError("Erro ao sair: ${e.toString()}"));
      }
    });
  }
}