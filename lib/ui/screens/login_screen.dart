import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/auth_bloc/auth_bloc.dart';
import '../../logic/auth_bloc/auth_event.dart';
import '../../logic/auth_bloc/auth_state.dart';
import 'selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. FUNDO COM TEXTURA GENÉRICA
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.background,
                  AppTheme.primary.withOpacity(0.05), // Uso genérico da cor
                  AppTheme.background,
                ],
              ),
            ),
          ),

          // Formas decorativas usando cores secundárias e terciárias
          _buildDecorShape(top: -100, left: -50, color: AppTheme.primary, opacity: 0.08),
          _buildDecorShape(bottom: 50, right: -80, color: AppTheme.secondary, opacity: 0.05),

          // 2. CONTEÚDO
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 50,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Olá!",
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondary, // Nome genérico
                        letterSpacing: -1.5,
                      ),
                    ),
                    const Text(
                      "Pronto para o próximo passo?",
                      style: TextStyle(fontSize: 18, color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 60),

                    _buildInput(controller: _emailController, hint: "Email", icon: Icons.alternate_email),
                    const SizedBox(height: 20),
                    _buildInput(controller: _passwordController, hint: "Senha", icon: Icons.lock_outline, isObscure: true),

                    // Checkbox e Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (v) => setState(() => _rememberMe = v!),
                              activeColor: AppTheme.primary,
                            ),
                            const Text("Lembrar de mim", style: TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text("Esqueci minha senha", 
                            style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Botão com BLoC e cores genéricas
                    BlocConsumer<AuthBloc, AuthState>(
                      listener: (context, state) {
                        if (state is Authenticated) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bem-vindo!")));
                        } else if (state is AuthError) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
                        }
                      },
                      builder: (context, state) {
                        return ElevatedButton(
                          onPressed: state is AuthLoading 
                            ? null 
                            : () => context.read<AuthBloc>().add(LoginRequested(_emailController.text, _passwordController.text)),
                          child: state is AuthLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Entrar", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                    const SizedBox(height: 30),

                    // Link de Cadastro
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SelectionScreen())),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                            children: [
                              TextSpan(text: "Não tem conta? "),
                              TextSpan(
                                text: "Cadastre-se!",
                                style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helpers para manter o código limpo
  Widget _buildDecorShape({double? top, double? left, double? bottom, double? right, required Color color, required double opacity}) {
    return Positioned(
      top: top, left: left, bottom: bottom, right: right,
      child: Opacity(
        opacity: opacity,
        child: Container(width: 300, height: 300, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      ),
    );
  }

  Widget _buildInput({required TextEditingController controller, required String hint, required IconData icon, bool isObscure = false}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: AppTheme.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }
}