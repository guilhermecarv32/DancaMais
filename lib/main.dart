import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Importações dos seus arquivos de arquitetura
import 'core/theme/app_theme.dart';
import 'ui/screens/login_screen.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'logic/auth_bloc/auth_bloc.dart';
import 'data/services/auth_service.dart';

void main() async {
  // Garante que as ligações do Flutter estejam prontas antes de iniciar o Firebase [cite: 184]
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa o Firebase com as configurações geradas pelo FlutterFire CLI [cite: 308]
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
  return MultiBlocProvider(
    providers: [
      BlocProvider(create: (context) => AuthBloc(AuthService())),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: DancaMaisTheme.theme,
      home: const LoginScreen(),
    ),
  );
}
}