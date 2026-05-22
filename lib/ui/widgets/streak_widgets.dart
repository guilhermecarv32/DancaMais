import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/streak/streak_service.dart';
import 'tap_effect.dart';

StreakEstado streakEstadoDe(Map<String, dynamic> userData) {
  final s = (userData['streakEstado'] as String?) ?? 'neutro';
  return switch (s) {
    'fogo' => StreakEstado.fogo,
    'gelo' => StreakEstado.gelo,
    _ => StreakEstado.neutro,
  };
}

/// Ícone da streak do aluno (home completo ou compacto na agenda).
class StreakHomeIcon extends StatelessWidget {
  final Map<String, dynamic> userData;
  final EscolaStreakConfig escolaConfig;

  /// Versão na linha "Minha Agenda": ícone estático + só o número de semanas.
  final bool compact;

  const StreakHomeIcon({
    super.key,
    required this.userData,
    required this.escolaConfig,
    this.compact = false,
  });

  StreakEstado get _estado => streakEstadoDe(userData);

  int get _semanas =>
      (_estado == StreakEstado.fogo
              ? (userData['streakFogo'] as num?)?.toInt()
              : (userData['streakGelo'] as num?)?.toInt()) ??
      0;

  int get _semanasExibidas {
    if (_estado == StreakEstado.neutro) return 0;
    final n = _semanas;
    return n < 1 ? 1 : n;
  }

  String get _legenda {
    if (_estado == StreakEstado.neutro) {
      return 'Comece sua sequência!';
    }
    final n = _semanas < 1 ? 1 : _semanas;
    final plural = n == 1 ? '' : 's';
    if (_estado == StreakEstado.fogo) {
      return '$n semana$plural ativo(a)!';
    }
    return '$n semana$plural inativo(a)...';
  }

  (IconData, Color) get _iconECor => switch (_estado) {
        StreakEstado.fogo => (
            Icons.local_fire_department_rounded,
            Colors.deepOrange,
          ),
        StreakEstado.gelo => (
            Icons.ac_unit_rounded,
            Colors.lightBlue,
          ),
        StreakEstado.neutro => (
            Icons.local_fire_department_rounded,
            Colors.grey,
          ),
      };

  void _abrirDetalhe(BuildContext context) {
    showStreakDetalheSheet(
      context,
      userData: userData,
      escolaConfig: escolaConfig,
    );
  }

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconECor;

    if (compact) {
      return TapEffect(
        onTap: () => _abrirDetalhe(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 3),
            Text(
              '$_semanasExibidas',
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ],
        ),
      );
    }

    return TapEffect(
      onTap: () => _abrirDetalhe(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AnimatedStreakIcon(estado: _estado, icon: icon, color: color),
          const SizedBox(height: 2),
          SizedBox(
            width: 72,
            child: Text(
              _legenda,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void showStreakDetalheSheet(
  BuildContext context, {
  required Map<String, dynamic> userData,
  required EscolaStreakConfig escolaConfig,
}) {
  final estado = streakEstadoDe(userData);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) {
      final h = MediaQuery.of(ctx).size.height;
      return SizedBox(
        height: h,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(ctx),
                behavior: HitTestBehavior.opaque,
              ),
            ),
            if (estado == StreakEstado.fogo || estado == StreakEstado.gelo)
              IgnorePointer(
                child: _StreakScreenEdgeEffect(estado: estado),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _StreakDetalheSheet(
                userData: userData,
                escolaConfig: escolaConfig,
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Detalhe da streak de um aluno (professor).
void showProfessorStreakAlertaDetalhe(
  BuildContext context, {
  required String alunoId,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => FutureBuilder<StreakDetalheProfessor?>(
      future: StreakService().detalheParaProfessor(alunoId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final detalhe = snap.data;
        if (detalhe == null) {
          return Container(
            padding: const EdgeInsets.fromLTRB(25, 24, 25, 32),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: const Text(
              'Não foi possível carregar os dados da streak.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          );
        }
        return _ProfessorStreakDetalheSheet(detalhe: detalhe);
      },
    ),
  );
}

class _ProfessorStreakDetalheSheet extends StatelessWidget {
  final StreakDetalheProfessor detalhe;

  const _ProfessorStreakDetalheSheet({required this.detalhe});

  @override
  Widget build(BuildContext context) {
    final (icone, cor) = switch (detalhe.estado) {
      StreakEstado.fogo => (
          Icons.local_fire_department_rounded,
          Colors.deepOrange,
        ),
      StreakEstado.gelo => (
          Icons.ac_unit_rounded,
          Colors.lightBlue,
        ),
      StreakEstado.neutro => (
          Icons.local_fire_department_rounded,
          Colors.grey,
        ),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              children: [
                Icon(icone, color: cor, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    detalhe.nomeCompleto,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _DetalheLinha(
              rotulo: 'Streak atual',
              valor: detalhe.streakAtual,
              destaque: true,
              cor: cor,
            ),
            const SizedBox(height: 12),
            _DetalheLinha(
              rotulo: 'O que mudou',
              valor: detalhe.motivoMudanca,
            ),
            if (detalhe.estado == StreakEstado.fogo && detalhe.streakFogo > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Semanas ativas consecutivas: ${detalhe.streakFogo}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (detalhe.estado == StreakEstado.gelo && detalhe.streakGelo > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Semanas inativas consecutivas: ${detalhe.streakGelo}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetalheLinha extends StatelessWidget {
  final String rotulo;
  final String valor;
  final bool destaque;
  final Color? cor;

  const _DetalheLinha({
    required this.rotulo,
    required this.valor,
    this.destaque = false,
    this.cor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rotulo,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            color: destaque ? (cor ?? AppTheme.primary) : Colors.grey[800],
            fontSize: destaque ? 15 : 14,
            fontWeight: destaque ? FontWeight.w800 : FontWeight.w600,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _StreakDetalheSheet extends StatefulWidget {
  final Map<String, dynamic> userData;
  final EscolaStreakConfig escolaConfig;

  const _StreakDetalheSheet({
    required this.userData,
    required this.escolaConfig,
  });

  @override
  State<_StreakDetalheSheet> createState() => _StreakDetalheSheetState();
}

class _StreakDetalheSheetState extends State<_StreakDetalheSheet> {
  bool _ativandoPausa = false;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final estado = (widget.userData['streakEstado'] as String?) ?? 'neutro';
    final fogo = (widget.userData['streakFogo'] as num?)?.toInt() ?? 0;
    final gelo = (widget.userData['streakGelo'] as num?)?.toInt() ?? 0;
    final pausaAteTs = widget.userData['pausaStreakAte'];
    DateTime? pausaAte;
    if (pausaAteTs is Timestamp) pausaAte = pausaAteTs.toDate();

    final pausaAtiva =
        pausaAte != null && DateTime.now().isBefore(pausaAte);
    final mesAtual = StreakService.mesReferencia(DateTime.now());
    final ultimoMes =
        (widget.userData['ultimaPausaStreakMes'] as num?)?.toInt();
    final podePausaMes = ultimoMes != mesAtual && !pausaAtiva;
    final escolaPausada = widget.escolaConfig.pausados;

    String titulo;
    String descricao;
    IconData icone;
    Color cor;

    switch (estado) {
      case 'fogo':
        titulo = 'Streak de fogo';
        descricao =
            'Você marcou passos como aprendidos nos últimos 7 dias. '
            'Semana${fogo == 1 ? '' : 's'} ativa${fogo == 1 ? '' : 's'} seguida${fogo == 1 ? '' : 's'}: $fogo.';
        icone = Icons.local_fire_department_rounded;
        cor = Colors.deepOrange;
        break;
      case 'gelo':
        titulo = 'Streak de gelo';
        descricao =
            'Há $gelo semana${gelo == 1 ? '' : 's'} sem marcar nenhum passo '
            'como aprendido. Marque um passo para voltar ao fogo!';
        icone = Icons.ac_unit_rounded;
        cor = Colors.lightBlue;
        break;
      default:
        titulo = 'Pratique sua dança!';
        descricao =
            'Marque pelo menos um passo como aprendido na semana para '
            'acender o fogo.';
        icone = Icons.local_fire_department_rounded;
        cor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Row(
              children: [
                _AnimatedStreakIcon(
                  estado: streakEstadoDe(widget.userData),
                  icon: icone,
                  color: cor,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              descricao,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Você pode congelar sua sequência por 7 dias. '
              'Disponível apenas 1 vez por mês. ',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
                height: 1.4,
              ),
            ),
            if (pausaAtiva && pausaAte != null) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Pausa pessoal ativa até ${_fmtData(pausaAte)}.',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor: Colors.grey[300],
                ),
                onPressed: (escolaPausada || !podePausaMes || _ativandoPausa)
                    ? null
                    : () => _ativarPausa(uid),
                child: _ativandoPausa
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        escolaPausada
                            ? 'Pausa indisponível (escola)'
                            : pausaAtiva
                                ? 'Pausa pessoal em andamento'
                                : podePausaMes
                                    ? 'Ativar pausa pessoal (7 dias)'
                                    : 'Pausa já usada este mês',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ativarPausa(String uid) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pausa pessoal de streak'),
        content: const Text(
          'Por 7 dias sua streak de gelo não aumenta e o fogo '
          'permanece no valor atual. Só pode usar 1 vez por mês. '
          'O professor não será notificado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ativar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _ativandoPausa = true);
    final erro =
        await StreakService().ativarPausaPessoal(uid);
    if (!mounted) return;
    setState(() => _ativandoPausa = false);

    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(erro)),
      );
      return;
    }
    if (mounted) Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pausa pessoal ativada por 7 dias.')),
    );
  }

  String _fmtData(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

/// Banner quando a escola pausou streaks globalmente.
class StreakEscolaPausadaBanner extends StatelessWidget {
  final EscolaStreakConfig config;

  const StreakEscolaPausadaBanner({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    if (!config.pausados) return const SizedBox.shrink();

    final ate = config.retomarEm;
    final texto = ate != null
        ? 'Contagem de streaks pausada pela escola até '
            '${ate.day.toString().padLeft(2, '0')}/'
            '${ate.month.toString().padLeft(2, '0')}/${ate.year}.'
        : 'Contagem de streaks pausada pela escola no momento.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 12, 25, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.withOpacity(0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.pause_circle_outline_rounded,
                color: Colors.amber[800], size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                texto,
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ícone animado (fogo / gelo) ─────────────────────────────────

class _AnimatedStreakIcon extends StatefulWidget {
  final StreakEstado estado;
  final IconData icon;
  final Color color;
  final double size;

  const _AnimatedStreakIcon({
    required this.estado,
    required this.icon,
    required this.color,
    this.size = 34,
  });

  @override
  State<_AnimatedStreakIcon> createState() => _AnimatedStreakIconState();
}

class _AnimatedStreakIconState extends State<_AnimatedStreakIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.estado != StreakEstado.neutro) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_AnimatedStreakIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.estado == StreakEstado.neutro) {
      _ctrl.stop();
    } else if (!_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.estado == StreakEstado.neutro) {
      return Icon(widget.icon, color: widget.color, size: widget.size);
    }

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final t = _ctrl.value;
        final pulse = 0.88 + 0.12 * math.sin(t * math.pi);
        final glow = widget.estado == StreakEstado.fogo
            ? 0.35 + 0.45 * t
            : 0.25 + 0.35 * t;

        final glowColor = widget.estado == StreakEstado.fogo
            ? const Color(0xFFFF6D00)
            : const Color(0xFF4FC3F7);

        return SizedBox(
          width: widget.size + 16,
          height: widget.size + 16,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                width: widget.size * pulse,
                height: widget.size * pulse,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withValues(alpha: glow),
                      blurRadius: widget.estado == StreakEstado.fogo ? 14 : 10,
                      spreadRadius: widget.estado == StreakEstado.fogo ? 3 : 1,
                    ),
                  ],
                ),
              ),
              if (widget.estado == StreakEstado.fogo)
                ..._particulasFogo(t, widget.size),
              Transform.scale(
                scale: 0.94 + 0.06 * t,
                child: Icon(
                  widget.icon,
                  color: Color.lerp(
                    widget.color,
                    widget.estado == StreakEstado.fogo
                        ? const Color(0xFFFFAB40)
                        : Colors.white,
                    0.35 * t,
                  ),
                  size: widget.size,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _particulasFogo(double t, double size) {
    return List.generate(3, (i) {
      final phase = (t + i * 0.33) % 1.0;
      final dy = -4 - phase * 10;
      final dx = (i - 1) * 6.0;
      return Positioned(
        top: size * 0.2 + dy,
        left: size * 0.5 + dx - 2,
        child: Opacity(
          opacity: (1 - phase).clamp(0.0, 1.0) * 0.7,
          child: Icon(
            Icons.circle,
            size: 3 + phase * 2,
            color: const Color(0xFFFFD54F),
          ),
        ),
      );
    });
  }
}

// ─── Bordas laterais (sheet de detalhes) ─────────────────────────

class _StreakScreenEdgeEffect extends StatefulWidget {
  final StreakEstado estado;

  const _StreakScreenEdgeEffect({required this.estado});

  @override
  State<_StreakScreenEdgeEffect> createState() =>
      _StreakScreenEdgeEffectState();
}

class _StreakScreenEdgeEffectState extends State<_StreakScreenEdgeEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isFogo = widget.estado == StreakEstado.fogo;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final wave = 0.5 + 0.5 * math.sin(_ctrl.value * 2 * math.pi);
        final wave2 = 0.5 + 0.5 * math.sin(_ctrl.value * 2 * math.pi + 1.2);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _edgeStrip(isFogo: isFogo, intensity: wave, mirror: false),
            const Spacer(),
            _edgeStrip(isFogo: isFogo, intensity: wave2, mirror: true),
          ],
        );
      },
    );
  }

  Widget _edgeStrip({
    required bool isFogo,
    required double intensity,
    required bool mirror,
  }) {
    const width = 36.0;

    if (isFogo) {
      return Container(
        width: width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: mirror ? Alignment.centerRight : Alignment.centerLeft,
            end: mirror ? Alignment.centerLeft : Alignment.centerRight,
            colors: [
              Color.lerp(
                const Color(0xFFFF5722),
                const Color(0xFFFFD54F),
                intensity * 0.5,
              )!.withValues(alpha: 0.55 + 0.35 * intensity),
              Color.lerp(
                const Color(0xFFFF9800),
                const Color(0xFFFFEB3B),
                intensity * 0.3,
              )!.withValues(alpha: 0.2 + 0.15 * intensity),
              Colors.transparent,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color:
                  const Color(0xFFFF6D00).withValues(alpha: 0.35 * intensity),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: mirror ? Alignment.centerRight : Alignment.centerLeft,
                end: mirror ? Alignment.centerLeft : Alignment.centerRight,
                colors: [
                  Color.lerp(
                    const Color(0xFF81D4FA),
                    const Color(0xFFE1F5FE),
                    intensity * 0.6,
                  )!.withValues(alpha: 0.5 + 0.3 * intensity),
                  const Color(0xFF4FC3F7)
                      .withValues(alpha: 0.15 + 0.12 * intensity),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF29B6F6)
                      .withValues(alpha: 0.25 * intensity),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          CustomPaint(
            painter: _FrostEdgePainter(intensity: intensity, mirror: mirror),
          ),
        ],
      ),
    );
  }
}

class _FrostEdgePainter extends CustomPainter {
  final double intensity;
  final bool mirror;

  _FrostEdgePainter({required this.intensity, required this.mirror});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final rng = math.Random(7);

    for (int i = 0; i < 18; i++) {
      final y = rng.nextDouble() * size.height;
      final r = 1.5 + rng.nextDouble() * 2.5;
      final x = mirror
          ? size.width - 4 - rng.nextDouble() * 8
          : 4 + rng.nextDouble() * 8;
      paint.color = Colors.white.withValues(
        alpha: (0.15 + 0.25 * intensity) * rng.nextDouble(),
      );
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_FrostEdgePainter old) =>
      old.intensity != intensity || old.mirror != mirror;
}
