import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dancamais/ui/screens/login_screen.dart';
import 'package:dancamais/ui/screens/student_dashboard.dart';
import 'package:dancamais/ui/screens/teacher_Dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/auth_bloc/auth_bloc.dart';
import '../../logic/auth_bloc/auth_event.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {

        // Não logado — vai para login
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // Logado — verifica tipo e status no Firestore
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(snapshot.data!.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }

            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const LoginScreen();
            }

            final data =
                userSnapshot.data!.data() as Map<String, dynamic>;
            final String tipo = data['tipo'] ?? 'aluno';
            final String status = data['status'] ?? 'ativo';

            // Professor pendente — tela de espera (sem signOut)
            if (tipo == 'professor' && status == 'pendente') {
              return PendingApprovalScreen(
                nome: data['nome'] ?? 'Professor',
                modalidade: data['modalidade'],
                podeSolicitarNovamente: false,
              );
            }

            // Professor recusado — pode solicitar novamente
            if (tipo == 'professor' && status == 'naoSolicitado') {
              return PendingApprovalScreen(
                nome: data['nome'] ?? 'Professor',
                modalidade: data['modalidade'],
                podeSolicitarNovamente: true,
              );
            }

            // Roteamento normal
            if (tipo == 'professor') return const TeacherDashboard();
            return const StudentDashboard();
          },
        );
      },
    );
  }
}

// ── Tela de aguardo de aprovação ──────────────────────────────────

class PendingApprovalScreen extends StatefulWidget {
  final String nome;
  final String? modalidade;
  final bool podeSolicitarNovamente;

  const PendingApprovalScreen({
    super.key,
    required this.nome,
    this.modalidade,
    this.podeSolicitarNovamente = false,
  });

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  List<String> _modalidadesDisponiveis = [];
  List<String> _modalidadesSelecionadas = [];
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    if (widget.podeSolicitarNovamente) _carregarModalidades();
    // Pré-seleciona modalidade anterior se existir
    if (widget.modalidade != null && widget.modalidade!.isNotEmpty) {
      _modalidadesSelecionadas = widget.modalidade!.split(', ');
    }
  }

  void _carregarModalidades() {
    FirebaseFirestore.instance
        .collection('escola')
        .doc('config')
        .snapshots()
        .listen((snap) {
      if (!mounted) return;
      final data = snap.data() as Map<String, dynamic>?;
      setState(() {
        _modalidadesDisponiveis =
            List<String>.from(data?['modalidades'] ?? []);
      });
    });
  }

  Future<void> _enviarNovaSolicitacao() async {
    if (_modalidadesSelecionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecione pelo menos uma modalidade.')),
      );
      return;
    }

    setState(() => _enviando = true);

    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .update({
      'status': 'pendente',
      'modalidades': _modalidadesSelecionadas,
      'modalidade': _modalidadesSelecionadas.join(', '),
    });

    setState(() => _enviando = false);
    // AuthWrapper detecta status 'pendente' e muda a tela automaticamente
  }

  @override
  Widget build(BuildContext context) {
    final primeiroNome = widget.nome.trim().split(' ').first;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 35),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: widget.podeSolicitarNovamente
                      ? Colors.orange.withOpacity(0.1)
                      : AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    widget.podeSolicitarNovamente ? '🔄' : '⏳',
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Text(
                'Olá, $primeiroNome!',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                widget.podeSolicitarNovamente
                    ? 'Solicitação não aprovada'
                    : 'Cadastro em análise',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
              const SizedBox(height: 24),

              // ── Modo aguardo ──────────────────────────────────
              if (!widget.podeSolicitarNovamente) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dados enviados para análise:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: AppTheme.secondary)),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                          Icons.person_outline_rounded, widget.nome),
                      if (_modalidadesSelecionadas.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _modalidadesSelecionadas
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
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.info_outline_rounded,
                        'Aguardando aprovação do administrador',
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Você será notificado assim que sua conta for aprovada.',
                  style: TextStyle(
                      fontSize: 14, color: Colors.grey[500], height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ],

              // ── Modo nova solicitação ─────────────────────────
              if (widget.podeSolicitarNovamente) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.orange.withOpacity(0.2)),
                  ),
                  child: const Text(
                    'Sua solicitação anterior não foi aprovada. '
                    'Selecione as modalidades e envie uma nova solicitação.',
                    style: TextStyle(
                        color: Colors.orange,
                        fontSize: 14,
                        height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),

                // Multi-select de modalidades
                if (_modalidadesDisponiveis.isNotEmpty) ...[
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Selecione as modalidades:',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppTheme.secondary)),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _modalidadesDisponiveis.map((m) {
                      final sel = _modalidadesSelecionadas.contains(m);
                      return GestureDetector(
                        onTap: () => setState(() => sel
                            ? _modalidadesSelecionadas.remove(m)
                            : _modalidadesSelecionadas.add(m)),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 9),
                          decoration: BoxDecoration(
                            color: sel
                                ? AppTheme.primary.withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: sel
                                  ? AppTheme.primary
                                  : Colors.grey.withOpacity(0.3),
                              width: sel ? 2 : 1,
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
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _enviando ? null : _enviarNovaSolicitacao,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _enviando
                          ? const SizedBox(
                              height: 22, width: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Text('Enviar Nova Solicitação',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ],

              const SizedBox(height: 20),

              // Botão de sair
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      context.read<AuthBloc>().add(LogoutRequested()),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Voltar ao Login'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {Color? color}) {
    return Row(children: [
      Icon(icon, size: 16, color: color ?? Colors.grey[400]),
      const SizedBox(width: 10),
      Expanded(
        child: Text(text,
            style: TextStyle(
                fontSize: 14,
                color: color ?? Colors.grey[600],
                fontWeight:
                    color != null ? FontWeight.w500 : FontWeight.normal)),
      ),
    ]);
  }
}