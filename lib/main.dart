import 'package:dancamais/ui/widgets/auth_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/app_theme_notifier.dart';
import 'logic/auth_bloc/auth_bloc.dart';
import 'data/services/auth_service.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(androidProvider: AndroidProvider.debug);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ValueNotifier<bool> _darkMode = ValueNotifier(false);

  @override
  void dispose() {
    _darkMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeNotifier(
      notifier: _darkMode,
      child: ValueListenableBuilder<bool>(
        valueListenable: _darkMode,
        builder: (context, isDark, _) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (context) => AuthBloc(AuthService())),
            ],
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'DançaMais',
              theme: AppTheme.themeData,
              darkTheme: AppTheme.darkThemeData,
              themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
              initialRoute: '/',
              routes: {'/': (context) => const AuthWrapper()},
            ),
          );
        },
      ),
    );
  }
}