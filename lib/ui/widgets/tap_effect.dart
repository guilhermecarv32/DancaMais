import 'package:flutter/material.dart';

/// Adiciona efeito de escurecimento ao pressionar qualquer widget.
/// Substitui GestureDetector + Container simples — envolva qualquer
/// botão customizado com TapEffect para ter o feedback visual.
///
/// Exemplo:
/// ```dart
/// TapEffect(
///   onTap: () => doSomething(),
///   borderRadius: BorderRadius.circular(16),
///   child: Container(...),
/// )
/// ```
class TapEffect extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final Duration duration;
  final HitTestBehavior? behavior;

  const TapEffect({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius,
    this.duration = const Duration(milliseconds: 80),
    this.behavior,
  });

  @override
  State<TapEffect> createState() => _TapEffectState();
}

class _TapEffectState extends State<TapEffect> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: widget.behavior,
      child: AnimatedOpacity(
        duration: widget.duration,
        opacity: _pressed ? 0.65 : 1.0,
        child: AnimatedScale(
          duration: widget.duration,
          scale: _pressed ? 0.97 : 1.0,
          child: widget.child,
        ),
      ),
    );
  }
}