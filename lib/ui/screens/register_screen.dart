import 'package:cloud_firestore/cloud_firestore.dart';
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
  final _dataNascController = TextEditingController();
  final _passController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _isPassObscure = true;
  bool _isConfirmPassObscure = true;
  List<String> _modalidadesSelecionadas = [];
  DateTime? _dataNascimento;

  // Modalidades carregadas uma vez no initState — não dependem de rebuild
  List<String> _modalidades = [];
  bool _carregandoModalidades = true;

  bool get _isProfessor => widget.tipo == 'professor';

  @override
  void initState() {
    super.initState();
    if (_isProfessor) _carregarModalidades();
  }

  void _carregarModalidades() {
    FirebaseFirestore.instance
        .collection('escola')
        .doc('config')
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      final data = snap.data();
      setState(() {
        _modalidades = List<String>.from(data?['modalidades'] ?? []);
        _carregandoModalidades = false;
      });
    });
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _dataNascController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  String _formatarData(DateTime d) {
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    return '$dia/$mes/${d.year}';
  }

  Future<void> _selecionarDataNascimento() async {
    final hoje = DateTime.now();
    final inicial = _dataNascimento ?? DateTime(2005, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: inicial.isAfter(hoje) ? hoje : inicial,
      firstDate: DateTime(1900, 1, 1),
      lastDate: hoje,
      helpText: 'Selecione sua data de nascimento',
    );
    if (picked == null) return;
    setState(() {
      _dataNascimento = picked;
      _dataNascController.text = _formatarData(picked);
    });
  }

  void _tentarCadastro(BuildContext context) {
    final nome = _nomeController.text.trim();
    final email = _emailController.text.trim();
    final senha = _passController.text.trim();
    final confirmSenha = _confirmPassController.text.trim();

    if (nome.isEmpty || email.isEmpty || senha.isEmpty) {
      _mostrarErro(context, 'Preencha todos os campos.');
      return;
    }

    if (senha.length < 6) {
      _mostrarErro(context, 'A senha deve ter pelo menos 6 caracteres.');
      return;
    }

    if (senha != confirmSenha) {
      _mostrarErro(context, 'As senhas não coincidem.');
      return;
    }

    if (_isProfessor && _modalidadesSelecionadas.isEmpty) {
      _mostrarErro(context, 'Selecione pelo menos uma modalidade.');
      return;
    }

    if (_dataNascimento == null) {
      _mostrarErro(context, 'Selecione sua data de nascimento.');
      return;
    }

    context.read<AuthBloc>().add(
          RegisterRequested(
            email,
            senha,
            nome,
            widget.tipo,
            dataNascimento: _dataNascimento!,
            modalidade: _modalidadesSelecionadas.join(', '),
            modalidades: _modalidadesSelecionadas,
          ),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),
                  const Text('No ritmo!',
                      style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: darkColor,
                          letterSpacing: -1.5)),
                  const Text('O primeiro passo começa aqui!',
                      style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 40),

                  _buildModernInput(
                    controller: _nomeController,
                    hint: 'Nome Completo',
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 15),
                  _buildModernInput(
                    controller: _emailController,
                    hint: 'Email',
                    icon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: _selecionarDataNascimento,
                    child: AbsorbPointer(
                      child: _buildModernInput(
                        controller: _dataNascController,
                        hint: 'Data de Nascimento',
                        icon: Icons.cake_outlined,
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildModernInput(
                    controller: _passController,
                    hint: 'Senha',
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
                    hint: 'Confirmar Senha',
                    icon: Icons.lock_reset_rounded,
                    isObscure: _isConfirmPassObscure,
                    suffixIcon: IconButton(
                      icon: Icon(_isConfirmPassObscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                      onPressed: () => setState(() =>
                          _isConfirmPassObscure = !_isConfirmPassObscure),
                    ),
                  ),

                  // Seletor de modalidade — só para professor
                  if (_isProfessor) ...[
                    const SizedBox(height: 15),
                    _buildModalidadeSelector(primaryColor),
                  ],

                  const SizedBox(height: 40),

                  BlocConsumer<AuthBloc, AuthState>(
                    listener: (context, state) {
                      if (state is Authenticated) {
                        // Aluno — navega para o dashboard
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            '/', (route) => false);
                      } else if (state is AuthPendingApproval) {
                        // Professor pendente — AuthWrapper mostra tela de espera
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            '/', (route) => false);
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
                                    color: Colors.white, strokeWidth: 2))
                            : const Text('Cadastrar',
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
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                          children: [
                            TextSpan(text: 'Já tem uma conta? '),
                            TextSpan(
                              text: 'Faça Login!',
                              style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Seletor de modalidade ─────────────────────────────────────

  Widget _buildModalidadeSelector(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(children: [
            const Icon(Icons.music_note_rounded,
                size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            const Text('Quais modalidades você leciona?',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ]),
        ),

        if (_carregandoModalidades)
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppTheme.primary),
              ),
            ),
          )
        else if (_modalidades.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.info_outline_rounded,
                  color: Colors.orange, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nenhuma modalidade cadastrada ainda. '
                  'O administrador precisará adicioná-las.',
                  style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ]),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _modalidades.map((m) {
              final sel = _modalidadesSelecionadas.contains(m);
              return GestureDetector(
                onTap: () => setState(() => sel ? _modalidadesSelecionadas.remove(m) : _modalidadesSelecionadas.add(m)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: sel
                        ? primaryColor.withOpacity(0.1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: sel
                          ? primaryColor
                          : Colors.grey.withOpacity(0.3),
                      width: sel ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (sel) ...[
                        Icon(Icons.check_rounded,
                            size: 14, color: primaryColor),
                        const SizedBox(width: 5),
                      ],
                      Text(m,
                          style: TextStyle(
                              color: sel ? primaryColor : Colors.grey[600],
                              fontWeight: sel
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 14)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
      ],
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