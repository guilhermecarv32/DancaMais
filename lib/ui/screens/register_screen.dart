import 'package:dancamais/logic/auth_bloc/auth_bloc.dart';
import 'package:dancamais/logic/auth_bloc/auth_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterScreen extends StatefulWidget {
  final String tipo;
  const RegisterScreen({super.key, required this.tipo});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text("No ritmo!", style: TextStyle(fontSize: 32)),
            const Text("O primeiro passo começa aqui!"),
            const SizedBox(height: 30),
            TextField(controller: _nomeController, decoration: const InputDecoration(labelText: "Nome Completo")),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: _passController, obscureText: true, decoration: const InputDecoration(labelText: "Senha")),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                context.read<AuthBloc>().add(RegisterRequested(
                  _emailController.text, 
                  _passController.text, 
                  _nomeController.text, 
                  widget.tipo
                ));
              },
              child: const Text("Cadastrar"),
            ),
          ],
        ),
      ),
    );
  }
}