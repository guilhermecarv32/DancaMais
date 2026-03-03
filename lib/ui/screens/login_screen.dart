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
  bool _isPasswordObscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = AppTheme.primary;
    const Color darkColor = Color(0xFF6C2E21);

    return Scaffold(
      body: Stack(
        children: [
          // 1. FUNDO COM GRADIENTE SUTIL
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

          // 2. FORMAS DECORATIVAS
          Positioned(
            top: -100,
            left: -50,
            child: Opacity(
              opacity: 0.08,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
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
                decoration: const BoxDecoration(color: darkColor, shape: BoxShape.circle),
              ),
            ),
          ),

          // 3. CONTEÚDO PRINCIPAL
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Olá!",
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: darkColor,
                        letterSpacing: -1.5,
                      ),
                    ),
                    const Text(
                      "Pronto para o próximo passo?",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    const SizedBox(height: 60),

                    _buildModernInput(
                      controller: _emailController,
                      hint: "Seu e-mail",
                      icon: Icons.alternate_email_rounded,
                    ),
                    const SizedBox(height: 20),

                    _buildModernInput(
                      controller: _passwordController,
                      hint: "Sua senha",
                      icon: Icons.lock_outline_rounded,
                      isObscure: _isPasswordObscure,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() => _isPasswordObscure = !_isPasswordObscure),
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: _rememberMe,
                              onChanged: (v) => setState(() => _rememberMe = v!),
                              activeColor: primaryColor,
                            ),
                            const Text("Lembrar de mim", style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            "Esqueci minha senha",
                            style: TextStyle(color: primaryColor, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // Lógica do Botão Entrar com Diagnóstico
                    BlocConsumer<AuthBloc, AuthState>(
                      listener: (context, state) {
                        if (state is Authenticated) {
                          // DIAGNÓSTICO: Isso aparecerá no console do VS Code
                          print("✅ SUCESSO: AuthBloc emitiu estado Authenticated!");
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Bem-vindo!"))
                          );
                        } else if (state is AuthError) {
                          // DIAGNÓSTICO: Mostra o erro exato do Firebase
                          print("❌ ERRO NO LOGIN: ${state.message}");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(state.message), backgroundColor: Colors.red)
                          );
                        }
                      },
                      builder: (context, state) {
                        return ElevatedButton(
                          onPressed: state is AuthLoading 
                            ? null 
                            : () => context.read<AuthBloc>().add(
                                LoginRequested(_emailController.text.trim(), _passwordController.text.trim())
                              ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
                          ),
                          child: state is AuthLoading
                            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("Entrar", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                    const SizedBox(height: 30),

                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => const SelectionScreen(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(opacity: animation, child: child);
                              },
                            ),
                          );
                        },
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                            children: [
                              TextSpan(text: "Não tem conta? "),
                              TextSpan(
                                text: "Cadastre-se!",
                                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
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

  Widget _buildModernInput({required TextEditingController controller, required String hint, required IconData icon, bool isObscure = false, Widget? suffixIcon,}) {
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