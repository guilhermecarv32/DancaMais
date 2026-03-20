import 'package:firebase_auth/firebase_auth.dart';
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

  void _mostrarRecuperacaoSenha(BuildContext context) {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    bool enviando = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final bottom = MediaQuery.of(ctx).viewInsets.bottom;
          return Container(
            padding: EdgeInsets.fromLTRB(25, 25, 25, 25 + bottom),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const Text('Recuperar senha',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondary)),
                const SizedBox(height: 6),
                const Text(
                    'Informe seu e-mail e enviaremos um link para redefinir sua senha.',
                    style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14)),
                  child: TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Seu e-mail',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      prefixIcon: Icon(Icons.email_outlined,
                          color: Colors.grey[400], size: 20),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: enviando
                        ? null
                        : () async {
                            final email = emailCtrl.text.trim();
                            if (email.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Informe seu e-mail.')),
                              );
                              return;
                            }
                            setModalState(() => enviando = true);
                            try {
                              await FirebaseAuth.instance
                                  .sendPasswordResetEmail(email: email);
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20)),
                                    title: const Row(children: [
                                      Text('✅ E-mail enviado'),
                                    ]),
                                    content: Text(
                                        'Enviamos um link de redefinição para $email.\n\n'
                                        'Não encontrou? Verifique a pasta de spam ou lixo eletrônico.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('OK',
                                            style: TextStyle(
                                                color: AppTheme.primary,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            } on FirebaseAuthException catch (e) {
                              setModalState(() => enviando = false);
                              final msg = e.code == 'user-not-found'
                                  ? 'Nenhuma conta encontrada com esse e-mail. Verifique se digitou corretamente.'
                                  : 'Erro ao enviar e-mail. Tente novamente.';
                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20)),
                                    title: const Row(children: [
                                      Text('❌ Erro'),
                                    ]),
                                    content: Text(msg),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('OK',
                                            style: TextStyle(
                                                color: AppTheme.primary,
                                                fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: enviando
                        ? const SizedBox(
                            height: 22, width: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Enviar link',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
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
            top: -100, left: -50,
            child: Opacity(
              opacity: 0.08,
              child: Container(
                width: 300, height: 300,
                decoration: const BoxDecoration(
                    color: primaryColor, shape: BoxShape.circle),
              ),
            ),
          ),
          Positioned(
            bottom: 50, right: -80,
            child: Opacity(
              opacity: 0.05,
              child: Container(
                width: 250, height: 250,
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
                height: MediaQuery.of(context).size.height - 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Olá!',
                        style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: darkColor,
                            letterSpacing: -1.5)),
                    const Text('Pronto para o próximo passo?',
                        style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 60),

                    _buildModernInput(
                      controller: _emailController,
                      hint: 'Seu e-mail',
                      icon: Icons.alternate_email_rounded,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),

                    _buildModernInput(
                      controller: _passwordController,
                      hint: 'Sua senha',
                      icon: Icons.lock_outline_rounded,
                      isObscure: _isPasswordObscure,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordObscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(
                            () => _isPasswordObscure = !_isPasswordObscure),
                      ),
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (v) =>
                                setState(() => _rememberMe = v!),
                            activeColor: primaryColor,
                          ),
                          const Text('Lembrar de mim',
                              style: TextStyle(color: Colors.grey)),
                        ]),
                        TextButton(
                          onPressed: () => _mostrarRecuperacaoSenha(context),
                          child: const Text('Esqueci minha senha',
                              style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    BlocConsumer<AuthBloc, AuthState>(
                      listener: (context, state) {
                        if (state is Authenticated) {
                          // AuthWrapper redireciona para o dashboard correto
                        } else if (state is AuthPendingApproval) {
                          // AuthWrapper mostrará a tela de aguardo
                          // Não precisamos navegar — o StreamBuilder do AuthWrapper
                          // já está escutando o estado do Firebase Auth
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Seu cadastro ainda está aguardando aprovação.'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        } else if (state is AuthError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(state.message),
                                backgroundColor: Colors.red),
                          );
                        }
                      },
                      builder: (context, state) {
                        return ElevatedButton(
                          onPressed: state is AuthLoading
                              ? null
                              : () => context.read<AuthBloc>().add(
                                    LoginRequested(
                                      _emailController.text.trim(),
                                      _passwordController.text.trim(),
                                    ),
                                  ),
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
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Entrar',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                    const SizedBox(height: 30),

                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation,
                                    secondaryAnimation) =>
                                const SelectionScreen(),
                            transitionsBuilder: (context, animation,
                                    secondaryAnimation, child) =>
                                FadeTransition(
                                    opacity: animation, child: child),
                          ),
                        ),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                                color: Colors.grey, fontSize: 16),
                            children: [
                              TextSpan(text: 'Não tem conta? '),
                              TextSpan(
                                text: 'Cadastre-se!',
                                style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold),
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
              offset: const Offset(0, 4)),
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