import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/models.dart';

/// Serviço central de gamificação.
/// Responsável por processar XP, subidas de nível e conquistas.
/// Segue o fluxo do Diagrama de Sequência do TCC:
/// Aluno marca aprendido → processa recompensa → atualiza Firestore → verifica conquistas.
class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- AÇÃO DO ALUNO: Marcar passo como aprendido ---

  /// Chamado quando o aluno marca uma movimentação como aprendida.
  /// Retorna as conquistas desbloqueadas (se houver), para exibir na UI.
  Future<List<ConquistaModel>> registrarAprendizado({
    required String alunoId,
    required MovimentacaoModel movimentacao,
  }) async {
    // 1. Cria ou atualiza o documento de progresso
    final progressoRef = _firestore
        .collection('progressoAluno')
        .doc('${alunoId}_${movimentacao.id}');

    final progressoSnap = await progressoRef.get();

    // Impede registrar novamente se já foi aprendido
    if (progressoSnap.exists) {
      final progresso = ProgressoAlunoModel.fromFirestore(progressoSnap);
      if (progresso.foiAprendido) return [];
    }

    final novoProgresso = ProgressoAlunoModel(
      id: '${alunoId}_${movimentacao.id}',
      alunoId: alunoId,
      movimentacaoId: movimentacao.id,
      movimentacaoNome: movimentacao.nome,
      modalidade: movimentacao.modalidade,
      status: StatusProgresso.aprendido,
      dataAprendido: DateTime.now(),
      xpGanhoAluno: XPRecompensa.marcarAprendido,
      xpGanhoValidacao: 0,
    );

    // 2. Salva o progresso e atualiza XP do aluno em transação atômica
    final conquistasDesbloqueadas = <ConquistaModel>[];

    await _firestore.runTransaction((transaction) async {
      final alunoRef = _firestore.collection('usuarios').doc(alunoId);
      final alunoSnap = await transaction.get(alunoRef);
      final alunoData = alunoSnap.data() as Map<String, dynamic>;

      final int xpAtual = alunoData['xp'] ?? 0;
      final int nivelAtual = alunoData['nivel'] ?? 1;
      final int novoXP = xpAtual + XPRecompensa.marcarAprendido;

      // Calcula novo nível baseado no XP total
      final int novoNivel = _calcularNivel(novoXP);

      // Salva o progresso
      transaction.set(progressoRef, novoProgresso.toMap());

      // Atualiza XP e nível do aluno
      transaction.update(alunoRef, {
        'xp': novoXP,
        'nivel': novoNivel,
      });

      // Incrementa contador na movimentação (útil para ranking)
      final movRef = _firestore.collection('movimentacoes').doc(movimentacao.id);
      transaction.update(movRef, {
        'totalAprenderam': FieldValue.increment(1),
      });
    });

    // 3. Verifica conquistas fora da transação (leitura necessária)
    final novas = await _verificarConquistas(alunoId);
    conquistasDesbloqueadas.addAll(novas);

    return conquistasDesbloqueadas;
  }

  // --- AÇÃO DO PROFESSOR: Validar aprendizado do aluno ---

  /// Chamado quando o professor valida que o aluno aprendeu uma movimentação.
  /// Pode ser feito junto com um feedback ou de forma independente.
  Future<void> validarAprendizado({
    required String professorId,
    required String alunoId,
    required String movimentacaoId,
    String? feedbackTexto,
    String? feedbackMovimentacaoNome,
  }) async {
    final progressoId = '${alunoId}_$movimentacaoId';
    final progressoRef = _firestore
        .collection('progressoAluno')
        .doc(progressoId);

    final progressoSnap = await progressoRef.get();
    if (!progressoSnap.exists) return; // Precisa ter sido marcado pelo aluno antes

    final progresso = ProgressoAlunoModel.fromFirestore(progressoSnap);
    if (progresso.foiValidado) return; // Já validado, não duplica XP

    await _firestore.runTransaction((transaction) async {
      final alunoRef = _firestore.collection('usuarios').doc(alunoId);
      final alunoSnap = await transaction.get(alunoRef);
      final alunoData = alunoSnap.data() as Map<String, dynamic>;

      final int xpAtual = alunoData['xp'] ?? 0;
      final int novoXP = xpAtual + XPRecompensa.validadoProfessor;
      final int novoNivel = _calcularNivel(novoXP);

      // Atualiza o progresso para 'validado'
      transaction.update(progressoRef, {
        'status': StatusProgresso.validado.name,
        'dataValidado': FieldValue.serverTimestamp(),
        'professorValidouId': professorId,
        'xpGanhoValidacao': XPRecompensa.validadoProfessor,
      });

      // Concede XP bônus ao aluno
      transaction.update(alunoRef, {
        'xp': novoXP,
        'nivel': novoNivel,
      });

      // Se vier com texto de feedback, salva o documento de feedback também
      if (feedbackTexto != null && feedbackTexto.isNotEmpty) {
        final feedbackRef = _firestore.collection('feedbacks').doc();
        transaction.set(feedbackRef, {
          'professorId': professorId,
          'alunoId': alunoId,
          'texto': feedbackTexto,
          'data': FieldValue.serverTimestamp(),
          'movimentacaoId': movimentacaoId,
          if (feedbackMovimentacaoNome != null)
            'movimentacaoNome': feedbackMovimentacaoNome,
          'validaMovimentacao': true,
        });
      }
    });
  }

  // --- LÓGICA DE NÍVEIS ---

  /// Calcula o nível correspondente a um total de XP acumulado.
  /// A fórmula usa crescimento progressivo: cada nível exige mais XP.
  int _calcularNivel(int xpTotal) {
    int nivel = 1;
    int xpAcumulado = 0;
    while (true) {
      final xpParaEsteNivel =
          (StudentModel.xpBaseParaNivel * (nivel * StudentModel.fatorCrescimento))
              .round();
      if (xpAcumulado + xpParaEsteNivel > xpTotal) break;
      xpAcumulado += xpParaEsteNivel;
      nivel++;
      if (nivel > 99) break; // Nível máximo
    }
    return nivel;
  }

  // --- VERIFICAÇÃO DE CONQUISTAS ---

  /// Verifica se o aluno desbloqueou novas conquistas após uma ação.
  /// Retorna a lista de conquistas recém-desbloqueadas.
  Future<List<ConquistaModel>> _verificarConquistas(String alunoId) async {
    final conquistasDesbloqueadas = <ConquistaModel>[];

    // Busca quantos passos o aluno já aprendeu
    final progressoSnap = await _firestore
        .collection('progressoAluno')
        .where('alunoId', isEqualTo: alunoId)
        .where('status', whereIn: [
          StatusProgresso.aprendido.name,
          StatusProgresso.validado.name,
        ])
        .get();

    final totalAprendidos = progressoSnap.docs.length;

    // Modalidades únicas aprendidas
    final modalidades = progressoSnap.docs
        .map((d) => d.data()['modalidade'] as String)
        .toSet();

    // Busca conquistas já obtidas pelo aluno
    final alunoSnap =
        await _firestore.collection('usuarios').doc(alunoId).get();
    final alunoData = alunoSnap.data() as Map<String, dynamic>;
    final List conquistasAtuais = alunoData['conquistas'] ?? [];
    final idsJaObtidos = conquistasAtuais.map((c) => c['id']).toSet();

    // Verifica cada conquista padrão
    for (final conquista in ConquistaModel.conquistasPadrao) {
      if (idsJaObtidos.contains(conquista.id)) continue;

      bool desbloqueou = false;

      switch (conquista.tipo) {
        case TipoConquista.primeiroPasso:
          desbloqueou = totalAprendidos >= 1;
        case TipoConquista.sequencia:
          desbloqueou = totalAprendidos >= 10;
        case TipoConquista.modalidade:
          desbloqueou = modalidades.length >= 3;
        case TipoConquista.frequencia:
          desbloqueou = await _verificarFrequencia(alunoId, progressoSnap.docs);
        default:
          break;
      }

      if (desbloqueou) {
        final conquistaObtida = ConquistaModel(
          id: conquista.id,
          nome: conquista.nome,
          descricao: conquista.descricao,
          icone: conquista.icone,
          tipo: conquista.tipo,
          dataObtida: DateTime.now(),
          xpRecompensa: conquista.xpRecompensa,
        );

        // Salva conquista no perfil do aluno e concede XP bônus
        await _firestore.collection('usuarios').doc(alunoId).update({
          'conquistas': FieldValue.arrayUnion([conquistaObtida.toMap()]),
          'xp': FieldValue.increment(conquista.xpRecompensa),
        });

        conquistasDesbloqueadas.add(conquistaObtida);
      }
    }

    return conquistasDesbloqueadas;
  }

  /// Verifica se o aluno aprendeu 3 passos em menos de 3 semanas (conquista "Pegando Fogo").
  Future<bool> _verificarFrequencia(
      String alunoId, List<QueryDocumentSnapshot> docs) async {
    if (docs.length < 3) return false;
    final tresSemanasAtras = DateTime.now().subtract(const Duration(days: 21));
    final recentes = docs.where((d) {
      final data = d.data() as Map<String, dynamic>;
      final ts = data['dataAprendido'] as Timestamp?;
      return ts != null && ts.toDate().isAfter(tresSemanasAtras);
    }).length;
    return recentes >= 3;
  }
}