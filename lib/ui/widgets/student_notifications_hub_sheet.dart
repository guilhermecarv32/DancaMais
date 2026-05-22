import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/feedback/feedback_service.dart';
import '../../logic/notifications/notification_service.dart';
import '../../models/notificacao_model.dart';
import 'tap_effect.dart';

Future<void> _mostrarDetalheFeedback(
  BuildContext context,
  NotificacaoModel n,
) async {
  if (n.refId == null || n.tipo != NotificacaoTipo.feedback) return;
  final data = await FeedbackService().buscar(n.refId!);
  if (!context.mounted || data == null) return;

  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(n.titulo),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (data['professorNome'] != null)
              Text(
                'Professor: ${data['professorNome']}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 10),
            Text(
              (data['texto'] as String?) ?? '',
              style: const TextStyle(height: 1.45),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Fechar'),
        ),
      ],
    ),
  );
}

void showStudentNotificationsHub(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _StudentNotificationsHubSheet(),
  );
}

class _StudentNotificationsHubSheet extends StatelessWidget {
  const _StudentNotificationsHubSheet();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

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
              child: StreamBuilder<List<NotificacaoModel>>(
                stream: NotificationService().streamParaUsuario(uid),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final itens = snap.data ?? [];
                  if (itens.isEmpty) {
                    return Center(
                      child: Text(
                        'Nenhuma notificação.',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: itens.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final n = itens[i];
                      return _NotifCard(
                        notif: n,
                        uid: uid,
                        onAbrir: () async {
                          await NotificationService().marcarLido(uid, n.id);
                          if (!context.mounted) return;
                          await _mostrarDetalheFeedback(context, n);
                        },
                        onOcultar: () =>
                            NotificationService().ocultar(uid, n.id),
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

class _NotifCard extends StatelessWidget {
  final NotificacaoModel notif;
  final String uid;
  final VoidCallback onAbrir;
  final VoidCallback onOcultar;

  const _NotifCard({
    required this.notif,
    required this.uid,
    required this.onAbrir,
    required this.onOcultar,
  });

  @override
  Widget build(BuildContext context) {
    return TapEffect(
      onTap: onAbrir,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.lido ? AppTheme.surface : AppTheme.primary.withValues(alpha: 0.06),
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
            Icon(
              Icons.chat_bubble_outline_rounded,
              color: notif.lido ? Colors.grey : AppTheme.primary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notif.titulo,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppTheme.secondary,
                    ),
                  ),
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
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              color: Colors.grey[400],
              onPressed: onOcultar,
              tooltip: 'Ocultar',
            ),
          ],
        ),
      ),
    );
  }
}
