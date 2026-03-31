import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../data/services/auth_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthBloc(this.authService) : super(AuthInitial()) {

    // --- LOGIN ---
    on<LoginRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await authService.signInWithEmail(
            event.email, event.password);

        if (user != null) {
          final doc = await _firestore
              .collection('usuarios')
              .doc(user.uid)
              .get();
          final data = doc.data();
          final tipo = data?['tipo'] ?? 'aluno';
          final status = data?['status'] ?? 'ativo';

          if (tipo == 'professor' && status == 'pendente') {
            // Mantém logado — AuthWrapper mostra tela de espera
            emit(AuthPendingApproval(user.uid));
            return;
          }

          if (tipo == 'professor' && status == 'rejeitado') {
            await authService.signOut();
            emit(AuthError(
                'Seu cadastro foi recusado. Entre em contato com o administrador.'));
            return;
          }

          emit(Authenticated(user.uid));
        } else {
          emit(AuthError('E-mail ou senha incorretos.'));
        }
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    // --- CADASTRO ---
    on<RegisterRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await authService.registerWithEmail(
            event.email, event.password);

        if (user != null) {
          final isProfessor = event.tipo == 'professor';

          await _firestore.collection('usuarios').doc(user.uid).set({
            'nome': event.nome,
            'email': event.email,
            'tipo': event.tipo,
            'dataCriacao': FieldValue.serverTimestamp(),
            'dataNascimento': Timestamp.fromDate(event.dataNascimento),
            'status': isProfessor ? 'pendente' : 'ativo',
            // Modalidade selecionada pelo professor no cadastro
            if (isProfessor && event.modalidade != null)
              'modalidade': event.modalidade,
            'modalidades': event.modalidades,
            // Gamificação para alunos
            'nivel': isProfessor ? null : 1,
            'xp': isProfessor ? null : 0,
            'conquistas': isProfessor ? null : [],
          });

          if (isProfessor) {
            // NÃO faz signOut — mantém logado para o AuthWrapper
            // detectar o status pendente e mostrar a tela de espera
            emit(AuthPendingApproval(user.uid));
          } else {
            emit(Authenticated(user.uid));
          }
        } else {
          emit(AuthError('Não foi possível criar a conta.'));
        }
      } catch (e) {
        emit(AuthError(e.toString()));
      }
    });

    // --- LOGOUT ---
    on<LogoutRequested>((event, emit) async {
      try {
        await authService.signOut();
        emit(AuthInitial());
      } catch (e) {
        emit(AuthError('Erro ao sair: ${e.toString()}'));
      }
    });
  }
}