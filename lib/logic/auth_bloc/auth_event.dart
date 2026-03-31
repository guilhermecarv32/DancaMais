abstract class AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested(this.email, this.password);
}

class LogoutRequested extends AuthEvent {}

class RegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String nome;
  final String tipo;       // 'aluno' ou 'professor'
  final DateTime dataNascimento;
  final String? modalidade;
  final List<String> modalidades; // Modalidade selecionada pelo professor no cadastro

  RegisterRequested(
    this.email,
    this.password,
    this.nome,
    this.tipo, {
    required this.dataNascimento,
    this.modalidades = const [],
    this.modalidade,
  });
}