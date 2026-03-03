import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'logic/auth_bloc/auth_bloc.dart';
import 'data/services/auth_service.dart';
import 'ui/screens/login_screen.dart';

void main() async {
  // Garante a inicialização dos bindings do Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o Firebase para persistência e autenticação na nuvem
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiBlocProvider permite que o estado de autenticação seja acessado em todo o app
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
        home: const LoginScreen(),
      ),
    );
  }
}