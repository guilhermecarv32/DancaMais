import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/notifications/notification_service.dart';
import 'student_notifications_hub_sheet.dart';
import 'tap_effect.dart';

/// Sininho com badge de não lidas (aluno).
class StudentNotificationsBell extends StatelessWidget {
  const StudentNotificationsBell({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return const SizedBox.shrink();

    return StreamBuilder<int>(
      stream: NotificationService().contagemNaoLidas(uid),
      builder: (context, snap) {
        final count = snap.data ?? 0;
        return TapEffect(
          onTap: () => showStudentNotificationsHub(context),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: Icon(
                    Icons.notifications_rounded,
                    color: Colors.grey[600],
                    size: 24,
                  ),
                ),
                if (count > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Sininho professor (home header).
class TeacherNotificationsBell extends StatelessWidget {
  final VoidCallback onTap;
  final Stream<int>? badgeStream;

  const TeacherNotificationsBell({
    super.key,
    required this.onTap,
    this.badgeStream,
  });

  @override
  Widget build(BuildContext context) {
    Widget bell = TapEffect(
      onTap: onTap,
      child: Icon(Icons.notifications_rounded,
          color: Colors.grey[500], size: 24),
    );

    if (badgeStream == null) return bell;

    return StreamBuilder<int>(
      stream: badgeStream,
      builder: (context, snap) {
        final count = snap.data ?? 0;
        return TapEffect(
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.notifications_rounded,
                  color: Colors.grey[500], size: 24),
              if (count > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      count > 9 ? '9+' : '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
