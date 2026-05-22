import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/permissao_service.dart';
import '../../logic/gamification/gamification_service.dart' as gamif;
import '../../logic/streak/streak_service.dart';
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
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StreamBuilder<EscolaStreakConfig>(
                      stream: streakService.configEscolaStream(),
                      builder: (context, escolaSnap) {
                        final escola =
                            escolaSnap.data ?? const EscolaStreakConfig();
                        if (!escola.pausados) {
                          return const SizedBox.shrink();
                        }
                        final ate = escola.retomarEm;
                        final msg = ate != null
                            ? 'Streaks pausados até ${ate.day.toString().padLeft(2, '0')}/${ate.month.toString().padLeft(2, '0')}/${ate.year}'
                            : 'Streaks pausados pela escola';
                        return _NotifTile(
                          icon: Icons.pause_circle_filled_rounded,
                          iconColor: Colors.amber[800]!,
                          titulo: msg,
                          subtitulo: 'Pausa global ativa',
                        );
                      },
                    ),
                    FutureBuilder<List<StreakAlertaProfessor>>(
                      future: streakService.listarAlertasProfessor(
                        modalidadesFiltro: modalidades,
                      ),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final alertas = snap.data ?? [];
                        if (alertas.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'Nenhum alerta de streak no momento.',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Streaks dos alunos',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            ...alertas.map(
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
                          ],
                        );
                      },
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
              ),
            ),
          ],
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
