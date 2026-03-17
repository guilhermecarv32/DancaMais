import 'package:flutter/material.dart';

/// Notificador global de tema.
/// Permite que qualquer tela troque o modo escuro/claro
/// sem precisar de um pacote externo de state management.
class AppThemeNotifier extends InheritedNotifier<ValueNotifier<bool>> {
  const AppThemeNotifier({
    super.key,
    required ValueNotifier<bool> notifier,
    required super.child,
  }) : super(notifier: notifier);

  static AppThemeNotifier? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppThemeNotifier>();

  bool get isDarkMode => notifier!.value;

  void setDarkMode(bool value) => notifier!.value = value;
}