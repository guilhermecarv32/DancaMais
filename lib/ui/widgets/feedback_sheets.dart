import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../logic/feedback/feedback_service.dart';
import '../../models/turma_model.dart';
import 'tap_effect.dart';

const _maxLen = FeedbackService.maxCaracteres;

void showFeedbackParaAlunoSheet(
  BuildContext context, {
  required String alunoId,
  required String alunoNome,
  required TurmaModel turma,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EnviarFeedbackSheet(
      titulo: 'Feedback para $alunoNome',
      subtitulo: turma.nome,
      onEnviar: (texto, {tambemValidar = false}) => FeedbackService().enviarParaAluno(
        alunoId: alunoId,
        turmaId: turma.id,
        turmaNome: turma.nome,
        texto: texto,
      ),
    ),
  );
}

void showFeedbackParaTurmaSheet(BuildContext context, {required TurmaModel turma}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EnviarFeedbackSheet(
      titulo: 'Feedback para a turma',
      subtitulo: '${turma.nome} · todos os alunos',
      onEnviar: (texto, {tambemValidar = false}) => FeedbackService().enviarParaTurma(
        turmaId: turma.id,
        turmaNome: turma.nome,
        texto: texto,
      ),
    ),
  );
}

void showFeedbackPassoSheet(
  BuildContext context, {
  required String alunoId,
  required String alunoNome,
  required String movimentacaoId,
  String? movimentacaoNome,
  required bool jaValidado,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EnviarFeedbackSheet(
      titulo: 'Feedback — $alunoNome',
      subtitulo: movimentacaoNome ?? 'Passo da semana',
      mostrarCheckboxValidar: !jaValidado,
      onEnviar: (texto, {bool tambemValidar = false}) =>
          FeedbackService().enviarPorMovimentacao(
        alunoId: alunoId,
        movimentacaoId: movimentacaoId,
        movimentacaoNome: movimentacaoNome,
        texto: texto,
        tambemValidar: tambemValidar,
      ),
    ),
  );
}

typedef EnviarFeedbackFn = Future<String?> Function(
  String texto, {
  bool tambemValidar,
});

class _EnviarFeedbackSheet extends StatefulWidget {
  final String titulo;
  final String? subtitulo;
  final EnviarFeedbackFn onEnviar;
  final bool mostrarCheckboxValidar;

  const _EnviarFeedbackSheet({
    required this.titulo,
    required this.onEnviar,
    this.subtitulo,
    this.mostrarCheckboxValidar = false,
  });

  @override
  State<_EnviarFeedbackSheet> createState() => _EnviarFeedbackSheetState();
}

class _EnviarFeedbackSheetState extends State<_EnviarFeedbackSheet> {
  final _ctrl = TextEditingController();
  bool _tambemValidar = false;
  bool _enviando = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    final erro = await widget.onEnviar(
      _ctrl.text,
      tambemValidar: _tambemValidar,
    );
    if (!mounted) return;
    setState(() => _enviando = false);
    if (erro != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(erro)));
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Feedback enviado!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final len = _ctrl.text.length;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
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
              Text(
                widget.titulo,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.secondary,
                ),
              ),
              if (widget.subtitulo != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.subtitulo!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _ctrl,
                maxLines: 5,
                maxLength: _maxLen,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Escreva seu feedback (máx. $_maxLen caracteres)',
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$len / $_maxLen',
                  style: TextStyle(
                    color: len > _maxLen ? Colors.red : Colors.grey[500],
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.mostrarCheckboxValidar) ...[
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _tambemValidar,
                  activeColor: AppTheme.primary,
                  title: const Text(
                    'Também validar este passo',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: const Text(
                    'Concede +100 XP ao aluno',
                    style: TextStyle(fontSize: 12),
                  ),
                  onChanged: (v) => setState(() => _tambemValidar = v == true),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: _enviando || len == 0 || len > _maxLen ? null : _enviar,
                  child: _enviando
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Enviar feedback'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botão compacto de feedback (lista de alunos / validação).
class FeedbackIconButton extends StatelessWidget {
  final VoidCallback onTap;
  const FeedbackIconButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TapEffect(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.rate_review_rounded, size: 16, color: AppTheme.primary),
            SizedBox(width: 4),
            Text(
              'Feedback',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
