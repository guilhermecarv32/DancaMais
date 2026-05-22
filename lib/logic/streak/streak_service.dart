import 'package:cloud_firestore/cloud_firestore.dart';

/// Estado visual da streak do aluno.
enum StreakEstado { fogo, gelo, neutro }

/// Resultado do cálculo de streak.
class StreakSnapshot {
  final StreakEstado estado;
  final int streakFogo;
  final int streakGelo;
  final DateTime? ultimaAtividadeAprendidoEm;

  const StreakSnapshot({
    required this.estado,
    required this.streakFogo,
    required this.streakGelo,
    this.ultimaAtividadeAprendidoEm,
  });

  static const neutro = StreakSnapshot(
    estado: StreakEstado.neutro,
    streakFogo: 0,
    streakGelo: 0,
  );
}

/// Configuração global de pausa de streaks (escola/config).
class EscolaStreakConfig {
  final bool pausados;
  final DateTime? retomarEm;
  final DateTime? pausadosDesde;

  const EscolaStreakConfig({
    this.pausados = false,
    this.retomarEm,
    this.pausadosDesde,
  });

  factory EscolaStreakConfig.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const EscolaStreakConfig();
    return EscolaStreakConfig(
      pausados: data['streaksPausados'] == true,
      retomarEm: _ts(data['streaksRetomarEm']),
      pausadosDesde: _ts(data['streaksPausadosDesde']),
    );
  }

  static DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }
}

/// Cálculo e persistência de streaks fogo/gelo (especificação v1 — fase 3).
class StreakService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static int mesReferencia(DateTime d) => d.year * 100 + d.month;

  /// Início dos últimos 7 dias corridos (inclui hoje), fuso local.
  static DateTime inicioJanela7Dias(DateTime agora) {
    final hoje = DateTime(agora.year, agora.month, agora.day);
    return hoje.subtract(const Duration(days: 6));
  }

  static int chaveSemana(DateTime d) {
    final local = DateTime(d.year, d.month, d.day);
    final monday = local.subtract(Duration(days: local.weekday - 1));
    return monday.year * 10000 + monday.month * 100 + monday.day;
  }

  static int semanaAnterior(int chave) {
    final y = chave ~/ 10000;
    final m = (chave % 10000) ~/ 100;
    final day = chave % 100;
    final monday = DateTime(y, m, day).subtract(const Duration(days: 7));
    return chaveSemana(monday);
  }

  /// Calcula streak a partir das datas de `aprendido` (somente esse status).
  StreakSnapshot calcular({
    required List<DateTime> datasAprendido,
    required DateTime agora,
    EscolaStreakConfig escola = const EscolaStreakConfig(),
    Map<String, dynamic>? usuarioAtual,
  }) {
    if (escola.pausados) {
      return _lerSnapshotSalvo(usuarioAtual);
    }

    final pausaAte = _ts(usuarioAtual?['pausaStreakAte']);
    if (pausaAte != null && agora.isBefore(pausaAte)) {
      return _lerSnapshotSalvo(usuarioAtual);
    }

    if (datasAprendido.isEmpty) {
      return StreakSnapshot.neutro;
    }

    final inicio7 = inicioJanela7Dias(agora);
    final fimHoje = DateTime(agora.year, agora.month, agora.day, 23, 59, 59);

    final hasRolling7 = datasAprendido.any((d) {
      final day = DateTime(d.year, d.month, d.day);
      return !day.isBefore(inicio7) && !day.isAfter(fimHoje);
    });

    final semanasComAtividade = <int>{};
    for (final d in datasAprendido) {
      semanasComAtividade.add(chaveSemana(d));
    }

    var semanasAtivas = 0;
    var w = chaveSemana(agora);
    while (semanasComAtividade.contains(w)) {
      semanasAtivas++;
      w = semanaAnterior(w);
    }

    var semanasInativas = 0;
    w = chaveSemana(agora);
    while (!semanasComAtividade.contains(w)) {
      semanasInativas++;
      w = semanaAnterior(w);
      if (semanasInativas > 104) break;
    }

    DateTime? ultima;
    for (final d in datasAprendido) {
      if (ultima == null || d.isAfter(ultima)) ultima = d;
    }

    if (hasRolling7) {
      return StreakSnapshot(
        estado: StreakEstado.fogo,
        streakFogo: semanasAtivas < 1 ? 1 : semanasAtivas,
        streakGelo: 0,
        ultimaAtividadeAprendidoEm: ultima,
      );
    }

    if (semanasInativas >= 2) {
      return StreakSnapshot(
        estado: StreakEstado.gelo,
        streakFogo: 0,
        streakGelo: semanasInativas,
        ultimaAtividadeAprendidoEm: ultima,
      );
    }

    return StreakSnapshot(
      estado: StreakEstado.neutro,
      streakFogo: 0,
      streakGelo: 0,
      ultimaAtividadeAprendidoEm: ultima,
    );
  }

  StreakSnapshot _lerSnapshotSalvo(Map<String, dynamic>? data) {
    if (data == null) return StreakSnapshot.neutro;
    final estadoStr = (data['streakEstado'] as String?) ?? 'neutro';
    final estado = switch (estadoStr) {
      'fogo' => StreakEstado.fogo,
      'gelo' => StreakEstado.gelo,
      _ => StreakEstado.neutro,
    };
    return StreakSnapshot(
      estado: estado,
      streakFogo: (data['streakFogo'] as num?)?.toInt() ?? 0,
      streakGelo: (data['streakGelo'] as num?)?.toInt() ?? 0,
      ultimaAtividadeAprendidoEm: _ts(data['ultimaAtividadeAprendidoEm']),
    );
  }

  static DateTime? _ts(dynamic v) {
    if (v is Timestamp) return v.toDate();
    return null;
  }

  static String estadoParaFirestore(StreakEstado e) => switch (e) {
        StreakEstado.fogo => 'fogo',
        StreakEstado.gelo => 'gelo',
        StreakEstado.neutro => 'neutro',
      };

  Future<EscolaStreakConfig> lerConfigEscola() async {
    final snap = await _db.collection('escola').doc('config').get();
    await _aplicarRetomadaAutomatica(snap);
    final refreshed = await _db.collection('escola').doc('config').get();
    return EscolaStreakConfig.fromMap(
      refreshed.data() as Map<String, dynamic>?,
    );
  }

  Stream<EscolaStreakConfig> configEscolaStream() {
    return _db.collection('escola').doc('config').snapshots().asyncMap(
      (snap) async {
        await _aplicarRetomadaAutomatica(snap);
        return EscolaStreakConfig.fromMap(
          snap.data() as Map<String, dynamic>?,
        );
      },
    );
  }

  Future<void> _aplicarRetomadaAutomatica(
      DocumentSnapshot<Map<String, dynamic>> snap) async {
    final data = snap.data();
    if (data == null || data['streaksPausados'] != true) return;
    final retomar = _ts(data['streaksRetomarEm']);
    if (retomar == null || DateTime.now().isBefore(retomar)) return;

    await _db.collection('escola').doc('config').update({
      'streaksPausados': false,
      'streaksRetomarEm': FieldValue.delete(),
    });
  }

  Future<List<DateTime>> _datasAprendido(String alunoId) async {
    final snap = await _db
        .collection('progressoAluno')
        .where('alunoId', isEqualTo: alunoId)
        .where('status', isEqualTo: 'aprendido')
        .get();

    final datas = <DateTime>[];
    for (final doc in snap.docs) {
      final d = doc.data();
      final ts = d['dataAprendido'];
      if (ts is Timestamp) datas.add(ts.toDate());
    }
    return datas;
  }

  Future<void> recalcularEGravar(String alunoId) async {
    final escola = await lerConfigEscola();
    if (escola.pausados) return;

    final userSnap = await _db.collection('usuarios').doc(alunoId).get();
    final userData = userSnap.data();
    final pausaAte = _ts(userData?['pausaStreakAte']);
    if (pausaAte != null && DateTime.now().isBefore(pausaAte)) {
      return;
    }

    final datas = await _datasAprendido(alunoId);
    final snap = calcular(
      datasAprendido: datas,
      agora: DateTime.now(),
      escola: escola,
      usuarioAtual: userData,
    );

    final update = <String, dynamic>{
      'streakEstado': estadoParaFirestore(snap.estado),
      'streakFogo': snap.streakFogo,
      'streakGelo': snap.streakGelo,
      'streaksCalculadoEm': FieldValue.serverTimestamp(),
    };
    if (snap.ultimaAtividadeAprendidoEm != null) {
      update['ultimaAtividadeAprendidoEm'] =
          Timestamp.fromDate(snap.ultimaAtividadeAprendidoEm!);
    }

    await _db.collection('usuarios').doc(alunoId).update(update);
  }

  /// Pausa pessoal: 7 dias, 1× por mês civil, privada.
  Future<String?> ativarPausaPessoal(String alunoId) async {
    final escola = await lerConfigEscola();
    if (escola.pausados) {
      return 'As streaks estão pausadas pela escola no momento.';
    }

    final ref = _db.collection('usuarios').doc(alunoId);
    final snap = await ref.get();
    final data = snap.data() ?? {};
    final mesAtual = mesReferencia(DateTime.now());
    final ultimoMes = (data['ultimaPausaStreakMes'] as num?)?.toInt();
    if (ultimoMes == mesAtual) {
      return 'Você já usou sua pausa pessoal este mês.';
    }

    final pausaAte = _ts(data['pausaStreakAte']);
    if (pausaAte != null && DateTime.now().isBefore(pausaAte)) {
      return 'Sua pausa pessoal já está ativa.';
    }

    final ate = DateTime.now().add(const Duration(days: 7));
    await ref.update({
      'pausaStreakAte': Timestamp.fromDate(ate),
      'ultimaPausaStreakMes': mesAtual,
      'pausasStreakUsadasNoMes': 1,
    });
    return null;
  }

  Future<void> pausarStreaksEscola({
    DateTime? retomarEm,
  }) async {
    final update = <String, dynamic>{
      'streaksPausados': true,
      'streaksPausadosDesde': FieldValue.serverTimestamp(),
    };
    if (retomarEm != null) {
      update['streaksRetomarEm'] = Timestamp.fromDate(retomarEm);
    } else {
      update['streaksRetomarEm'] = FieldValue.delete();
    }
    await _db.collection('escola').doc('config').set(update, SetOptions(merge: true));
  }

  Future<void> retomarStreaksEscola() async {
    await _db.collection('escola').doc('config').set({
      'streaksPausados': false,
      'streaksRetomarEm': FieldValue.delete(),
      'streaksPausadosDesde': FieldValue.delete(),
    }, SetOptions(merge: true));
  }

  /// IDs de alunos inscritos em turmas das modalidades do professor.
  Future<Set<String>> alunosNoEscopoProfessor({
    required List<String>? modalidadesFiltro,
  }) async {
    Query<Map<String, dynamic>> turmasQ =
        _db.collection('turmas');
    final turmasSnap = await turmasQ.get();
    final turmaIds = <String>{};
    for (final t in turmasSnap.docs) {
      final mod = (t.data()['modalidade'] as String?) ?? '';
      if (modalidadesFiltro == null || modalidadesFiltro.contains(mod)) {
        turmaIds.add(t.id);
      }
    }
    if (turmaIds.isEmpty) return {};

    final inscSnap = await _db.collection('inscricoes').get();
    final alunoIds = <String>{};
    for (final d in inscSnap.docs) {
      final data = d.data();
      if (turmaIds.contains(data['turmaId'])) {
        final aid = data['alunoId'] as String?;
        if (aid != null && aid.isNotEmpty) alunoIds.add(aid);
      }
    }
    return alunoIds;
  }

  /// Alertas de streak para o sininho do professor.
  Future<List<StreakAlertaProfessor>> listarAlertasProfessor({
    required List<String>? modalidadesFiltro,
  }) async {
    final alunoIds =
        await alunosNoEscopoProfessor(modalidadesFiltro: modalidadesFiltro);
    if (alunoIds.isEmpty) return [];

    final alertas = <StreakAlertaProfessor>[];
    for (final id in alunoIds) {
      final doc = await _db.collection('usuarios').doc(id).get();
      if (!doc.exists) continue;
      final data = doc.data()!;
      if ((data['tipo'] as String?) != 'aluno') continue;

      final estado = (data['streakEstado'] as String?) ?? 'neutro';
      final fogo = (data['streakFogo'] as num?)?.toInt() ?? 0;
      final gelo = (data['streakGelo'] as num?)?.toInt() ?? 0;
      final nome = (data['nome'] as String?) ?? 'Aluno';

      if (estado == 'fogo' && fogo > 0) {
        alertas.add(StreakAlertaProfessor(
          alunoId: id,
          nome: nome,
          estado: StreakEstado.fogo,
          semanas: fogo,
        ));
      } else if (estado == 'gelo' && gelo >= 2) {
        alertas.add(StreakAlertaProfessor(
          alunoId: id,
          nome: nome,
          estado: StreakEstado.gelo,
          semanas: gelo,
        ));
      }
    }

    alertas.sort((a, b) => b.semanas.compareTo(a.semanas));
    return alertas;
  }

  /// Dados completos para o professor abrir o detalhe da streak do aluno.
  Future<StreakDetalheProfessor?> detalheParaProfessor(String alunoId) async {
    final doc = await _db.collection('usuarios').doc(alunoId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    if ((data['tipo'] as String?) != 'aluno') return null;

    final nome = (data['nome'] as String?) ?? 'Aluno';
    final datas = await _datasAprendido(alunoId);
    final escola = await lerConfigEscola();
    final snap = calcular(
      datasAprendido: datas,
      agora: DateTime.now(),
      escola: escola,
      usuarioAtual: data,
    );

    final ultima = snap.ultimaAtividadeAprendidoEm ??
        _ts(data['ultimaAtividadeAprendidoEm']);

    String motivo;
    String streakAtual;
    switch (snap.estado) {
      case StreakEstado.fogo:
        final n = snap.streakFogo;
        motivo =
            'O aluno marcou passos como aprendidos na semana atual e manteve '
            'atividade nas semanas anteriores'
            '${ultima != null ? ' (última marcação: ${_fmtDataHora(ultima)})' : ''}.';
        streakAtual =
            'Fogo · $n semana${n == 1 ? '' : 's'} ativa${n == 1 ? '' : 's'}';
        break;
      case StreakEstado.gelo:
        final n = snap.streakGelo;
        motivo =
            'O aluno não marcou nenhum passo como aprendido por $n semana'
            '${n == 1 ? '' : 's'} seguida${n == 1 ? '' : 's'}'
            '${ultima != null ? '. Última marcação: ${_fmtDataHora(ultima)}' : '.'}';
        streakAtual =
            'Gelo · $n semana${n == 1 ? '' : 's'} inativa${n == 1 ? '' : 's'}';
        break;
      case StreakEstado.neutro:
        motivo = ultima != null
            ? 'Sem atividade na semana atual. Última marcação: ${_fmtDataHora(ultima)}.'
            : 'O aluno ainda não marcou passos como aprendidos.';
        streakAtual = 'Neutro · sem sequência ativa';
        break;
    }

    return StreakDetalheProfessor(
      alunoId: alunoId,
      nomeCompleto: nome,
      estado: snap.estado,
      streakFogo: snap.streakFogo,
      streakGelo: snap.streakGelo,
      ultimaAtividadeAprendidoEm: ultima,
      motivoMudanca: motivo,
      streakAtual: streakAtual,
    );
  }

  static String _fmtDataHora(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year;
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy às $hh:$min';
  }
}

class StreakAlertaProfessor {
  final String alunoId;
  final String nome;
  final StreakEstado estado;
  final int semanas;

  const StreakAlertaProfessor({
    required this.alunoId,
    required this.nome,
    required this.estado,
    required this.semanas,
  });

  String get tituloExibicao {
    final primeiro = nome.trim().split(RegExp(r'\s+')).first;
    if (estado == StreakEstado.fogo) {
      return '🔥 $primeiro — $semanas semana${semanas == 1 ? '' : 's'} ativa${semanas == 1 ? '' : 's'}';
    }
    return '❄️ $primeiro — $semanas semana${semanas == 1 ? '' : 's'} sem atividade';
  }

  String get resumoNotificacao {
    if (estado == StreakEstado.fogo) {
      return 'Streak de fogo · $semanas semana${semanas == 1 ? '' : 's'}';
    }
    return 'Streak de gelo · $semanas semana${semanas == 1 ? '' : 's'} sem atividade';
  }
}

/// Detalhe de streak de um aluno (visão do professor).
class StreakDetalheProfessor {
  final String alunoId;
  final String nomeCompleto;
  final StreakEstado estado;
  final int streakFogo;
  final int streakGelo;
  final DateTime? ultimaAtividadeAprendidoEm;
  final String motivoMudanca;
  final String streakAtual;

  const StreakDetalheProfessor({
    required this.alunoId,
    required this.nomeCompleto,
    required this.estado,
    required this.streakFogo,
    required this.streakGelo,
    this.ultimaAtividadeAprendidoEm,
    required this.motivoMudanca,
    required this.streakAtual,
  });
}
