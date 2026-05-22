import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/services/permissao_service.dart';
import '../../logic/gamification/gamification_service.dart' as gamif;
import '../../logic/notifications/notification_service.dart';
import '../../logic/streak/streak_service.dart';
import '../../models/notificacao_model.dart';
import 'streak_widgets.dart';
import 'tap_effect.dart';

/// Sininho do professor: notificações + atalhos.
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
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final notifSvc = NotificationService();

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
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Notificações',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: AppTheme.secondary,
                    ),
                  ),
                ),
                if (uid.isNotEmpty)
                  TextButton(
                    onPressed: () async {
                      await notifSvc.limparTodasVisiveis(uid);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Notificações limpas'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Limpar tudo',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: FutureBuilder<_ProfessorHubData>(
                future: _carregarHub(
                  uid,
                  perfil.filtroModalidades,
                  notifSvc,
                ),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snap.data!;

                  if (uid.isEmpty) {
                    return const Center(
                      child: Text('Faça login para ver notificações.'),
                    );
                  }

                  return StreamBuilder<List<NotificacaoModel>>(
                    stream: notifSvc.streamParaUsuario(uid),
                    builder: (context, notifSnap) {
                      final notifs = notifSnap.data ?? [];

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
                            if (notifs.isNotEmpty) ...[
                              const _SecaoTitulo('Recentes'),
                              ...notifs.map(
                                (n) => _ProfessorNotifCard(
                                  notif: n,
                                  onTap: () => _aoTocarNotificacao(
                                    context,
                                    uid,
                                    n,
                                    notifSvc,
                                    onValidarPasso: onValidarPasso,
                                    onSolicitacoesEntrada:
                                        onSolicitacoesEntrada,
                                  ),
                                  onOcultar: () =>
                                      notifSvc.ocultar(uid, n.id),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ] else if (!data.escolaPausados) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'Nenhuma notificação no momento.',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
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

Future<void> _aoTocarNotificacao(
  BuildContext context,
  String uid,
  NotificacaoModel n,
  NotificationService notifSvc, {
  required VoidCallback onValidarPasso,
  required VoidCallback onSolicitacoesEntrada,
}) async {
  await notifSvc.marcarLido(uid, n.id);
  if (!context.mounted) return;

  switch (n.tipo) {
    case NotificacaoTipo.streakAlerta:
      final alunoId = n.refId;
      if (alunoId != null && alunoId.isNotEmpty) {
        showProfessorStreakAlertaDetalhe(context, alunoId: alunoId);
      }
      break;
    case NotificacaoTipo.validacaoPendente:
      Navigator.pop(context);
      onValidarPasso();
      break;
    case NotificacaoTipo.solicitacao:
      Navigator.pop(context);
      onSolicitacoesEntrada();
      break;
    default:
      break;
  }
}

class _ProfessorHubData {
  final bool escolaPausados;
  final String escolaMsg;

  _ProfessorHubData({
    required this.escolaPausados,
    required this.escolaMsg,
  });
}

Future<_ProfessorHubData> _carregarHub(
  String professorUid,
  List<String>? modalidades,
  NotificationService notifSvc,
) async {
  if (professorUid.isNotEmpty) {
    await notifSvc.sincronizarPendenciasProfessor(
      professorUid: professorUid,
      modalidadesFiltro: modalidades,
    );
  }

  final escola = await StreakService().lerConfigEscola();

  String escolaMsg = 'Streaks pausados pela escola';
  if (escola.pausados && escola.retomarEm != null) {
    final ate = escola.retomarEm!;
    escolaMsg =
        'Streaks pausados até ${ate.day.toString().padLeft(2, '0')}/${ate.month.toString().padLeft(2, '0')}/${ate.year}';
  }

  return _ProfessorHubData(
    escolaPausados: escola.pausados,
    escolaMsg: escolaMsg,
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

class _ProfessorNotifCard extends StatelessWidget {
  final NotificacaoModel notif;
  final VoidCallback onTap;
  final VoidCallback onOcultar;

  const _ProfessorNotifCard({
    required this.notif,
    required this.onTap,
    required this.onOcultar,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconeParaNotif(notif);

    return TapEffect(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.lido
              ? AppTheme.surface
              : AppTheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notif.lido
                ? Colors.transparent
                : AppTheme.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.titulo,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppTheme.secondary,
                    ),
                  ),
                  if (notif.corpo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      notif.corpo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              color: Colors.grey[400],
              onPressed: onOcultar,
              tooltip: 'Remover',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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

(IconData, Color) _iconeParaNotif(NotificacaoModel n) {
  if (n.tipo == NotificacaoTipo.streakAlerta &&
      n.corpo.toLowerCase().contains('gelo')) {
    return (Icons.ac_unit_rounded, Colors.lightBlue);
  }
  return _iconeParaTipo(n.tipo);
}

(IconData, Color) _iconeParaTipo(NotificacaoTipo tipo) {
  return switch (tipo) {
    NotificacaoTipo.validacaoPendente => (
        Icons.verified_outlined,
        Colors.orange[800]!,
      ),
    NotificacaoTipo.solicitacao => (
        Icons.person_add_alt_1_rounded,
        Colors.orange[800]!,
      ),
    NotificacaoTipo.feedback => (
        Icons.chat_bubble_outline_rounded,
        AppTheme.primary,
      ),
    NotificacaoTipo.streakAlerta => (
        Icons.local_fire_department_rounded,
        Colors.deepOrange,
      ),
    NotificacaoTipo.streaksPausados => (
        Icons.pause_circle_filled_rounded,
        Colors.amber[800]!,
      ),
  };
}
