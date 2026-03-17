import 'package:dancamais/ui/widgets/auth_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'logic/auth_bloc/auth_bloc.dart';
import 'data/services/auth_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AuthBloc(AuthService()),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'DançaMais',
        theme: AppTheme.themeData,
        // Rota inicial nomeada — permite que RegisterScreen navegue de volta
        // com pushNamedAndRemoveUntil('/'), limpando toda a pilha.
        // O AuthWrapper decide automaticamente para onde ir (aluno ou professor).
        initialRoute: '/',
        routes: {
          '/': (context) => const AuthWrapper(),
        },
      ),
    );
  }
}