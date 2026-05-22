import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/permissao_service.dart';
import '../../logic/gamification/gamification_service.dart' as gamif;
import '../../logic/notifications/notification_service.dart';
import '../../logic/streak/streak_service.dart';
import '../../models/notificacao_model.dart';
import 'tap_effect.dart';

/// Sininho do professor: streaks + atalhos de solicitações + aviso de pausa global.
class NotificationsHubSheet extends StatelessWidget {
  final PerfilProfessor perfil;
  final VoidCallback onValidarPasso;
  final VoidCallback onSolicitacoesEntrada;

  const NotificationsHubSheet({
    super.key,
    required this.perfil,
    required this.onValidarPasso,
    required this.onSolicitacoesEntrada,
  });

  @override
  Widget build(BuildContext context) {
    final streakService = StreakService();
    final modalidades = perfil.filtroModalidades;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 35),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Text(
              'Notificações',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: FutureBuilder<_ProfessorHubData>(
                future: _carregarHub(streakService, modalidades),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snap.data!;

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (data.escolaPausados) ...[
                          _NotifTile(
                            icon: Icons.pause_circle_filled_rounded,
                            iconColor: Colors.amber[800]!,
                            titulo: data.escolaMsg,
                            subtitulo: 'Pausa global ativa',
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (data.validacoes.isNotEmpty) ...[
                          _SecaoTitulo('Validações pendentes'),
                          ...data.validacoes.map(
                            (v) => TapEffect(
                              onTap: () {
                                Navigator.pop(context);
                                onValidarPasso();
                              },
                              child: _NotifTile(
                                icon: Icons.verified_outlined,
                                iconColor: Colors.orange[800]!,
                                titulo: v.tituloExibicao,
                                subtitulo: v.turmaNome,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (data.solicitacoes.isNotEmpty) ...[
                          _SecaoTitulo('Solicitações de entrada'),
                          ...data.solicitacoes.map(
                            (s) => TapEffect(
                              onTap: () {
                                Navigator.pop(context);
                                onSolicitacoesEntrada();
                              },
                              child: _NotifTile(
                                icon: Icons.person_add_alt_1_rounded,
                                iconColor: Colors.orange[800]!,
                                titulo: (s['nomeAluno'] as String?) ??
                                    'Aluno',
                                subtitulo:
                                    (s['nomeTurma'] as String?) ?? 'Turma',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        _SecaoTitulo('Streaks dos alunos'),
                        if (data.streaks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Nenhum alerta de streak no momento.',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          ...data.streaks.map(
                            (a) => _NotifTile(
                              icon: a.estado == StreakEstado.fogo
                                  ? Icons.local_fire_department_rounded
                                  : Icons.ac_unit_rounded,
                              iconColor: a.estado == StreakEstado.fogo
                                  ? Colors.deepOrange
                                  : Colors.lightBlue,
                              titulo: a.tituloExibicao,
                              subtitulo: perfil.isAdmin
                                  ? 'Todas as modalidades'
                                  : 'Suas modalidades',
                            ),
                          ),
                        const Divider(height: 24),
                    const Text(
                      'Ações',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppTheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TapEffect(
                      onTap: () {
                        Navigator.pop(context);
                        onValidarPasso();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.verified_rounded,
                                color: Colors.green, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Validar passo da semana',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15)),
                                Text(
                                  '+${gamif.XPRecompensa.validadoProfessor} XP',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]),
                      ),
                    ),
                    TapEffect(
                      onTap: () {
                        Navigator.pop(context);
                        onSolicitacoesEntrada();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.person_add_alt_1_rounded,
                                color: Colors.orange[800], size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Solicitações de entrada em turma',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.orange[900],
                              ),
                            ),
                          ),
                        ]),
                      ),
                    ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfessorHubData {
  final bool escolaPausados;
  final String escolaMsg;
  final List<StreakAlertaProfessor> streaks;
  final List<ValidacaoPendenteItem> validacoes;
  final List<Map<String, dynamic>> solicitacoes;

  _ProfessorHubData({
    required this.escolaPausados,
    required this.escolaMsg,
    required this.streaks,
    required this.validacoes,
    required this.solicitacoes,
  });
}

Future<_ProfessorHubData> _carregarHub(
  StreakService streakService,
  List<String>? modalidades,
) async {
  final notifSvc = NotificationService();
  final escola = await streakService.lerConfigEscola();
  final streaks = await streakService.listarAlertasProfessor(
    modalidadesFiltro: modalidades,
  );
  final validacoes = await notifSvc.listarValidacoesPendentes(
    modalidadesFiltro: modalidades,
  );
  final solicitacoes = await notifSvc.listarSolicitacoesPendentes(
    modalidadesFiltro: modalidades,
  );

  String escolaMsg = 'Streaks pausados pela escola';
  if (escola.pausados && escola.retomarEm != null) {
    final ate = escola.retomarEm!;
    escolaMsg =
        'Streaks pausados até ${ate.day.toString().padLeft(2, '0')}/${ate.month.toString().padLeft(2, '0')}/${ate.year}';
  }

  return _ProfessorHubData(
    escolaPausados: escola.pausados,
    escolaMsg: escolaMsg,
    streaks: streaks,
    validacoes: validacoes,
    solicitacoes: solicitacoes,
  );
}

class _SecaoTitulo extends StatelessWidget {
  final String texto;
  const _SecaoTitulo(this.texto);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        texto,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String titulo;
  final String? subtitulo;

  const _NotifTile({
    required this.icon,
    required this.iconColor,
    required this.titulo,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.secondary,
                  ),
                ),
                if (subtitulo != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitulo!,
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
