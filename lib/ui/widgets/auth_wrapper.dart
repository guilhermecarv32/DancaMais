import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dancamais/ui/screens/login_screen.dart';
import 'package:dancamais/ui/screens/student_dashboard.dart';
import 'package:dancamais/ui/screens/teacher_Dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Se não estiver logado, vai para o Login
        if (!snapshot.hasData) {
          return const LoginScreen();
        }

        // 2. Se estiver logado, verifica o 'tipo' no Firestore
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('usuarios')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final data = userSnapshot.data!.data() as Map<String, dynamic>;
              final String tipo = data['tipo'] ?? 'aluno';

              // Redireciona conforme o cargo
              if (tipo == 'professor') {
                return const TeacherDashboard();
              } else {
                return const StudentDashboard();
              }
            }

            // Fallback caso o documento não exista
            return const LoginScreen();
          },
        );
      },
    );
  }
}