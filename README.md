# DançaMais

App Flutter de gestão de turmas e gamificação para escola de dança, com **dois perfis**:

- **Aluno**: agenda, turmas, passo da semana, conquistas, ranking, perfil.
- **Professor/Admin**: gerenciar turmas, biblioteca de passos/coreos, solicitações, validar “passo da semana”, conceder conquistas, perfil.

## Stack e dependências principais

- **Flutter** (SDK no `pubspec.yaml`: `>=3.4.3 <4.0.0`)
- **Firebase**
  - `firebase_core`
  - `firebase_auth`
  - `cloud_firestore`
  - `firebase_app_check` (ativado em modo debug no Android)
- **Estado**
  - `flutter_bloc` (Auth)
- **UI**
  - `google_fonts`

## Rodando o projeto (passo a passo)

### Pré-requisitos

- Flutter instalado e funcionando (`flutter doctor`)
- Um projeto Firebase configurado com **Authentication** e **Firestore**

### Instalação

```bash
flutter pub get
```

### Executar

```bash
flutter run
```

## Firebase (configuração do app)

### Arquivos/entradas relevantes

- **Inicialização**: `lib/main.dart`
  - Inicializa o Firebase (`Firebase.initializeApp`)
  - Ativa App Check no Android (provider debug)
  - Sobe `MaterialApp` com tema e `AuthBloc`
- **Config do Firebase por plataforma**: `lib/firebase_options.dart`
  - Gerado via FlutterFire CLI.
  - Se você for trocar de projeto Firebase, reconfigure com o FlutterFire CLI.

### Autenticação e roteamento

- **Roteamento por sessão**: `lib/ui/widgets/auth_wrapper.dart`
  - Não logado → `LoginScreen`
  - Logado → lê `usuarios/{uid}` e decide:
    - `tipo == professor` e `status == pendente` → tela de espera (`PendingApprovalScreen`)
    - `tipo == professor` e `status == naoSolicitado` → pode solicitar novamente
    - `tipo == professor` → `TeacherDashboard`
    - Caso contrário → `StudentDashboard`
- **Auth com BLoC**: `lib/logic/auth_bloc/`
  - `AuthBloc` chama `AuthService` e persiste o perfil no Firestore em `usuarios/{uid}` no cadastro.

## Estrutura de pastas (guia rápido)

- `lib/main.dart`: entrada do app.
- `lib/core/`
  - `theme/app_theme.dart`: paleta e `ThemeData`.
  - `app_theme_notifier.dart`: controle de dark mode via `ValueNotifier`.
- `lib/data/services/`
  - `auth_service.dart`: sign-in, register, sign-out.
  - `permissao_service.dart`: permissões do professor/admin (usado em solicitações/validações).
- `lib/logic/`
  - `auth_bloc/`: login/cadastro/logout e estados.
  - `gamification/`: regras de XP/nível, progresso e conquistas.
- `lib/models/`: modelos e parsing do Firestore.
  - `models.dart` exporta todos os models (ponto único de import).
- `lib/ui/`
  - `screens/`: telas (dashboards, turmas, ranking, perfil, etc).
  - `widgets/`: componentes reutilizáveis (ex.: `TapEffect`).

## Tema e cores

Definido em `lib/core/theme/app_theme.dart`.

- `primary`: cor principal
- `secondary`: cor secundária (escura)
- `third`: cor terciária
- `accent`: variação do `primary`
- `detail`: destaque (usada, por ex., em estados “aprendido/validado” em algumas telas)

## Firestore (modelo mental das coleções)

O app usa principalmente estas coleções/documentos:

- **`usuarios/{uid}`**
  - Campos comuns: `nome`, `email`, `tipo` (`aluno`/`professor`), `status` (para professor), `modalidades` (lista)
  - Para aluno: `nivel`, `xp`, `conquistas` (array de mapas com `id`, `nome`, `icone`, `xpRecompensa`, `dataObtida`, etc.)
  - Subcoleção: `usuarios/{uid}/conquistas` (também pode conter conquistas obtidas; o app faz merge com o array)
- **`turmas/{turmaId}`**
  - Informações da turma: nome, modalidade, nível, horários etc.
- **`inscricoes`**
  - Matrícula/inscrição do aluno na turma (ex.: `alunoId`, `turmaId`)
- **`movimentacoes/{movId}`**
  - Catálogo de passos e coreografias (nome, tipo, modalidade, contadores, etc.)
- **`progressoAluno/{alunoId_movId}`**
  - Fonte de verdade do progresso do aluno numa movimentação:
    - `status`: `naoAprendido` / `emProgresso` / `aprendido` / `validado`
    - datas, XP, e quem validou (quando aplicável)
- **`conquistasCustom/{conquistaId}`**
  - Catálogo de conquistas cadastradas (critérios + recompensa)
- **`feedbacks/{feedbackId}`**
  - Feedback do professor ao validar (quando enviado)
- **`escola/config`**
  - Configurações gerais (ex.: lista de modalidades disponíveis)

> Observação: em algumas telas o app lê conquistas tanto do **array** `usuarios/{uid}.conquistas` quanto da **subcoleção** `usuarios/{uid}/conquistas` e faz merge (para compatibilidade de dados).

## Gamificação (como funciona)

O serviço central é `lib/logic/gamification/gamification_service.dart`.

### XP e níveis

- Recompensas de XP em `XPRecompensa`:
  - `marcarAprendido = 50`
  - `validadoProfessor = 15`
- O nível é calculado a partir do XP acumulado (`_calcularNivel`).

### Progresso do aluno (passo/coreo)

O fluxo principal:

1. **Aluno marca como aprendido**
   - Cria/atualiza `progressoAluno/{alunoId_movId}` com status `aprendido`
   - Incrementa XP do aluno e recalcula nível
2. **Professor valida**
   - Atualiza status para `validado`
   - Concede bônus de XP (`+15`)
   - Pode registrar um documento em `feedbacks`
3. **Professor desvalida**
   - Volta de `validado` para `aprendido`
   - Remove o bônus de XP e limpa campos de validação

### Conquistas automáticas

Após mudanças relevantes (aprender/validar), `_verificarConquistas` avalia conquistas do catálogo (`conquistasCustom`) e adiciona ao aluno aquelas cujo critério foi atingido **e** que ele ainda não possui.

## Telas importantes (onde editar o quê)

### Aluno

- **Dashboard**: `lib/ui/screens/student_dashboard.dart`
  - “Minha Agenda”, “Passo da Semana”, e “Últimas conquistas”
  - Cards de conquistas recentes (clicáveis) abrem bottom sheet de detalhes
- **Turmas**: `lib/ui/screens/student_classes_screen.dart`
- **Conquistas**: `lib/ui/screens/student_badges_screen.dart` (`StudentConquistasScreen`)
- **Ranking**: `lib/ui/screens/student_ranking_screen.dart`
- **Perfil**: `lib/ui/screens/student_profile_screen.dart`

### Professor

- **Dashboard**: `lib/ui/screens/teacher_dashboard.dart`
  - Header com data + ícone de calendário e confirmação de logout
  - Bento Grid com cards coloridos
  - Hub de “Solicitações” (validar passo da semana / solicitações de entrada)
- **Turmas**: `lib/ui/screens/teacher_classes_screen.dart`
  - Máscara de horário, bottom sheets, solicitações e validação do passo da semana
- **Biblioteca**: `lib/ui/screens/teacher_steps_library_screen.dart`
  - Contagem de alunos que marcaram como “aprendido/validado” via `progressoAluno`
- **Conquistas (criar/editar/conceder)**: `lib/ui/screens/teacher_badges_screen.dart`
  - Conceder conquista **não permite duplicar** para o mesmo aluno
- **Perfil**: `lib/ui/screens/teacher_profile_screen.dart`

## Padrões de UI/UX usados no projeto

- Bottom sheets: `showModalBottomSheet` com `backgroundColor: Colors.transparent`
- Botões com efeito: `lib/ui/widgets/tap_effect.dart`
- Cards com sombra leve e cantos arredondados (consistência visual)
- Uso intenso de `StreamBuilder`/`FutureBuilder` para Firestore

## Dicas de debug / desenvolvimento

- Se algo “não aparece”, verifique:
  - O usuário está logado? (`FirebaseAuth`)
  - O documento `usuarios/{uid}` existe e tem `tipo/status` coerentes?
  - As coleções (`turmas`, `inscricoes`, `progressoAluno`, etc.) têm dados?
- Para UI overflow:
  - Prefira `Wrap` no lugar de `Row` para chips/tags
  - Use `Expanded` + `maxLines` + `TextOverflow.ellipsis` para textos longos

## Licença

Projeto interno/educacional (ajuste conforme sua necessidade).
