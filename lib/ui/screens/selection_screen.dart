import 'package:dancamais/ui/screens/register_screen.dart';
import 'package:flutter/material.dart';

class SelectionScreen extends StatelessWidget {
  const SelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Antes disso...", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const Text("Você irá ensinar ou aprender?"),
          const SizedBox(height: 40),
          // Botão Ensinar
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const RegisterScreen(tipo: 'professor'))),
            child: const Text("Ensinar!"),
          ),
          // Botão Aprender
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const RegisterScreen(tipo: 'aluno'))),
            child: const Text("Aprender!"),
          ),
        ],
      ),
    );
  }
}