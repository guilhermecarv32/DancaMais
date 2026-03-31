import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../widgets/tap_effect.dart';

class StudentEventsScreen extends StatefulWidget {
  const StudentEventsScreen({super.key});

  @override
  State<StudentEventsScreen> createState() => _StudentEventsScreenState();
}

enum _EventosViewMode { lista, meses }

enum _OrdenacaoEventos { dataAsc, dataDesc, nomeAsc, nomeDesc }

class _StudentEventsScreenState extends State<StudentEventsScreen>
    with SingleTickerProviderStateMixin {
  _EventosViewMode _mode = _EventosViewMode.lista;
  _OrdenacaoEventos _ord = _OrdenacaoEventos.dataAsc;
  int _ano = DateTime.now().year;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(
              mode: _mode,
              onModeChanged: (m) => setState(() => _mode = m),
              ord: _ord,
              onOrdChanged: (o) => setState(() => _ord = o),
              ano: _ano,
              onAnoChanged: (a) => setState(() => _ano = a),
            ),
            Expanded(
              child: _mode == _EventosViewMode.lista
                  ? _EventosLista(ord: _ord)
                  : _EventosMeses(ano: _ano),
            ),
          ],
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

  const _Header({
    required this.mode,
    required this.onModeChanged,
    required this.ord,
    required this.onOrdChanged,
    required this.ano,
    required this.onAnoChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 25, 25, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TapEffect(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_back_rounded,
                        color: AppTheme.secondary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      'Calendário completo de eventos',
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _ModeToggle(value: mode, onChanged: onModeChanged)),
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
  final _OrdenacaoEventos ord;
  const _EventosLista({required this.ord});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('eventos').snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final eventos = docs.map((d) {
          final m = d.data() as Map<String, dynamic>;
          final nome = (m['nome'] as String?)?.trim() ?? '';
          final desc = (m['descricao'] as String?)?.trim() ?? '';
          final ts = m['dataHora'] as Timestamp?;
          final dt = ts?.toDate();
          return _EventoVm(
            id: d.id,
            nome: nome.isEmpty ? 'Evento' : nome,
            descricao: desc,
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

        if (eventos.isEmpty) return const _EmptyEventos();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(25, 10, 25, 25),
          itemCount: eventos.length,
          itemBuilder: (_, i) => _EventoTile(evento: eventos[i]),
        );
      },
    );
  }
}

class _EventosMeses extends StatelessWidget {
  final int ano;
  const _EventosMeses({required this.ano});

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
          final ts = m['dataHora'] as Timestamp?;
          final dt = ts?.toDate();
          if (dt == null) continue;
          porMes[dt.month]?.add(_EventoVm(
            id: d.id,
            nome: nome.isEmpty ? 'Evento' : nome,
            descricao: desc,
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
            : eventos.map((e) => _EventoMiniTile(evento: e)).toList(),
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
                  'Evento · $dataStr · $horaStr',
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
              'Quando houver eventos cadastrados, eles aparecerão aqui.',
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
  final DateTime? dataHora;
  _EventoVm({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.dataHora,
  });
}

