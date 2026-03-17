import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dancamais/core/app_theme_notifier.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/auth_bloc/auth_bloc.dart';
import '../../logic/auth_bloc/auth_event.dart';

class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  final _nomeCtrl = TextEditingController();
  final _senhaAtualCtrl = TextEditingController();
  final _novaSenhaCtrl = TextEditingController();
  final _confirmaSenhaCtrl = TextEditingController();

  List<String> _modalidadesSelecionadas = [];
  List<String> _modalidadesOriginais = [];
  String _nomeOriginal = '';

  bool _editandoDados = false;
  bool _editandoSenha = false;
  bool _salvandoDados = false;
  bool _salvandoSenha = false;
  bool _obscureSenhaAtual = true;
  bool _obscureNovaSenha = true;
  bool _obscureConfirma = true;
  bool _dadosCarregados = false;
  bool _modoEscuro = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _senhaAtualCtrl.dispose();
    _novaSenhaCtrl.dispose();
    _confirmaSenhaCtrl.dispose();
    super.dispose();
  }

  void _iniciarEdicaoDados() {
    _nomeOriginal = _nomeCtrl.text;
    _modalidadesOriginais = List.from(_modalidadesSelecionadas);
    setState(() => _editandoDados = true);
  }

  void _cancelarEdicaoDados() {
    _nomeCtrl.text = _nomeOriginal;
    setState(() {
      _modalidadesSelecionadas = List.from(_modalidadesOriginais);
      _editandoDados = false;
    });
  }

  void _toggleModalidade(String m) {
    setState(() {
      if (_modalidadesSelecionadas.contains(m)) {
        _modalidadesSelecionadas.remove(m);
      } else {
        _modalidadesSelecionadas.add(m);
      }
    });
  }

  Future<void> _salvarDados() async {
    final nome = _nomeCtrl.text.trim();
    if (nome.isEmpty) {
      _mostrarErro('O nome não pode estar vazio.');
      return;
    }

    setState(() => _salvandoDados = true);

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Dados pessoais salvam no perfil do professor (usuarios/{uid})
    // As modalidades aqui são as que ELE leciona, não as da escola
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .update({
      'nome': nome,
      'modalidades': _modalidadesSelecionadas,
      'modalidade': _modalidadesSelecionadas.isNotEmpty
          ? _modalidadesSelecionadas.join(', ')
          : '',
    });

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
      _mostrarErro(e.code == 'wrong-password'
          ? 'Senha atual incorreta.'
          : 'Erro: ${e.message}');
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _mostrarSucesso(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    const Color dark = AppTheme.secondary;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          // Carrega usuario + configuracoes em paralelo
          stream: FirebaseFirestore.instance
              .collection('usuarios')
              .where(FieldPath.documentId, isEqualTo: uid)
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final userData = snap.data?.docs.isNotEmpty == true
                ? snap.data!.docs.first.data() as Map<String, dynamic>
                : <String, dynamic>{};

            final nome = userData['nome'] ?? '';
            final email = FirebaseAuth.instance.currentUser?.email ?? '';
            final isAdmin = userData['isAdmin'] == true;

            // Carrega modalidades salvas (suporte ao formato antigo string)
            final raw = userData['modalidades'];
            final modalidadesSalvas = raw is List
                ? List<String>.from(raw)
                : raw is String && raw.isNotEmpty
                    ? raw.split(', ')
                    : <String>[];

            // Preenche apenas na primeira carga
            if (!_dadosCarregados) {
              _nomeCtrl.text = nome;
              _modalidadesSelecionadas = List.from(modalidadesSalvas);
              _modoEscuro = userData['modoEscuro'] == true;
              _dadosCarregados = true;
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(25, 25, 25, 40),
              children: [
                _buildAvatar(nome, dark),
                const SizedBox(height: 30),

                // ── Dados Pessoais ─────────────────────────────
                _buildSectionHeader('Dados Pessoais', dark,
                    trailing: _editandoDados
                        ? _buildAcoesBotoes(
                            onSalvar:
                                _salvandoDados ? null : _salvarDados,
                            onCancelar: _cancelarEdicaoDados,
                            salvando: _salvandoDados,
                          )
                        : _buildBotaoEditar(onTap: _iniciarEdicaoDados)),
                const SizedBox(height: 14),

                _buildCard(children: [
                  _buildCampoInline(
                    label: 'Nome',
                    controller: _nomeCtrl,
                    icon: Icons.person_outline_rounded,
                    editando: _editandoDados,
                  ),
                  _buildDivider(),
                  _buildCampoSoLeitura(
                    label: 'E-mail',
                    valor: email,
                    icon: Icons.alternate_email_rounded,
                  ),
                  _buildDivider(),
                  // Modalidades — multi-select quando editando
                  _buildCampoModalidades(uid),
                ]),

                const SizedBox(height: 28),

                // ── Segurança ──────────────────────────────────
                _buildSectionHeader('Segurança', dark,
                    trailing: _editandoSenha
                        ? _buildAcoesBotoes(
                            onSalvar:
                                _salvandoSenha ? null : _salvarSenha,
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
                                setState(() => _editandoSenha = true))),
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
                      onToggle: () => setState(() =>
                          _obscureSenhaAtual = !_obscureSenhaAtual),
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

                // ── Aprovação de professores (só para admin) ───
                if (isAdmin) ...[
                  const SizedBox(height: 28),
                  _buildSectionHeader('Administração', dark,
                      trailing: const SizedBox.shrink()),
                  const SizedBox(height: 14),
                  _buildPainelAdmin(),
                ],

                // ── Configurações ──────────────────────────────
                const SizedBox(height: 28),
                _buildSectionHeader('Configurações', dark,
                    trailing: const SizedBox.shrink()),
                const SizedBox(height: 14),
                _buildCard(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    child: Row(children: [
                      Icon(Icons.dark_mode_rounded,
                          size: 18, color: Colors.grey[400]),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Modo escuro',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: AppTheme.secondary)),
                            Text('Altera o tema do aplicativo',
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _modoEscuro,
                        activeColor: AppTheme.primary,
                        onChanged: (val) async {
                          setState(() => _modoEscuro = val);
                          // Salva preferência no Firestore
                          await FirebaseFirestore.instance
                              .collection('usuarios')
                              .doc(uid)
                              .update({'modoEscuro': val});
                          // Notifica o app para trocar o tema
                          AppThemeNotifier.of(context)?.setDarkMode(val);
                        },
                      ),
                    ]),
                  ),
                ]),

                const SizedBox(height: 40),
                _buildBotaoLogout(context),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Campo de modalidades com multi-select ─────────────────────

  Widget _buildCampoModalidades(String uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('escola')
          .doc('config')
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final todasModalidades =
            List<String>.from(data?['modalidades'] ?? []);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.music_note_rounded,
                    size: 18, color: Colors.grey[400]),
                const SizedBox(width: 12),
                const Text('Modalidades',
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ]),
              const SizedBox(height: 10),

              // Modo leitura: chips das modalidades selecionadas
              if (!_editandoDados) ...[
                if (_modalidadesSelecionadas.isEmpty)
                  Text('Nenhuma',
                      style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                          fontWeight: FontWeight.w600))
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _modalidadesSelecionadas
                        .map((m) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(m,
                                  style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ))
                        .toList(),
                  ),
              ],

              // Modo edição: chips selecionáveis de todas as modalidades
              if (_editandoDados) ...[
                if (todasModalidades.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: const Row(children: [
                      Icon(Icons.info_outline_rounded,
                          color: Colors.orange, size: 14),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Cadastre modalidades em "Turmas" primeiro.',
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
                    spacing: 8,
                    runSpacing: 8,
                    children: todasModalidades.map((m) {
                      final sel = _modalidadesSelecionadas.contains(m);
                      return GestureDetector(
                        onTap: () => _toggleModalidade(m),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppTheme.primary.withOpacity(0.1)
                                : AppTheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel
                                  ? AppTheme.primary
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (sel) ...[
                                const Icon(Icons.check_rounded,
                                    size: 13, color: AppTheme.primary),
                                const SizedBox(width: 4),
                              ],
                              Text(m,
                                  style: TextStyle(
                                      color: sel
                                          ? AppTheme.primary
                                          : Colors.grey[600],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── Painel admin: aprovar/rejeitar professores ─────────────────

  Widget _buildPainelAdmin() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('usuarios')
          .where('tipo', isEqualTo: 'professor')
          .where('status', isEqualTo: 'pendente')
          .snapshots(),
      builder: (context, snap) {
        final pendentes = snap.data?.docs ?? [];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04), blurRadius: 10)
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(children: [
                  const Icon(Icons.pending_actions_rounded,
                      size: 18, color: AppTheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    pendentes.isEmpty
                        ? 'Nenhuma solicitação pendente'
                        : '${pendentes.length} solicitação${pendentes.length > 1 ? 'ões' : ''} pendente${pendentes.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: AppTheme.secondary),
                  ),
                ]),
              ),

              if (pendentes.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Text(
                    'Todos os professores foram aprovados.',
                    style: TextStyle(color: Colors.grey[400], fontSize: 13),
                  ),
                ),

              ...pendentes.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final nome = data['nome'] ?? 'Sem nome';
                final email = data['email'] ?? '';

                // Modalidades podem ser lista ou string legada
                final raw = data['modalidades'];
                final modalidades = raw is List
                    ? List<String>.from(raw)
                    : data['modalidade'] is String &&
                            (data['modalidade'] as String).isNotEmpty
                        ? (data['modalidade'] as String).split(', ')
                        : <String>[];

                return Column(children: [
                  _buildDivider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Linha principal: avatar + nome + botões
                        Row(children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                AppTheme.primary.withOpacity(0.1),
                            child: Text(
                              nome[0].toUpperCase(),
                              style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(nome,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14)),
                                Text(email,
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ),
                          // Rejeitar — volta status para 'naoSolicitado'
                          // para o professor poder tentar de novo
                          GestureDetector(
                            onTap: () => _responderSolicitacao(
                                doc.id, false, nome),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.close_rounded,
                                  color: Colors.red, size: 18),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Aprovar
                          GestureDetector(
                            onTap: () =>
                                _responderSolicitacao(doc.id, true, nome),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.check_rounded,
                                  color: Colors.green, size: 18),
                            ),
                          ),
                        ]),

                        // Modalidades solicitadas
                        if (modalidades.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: modalidades
                                .map((m) => Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary
                                            .withOpacity(0.08),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                            color: AppTheme.primary
                                                .withOpacity(0.2)),
                                      ),
                                      child: Text(m,
                                          style: const TextStyle(
                                              color: AppTheme.primary,
                                              fontSize: 12,
                                              fontWeight:
                                                  FontWeight.w600)),
                                    ))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ]);
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _responderSolicitacao(
      String professorUid, bool aprovar, String nome) async {
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(professorUid)
        .update({
      'status': aprovar ? 'ativo' : 'rejeitado',
    });

    _mostrarSucesso(aprovar
        ? '$nome aprovado com sucesso!'
        : 'Solicitação de $nome recusada.');
  }

  // ── Componentes de UI ─────────────────────────────────────────

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
            child: Text(inicial,
                style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary)),
          ),
        ),
        const SizedBox(height: 12),
        Text(nome,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: dark,
                letterSpacing: -0.5)),
        const SizedBox(height: 4),
        const Text('Professor',
            style: TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  Widget _buildSectionHeader(String titulo, Color dark,
      {required Widget trailing}) {
    return Row(children: [
      Text(titulo,
          style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: dark.withOpacity(0.7))),
      const Spacer(),
      trailing,
    ]);
  }

  Widget _buildBotaoEditar(
      {String label = 'Editar', required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.edit_rounded, size: 14, color: AppTheme.primary),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildAcoesBotoes({
    required VoidCallback? onSalvar,
    required VoidCallback onCancelar,
    required bool salvando,
  }) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      GestureDetector(
        onTap: onCancelar,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
    ]);
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
      child: Row(children: [
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
                hintStyle:
                    TextStyle(color: Colors.grey[300], fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildCampoSoLeitura({
    required String label,
    required String valor,
    required IconData icon,
  }) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
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
          child: Text(valor,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Colors.grey[400]),
              textAlign: TextAlign.end),
        ),
      ]),
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
      child: Row(children: [
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
      ]),
    );
  }

  Widget _buildDivider() => Divider(
      height: 1,
      indent: 46,
      endIndent: 16,
      color: Colors.grey[100]);

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
            Icon(Icons.logout_rounded,
                color: Colors.redAccent, size: 18),
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