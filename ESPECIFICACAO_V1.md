# DançaMais — Especificação v1.0 (novas funcionalidades)

Documento de alinhamento fechado para implementação. Complementa `SISTEMA_DANCAMAIS.md`.

**Ordem de entrega:** 1 → 3 → 4 → 2

| Fase | Escopo |
|------|--------|
| **1** | XP de validação = 100 |
| **2** | Ranking com opt-in irreversível + visão embaçada |
| **3** | Streaks fogo/gelo + pausas + sininho (professor e aluno) |
| **4** | Feedback escrito + sininho aluno + validações no sininho professor |

---

## Fase 1 — XP na validação

| Regra | Valor |
|--------|--------|
| XP ao marcar **aprendido** (aluno) | **+50** (mantém) |
| XP ao **validar** (professor) | **+100** |
| Ao **desvalidar** | Remove **100** de validação |
| Retroativo | Não |

**Arquivos principais:** `XPRecompensa` em `progresso_feedback_model.dart` e `gamification_service.dart`; textos da UI que citam o valor antigo.

---

## Fase 2 — Ranking público opcional

### Campo Firestore

- `usuarios/{uid}.participaRanking` (bool)
- **Cadastro novo:** `false` (precisa aceitar no ranking)
- **Contas antigas sem o campo:** tratadas como `true` (comportamento atual preservado)

### Opt-in irreversível

- Enquanto `participaRanking == false`, o aluno pode **ativar** participação.
- Depois de `true`, **não pode voltar para false**.
- UI: dialog de confirmação com texto explícito sobre irreversibilidade.

### Comportamento

| `participaRanking` | Outros veem o aluno? | Aluno vê os outros? | Aluno vê a si mesmo |
|--------------------|----------------------|---------------------|---------------------|
| `false` | Não | Não | Sim — linha dele nítida; demais linhas **embaçadas**; **sem posição numérica**; CTA para participar |
| `true` | Sim | Sim | Ranking normal (nível → XP → passos → coreos → nome) |

### Filtros

- Abas **Geral** e **Por modalidade**: excluir alunos com `participaRanking == false` das listas que os outros enxergam.

---

## Fase 3 — Streaks (fogo / gelo)

### Definição de atividade

- **Atividade:** aluno marca status **`aprendido`** em qualquer movimentação.
- Registrar/atualizar data em `progressoAluno` (`dataAprendido`) para cálculo.
- **Inatividade:** nenhum `aprendido` na janela de análise.

### Janela de tempo

- **Últimos 7 dias corridos** (rolling), fuso do dispositivo.

### Regras de contadores (uma streak só: fogo **ou** gelo)

| Situação | `streakFogo` | `streakGelo` | Estado UI |
|----------|--------------|--------------|-----------|
| `aprendido` na janela de 7 dias | **1** (reinicia) | **0** | fogo |
| 1ª semana sem `aprendido` (perde fogo) | **0** | **0** | neutro |
| 2ª+ semana consecutiva sem `aprendido` | **0** | **2, 3, …** | gelo |

- Ao voltar a registrar `aprendido`: gelo → 0, fogo → **1**.

### Campos pré-calculados em `usuarios/{uid}`

Sugestão:

```text
streakEstado: 'fogo' | 'gelo' | 'neutro'
streakFogo: int
streakGelo: int
ultimaAtividadeAprendidoEm: Timestamp?
streaksCalculadoEm: Timestamp?
pausaStreakAte: Timestamp?          // pausa pessoal do aluno
pausasStreakUsadasNoMes: int       // mês de referência (ex. 202605)
```

Recálculo ao marcar/desfazer `aprendido` e ao abrir telas relevantes (fallback).

### Exibição

| Quem | Onde |
|------|------|
| Aluno | Ícone da streak na home (toque abre detalhe + botão pausa pessoal) |
| Professor | Sininho — itens misturados com outros tipos |

Formato professor: `🔥 Maria — 4 semanas ativas` / `❄️ João — 3 semanas sem atividade` (ícone **antes** do texto).

Regras de notificação para professor:

- Notificar quando o aluno mudar de estado de streak entre **fogo**, **neutro** e **gelo**.
- Notificar quando o aluno completar **3 semanas** na mesma streak (**fogo** ou **gelo**).
- Não reenviar notificação apenas porque o aluno continua no mesmo estado; novos alertas dependem de mudança de estado ou novo marco de 3 semanas em outra sequência.

Escopo:

- Professor: alunos das **modalidades** dele.
- **Admin** (`isAdmin`): todas as modalidades.

Tempo real ao abrir sininho / streams.

---

### Pausa pessoal do aluno (1× por mês)

| Regra | Valor |
|--------|--------|
| Duração | **7 dias** a partir do dia em que ativou |
| Efeito | **Não aumenta gelo**; **mantém** `streakFogo` no número atual (ex.: continua 5) |
| Crédito | **1 uso** por mês civil (dia 1 ao último dia do mês) |
| Visibilidade | **Privado** (professor não vê) |
| UI | Botão só ao abrir detalhe da streak (ícone na home) + texto explicativo |
| Pausa global ativa | Botão de pausa pessoal **desabilitado** |

Campos sugeridos: `pausaStreakAte`, controle de mês em `pausasStreakUsadasNoMes` ou `ultimaPausaStreakMes` (YYYYMM).

---

### Pausa global da escola (só admin)

| Regra | Valor |
|--------|--------|
| Quem | Apenas professor **admin** |
| Onde | **Perfil admin** |
| Controles | Toggle **Pausar / Retomar** + opcional **Retomar automaticamente em** (data/hora) |
| Enquanto pausado | Streaks **congelam** (fogo e gelo não mudam; gelo não acumula) |
| Retomada agendada | Após data/hora, sistema **retoma sozinho** |
| Alunos | Banner na home: *“Contagem de streaks pausada pela escola até …”* |
| Professores | Item no sininho: streaks pausados até DD/MM |

**Firestore:** `escola/config`

```text
streaksPausados: bool
streaksRetomarEm: Timestamp?   // retomada automática
streaksPausadosDesde: Timestamp?
```

---

## Fase 4 — Feedback escrito

### Regras gerais

| Regra | Valor |
|--------|--------|
| Obrigatório para validar? | **Não** |
| Tamanho máximo | **500** caracteres |
| Editar | **Não** |
| Apagar | **Sim** (professor) — some para o aluno |
| Desvalidar passo | Feedback **permanece** |
| Validar passo | Independente de enviar feedback |

### Tipos de feedback

1. **Por movimentação** — `movimentacaoId` preenchido (passo/coreo).
2. **Geral** — sem passo; escopo:
   - **Aluno específico** (da lista de alunos da turma), ou
   - **Turma inteira** (todos inscritos recebem notificação).

Firestore (`feedbacks`):

```text
professorId, professorNome?, alunoId?, turmaId?, turmaNome?,
movimentacaoId?, movimentacaoNome?, texto, data,
tipo: 'movimentacao' | 'aluno' | 'turma'
validaMovimentacao: bool   // true só se marcou "também validar" no fluxo combinado
```

Feedback geral **não** valida passo automaticamente.

### UX professor

Na lista de alunos da turma:

- **Feedback para aluno X**
- **Feedback para toda a turma**

Fluxo passo da semana / validação (mantém):

1. **Validar / Desvalidar** — só progresso + XP.
2. **Enviar feedback** — sheet com texto; checkbox opcional **“Também validar este passo”** (desmarcado por padrão).

---

## Centro de notificações (sininho)

### Comum

- Ícone **sininho na home** (aluno e professor).
- **Ao abrir um item → marca como lido** (`lido: true` em doc de notificação ou subcoleção).
- Badge com contagem de não lidos.

### Aluno — conteúdo

- Feedbacks recebidos (por movimentação, por aluno, ou turma).
- Some da lista se:
  - aluno **ocultar** (não apaga `feedbacks` no Firestore — só flag `ocultoParaAluno` ou doc em `usuarios/{uid}/notificacoes`), ou
  - professor **excluir** o feedback.

### Professor — conteúdo (lista única, misturada)

- Streaks fogo/gelo (modalidades do professor; admin = todas).
- **Validações pendentes** — **um item por aluno+passo** (ou contexto claro).
- **Solicitações pendentes** (entrada em turma, etc.).
- Aviso de pausa global de streaks.

Filtro de modalidade para não-admin.

---

## Modelo de notificações (implementação sugerida)

Para não sobrecarregar leituras em `feedbacks`, usar subcoleção:

`usuarios/{uid}/notificacoes/{notifId}`

```text
tipo: 'feedback' | 'streak_alerta' | 'validacao_pendente' | 'solicitacao' | 'streaks_pausados'
titulo, corpo, icone?, data, lido: bool
oculto: bool                    // aluno limpou da lista
refId?, refTipo?                 // id do feedback, turma, etc.
```

Alternativa: derivar notificações de `feedbacks` + queries de pendências; subcoleção facilita `lido` e `oculto`.

**Decisão na implementação:** escolher o caminho mais simples que suporte `lido` ao abrir e `oculto` sem apagar feedback.

---

## Fora do escopo v1

- Push (FCM)
- Foto/vídeo para comprovar presença na semana
- Edição de feedback
- Opt-out do ranking após opt-in
- Retroativo de XP

---

## Checklist de aceite (resumo)

- [x] Validar concede +100 XP; desvalidar remove 100
- [x] Ranking: blur + opt-in irreversível; novos cadastros `false`; legado sem campo = `true`
- [x] Streak: fogo/gelo conforme tabela; 7 dias rolling; pré-cálculo em `usuarios`
- [x] Pausa aluno: 7 dias, 1×/mês, mantém fogo, privado
- [x] Pausa admin: toggle + agendamento + banner + sininho
- [x] Sininho: misturado, lido ao abrir, professor filtrado por modalidade
- [x] Feedback: com/sem passo; turma ou aluno; separado de validar; ocultar vs excluir

---

*Especificação acordada em conversa de produto. Atualizar este arquivo se regras mudarem antes ou durante a implementação.*
