import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/auth_bloc/auth_bloc.dart';
import '../../logic/auth_bloc/auth_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  final _nomeCtrl = TextEditingController();
  final _modalidadeCtrl = TextEditingController();
  final _senhaAtualCtrl = TextEditingController();
  final _novaSenhaCtrl = TextEditingController();
  final _confirmaSenhaCtrl = TextEditingController();

  bool _editandoDados = false;
  bool _editandoSenha = false;
  bool _salvandoDados = false;
  bool _salvandoSenha = false;
  bool _obscureSenhaAtual = true;
  bool _obscureNovaSenha = true;
  bool _obscureConfirma = true;

  // Guarda os valores originais para restaurar se o usuário cancelar
  String _nomeOriginal = '';
  String _modalidadeOriginal = '';

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _modalidadeCtrl.dispose();
    _senhaAtualCtrl.dispose();
    _novaSenhaCtrl.dispose();
    _confirmaSenhaCtrl.dispose();
    super.dispose();
  }

  void _iniciarEdicaoDados() {
    _nomeOriginal = _nomeCtrl.text;
    _modalidadeOriginal = _modalidadeCtrl.text;
    setState(() => _editandoDados = true);
  }

  void _cancelarEdicaoDados() {
    _nomeCtrl.text = _nomeOriginal;
    _modalidadeCtrl.text = _modalidadeOriginal;
    setState(() => _editandoDados = false);
  }

  Future<void> _salvarDados() async {
    final nome = _nomeCtrl.text.trim();
    final modalidade = _modalidadeCtrl.text.trim();

    if (nome.isEmpty) {
      _mostrarErro('O nome não pode estar vazio.');
      return;
    }

    setState(() => _salvandoDados = true);

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .update({'nome': nome, 'modalidade': modalidade});

    setState(() {
      _salvandoDados = false;
      _editandoDados = false;
    });

    _mostrarSucesso('Dados atualizados com sucesso!');
  }

  Future<void> _salvarSenha() async {
    final senhaAtual = _senhaAtualCtrl.text.trim();
    final novaSenha = _novaSenhaCtrl.text.trim();
    final confirmaSenha = _confirmaSenhaCtrl.text.trim();

    if (senhaAtual.isEmpty || novaSenha.isEmpty || confirmaSenha.isEmpty) {
      _mostrarErro('Preencha todos os campos de senha.');
      return;
    }

    if (novaSenha.length < 6) {
      _mostrarErro('A nova senha deve ter pelo menos 6 caracteres.');
      return;
    }

    if (novaSenha != confirmaSenha) {
      _mostrarErro('As senhas não coincidem.');
      return;
    }

    setState(() => _salvandoSenha = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      // Reautentica com a senha atual antes de trocar
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: senhaAtual,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(novaSenha);

      _senhaAtualCtrl.clear();
      _novaSenhaCtrl.clear();
      _confirmaSenhaCtrl.clear();

      setState(() {
        _salvandoSenha = false;
        _editandoSenha = false;
      });

      _mostrarSucesso('Senha alterada com sucesso!');
    } on FirebaseAuthException catch (e) {
      setState(() => _salvandoSenha = false);
      if (e.code == 'wrong-password') {
        _mostrarErro('Senha atual incorreta.');
      } else {
        _mostrarErro('Erro ao alterar senha: ${e.message}');
      }
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _mostrarSucesso(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    const Color dark = AppTheme.secondary;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(uid)
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final data = snap.data?.data() as Map<String, dynamic>?;
            final nome = data?['nome'] ?? '';
            final email =
                FirebaseAuth.instance.currentUser?.email ?? '';
            final modalidade = data?['modalidade'] ?? '';

            // Preenche os campos apenas na primeira carga
            if (_nomeCtrl.text.isEmpty) _nomeCtrl.text = nome;
            if (_modalidadeCtrl.text.isEmpty)
              _modalidadeCtrl.text = modalidade;

            return ListView(
              padding: const EdgeInsets.fromLTRB(25, 25, 25, 40),
              children: [
                // ── Avatar + nome ──────────────────────────────
                _buildAvatar(nome, dark),
                const SizedBox(height: 30),

                // ── Seção: Dados Pessoais ──────────────────────
                _buildSectionHeader(
                  'Dados Pessoais',
                  dark,
                  trailing: _editandoDados
                      ? _buildAcoesBotoes(
                          onSalvar: _salvandoDados ? null : _salvarDados,
                          onCancelar: _cancelarEdicaoDados,
                          salvando: _salvandoDados,
                        )
                      : _buildBotaoEditar(onTap: _iniciarEdicaoDados),
                ),
                const SizedBox(height: 14),

                _buildCard(children: [
                  _buildCampoInline(
                    label: 'Nome',
                    controller: _nomeCtrl,
                    icon: Icons.person_outline_rounded,
                    editando: _editandoDados,
                  ),
                  _buildDivider(),
                  // E-mail nunca é editável (vinculado ao Firebase Auth)
                  _buildCampoSoLeitura(
                    label: 'E-mail',
                    valor: email,
                    icon: Icons.alternate_email_rounded,
                  ),
                  _buildDivider(),
                  _buildCampoInline(
                    label: 'Modalidade',
                    controller: _modalidadeCtrl,
                    icon: Icons.music_note_rounded,
                    editando: _editandoDados,
                    hint: 'Ex: Forró, Bachata...',
                  ),
                ]),

                const SizedBox(height: 28),

                // ── Seção: Alterar Senha ───────────────────────
                _buildSectionHeader(
                  'Segurança',
                  dark,
                  trailing: _editandoSenha
                      ? _buildAcoesBotoes(
                          onSalvar: _salvandoSenha ? null : _salvarSenha,
                          onCancelar: () {
                            _senhaAtualCtrl.clear();
                            _novaSenhaCtrl.clear();
                            _confirmaSenhaCtrl.clear();
                            setState(() => _editandoSenha = false);
                          },
                          salvando: _salvandoSenha,
                        )
                      : _buildBotaoEditar(
                          label: 'Alterar',
                          onTap: () =>
                              setState(() => _editandoSenha = true)),
                ),
                const SizedBox(height: 14),

                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 250),
                  crossFadeState: _editandoSenha
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: _buildCard(children: [
                    _buildCampoSoLeitura(
                      label: 'Senha',
                      valor: '••••••••',
                      icon: Icons.lock_outline_rounded,
                    ),
                  ]),
                  secondChild: _buildCard(children: [
                    _buildCampoSenha(
                      label: 'Senha atual',
                      controller: _senhaAtualCtrl,
                      obscure: _obscureSenhaAtual,
                      onToggle: () => setState(
                          () => _obscureSenhaAtual = !_obscureSenhaAtual),
                    ),
                    _buildDivider(),
                    _buildCampoSenha(
                      label: 'Nova senha',
                      controller: _novaSenhaCtrl,
                      obscure: _obscureNovaSenha,
                      onToggle: () => setState(
                          () => _obscureNovaSenha = !_obscureNovaSenha),
                    ),
                    _buildDivider(),
                    _buildCampoSenha(
                      label: 'Confirmar nova senha',
                      controller: _confirmaSenhaCtrl,
                      obscure: _obscureConfirma,
                      onToggle: () => setState(
                          () => _obscureConfirma = !_obscureConfirma),
                    ),
                  ]),
                ),

                const SizedBox(height: 40),

                // ── Botão de Logout ────────────────────────────
                _buildBotaoLogout(context),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── COMPONENTES ───────────────────────────────────────────────

  Widget _buildAvatar(String nome, Color dark) {
    final inicial =
        nome.isNotEmpty ? nome.trim()[0].toUpperCase() : '?';
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              inicial,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppTheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          nome,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: dark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Professor',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String titulo, Color dark,
      {required Widget trailing}) {
    return Row(
      children: [
        Text(titulo,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: dark.withOpacity(0.7))),
        const Spacer(),
        trailing,
      ],
    );
  }

  Widget _buildBotaoEditar(
      {String label = 'Editar', required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.edit_rounded,
                size: 14, color: AppTheme.primary),
            const SizedBox(width: 5),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildAcoesBotoes({
    required VoidCallback? onSalvar,
    required VoidCallback onCancelar,
    required bool salvando,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onCancelar,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Cancelar',
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: onSalvar,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: salvando
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Salvar',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04), blurRadius: 10)
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildCampoInline({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required bool editando,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[400]),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: editando
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Text(
                controller.text.isEmpty ? '—' : controller.text,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.secondary),
                textAlign: TextAlign.end,
              ),
              secondChild: TextField(
                controller: controller,
                textAlign: TextAlign.end,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.secondary),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                      color: Colors.grey[300], fontSize: 13),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoSoLeitura({
    required String label,
    required String valor,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[400]),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(
              valor,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.grey[400]),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoSenha({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(Icons.lock_outline_rounded,
              size: 18, color: Colors.grey[400]),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscure,
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.secondary),
              decoration: InputDecoration(
                hintText: label,
                hintStyle:
                    TextStyle(color: Colors.grey[400], fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: GestureDetector(
                  onTap: onToggle,
                  child: Icon(
                    obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
        height: 1, indent: 46, endIndent: 16, color: Colors.grey[100]);
  }

  Widget _buildBotaoLogout(BuildContext context) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Text('Sair da conta?'),
          content: const Text(
              'Você será redirecionado para a tela de login.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<AuthBloc>().add(LogoutRequested());
              },
              child: const Text('Sair',
                  style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Colors.red.withOpacity(0.15), width: 1.5),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
            SizedBox(width: 8),
            Text('Sair da conta',
                style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ],
        ),
      ),
    );
  }
}