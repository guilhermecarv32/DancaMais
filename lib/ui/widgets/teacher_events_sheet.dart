import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'tap_effect.dart';

Future<void> showTeacherEventsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _TeacherEventsSheetBody(),
  );
}

enum _EventosViewMode { lista, meses }

enum _OrdenacaoEventos { dataAsc, dataDesc, nomeAsc, nomeDesc }

class _TeacherEventsSheetBody extends StatefulWidget {
  const _TeacherEventsSheetBody();

  @override
  State<_TeacherEventsSheetBody> createState() =>
      _TeacherEventsSheetBodyState();
}

class _TeacherEventsSheetBodyState extends State<_TeacherEventsSheetBody>
    with SingleTickerProviderStateMixin {
  _EventosViewMode _mode = _EventosViewMode.lista;
  _OrdenacaoEventos _ord = _OrdenacaoEventos.dataAsc;
  int _ano = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Material(
          color: AppTheme.background,
          child: SizedBox(
            height: media.size.height * 0.92,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  _Header(
                    mode: _mode,
                    onModeChanged: (m) => setState(() => _mode = m),
                    ord: _ord,
                    onOrdChanged: (o) => setState(() => _ord = o),
                    ano: _ano,
                    onAnoChanged: (a) => setState(() => _ano = a),
                    onNovo: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => _NovoEventoSheet(uid: uid),
                    ),
                  ),
                  Expanded(
                    child: _mode == _EventosViewMode.lista
                        ? _EventosLista(uid: uid, ord: _ord)
                        : _EventosMeses(uid: uid, ano: _ano),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final _EventosViewMode mode;
  final void Function(_EventosViewMode) onModeChanged;
  final _OrdenacaoEventos ord;
  final void Function(_OrdenacaoEventos) onOrdChanged;
  final int ano;
  final void Function(int) onAnoChanged;
  final VoidCallback onNovo;

  const _Header({
    required this.mode,
    required this.onModeChanged,
    required this.ord,
    required this.onOrdChanged,
    required this.ano,
    required this.onAnoChanged,
    required this.onNovo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 14, 25, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Eventos',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.secondary,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      'Crie e acompanhe eventos da escola',
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  ],
                ),
              ),
              TapEffect(
                onTap: onNovo,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text('Novo',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ModeToggle(
                  value: mode,
                  onChanged: onModeChanged,
                ),
              ),
              const SizedBox(width: 10),
              if (mode == _EventosViewMode.lista)
                _OrdenacaoDropdown(value: ord, onChanged: onOrdChanged)
              else
                _AnoPicker(ano: ano, onAnoChanged: onAnoChanged),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final _EventosViewMode value;
  final void Function(_EventosViewMode) onChanged;
  const _ModeToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, _EventosViewMode v, IconData icon) {
      final sel = v == value;
      return Expanded(
        child: TapEffect(
          onTap: () => onChanged(v),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: sel ? AppTheme.primary : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: sel ? AppTheme.primary : Colors.grey.withOpacity(0.20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(sel ? 0.07 : 0.03),
                  blurRadius: sel ? 12 : 8,
                  offset: const Offset(0, 3),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 16, color: sel ? Colors.white : Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: sel ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip('Lista', _EventosViewMode.lista, Icons.view_list_rounded),
        const SizedBox(width: 10),
        chip('Meses', _EventosViewMode.meses, Icons.calendar_month_rounded),
      ],
    );
  }
}

class _OrdenacaoDropdown extends StatelessWidget {
  final _OrdenacaoEventos value;
  final void Function(_OrdenacaoEventos) onChanged;
  const _OrdenacaoDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    String label(_OrdenacaoEventos o) {
      switch (o) {
        case _OrdenacaoEventos.dataAsc:
          return 'Data ↑';
        case _OrdenacaoEventos.dataDesc:
          return 'Data ↓';
        case _OrdenacaoEventos.nomeAsc:
          return 'Nome A→Z';
        case _OrdenacaoEventos.nomeDesc:
          return 'Nome Z→A';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.18)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_OrdenacaoEventos>(
          value: value,
          items: _OrdenacaoEventos.values
              .map((o) => DropdownMenuItem(
                    value: o,
                    child: Text(label(o),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _AnoPicker extends StatelessWidget {
  final int ano;
  final void Function(int) onAnoChanged;
  const _AnoPicker({required this.ano, required this.onAnoChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TapEffect(
            onTap: () => onAnoChanged(ano - 1),
            child: Icon(Icons.chevron_left_rounded,
                size: 20, color: Colors.grey[700]),
          ),
          const SizedBox(width: 8),
          Text(
            '$ano',
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: AppTheme.secondary),
          ),
          const SizedBox(width: 8),
          TapEffect(
            onTap: () => onAnoChanged(ano + 1),
            child: Icon(Icons.chevron_right_rounded,
                size: 20, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

class _EventosLista extends StatelessWidget {
  final String uid;
  final _OrdenacaoEventos ord;
  const _EventosLista({required this.uid, required this.ord});

  void _abrirOpcoes(BuildContext context, _EventoVm evento) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EventoOpcoesSheet(evento: evento, uid: uid),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('eventos')
          .where('criadoPorId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final eventos = docs.map((d) {
          final m = d.data() as Map<String, dynamic>;
          final nome = (m['nome'] as String?)?.trim() ?? '';
          final desc = (m['descricao'] as String?)?.trim() ?? '';
          final loc = (m['localizacao'] as String?)?.trim() ?? '';
          final ts = m['dataHora'] as Timestamp?;
          final dt = ts?.toDate();
          return _EventoVm(
            id: d.id,
            nome: nome.isEmpty ? 'Evento' : nome,
            descricao: desc,
            localizacao: loc,
            dataHora: dt,
          );
        }).toList();

        int cmpData(_EventoVm a, _EventoVm b) {
          final da = a.dataHora ?? DateTime.fromMillisecondsSinceEpoch(0);
          final db = b.dataHora ?? DateTime.fromMillisecondsSinceEpoch(0);
          return da.compareTo(db);
        }

        int cmpNome(_EventoVm a, _EventoVm b) =>
            a.nome.toLowerCase().compareTo(b.nome.toLowerCase());

        switch (ord) {
          case _OrdenacaoEventos.dataAsc:
            eventos.sort(cmpData);
          case _OrdenacaoEventos.dataDesc:
            eventos.sort((a, b) => cmpData(b, a));
          case _OrdenacaoEventos.nomeAsc:
            eventos.sort(cmpNome);
          case _OrdenacaoEventos.nomeDesc:
            eventos.sort((a, b) => cmpNome(b, a));
        }

        if (eventos.isEmpty) {
          return const _EmptyEventos();
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(25, 10, 25, 25),
          itemCount: eventos.length,
          itemBuilder: (_, i) => TapEffect(
            onTap: () => _abrirOpcoes(context, eventos[i]),
            child: _EventoTile(evento: eventos[i]),
          ),
        );
      },
    );
  }
}

class _EventosMeses extends StatelessWidget {
  final String uid;
  final int ano;
  const _EventosMeses({required this.uid, required this.ano});

  @override
  Widget build(BuildContext context) {
    final start = DateTime(ano, 1, 1, 0, 0, 0);
    final end = DateTime(ano, 12, 31, 23, 59, 59);
    final meses = const [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('eventos')
          .where('criadoPorId', isEqualTo: uid)
          .where('dataHora', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('dataHora', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final porMes = <int, List<_EventoVm>>{
          for (int m = 1; m <= 12; m++) m: []
        };

        for (final d in docs) {
          final m = d.data() as Map<String, dynamic>;
          final nome = (m['nome'] as String?)?.trim() ?? '';
          final desc = (m['descricao'] as String?)?.trim() ?? '';
          final loc = (m['localizacao'] as String?)?.trim() ?? '';
          final ts = m['dataHora'] as Timestamp?;
          final dt = ts?.toDate();
          if (dt == null) continue;
          porMes[dt.month]?.add(_EventoVm(
            id: d.id,
            nome: nome.isEmpty ? 'Evento' : nome,
            descricao: desc,
            localizacao: loc,
            dataHora: dt,
          ));
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(25, 10, 25, 25),
          itemCount: 12,
          itemBuilder: (_, i) {
            final mesIdx = i + 1;
            final lista = porMes[mesIdx] ?? [];
            lista.sort((a, b) => (a.dataHora ?? DateTime(1900))
                .compareTo(b.dataHora ?? DateTime(1900)));
            return _MesSection(
              titulo: '${meses[i]} / $ano',
              eventos: lista,
            );
          },
        );
      },
    );
  }
}

class _MesSection extends StatelessWidget {
  final String titulo;
  final List<_EventoVm> eventos;
  const _MesSection({required this.titulo, required this.eventos});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        collapsedIconColor: Colors.grey[500],
        iconColor: Colors.grey[500],
        title: Text(
          titulo,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            color: AppTheme.secondary,
          ),
        ),
        subtitle: Text(
          eventos.isEmpty ? 'Nenhum evento' : '${eventos.length} evento(s)',
          style: TextStyle(color: Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w600),
        ),
        children: eventos.isEmpty
            ? [
                Row(
                  children: [
                    const Icon(Icons.event_busy_rounded, size: 18, color: Colors.grey),
                    const SizedBox(width: 10),
                    Text('Nada por aqui.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                )
              ]
            : eventos
                .map((e) => TapEffect(
                      onTap: () => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => _EventoOpcoesSheet(evento: e, uid: null),
                      ),
                      child: _EventoMiniTile(evento: e),
                    ))
                .toList(),
      ),
    );
  }
}

class _EventoOpcoesSheet extends StatelessWidget {
  final _EventoVm evento;
  final String? uid; // quando null, usa apenas edição/remoção (sem depender do uid)

  const _EventoOpcoesSheet({required this.evento, required this.uid});

  Future<void> _confirmarExcluir(BuildContext context) async {
    final ok = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Excluir evento?'),
            content: Text('"${evento.nome}" será excluído permanentemente.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Excluir', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;
    if (!ok) return;

    await FirebaseFirestore.instance.collection('eventos').doc(evento.id).delete();
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('🗑️ Evento excluído.'),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _abrirEditar(BuildContext context) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditarEventoSheet(evento: evento),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 18, 25, 25),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(
              evento.nome,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(height: 16),
            TapEffect(
              onTap: () => _abrirEditar(context),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_rounded,
                        color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text('Editar',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ]),
              ),
            ),
            const Divider(height: 8),
            TapEffect(
              onTap: () => _confirmarExcluir(context),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        color: Colors.redAccent, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text('Excluir',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.redAccent)),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditarEventoSheet extends StatefulWidget {
  final _EventoVm evento;
  const _EditarEventoSheet({required this.evento});

  @override
  State<_EditarEventoSheet> createState() => _EditarEventoSheetState();
}

class _EditarEventoSheetState extends State<_EditarEventoSheet> {
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _locCtrl;
  DateTime? _dataHora;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.evento.nome);
    _descCtrl = TextEditingController(text: widget.evento.descricao);
    _locCtrl = TextEditingController(text: widget.evento.localizacao);
    _dataHora = widget.evento.dataHora;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  String _formatarDataHora(DateTime d) {
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    final hora = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${d.year} • $hora:$min';
  }

  Future<void> _selecionarDataHora() async {
    final agora = DateTime.now();
    final base = _dataHora ?? agora;
    final data = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      helpText: 'Selecione a data do evento',
    );
    if (data == null) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      helpText: 'Selecione o horário',
    );
    if (hora == null) return;
    setState(() {
      _dataHora =
          DateTime(data.year, data.month, data.day, hora.hour, hora.minute);
    });
  }

  Future<void> _salvar() async {
    final nome = _nomeCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final loc = _locCtrl.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do evento.')),
      );
      return;
    }
    if (_dataHora == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a data e hora do evento.')),
      );
      return;
    }

    setState(() => _salvando = true);
    await FirebaseFirestore.instance.collection('eventos').doc(widget.evento.id).update({
      'nome': nome,
      'descricao': desc,
      'localizacao': loc,
      'dataHora': Timestamp.fromDate(_dataHora!),
      'atualizadoEm': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Evento atualizado!'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(25, 20, 25, 25 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
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
            const Text(
              'Editar evento',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(height: 14),
            _Input(
              controller: _nomeCtrl,
              hint: 'Nome do evento',
              icon: Icons.drive_file_rename_outline_rounded,
            ),
            const SizedBox(height: 12),
            _Input(
              controller: _descCtrl,
              hint: 'Descrição (opcional)',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _Input(
              controller: _locCtrl,
              hint: 'Localização (opcional)',
              icon: Icons.place_outlined,
            ),
            const SizedBox(height: 12),
            TapEffect(
              onTap: _selecionarDataHora,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded,
                        color: AppTheme.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _dataHora == null
                            ? 'Data e hora'
                            : _formatarDataHora(_dataHora!),
                        style: TextStyle(
                          color: _dataHora == null
                              ? Colors.grey[500]
                              : AppTheme.secondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _salvando
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Salvar alterações',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventoMiniTile extends StatelessWidget {
  final _EventoVm evento;
  const _EventoMiniTile({required this.evento});

  @override
  Widget build(BuildContext context) {
    final dt = evento.dataHora;
    final dia = dt == null ? '--' : dt.day.toString().padLeft(2, '0');
    final hora = dt == null
        ? '—'
        : '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                dia,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(evento.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppTheme.secondary)),
                const SizedBox(height: 3),
                Text('Evento · $hora',
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventoTile extends StatelessWidget {
  final _EventoVm evento;
  const _EventoTile({required this.evento});

  @override
  Widget build(BuildContext context) {
    final dt = evento.dataHora;
    final dataStr = dt == null
        ? 'Sem data'
        : '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final horaStr = dt == null
        ? '—'
        : '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    final loc = evento.localizacao.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.event_rounded, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(evento.nome,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: AppTheme.secondary)),
                const SizedBox(height: 4),
                Text(
                  loc.isEmpty
                      ? 'Evento · $dataStr · $horaStr'
                      : 'Evento · $dataStr · $horaStr · $loc',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
                if (evento.descricao.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    evento.descricao.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[700], fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyEventos extends StatelessWidget {
  const _EmptyEventos();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_busy_rounded, size: 52, color: Colors.grey[300]),
            const SizedBox(height: 12),
            const Text(
              'Nenhum evento ainda.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Toque em "Novo" para cadastrar o primeiro.',
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EventoVm {
  final String id;
  final String nome;
  final String descricao;
  final String localizacao;
  final DateTime? dataHora;
  _EventoVm({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.localizacao,
    required this.dataHora,
  });
}

class _NovoEventoSheet extends StatefulWidget {
  final String uid;
  const _NovoEventoSheet({required this.uid});

  @override
  State<_NovoEventoSheet> createState() => _NovoEventoSheetState();
}

class _NovoEventoSheetState extends State<_NovoEventoSheet> {
  final _nomeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locCtrl = TextEditingController();
  DateTime? _dataHora;
  bool _salvando = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _descCtrl.dispose();
    _locCtrl.dispose();
    super.dispose();
  }

  String _formatarDataHora(DateTime d) {
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    final hora = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dia/$mes/${d.year} • $hora:$min';
  }

  Future<void> _selecionarDataHora() async {
    final agora = DateTime.now();
    final base = _dataHora ?? agora;
    final data = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2100, 12, 31),
      helpText: 'Selecione a data do evento',
    );
    if (data == null) return;
    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      helpText: 'Selecione o horário',
    );
    if (hora == null) return;
    setState(() {
      _dataHora = DateTime(data.year, data.month, data.day, hora.hour, hora.minute);
    });
  }

  Future<void> _salvar() async {
    final nome = _nomeCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final loc = _locCtrl.text.trim();
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe o nome do evento.')),
      );
      return;
    }
    if (_dataHora == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione a data e hora do evento.')),
      );
      return;
    }

    setState(() => _salvando = true);
    final ref = FirebaseFirestore.instance.collection('eventos').doc();
    await ref.set({
      'nome': nome,
      'descricao': desc,
      'localizacao': loc,
      'dataHora': Timestamp.fromDate(_dataHora!),
      'criadoPorId': widget.uid,
      'criadoEm': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Evento criado!'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(25, 20, 25, 25 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
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
            const Text(
              'Novo evento',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.secondary,
              ),
            ),
            const SizedBox(height: 14),
            _Input(
              controller: _nomeCtrl,
              hint: 'Nome do evento',
              icon: Icons.drive_file_rename_outline_rounded,
            ),
            const SizedBox(height: 12),
            _Input(
              controller: _descCtrl,
              hint: 'Descrição (opcional)',
              icon: Icons.notes_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            _Input(
              controller: _locCtrl,
              hint: 'Localização (opcional)',
              icon: Icons.place_outlined,
            ),
            const SizedBox(height: 12),
            TapEffect(
              onTap: _selecionarDataHora,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, color: AppTheme.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _dataHora == null ? 'Data e hora' : _formatarDataHora(_dataHora!),
                        style: TextStyle(
                          color: _dataHora == null ? Colors.grey[500] : AppTheme.secondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _salvando
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Criar evento',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;
  const _Input({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          icon: Icon(icon, color: AppTheme.primary, size: 18),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          border: InputBorder.none,
        ),
      ),
    );
  }
}

