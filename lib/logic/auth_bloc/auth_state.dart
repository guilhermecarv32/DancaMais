abstract class AuthState {}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}

class Authenticated extends AuthState {
  final String uid;
  Authenticated(this.uid);
}

class Unauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

/// Professor logado mas aguardando aprovação do admin.
/// Mantém o uid para o AuthWrapper identificar o usuário.
class AuthPendingApproval extends AuthState {
  final String uid;
  AuthPendingApproval(this.uid);
}