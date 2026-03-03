import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'register_screen.dart';

class SelectionScreen extends StatefulWidget {
  const SelectionScreen({super.key});

  @override
  State<SelectionScreen> createState() => _SelectionScreenState();
}

class _SelectionScreenState extends State<SelectionScreen> {
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = AppTheme.primary;
    const Color darkColor = Color(0xFF6C2E21);

    return Scaffold(
      body: Stack(
        children: [
          // 1. FUNDO IDÊNTICO AO LOGIN (Mantido conforme sua versão)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.orange.shade50.withOpacity(0.5),
                  Colors.white,
                ],
              ),
            ),
          ),

          // Formas Decorativas (Posições originais mantidas)
          Positioned(
            top: -100,
            left: -50,
            child: Opacity(
              opacity: 0.08,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(color: primaryColor, shape: BoxShape.circle),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            right: -80,
            child: Opacity(
              opacity: 0.05,
              child: Container(
                width: 250,
                height: 250,
                decoration: const BoxDecoration(color: darkColor, shape: BoxShape.circle),
              ),
            ),
          ),

          // 2. CONTEÚDO
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Antes disso...",
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: darkColor,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const Text(
                    "Você irá ensinar ou aprender?",
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 60),

                  // Botões com a nova estilização animada
                  _buildSelectionButton(
                    label: "Ensinar!",
                    isSelected: _selectedRole == 'professor',
                    onTap: () => setState(() => _selectedRole = 'professor'),
                  ),
                  
                  const SizedBox(height: 20),

                  _buildSelectionButton(
                    label: "Aprender!",
                    isSelected: _selectedRole == 'aluno',
                    onTap: () => setState(() => _selectedRole = 'aluno'),
                  ),

                  const SizedBox(height: 80),

                  ElevatedButton(
                    onPressed: _selectedRole == null 
                      ? null 
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RegisterScreen(tipo: _selectedRole!),
                            ),
                          );
                        },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: darkColor,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 4,
                    ),
                    child: const Text("Cadastrar", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  ),

                  const SizedBox(height: 25),

                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                          children: [
                            TextSpan(text: "Já tem uma conta? "),
                            TextSpan(
                              text: "Faça Login!",
                              style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline, color: primaryColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper atualizado com Implicit Animations (Clean & Reativo)
  Widget _buildSelectionButton({required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250), // Tempo da "animaçãozinha"
        curve: Curves.easeInOut,
        height: 60,
        decoration: BoxDecoration(
          // Fundo fica levemente colorido ao selecionar
          color: isSelected ? AppTheme.primary.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            // A borda "surge" suavemente
            color: isSelected ? AppTheme.primary : Colors.white, 
            width: 2.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.08 : 0.05),
              blurRadius: isSelected ? 12 : 8,
              offset: Offset(0, isSelected ? 4 : 2),
            ),
          ],
        ),
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              // O texto muda de cor sem pulos
              color: isSelected ? AppTheme.primary : Colors.grey[400],
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}