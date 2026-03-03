import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../data/services/auth_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;

  AuthBloc(this.authService) : super(AuthInitial()) {
    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await authService.loginWithEmail(event.email, event.password);
        if (user != null) {
          emit(Authenticated(user.uid));
        } else {
          emit(AuthError("Falha no login. Verifique suas credenciais."));
        }
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    on<LogoutRequested>((event, emit) async {
      await authService.signOut();
      emit(Unauthenticated());
    });

    on<RegisterRequested>((event, emit) async {
  emit(AuthLoading());
  try {
    final user = await authService.registerWithEmail(event.email, event.password);
    if (user != null) {
      // Aqui salvamos o perfil completo no Firestore após criar a conta
      await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).set({
        'nome': event.nome,
        'email': event.email,
        'tipo': event.tipo,
        'nivel': event.tipo == 'aluno' ? 1 : null, // Aluno começa no nível 1 [cite: 467]
        'experiencia': event.tipo == 'aluno' ? 0.0 : null,
      });
      emit(Authenticated(user.uid));
    }
  } catch (e) {
    emit(AuthError("Erro ao cadastrar: ${e.toString()}"));
  }
});
  }
}