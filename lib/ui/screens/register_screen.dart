import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/auth_bloc/auth_bloc.dart';
import '../../logic/auth_bloc/auth_event.dart';
import '../../logic/auth_bloc/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  final String tipo;
  const RegisterScreen({super.key, required this.tipo});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isPassObscure = true;
  bool _isConfirmPassObscure = true;

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _tentarCadastro(BuildContext context) {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _passController.text.trim();
    final confirmSenha = _confirmPassController.text.trim();

    if (nome.isEmpty || email.isEmpty || senha.isEmpty) {
      _mostrarErro(context, "Preencha todos os campos.");
      return;
    }

    if (senha.length < 6) {
      _mostrarErro(context, "A senha deve ter pelo menos 6 caracteres.");
      return;
    }

    if (senha != confirmSenha) {
      _mostrarErro(context, "As senhas não coincidem.");
      return;
    }

    context.read<AuthBloc>().add(
          RegisterRequested(email, senha, nome, widget.tipo),
        );
  }

  void _mostrarErro(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = AppTheme.primary;
    const Color darkColor = Color(0xFF6C2E21);

    return Scaffold(
      body: Stack(
        children: [
          // Fundo
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.orange.shade50.withOpacity(0.5),
                  Colors.white,
                ],
              ),
            ),
          ),
          Positioned(
            top: -100,
            left: -50,
            child: Opacity(
              opacity: 0.08,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                    color: primaryColor, shape: BoxShape.circle),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            right: -80,
            child: Opacity(
              opacity: 0.05,
              child: Container(
                width: 250,
                height: 250,
                decoration: const BoxDecoration(
                    color: darkColor, shape: BoxShape.circle),
              ),
            ),
          ),

          // Conteúdo
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: SizedBox(
                height: MediaQuery.of(context).size.height > 700
                    ? MediaQuery.of(context).size.height - 50
                    : null,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      "No ritmo!",
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: darkColor,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const Text(
                      "O primeiro passo começa aqui!",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 50),

                    _buildModernInput(
                      controller: _nomeController,
                      hint: "Nome Completo",
                      icon: Icons.person_outline_rounded,
                    ),
                    const SizedBox(height: 15),
                    _buildModernInput(
                      controller: _emailController,
                      hint: "Email",
                      icon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 15),
                    _buildModernInput(
                      controller: _passController,
                      hint: "Senha",
                      icon: Icons.lock_outline_rounded,
                      isObscure: _isPassObscure,
                      suffixIcon: IconButton(
                        icon: Icon(_isPassObscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _isPassObscure = !_isPassObscure),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildModernInput(
                      controller: _confirmPassController,
                      hint: "Confirmar Senha",
                      icon: Icons.lock_reset_rounded,
                      isObscure: _isConfirmPassObscure,
                      suffixIcon: IconButton(
                        icon: Icon(_isConfirmPassObscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () => setState(
                            () => _isConfirmPassObscure = !_isConfirmPassObscure),
                      ),
                    ),

                    const SizedBox(height: 50),

                    // BlocConsumer: listener navega, builder desenha o botão
                    BlocConsumer<AuthBloc, AuthState>(
                      listener: (context, state) {
                        if (state is Authenticated) {
                          // Navega limpando toda a pilha de navegação.
                          // O AuthWrapper cuida de mostrar o dashboard correto.
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/',
                            (route) => false,
                          );
                        } else if (state is AuthError) {
                          _mostrarErro(context, state.message);
                        }
                      },
                      builder: (context, state) {
                        return ElevatedButton(
                          onPressed: state is AuthLoading
                              ? null
                              : () => _tentarCadastro(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                          child: state is AuthLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Text("Cadastrar",
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                        );
                      },
                    ),

                    const SizedBox(height: 30),

                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context)
                            .popUntil((route) => route.isFirst),
                        child: RichText(
                          text: const TextSpan(
                            style:
                                TextStyle(color: Colors.grey, fontSize: 16),
                            children: [
                              TextSpan(text: "Já tem uma conta? "),
                              TextSpan(
                                text: "Faça Login!",
                                style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInput({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isObscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }
}