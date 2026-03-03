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
  }
}