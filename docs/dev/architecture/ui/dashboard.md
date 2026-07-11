# Dashboard

Status: Draft
Versão: 0.1
Última atualização: 2026-07-10
Responsável: Arquitetura

---

# 1. Objetivo

Documentar o funcionamento da tela principal (Dashboard) da Ana: layout,
componentes, estados e interações.

Este documento é a fonte de verdade sobre *comportamento de UI*.
`../04-frontend.md` descreve a arquitetura geral do Frontend (camadas,
organização React); este documento descreve o que cada parte da tela
faz.

---

# 2. Escopo

## Responsabilidades

- estrutura visual da tela (Header, Desktop, Footer);
- comportamento de cada componente (seleção, colapso, persistência de
  preferências);
- o que é MVP e o que existe só para produção de estilo/interação
  dentro desta tela.

## Não Responsabilidades

- arquitetura do Frontend (ver `../04-frontend.md`);
- endpoints consumidos (ver `../05-api.md`);
- lógica de negócio (ver `../06b-services.md`).

---

# 3. Visão Geral

Referência visual: `tmp/layout.png` — mockup de alta-fidelidade,
inspirado nas IDEs da JetBrains.

Estrutura geral da página, de cima para baixo:

```
┌────────────────────────────────────────────────────────────────────┐
│ Header  [Logo | Central: Projeto · Git · Notif · Provider | Account]│
├────────────┬───────────┬──────────────┬───────────┬─────────────────┤
│            │           │              │           │                 │
│ ContextBar │ WorkPanel │     Main     │ ToolPanel │     ToolBar     │
│            │           │              │           │                 │
├────────────┴───────────┴──────────────┴───────────┴─────────────────┤
│ Footer (largura total do viewport)                                  │
└────────────────────────────────────────────────────────────────────┘
```

`ContextBar` e `ToolBar` são as duas sidebars fixas. `WorkPanel`, `Main`
e `ToolPanel` são os 3 painéis do `Desktop`, e mudam de conteúdo conforme
a seleção nas sidebars.

---

# 4. Header

Dividido em 3 partes horizontais:

1. **Logo** — mesma largura da `ContextBar`. Contém só a logo (avatar
   quadrado, cantos arredondados).
2. **Central** — ocupa toda a largura restante entre as partes 1 e 3.
   Subdividida em esquerda/direita. Concentra os componentes
   interativos do header.
3. **Account** — mesma largura da `ToolBar`. Vazia por enquanto;
   possivelmente receberá o avatar do usuário no futuro.

## Componentes da parte Central

### Dropdown de Projeto

Indica o projeto atual. Permite:

- trocar de projeto;
- acessar configurações do projeto (renomear, mudar pasta raiz).

MVP: sim — ver `../05-api.md` > Projects (`PATCH /projects/{id}`).

### Dropdown de Git (branch)

Indica a branch atual.

MVP: só exibição do nome da branch, vinda de `GET /projects/{id}/git`
— **mockado** (não executa git de fato, valor fixo — ver
`../05-api.md` > Git e `../06b-services.md` > GitService). Pull/push,
troca de branch e renomear branch ficam para o futuro, junto da
integração real com git.

### Sino de notificações

Reservado para o futuro. Sem funcionalidade no MVP.

### Dropdown de Provider/Modelo

Indica o provider/modelo em uso no momento (nome do modelo, em
uppercase). Permite trocar para outro já cadastrado, ou cadastrar um
novo provider.

MVP: sim — ver `../06b-services.md` > ProviderService e ConfigService.

Quando o provider ativo está indisponível, o texto do dropdown fica na
cor `warn` (ver `Requisitos Não-Funcionais` > Cores e `Main` > Provider
indisponível).

Ao trocar de provider ou modelo, o Frontend só avisa o Backend da
escolha e segue em frente — a troca é sempre aceita na hora, sem
esperar teste de conexão nenhum (mesmo que o provider/modelo escolhido
esteja indisponível ou já tenha sido removido). O envio de mensagens
só fica bloqueado depois, em dois casos possíveis (nunca no instante
da troca), com escopos diferentes: se o usuário efetivamente tentar
enviar e o Backend rejeitar (ver `Main` > Estado de erro), o bloqueio
vale só **para aquele chat/aquela tentativa** — os demais chats do
projeto continuam liberados normalmente; ou, de forma mais ampla, se o
sistema de disponibilidade (cache de providers) terminar de checar
tudo antes do primeiro envio e já classificar o modelo como
indisponível/removido — nesse caso **todos os chats do projeto** ficam
bloqueados, mesmo bloqueio visual de "Provider indisponível" (ver
`Main`, abaixo).

#### Pilha de providers e modelos

Estrutura do conteúdo expandido, de cima para baixo:

```md
[       MODELO 12       ] < Modelo atual em uppercase
| ➕ Cadastrar Provider |
| 🔍 Buscar Modelo | < sem funcionalidade no MVP
| -------------------- |
| :: Provider A | < clicar no provider abre AI Configs no ToolPanel,
                    para editar ou remover (fora do MVP)
| Modelo-63 |
| Modelo-12 | < SELECIONADO: destacado dos demais
| Modelo-71 |
| Modelo-08 |
| -------------------- |
| :: Provider B |
| Modelo-40 |
| Modelo-63 |
| Modelo-53 |
| Modelo-86 |
| -------------------- |
```

Regras:

- a ordem dos providers (pilha) é uma configuração por projeto
  (`configs.provider_order`, ver `../07-database.md` > configs), junto
  do modelo em uso (`active_provider_id`/`active_model_ref`); modelos
  dentro de um provider **não** são ordenáveis — ficam na ordem
  devolvida por `provider_models` (ver `../07-database.md` >
  provider_models);
- resumindo o ciclo de vida da pilha no Frontend: ela é sempre
  **solicitada**, nunca sugerida. Isso vale pra toda ação que possa
  afetá-la — trocar de projeto, cadastrar/editar/excluir um provider,
  trocar ou selecionar um modelo — em nenhuma delas o Frontend
  manipula a lista diretamente. A lista só é buscada em dois momentos:
  no carregamento de um projeto (recém-criado ou reaberto numa troca)
  e sempre que chega um aviso `provider_stack` (ver abaixo);
- ao abrir o dropdown, o Frontend não envia nenhuma ordenação — quem já
  entrega a pilha ordenada é o Backend
  (`GET /projects/{id}/provider-stack`, ver `../05-api.md` > Provider
  Stack). Sem ordem gravada ainda, o Backend ordena os providers
  alfabeticamente (sem persistir esse fallback);
- trocar para um modelo de **outro** provider move esse provider para o
  topo da pilha (com todos os seus modelos juntos); trocar para um
  modelo do **mesmo** provider (já no topo) não move nada. Mas essa
  reordenação **não é decidida nem aplicada localmente pelo Frontend**
  — o Frontend só avisa "o modelo em uso mudou para X" (`PATCH
  /projects/{id}/config`); é o Backend quem reordena de fato (ver
  `../06b-services.md` > ConfigService) e quem devolve a pilha já
  atualizada na próxima busca. A **lista expandida** (ordem das seções
  de provider) nunca é reordenada localmente — só reflete o que veio da
  última busca. O texto do dropdown **colapsado** (`[ MODELO X ]`) pode
  atualizar assim que o usuário escolhe, já que é só reexibir a própria
  escolha do usuário, sem depender de nenhuma ordenação;
- clicar num modelo da lista **fecha o dropdown imediatamente** — igual
  a um `<select>` nativo; o usuário não precisa de um segundo clique
  pra fechar depois de escolher;
- cadastrar/assinar um provider não muda o modelo ativo — só
  acrescenta uma seção à pilha. "Cadastrar" pode não criar nada de
  novo: se o provider e a credencial informados já existirem, o
  Frontend só assina o que já está lá — a tela de cadastro exibe um
  aviso informando que a credencial já existia e como está registrada
  (pública ou privada), sem duplicar nada (ver `../06b-services.md` >
  ProviderService.register e `../../contracts/provider.md`);
- só existe **uma** credencial pública por provider — se o formulário
  pedir pública com uma já existente, o Backend cadastra a nova como
  privada mesmo assim e avisa esse ajuste na tela (ver
  `../../contracts/provider-credential.md`);
- quando uma credencial **pública** é cadastrada (ou uma privada passa
  a ter mais assinantes), o provider entra/permanece na pilha de
  **todos os projetos** que a enxergam; uma credencial **privada** só
  entra na pilha dos projetos que a assinam. Em qualquer um dos casos,
  o Backend avisa via WebSocket (`provider_stack`, ver
  `../10-resilience.md`) os projetos afetados;
- o aviso `provider_stack` do WebSocket é só um sinal (com
  `provider_order_updated_at` como carimbo) — não carrega a pilha em
  si. Ao recebê-lo, o Frontend é **obrigado** a chamar
  `GET /projects/{id}/provider-stack` de volta (dropdown aberto ou
  fechado, em uso ou não) — é essa busca que libera o Backend para
  eventualmente enviar o próximo aviso (ver abaixo). Ao aplicar o
  resultado da busca, o Frontend ainda confere se o carimbo é mais novo
  que o que já tinha, por segurança contra respostas fora de ordem;
- cadastrar/assinar, editar uma credencial ou desassinar um provider
  aciona o Backend a recomputar a disponibilidade da pilha **inteira**
  imediatamente (não incremental) — cadastro e edição respondem na
  hora (a recomputação roda em segundo plano); **desassinar** ("excluir"
  na UI) é diferente: o modal de confirmação mostra um spinner que só
  some quando a recomputação terminar e o aviso de pilha
  (`provider_stack`) tiver sido enviado — só então o Backend confirma a
  operação em si (ver `../06b-services.md` > ProviderService.unsubscribe
  e ProviderCacheService). "Excluir" pela UI nunca é uma exclusão física
  direta — é sempre desassinar; a exclusão física de fato (credencial e,
  se for o caso, o provider) só acontece como consequência de ninguém
  mais restar assinando (ver `../../contracts/provider-subscription.md`).
  Além desse gatilho por evento, uma checagem periódica cobre quedas/
  recuperações de credencial que não vieram de nenhuma ação de cadastro
  — o intervalo depende de a credencial pertencer a um provider externo
  ou local (`PROVIDER_CACHE_REFRESH_SECONDS`, padrão 60s, pra local;
  `PROVIDER_CACHE_REFRESH_SECONDS_EXTERNAL`, padrão 60 minutos, pra
  externo — ver `../06b-services.md` > ProviderCacheService) — e uma
  tentativa de envio real que esbarre numa indisponibilidade
  ainda não refletida também pode disparar essa checagem fora de hora
  (ver `../06b-services.md` > `ProviderCacheService.report_unavailable`);
- só existe aviso `provider_stack` quando algo **realmente muda**
  (ordenação ou disponibilidade) — uma checagem periódica sem novidade
  não gera aviso nenhum;
- o Backend nunca manda mais de um aviso "no ar" por projeto: depois de
  enviar um, fica bloqueado por **3 segundos** antes de poder enviar o
  próximo pra esse mesmo projeto, mesmo que mais coisa mude nesse
  meio-tempo — só marca que há mudança pendente, sem notificar de novo.
  Esse bloqueio se desfaz sozinho no fim do prazo, **mesmo que o
  Frontend nunca busque a pilha de volta** (aba fechada, usuário trocou
  de projeto etc.) — não depende da resposta do Frontend pra destravar.
  Em paralelo, sempre que o Frontend chamar `GET /provider-stack` — a
  qualquer momento, dentro ou depois do bloqueio — o Backend descarta
  qualquer mudança pendente que estivesse esperando pra notificar,
  já que a própria resposta dessa chamada entrega o estado mais atual;
  se não havia nada pendente, a chamada não muda nada. Esse limite de
  frequência vale **só pra `provider_stack`** — as demais notificações
  do WebSocket (`processing`, `new_message`) não são afetadas (ver
  `../06b-services.md` > RealtimeService);
- se o modelo em uso pertencer a um provider removido nesse meio tempo,
  isso é detectado no mesmo fluxo de atualização da pilha — ver `Main`
  > Provider indisponível;
- providers/modelos marcados como indisponíveis pela checagem de
  conectividade continuam aparecendo na lista expandida (não somem),
  mas visualmente identificados como fora do ar — só os removidos
  (excluídos de fato) somem da lista.

## Padrão de conteúdo expandido (dropdowns do Header)

Referência visual: captura de tela do dropdown de projetos do PhpStorm
(JetBrains) — mesma inspiração do restante da tela.

- ações de topo, fixas, fora da lista (ex: "Criar projeto...");
- lista dividida em seções com cabeçalho;
- cada item da lista: ícone/avatar + nome (destaque) + texto secundário
  (detalhe, ex: caminho da pasta);
- scroll vertical quando o conteúdo ultrapassar a altura do dropdown.

### Conteúdo expandido — Projeto

- ação de topo: criar novo projeto;
- lista única (sem seções) de projetos do usuário — ícone/avatar + nome
  + pasta raiz;
- ordenada do acesso mais recente para o menos recente — "acesso" é só
  abrir/visualizar o projeto, não exige nenhuma interação além disso;
- cada item tem um ícone de exclusão — remove apenas a pasta `.ana` do
  projeto (não a pasta raiz do usuário) e muda o status do projeto no
  banco de dados (`projects.status`, exclusão lógica). Não é possível
  excluir o **projeto ativo** — checagem feita só pelo Frontend (o
  Backend não valida isso, ver `../05-api.md` > Projects) — ícone
  desabilitado nesse item da lista.

  Ordenação por `projects.last_accessed_at` (atualizado como efeito
  colateral de `GET /projects/{id}`, ver `../06b-services.md` >
  ProjectService), sem chamada dedicada só para "marcar acesso".

### Conteúdo expandido — Git

Semelhante ao PhpStorm:

- seção com ações **Pull** e **Push**;
- separador;
- itens **Novo Branch** e **Alterar Branch** (trocar para outra branch);
- lista de branches, agrupadas por local e remoto.

Presente no protótipo (mesmo padrão visual: ícone + nome + scroll se
necessário), mas Pull/Push/Novo Branch/troca de branch continuam sem
função real no MVP — só exibição do nome da branch atual é funcional
(ver seção Componentes da parte Central, acima).

### Conteúdo expandido — Provider/Modelo

Estrutura, regras de ordenação e sincronização detalhadas em
`Componentes da parte Central` > `Dropdown de Provider/Modelo` > Pilha
de providers e modelos, acima — inclui a ação "Cadastrar Provider" no
topo (abre modal de cadastro).

---

# 5. ContextBar (sidebar esquerdo)

Define o **contexto** de uso da Ana. O contexto selecionado determina o
que aparece na `WorkPanel` (ver `Desktop`, abaixo).

Nomes dos contextos seguem o nome do componente, em inglês.

## Contextos

| Contexto | MVP?                                              |
|----------|----------------------------------------------------|
| Chats    | Sim — contexto padrão/inicial                       |
| Files    | Não — existe só para produção de estilo/interação   |
| Tasks    | Não — idem                                          |
| Git      | Não — idem                                          |

Fixos (não podem ser ocultados pelo usuário): **Chats**, **Files** e
**Git**. Configuração vem do banco de dados — `configs.fixed_contexts`
(ver `../07-database.md` > configs, `07-configs.sql` e
`../../contracts/config.md`), não fixo no código. Sem UI de edição no
MVP; fica para quando entrar em Settings (futuro).

## Comportamento

- Ícones de contexto ficam alinhados no topo da `ContextBar`.
- Clicar no contexto já selecionado o desmarca — a `WorkPanel` oculta
  automaticamente nesse caso.
- A ordem dos ícones é fixa, independente de quais estão
  visíveis/ativos.
- Contextos fixos não podem ser ocultados pelo usuário (ver acima).

## Ícones de ferramenta (alinhados na base)

Não são contextos — são atalhos para menus exclusivos, fora do MVP.
Seguem o mesmo estilo visual dos ícones de contexto, mas não competem
pela mesma seleção.

- **Settings** — único ícone presente hoje; existe para representar
  visualmente como um ícone fica quando indisponível (desabilitado).

## Menu de exibição

O último item da lista de ícones de contexto não é um contexto — é um
menu que mostra/oculta contextos específicos na interface. Essa
preferência é salva **por projeto**, em `configs.hidden_contexts` (ver
`../07-database.md` > configs e `../../contracts/config.md`).

A mudança de visibilidade não é enviada ao Backend a cada clique: o
Frontend espera um **debounce de 3 segundos** sem nova alteração antes
de disparar `PATCH /projects/{id}/config`, e o disparo em si é
assíncrono (não bloqueia nada que o usuário esteja fazendo enquanto a
requisição sai). O carregamento de um projeto já traz `hidden_contexts`
(junto com `hidden_tools` e `fixed_contexts`) numa única resposta de
`GET /projects/{id}/config` — não é preciso nenhuma chamada extra para
montar o estado inicial da `ContextBar`/`ToolBar`.

---

# 6. ToolBar (sidebar direito)

Funciona de forma análoga à `ContextBar`, mas controla o que aparece na
`ToolPanel` em vez da `WorkPanel`.

## Ferramentas

| Ferramenta | Estado no mockup      | MVP? |
|------------|------------------------|------|
| Configs    | ativa, não selecionada | Não  |
| Gastos     | ativa, não selecionada | Sim  |
| Ajuda      | desativada             | Não  |

- **Configs** (também referida como "AI Configs", já que configura o
  provider/modelo de IA) — abre as configurações do provider/modelo
  atualmente selecionado, para edição. **Bloqueada por hardcode no
  MVP**: o estilo do ícone segue igual ao mockup (parece habilitada,
  igual a Gastos), mas o clique não faz nada — não abre o `ToolPanel`,
  não chama `POST /projects/{id}/tools/{tool}` nenhum, é um bloqueio
  fixo no Frontend, não uma condição calculada. Fora do escopo do
  protótipo do MVP — sem detalhamento de campos por enquanto. Quando o
  provider ativo está indisponível, o ícone recebe um badge na cor
  `warn` (ver `Requisitos Não-Funcionais` > Cores), indicando que há
  algo de errado (ver `Main` > Provider indisponível) — isso continua
  valendo mesmo com o clique bloqueado.

  > Evolução futura: o painel de Configs terá um campo de status
  > indicando o estado de falha do provider, com a mensagem de
  > erro real/técnica logo abaixo.
- **Gastos** — abre um resumo dos gastos até o momento; atualiza em
  tempo real enquanto permanecer aberto. As cores usadas para
  diferenciar os modelos nesse painel são geradas automaticamente e
  gravadas em cookies, para persistência mínima entre sessões. **Sempre
  habilitada**, esteja oculta ou não — mesmo sem nenhum uso registrado
  ainda, o painel abre normalmente mostrando os totais zerados, sem
  modelos e linha do tempo vazia (o Tool sempre retorna algo, nunca um
  erro; ver `ToolPanel na ferramenta Gastos`, abaixo).
- **Ajuda** — desativada, sem previsão.

Nenhum ícone do `ToolBar` inicia selecionado (`ToolPanel` colapsado ao
abrir um projeto). Sempre que o usuário abre um projeto ou troca entre
projetos, o Frontend reavalia `hidden_tools` para saber quais ícones
ficam visíveis — isso não afeta seleção, só visibilidade.

## Comportamento

- Mesma lógica de seleção/desseleção da `ContextBar` (clicar na
  ferramenta já selecionada a desmarca, ocultando a `ToolPanel`).
- Ao clicar num ícone do `ToolBar`, o `ToolPanel` abre imediatamente com
  um spinner, enquanto o Frontend busca os dados em
  `POST /projects/{id}/tools/{tool}` (ver `../05-api.md` > Tools e
  `../06b-services.md` > ToolService), enviando o identificador da
  ferramenta e quaisquer dados complementares que ela precise (nenhuma
  ferramenta do MVP usa isso ainda).
- Ícone de "três pontos" para ocultar/mostrar ferramentas específicas
  (mesmo conceito do menu de exibição da `ContextBar`). Essa
  preferência é salva **por projeto**, em `configs.hidden_tools`, com o
  mesmo debounce de 3s + envio assíncrono da `ContextBar` (ver
  `ContextBar` > Menu de exibição, acima).
- Haverá ícones nativos da Ana que não poderão ser ocultados pelo
  usuário (mesmo princípio da `ContextBar`).
- Também prevê ícones alinhados no rodapé, para uso futuro.

---

# 7. Desktop

Área de trabalho principal. Ocupa toda a altura da tela descontados
`Header` e `Footer`, e toda a largura descontadas `ContextBar` e
`ToolBar`.

O que aparece aqui depende do contexto selecionado na `ContextBar`. Por
padrão, exibe a tela de conversa (chat) com a Ana.

Dividido em 3 painéis:

## WorkPanel (esquerda)

- Muda conforme o contexto selecionado.
- Se nenhum contexto estiver selecionado, colapsa deslizando para a
  esquerda, para fora da visão — como se saísse da "tela" do Desktop.
- Largura fixa: 256px (ver `Requisitos Não-Funcionais` > Dimensões).
- Tem um toggle flutuante, sempre visível, posicionado à direita do
  próprio painel — faz parte da `WorkPanel`, não do `Main`. Permite
  alternar a visibilidade da `WorkPanel`.
- Se nenhum contexto estiver selecionado e o usuário reabrir a
  `WorkPanel` pelo toggle, o contexto "Chats" abre por padrão.

## Main (centro)

- Área de conversa principal.
- Ocupa a largura que sobra entre `WorkPanel` e `ToolPanel` (os painéis
  irmãos).
- No MVP, exibe fixamente o chat ativo.
- No futuro, essa área também exibirá outras telas, como "Settings".
- Layout da conversa inspirado no Claude.ai (web) — referência só de
  estrutura/espaçamento, ainda a detalhar quando o restante da
  paleta/dimensões for fechado. A fonte continua sendo a padrão do site
  (D-DIN, ver `Requisitos Não-Funcionais` > Tipografia) — não uma fonte
  própria da área de chat:
  - coluna de conteúdo centralizada, com largura máxima (não ocupa 100%
    da largura disponível em telas largas);
  - mensagens sem bolha com contorno pesado — diferenciadas por
    alinhamento/peso de fonte e leve destaque de fundo na mensagem do
    usuário (`gray-3` para texto do usuário, branco para a Ana, ver
    `Requisitos Não-Funcionais` > Cores);
  - composer fixo na base do painel, anexo à esquerda do campo de texto
    e botão de enviar à direita (já presente em `tmp/layout.png`);
  - conteúdo das respostas renderizado em markdown (títulos, listas,
    blocos de código com syntax highlight — ver Card de bloco de
    código, abaixo);
  - sem avatar por mensagem — a distinção usuário/Ana é só por estilo
    de texto;
  - espaçamento vertical generoso entre mensagens.

### Card de bloco de código

Sempre que a resposta da Ana contiver um bloco de código, SQL ou
markdown, ele aparece dentro de um card específico, com botão de
copiar.

- Fundo do card: mesmo fundo usado nos painéis (`gray-1`, ver
  `Requisitos Não-Funcionais` > Cores);
- Fonte: **JetBrains Mono** (diferente da fonte padrão do site, D-DIN)
  — arquivo próprio, mesmo esquema de self-hosting descrito em
  `../04-frontend.md` (`styles/fonts/`).

### Chat ativo

- O chat ativo é armazenado no estado da sessão e persiste mesmo
  trocando de contexto na `ContextBar` (ex: indo para "Files" e
  voltando para "Chats" mantém o mesmo chat aberto).
- `Main` pode ficar **sem** nenhum chat selecionado — tanto quando o
  projeto ainda não tem nenhum chat, quanto depois de um clique em
  "Novo chat" (ver `WorkPanel no contexto Chats`, abaixo) — nesse
  estado, exibe uma tela vazia (exatamente como em `tmp/layout.png`):
  sem título, sem histórico, só o composer pronto para receber a
  primeira mensagem.
- Um chat só passa a existir de verdade (e a aparecer na lista de
  Chats da `WorkPanel`) depois que sua primeira mensagem é processada
  com sucesso — a criação do chat e o envio da primeira mensagem são
  uma única chamada atômica (`POST /projects/{id}/chats`, corpo igual a
  `MessageCreate` — ver `../05-api.md` > Chats). Não existe estado
  "chat criado, mas ainda sem mensagem".
- Se essa primeira mensagem for rejeitada por qualquer motivo (Guard,
  ou a Ana rejeitando o conteúdo), nenhum chat é criado — o item nunca
  chega a aparecer na lista, e o Frontend mostra um alerta de erro
  (não uma mensagem de evento, já que não existe chat para guardá-la —
  ver `Estado de erro`, abaixo).

### Composer

- Campo de texto expande conforme o conteúdo (texto digitado ou
  anexos), até no máximo 1/3 da altura do `Desktop` — além disso, passa
  a ter scroll interno.
- Atalho de envio padrão: `Enter` envia a mensagem, `Shift+Enter` quebra
  linha.
- Ícone de toggle ao lado do anexo alterna entre os dois modos de
  atalho. Tooltip (mouseover) do ícone: "Enviar com ENTER".
  - **Ativado**: `Enter` envia, `Shift+Enter` quebra linha (padrão
    acima);
  - **Desativado**: `Shift+Enter` envia, `Enter` só quebra linha.
- Ícone de anexo (clipe): atalho direto para o seletor de arquivo
  nativo do sistema operacional — sem dropdown ou menu intermediário.
- A **primeira mensagem** de um chat pode ter anexo, mas o texto é
  **obrigatório** nela (não pode ser só anexo — precisa de conteúdo
  para a Ana gerar o título do chat, ver Geração de título do chat,
  abaixo). Nas demais mensagens, texto é opcional se houver ao menos um
  anexo.
- Uma mensagem precisa ter **texto ou anexo** para ser válida — não é
  possível enviar uma mensagem sem nenhum dos dois (botão de enviar
  fica desabilitado nesse caso). Na primeira mensagem do chat, texto é
  sempre exigido, independente de ter anexo ou não.
- Além da validade de texto/anexo, o botão de enviar também exige um
  modelo ativo **selecionado e resolvido como disponível** (status
  `normal`, ver `../06b-services.md` >
  `ProviderCacheService.resolve_active_model`) — sem isso, o botão fica
  desabilitado independente do que foi digitado. Um projeto novo (ou
  uma instalação nova da Ana, antes de qualquer provider ser cadastrado)
  nasce sem nenhum modelo pré-selecionado
  (`configs.active_provider_id`/`active_model_ref` `NULL`) — nesse caso
  o dropdown mostra um rótulo neutro de call-to-action (ex: "Selecionar
  modelo"), **sem** a cor `warn` (não é uma falha, é só o estado
  inicial, ver `Provider indisponível`, abaixo), e o botão de enviar
  permanece desabilitado até o usuário escolher um modelo pela primeira
  vez.
- Se a mensagem tiver **somente texto** (sem nenhum anexo), esse texto
  precisa ter no mínimo 2 caracteres para o botão de enviar ficar
  habilitado (configurável via `MIN_TEXT_LENGTH`, ver
  `src/.env.example`). Com anexo, não há mínimo de texto. O Backend
  valida a mesma regra e rejeita o envio inteiro do mesmo jeito que o
  estouro de limite de anexos (ver `../05-api.md` > Messages e
  `../06b-services.md` > GuardService) — sem processar
  nem registrar a mensagem. O Frontend busca esse valor (e o de
  `MAX_ATTACHMENTS_PER_MESSAGE`, abaixo) em `GET /limits` (ver
  `../05-api.md` > Limits), em vez de replicar os defaults do Backend.
- Limite de anexos por envio (ver `../../contracts/attachment.md` >
  Limite e retenção — hoje 10, configurável via
  `MAX_ATTACHMENTS_PER_MESSAGE`, ver `src/.env.example`):
  - o ícone de anexo (clipe) fica **desabilitado** assim que o limite é
    atingido nessa mensagem;
  - se o usuário tentar selecionar de uma vez mais arquivos do que o
    limite permite (seleção múltipla no seletor do SO), a seleção
    inteira é rejeitada imediatamente — nenhum dos arquivos é anexado;
  - se, ainda assim, uma mensagem acima do limite chegar ao Backend
    (com ou sem texto), o envio inteiro é rejeitado — a mensagem não é
    processada nem registrada (ver `../05-api.md` > Messages). Nesse
    caso, o Frontend devolve o texto digitado (se houver) para o
    composer e remove todos os anexos daquela tentativa, para o
    usuário recomeçar a anexação.
  - Rejeição por seleção múltipla acima do limite ou pelo Backend:
    notificação estilo *toast* é evolução futura, fora do MVP (ver
    `Evolução Futura`).
- Proteção contra dupla submissão (intencional ou acidental): o botão
  de enviar (e o atalho de teclado equivalente) fica desabilitado
  imediatamente ao ser acionado, antes mesmo da resposta do Backend —
  evita reenvio por duplo clique/tecla repetida na mesma aba. Essa
  proteção precisa funcionar mesmo entre abas, navegadores ou
  dispositivos diferentes olhando o mesmo projeto — o mecanismo real é
  a trava de processamento por projeto do próprio Backend
  (`processing_chat_id`, atômica — ver `Bloqueio de envio durante
  processamento`, abaixo), que qualquer sessão enxerga da mesma forma;
  o desabilitar imediato do botão é só a camada extra do Frontend para
  a mesma aba.

### Anexos na mensagem

- Cada anexo aparece como um ícone acima da mensagem enviada (um ícone
  por anexo).
- Clicar no ícone abre um modal, com conteúdo conforme o tipo do anexo
  (lista completa de tipos aceitos em
  `../../contracts/attachment-mime-types.md`):
  - **texto simples reconhecível** (categoria `text`, ex: `.php`, `.js`,
    `.csv`) — caixa de texto parecida com o Card de bloco de código
    (ver `Main`, acima), mas com barra de rolagem e sem ícone de
    copiar;
  - **imagem** (categoria `image`) — abre a imagem;
  - **áudio** e **vídeo** (categorias `audio`/`video`) — abrem em
    players específicos e simples;
  - **demais arquivos** (categoria `document`/`file`, sem preview de
    conteúdo) — modal mostra só ícone e nome do arquivo.
- Passar o mouse sobre o ícone faz aparecer um badge de exclusão
  sobreposto a ele; clicar no badge remove o anexo (ver
  `../../contracts/attachment.md` > Remoção) — vale tanto para mensagens
  já enviadas quanto para anexos ainda presos no composer (mensagem
  ainda não enviada).
- **Anexo ainda não enviado** (composer): o clique no badge chama
  `DELETE /projects/{id}/attachments/staged/{staged_file_id}` (ver
  `../05-api.md` > Attachments) — remove só o arquivo em disco, sem
  gerar nenhum registro, já que o anexo em si (e a mensagem) nunca
  chegaram a existir de fato.
- **Anexo de mensagem já enviada**: a exclusão gera uma mensagem de
  evento na própria conversa — visualmente diferente das mensagens de
  usuário e da Ana, para deixar claro que é um registro temporal, não
  uma fala (ex: "o usuário deletou o anexo X da mensagem Y"). Essa
  mensagem de evento sempre aparece depois da última mensagem do chat.
  - Se a Ana estiver processando uma resposta no momento em que o anexo
    é apagado, a mensagem de evento só aparece depois que a resposta da
    Ana retornar — mantendo a regra de sempre vir após a última
    mensagem.
  - Estilo: ícone ainda a desenhar; cor do ícone `purple`, cor
    secundária `gray-0` (ver `Requisitos Não-Funcionais` > Cores);
    alinhamento igual ao das mensagens do usuário.
  - Modelada como `role = 'event'` em `messages` (ver `../07-database.md` >
    messages e `../../contracts/message.md`).

### Armazenamento e retenção de anexos

- Limite de anexos por envio (por mensagem) — ver Composer, acima.
  Sem limite total por projeto.
- Anexos são armazenados em `.ana/storage`, na raiz do projeto (projeto
  local) — não num diretório compartilhado entre projetos.
- Anexo é removido fisicamente junto com a mensagem que o originou, se
  essa mensagem (ou o chat dela) for apagada.
- Anexos são **itens descartáveis por padrão**: permanecem por 12 horas,
  a não ser que o usuário os remova manualmente antes disso, ou peça
  explicitamente para a Ana removê-los antes do prazo.
- Só os documentos do próprio projeto (já salvos na pasta do projeto)
  são permanentes por padrão. Anexo é sempre um artefato de uso
  temporário (prints, manuais, imagens etc.) — se o usuário quer que
  algo enviado (documentação, print, mídia, link para baixar algo) se
  torne permanente, precisa pedir explicitamente para a Ana salvar
  aquilo em algum lugar do projeto.
- Arquivo produzido pela própria Ana **nunca** é considerado anexo — já
  nasce salvo na pasta do projeto, não em `.ana/storage`.
- Anexo pertence sempre a uma mensagem (nunca a um chat/projeto
  diretamente — isso é derivado da mensagem). Enquanto preso no
  composer (mensagem ainda não enviada), o arquivo já está salvo em
  `.ana/storage`, mas ainda não é um anexo de fato — só passa a ser no
  momento do envio, junto com a criação da mensagem (ver
  `../07-database.md` > attachments, `../../contracts/attachment.md` e
  `../06b-services.md` > AttachmentService/MessageService). A limpeza por
  retenção de 12h roda como worker (`AttachmentService.cleanup()`),
  cobrindo tanto anexos já enviados quanto arquivos presos no composer
  que nunca foram enviados.

### Bloqueio de envio durante processamento

O bloqueio é **por projeto**: enquanto a Ana estiver processando uma
mensagem ou tarefa ainda não concluída em qualquer chat de um projeto,
não é possível enviar uma nova mensagem em nenhum chat *daquele mesmo
projeto* — mesmo trocando de chat ativo ou saindo e voltando.

Chats de **outros projetos** não são afetados: o usuário pode trabalhar
normalmente em outro projeto enquanto a Ana processa algo no primeiro.
Quando a resposta pendente terminar, ela entra no histórico do chat de
origem e o usuário a vê ao voltar para lá.

Modelado via `projects.processing_chat_id` (ver `../07-database.md` >
projects, `../../contracts/project.md` e `../06b-services.md` >
`MessageService`); tanto `POST /projects/{id}/chats` (primeira
mensagem) quanto `POST /chats/{id}/messages` (demais) retornam
`409 Conflict` quando a trava já está ativa (ver `../05-api.md`). A
leitura e a escrita dessa trava são atômicas no Backend, então duas
submissões simultâneas do mesmo projeto — de abas, navegadores ou
dispositivos diferentes — nunca passam as duas ao mesmo tempo; é essa
trava que garante a proteção contra dupla submissão entre sessões (ver
`Main` > Composer).

O Frontend sabe qual chat está em processamento em tempo real via
`WS /projects/{id}/realtime` (mensagem `processing`, ver
`../10-resilience.md`), não por polling. Consequências de UI:

- enquanto a Ana processa, os **demais chats do projeto** ficam com
  50% de opacidade na `WorkPanel` e não podem ser selecionados — a
  troca de chat ativo fica bloqueada até o processamento terminar;
- se o usuário trocar de projeto e voltar, ou abrir a Ana em outra aba
  no mesmo projeto, a UI seleciona automaticamente o chat que está em
  processamento (ignora o "último chat ativo" nesse caso);
- se o mesmo chat estiver aberto em duas ou mais abas do navegador, uma
  ação feita numa aba reflete na outra imediatamente — incluindo o
  avatar "trabalhando" aparecendo em todas. Isso já vem de graça do
  WebSocket (`WS /projects/{id}/realtime` é por projeto, não por aba —
  toda aba conectada ao mesmo projeto recebe a mesma mensagem
  `processing`); não existe mecanismo de sincronização via cookie
  nenhum.

> Comportamento do bloqueio em relação aos demais contextos (Files,
> Tasks, Git) ainda não está definido — como esses contextos não
> fazem parte do MVP, isso será decidido junto do desenvolvimento
> deles.

### Avatar da Ana

- Mensagens da Ana mostram um avatar — o mesmo ícone do logo no
  `Header`. Mensagens do usuário não têm avatar.
- O avatar tem múltiplas **expressões**, que podem ser adicionadas com
  o tempo. Exemplos de hoje: sucesso, conseguiu achar, terminei de
  fazer, não entendi, fiz mas deu trabalho, fiz facilmente, estudei
  para responder.
- A Ana escolhe a expressão avaliando qual situação faz mais sentido
  para a resposta que está dando — não analisa a própria imagem do
  avatar.
- Um arquivo separado define, por expressão: uma frase descritiva usada
  só como referência interna para a Ana decidir (nunca exibida ao
  usuário), a URL da imagem, e uma legenda (`caption`) que **é** exibida
  ao usuário — como descrição flutuante (tooltip) ao passar o mouse
  sobre o avatar.
- A escolha da expressão vem do Backend; o Frontend recebe a URL da
  imagem e a legenda já resolvidas, prontas para exibir — não mantém
  nenhum mapeamento próprio de expressão para asset.
- Persistida em `messages.avatar_expression` (ver `../07-database.md` >
  messages) como identificador; decidida em `MessageService`
  (`start_chat`/`send_message`, ver `../06b-services.md`), com
  referência em `shared/prompts/avatar-expressions.json` (ver
  `../01-system.md`). Na resposta de `MessageRead`, esse identificador
  já vem resolvido para `{id, image_url, caption}` — nunca uma string
  solta que o Frontend precise traduzir.

### Estado de processamento

- Enquanto a Ana processa, o avatar mostra um GIF animado do rosto dela
  "trabalhando" — um conjunto de expressões diferente das usadas nas
  respostas.
- Ao lado do avatar, uma mensagem "..." animada (indicador de
  digitação).
- Esse avatar "trabalhando" aparece em **todos os chats do projeto**
  enquanto o bloqueio por projeto estiver ativo (ver Bloqueio de envio
  durante processamento) — mas o retorno, seja sucesso ou erro, só
  aparece no **chat de origem** (aquele onde a mensagem foi enviada).

### Carregamento do histórico

Ao trocar de chat ativo, enquanto o histórico de mensagens carrega,
aparece um spinner (SVG animado) centralizado na área de histórico.

### Estado de erro

Dois casos, dependendo de onde a falha acontece (validação ou chamada
ao LLM — ver `../06b-services.md` > MessageService):

- **Mensagem adicional de um chat existente** — a falha vira uma
  mensagem `role = 'event'` persistida no histórico do chat: "Hum,
  algo deu errado"; abaixo, o erro real/técnico. Visualmente é um
  evento (não uma fala da Ana, sem avatar — mesmo estilo do evento de
  exclusão de anexo, ver `Anexos na mensagem`), e sobrevive a reload —
  quem reabrir o chat depois continua vendo o registro. O erro também
  é gravado nos logs do Backend, filtrável por projeto (ver
  `../03-backend.md` > Camadas > Logging).
- **Primeira mensagem de um chat novo** (`POST /projects/{id}/chats`) —
  como o chat não chega a existir quando essa mensagem falha (ver
  `Main` > Chat ativo), não há onde persistir um evento: o Frontend
  mostra um alerta de erro transitório (mesmo texto "Hum, algo deu
  errado" + detalhe técnico), sem deixar rastro no histórico nem na
  lista de chats.

Princípios gerais de tratamento de falha (detectar, explicar, permitir
retry/rollback) valem para os dois casos — ver `../10-resilience.md`.

### Provider indisponível

O Frontend reflete o status do modelo ativo do projeto em tempo real,
via `provider_stack` no `WS /projects/{id}/realtime` (delay máximo de
**3 segundos** — ver `../10-resilience.md` > Monitoramento de status em
tempo real) — a cada mensagem, resolve de novo se o modelo ativo mudou
de estado (ver `../06b-services.md` > `ProviderCacheService.resolve_active_model`).
Dois estados distintos, ambos bloqueando o envio de mensagens e ambos
com o texto do dropdown de Provider/Modelo na cor `warn` + badge `warn`
no ícone de Configs (`ToolBar`, ver `Requisitos Não-Funcionais` >
Cores), mas com **avisos diferentes**, pra deixar claro qual é qual:

- **indisponível** (transitório) — o provider/modelo ainda existem,
  mas a checagem de conectividade mais recente falhou. Aviso: "Provider
  indisponível no momento — tente novamente em instantes". Volta ao
  normal sozinho assim que a próxima checagem confirmar disponibilidade
  — o usuário não precisa fazer nada;
- **removido** — o provider foi excluído de fato, ou o projeto perdeu
  o acesso a ele (desassinou, ou a credencial que usava virou privada de
  outro projeto), ou o modelo específico foi removido do catálogo.
  Aviso: "Provider do modelo foi removido — escolha outro modelo".
  Diferente do caso acima, esse não se resolve sozinho **a menos que**
  o acesso seja restabelecido (provider recadastrado/assinado de novo,
  ou modelo do mesmo `provider_ref` reaparecer no catálogo) — aí volta
  ao normal automaticamente, sem o usuário reabrir o dropdown e escolher
  de novo.

Em ambos os casos, o dropdown colapsado (`[ MODELO 12 ]`) continua
mostrando o nome do modelo que estava ativo, mesmo que ele já não
apareça na lista expandida da pilha — o Backend resolve
`active_provider_id`/`active_model_ref` (ver `../07-database.md` >
configs) e devolve o `display_name`/nome do modelo assim que consegue.
Só na exclusão física de fato do provider (evento raro — ver
`../../contracts/provider-subscription.md`) esse nome deixa de existir
em algum lugar pra resolver; nesse caso o dropdown cai num rótulo
genérico ("Provider removido") em vez do nome específico.

Um terceiro estado, **sem modelo ativo** (`configs.active_provider_id`
`NULL` — projeto que nunca teve um modelo escolhido, ver `Main` >
Composer, acima), bloqueia o envio da mesma forma, mas não é tratado
como falha: sem nome nenhum pra mostrar (nunca houve escolha), sem cor
`warn`, sem aviso/notificação — o dropdown só convida a escolher um
modelo. Diferente de "removido", esse estado nunca "volta ao normal
sozinho" (não há nada que recadastrar) — só se resolve quando o usuário
escolhe um modelo pela primeira vez.

### Geração de título do chat

- Título do chat gerado automaticamente a partir da primeira mensagem.
- A primeira mensagem carrega uma flag (`messages.is_first`, ver
  `../07-database.md` > messages) indicando que é a primeira do chat, para
  a Ana tratar isso internamente — `MessageService.start_chat` aciona
  a geração do título como parte do mesmo fluxo (ver
  `../06b-services.md`).
- A resposta de `POST /projects/{id}/chats` já inclui o chat gerado
  (`id` e `title`) — o Frontend não precisa de uma chamada extra para
  adicionar o item já com o título certo na `WorkPanel` (ver
  `../../contracts/message.md`).

### Scroll do histórico

- O gatilho para buscar mensagens novas é sempre a mensagem
  `new_message` do `WS /projects/{id}/realtime` (ver
  `../10-resilience.md`) — nunca a transição de `processing` para
  `null` isoladamente. Ao receber `new_message` para o chat
  atualmente aberto, o Frontend refaz `GET /chats/{id}/messages`.
- Não rola automaticamente para a última mensagem quando chega uma
  resposta da Ana, nem quando um anexo é excluído (mensagem de evento).
- Rola automaticamente quando o próprio usuário envia uma mensagem.
- Indicador discreto de mensagem não lida, flutuante acima do
  composer: aparece quando o usuário está com o scroll em mensagens
  antigas enquanto a Ana responde (ou termina de processar) e uma
  mensagem nova chega fora da área visível.
- O indicador some assim que a mensagem nova entra no campo de visão
  (usuário rola até ela).
- Clicar no indicador rola automaticamente até o final da conversa —
  não muda a regra acima, é só um atalho para o mesmo resultado (o
  indicador some ao a mensagem nova entrar em vista, seja por scroll
  manual ou por esse clique).

## ToolPanel (direita)

- Muda conforme a ferramenta selecionada na `ToolBar`.
- Mesmo comportamento de colapso ao perder seleção — nesse caso,
  desliza para a direita (saindo de vista). Diferente da `WorkPanel`,
  não tem um toggle flutuante equivalente.
- É um **container**: não define layout interno próprio — sua
  estrutura interna é sempre a do container da ferramenta ativa que o
  preenche (ex: o container de Gastos, ver seção 10). O `ToolPanel` em
  si só define a moldura (posição, largura, colapso).
- Diferente da `WorkPanel`, não tem uma única largura fixa: tem 3
  larguras configuráveis por ferramenta (ver `Requisitos
  Não-Funcionais` > Dimensões):
  - **normal**: 256px — mesma largura da `WorkPanel`; é a largura
    mostrada em `tmp/layout.png`;
  - **small**: 128px (metade da normal);
  - **big**: 512px (o dobro da normal).

---

# 8. Footer

Fica imediatamente abaixo do `Desktop`, mas ocupa a largura total do
viewport — diferente do `Desktop`, não é recuado pelas sidebars.

Fortemente inspirado no footer do PhpStorm (JetBrains).

- **Esquerda**: possivelmente um breadcrumb `[projeto > branch >
  contexto]`.
- **Direita**: diversos itens futuros, ainda não definidos.
- Estilo geral: a maior parte do conteúdo usa fonte 10px ou menor, cor
  `gray-3` — ícones na mesma cor (ver `Requisitos Não-Funcionais` >
  Cores).
- Sem interação no MVP. Interações mais avançadas estão previstas para
  quando a Ana já estiver em operação (versões futuras).
- Deve exibir, entre outras coisas, logs de atividade em segundo plano
  (padrão comum em IDEs).

---

# 9. WorkPanel no contexto Chats

Conteúdo, de cima para baixo:

- "Novo chat" — o chat atual perde a seleção e o `Main` é limpo (tela
  vazia de "nenhum chat ainda", ver `Desktop` > `Main` > Chat ativo) —
  só isso: nenhuma chamada à API, nenhum item novo aparece no topo da
  lista de Chats ainda. O item só é adicionado à lista quando a
  primeira mensagem digitada nessa tela vazia retornar com sucesso
  (`POST /projects/{id}/chats`, ver `../05-api.md` > Chats); se for
  rejeitada por qualquer motivo, o chat não é criado no Backend e
  nenhum item novo aparece — sem mensagem de evento, só um alerta de
  erro (ver `Main` > Estado de erro). A ação fica indisponível enquanto
  a Ana estiver processando (mesmo escopo do bloqueio por projeto — ver
  `Main` > Bloqueio de envio);
- "Buscar" — abre um modal de busca;
- seção colapsável "Works" — não prevista para o MVP;
- seção colapsável "Chats" — lista de chats; o item em negrito indica
  o chat selecionado/ativo;
- botão fixo "Novo chat" no rodapé — mesmo comportamento do item acima;
  candidato a remoção, mantido até decisão final.

## Modal de Busca

- Busca por título **e** por conteúdo das mensagens, restrita aos
  chats do projeto atual — dois dos níveis de busca previstos para a
  Ana (título do chat, e mensagens; resumos e memórias ficam para o
  futuro, ver `../11-search.md`).
- Lista de chats encontrados aparece a partir do 3º caractere
  digitado (`GET /projects/{id}/chats/search?q=`, ver `../05-api.md` >
  Chats) — resultado é sempre uma lista de chats, mesmo quando o que
  bateu foi conteúdo de mensagem.
- Dropdown de tópicos, com "Tudo" como opção padrão/selecionada —
  presente no protótipo do MVP, mas **sem funcionalidade** (não
  filtra de fato); existe só para produção de estilo/interação, mesmo
  princípio de "Files"/"Tasks"/"Git" na `ContextBar`. Filtro
  real fica para quando Topic for implementado (ver "Item da lista de
  Chats" > Mudar Tópico, abaixo).

## Item da lista de Chats

Cada item tem um ícone de três pontos (menu de contexto), no mesmo
padrão do Claude.ai (web). Ações:

- **Favoritar** — fixa o chat no topo da lista. Chats favoritados
  formam uma pilha ordenada por quando foram favoritados: o último
  favoritado fica no topo;
- **Renomear**;
- **Arquivar**;
- **Apagar**.

Futuro (fora do MVP): **Mudar Tópico** — equivalente a mudar de projeto
no Claude.ai, usando o conceito de Topic da Ana (ver
`../../contracts/topic.md`).

"Favoritar" ordena por `chats.pinned_at` (ver `09-chats.sql`,
`../07-database.md` > chats e `../../contracts/chat.md`).

---

# 10. ToolPanel na ferramenta Gastos

Dados reais no MVP, vindos de `POST /projects/{id}/tools/gastos` (ver
`../05-api.md` > Tools e `../06b-services.md` >
`TokenUsageService.get_summary`) — agrega `token_usage_totals` e o
preço vigente em `model_prices` (ver `../../contracts/model-price.md`).
Sem uso registrado ainda, o mesmo
endpoint retorna a estrutura zerada (tokens/custo em 0, sem modelos,
linha do tempo vazia) — nunca um erro, e o painel abre normalmente (ver
`ToolBar`, acima).

## Cabeçalho

- título "GASTOS";
- dropdown de moeda — reflete a moeda configurada do projeto
  (`configs.currency_id`); trocar a moeda por aqui continua fora do
  escopo do protótipo do MVP (isso é uma ação de `AI Configs`, ver
  `ToolBar`, acima).

## Bloco Tokens

Contagem bruta, sem custo:

- **Entradas** (↑) — `input_tokens`;
- **Saídas** (↓) — `output_tokens`;
- **Total** — soma de Entradas + Saídas.

## Bloco Estimativa de Custos

Mesmas dimensões, em US$, com uma linha a mais:

- **Entradas** — custo de `input_tokens`;
- **Cache** — custo de `cache_tokens` (não tem contagem própria no
  bloco Tokens acima — só aparece como custo aqui);
- **Saídas** — custo de `output_tokens`;
- **Total** — soma das três linhas acima.

## Bloco Distribuição

- barra horizontal que representa graficamente a **linha do tempo de
  uso por modelo** — não é uma proporção estática de custo; cada
  segmento colorido indica o período em que um modelo foi usado,
  conforme a ordem cronológica de uso no projeto;
- um card por (provider, modelo) usado no projeto — mesmo agrupamento
  de `token_usage_totals`.

### Card de modelo — cabeçalho (sempre visível)

- círculo colorido (mesma cor do segmento correspondente na barra de
  Distribuição);
- nome do modelo;
- percentual — % de tokens daquele modelo em relação ao total global de
  tokens do projeto (não é % de custo);
- valor total em US$ daquele modelo (ou "0" quando sem uso);
- seta de expandir/colapsar.

### Card de modelo — corpo (expansível)

Tabela de 3 colunas (↑ Entrada, ↓ Saída, Total) e 3 linhas:

1. **Preço** — preço **atual** por 1K tokens de entrada (com os dois
   preços de cache como sub-informação, ex: "+cache leitura $0.125/1K,
   +cache escrita $1.50/1K" — provider que não distingue os dois mostra
   só um valor), preço atual por 1K de saída; coluna Total não se
   aplica ("-"). Vem do campo
   `current_price` da linha do tempo (ver
   `../../contracts/api-payloads.md` > Tools > Gastos) — sempre o valor
   vigente agora em `ModelPrice` (ver `../../contracts/model-price.md` e
   `../06b-services.md` > ModelPriceService), informativo, não uma
   reconstrução histórica: se o preço do modelo mudou no meio do uso do
   projeto, essa linha não reflete os valores antigos usados em cada
   chamada passada. `current_price` vem `null` quando o modelo já não
   existe mais (excluído, ou o provider excluído junto) — nesse caso a
   linha mostra "-" nas três colunas. A linha **Custo**, abaixo, continua
   exata em qualquer caso, com ou sem `current_price` — é sempre a soma do que
   cada chamada realmente custou na época, nunca recalculada com o
   preço atual (ver `../../contracts/token-usage-totals.md`);
2. **Tokens** — contagem de tokens de entrada, saída e total;
3. **Custo** — custo em US$ de entrada, saída e total (valores
   negativos, indicando gasto).

---

# 11. Requisitos Não-Funcionais (Design Tokens)

Especificações visuais consolidadas para implementação. Referência
visual: `tmp/layout.png`.

## Cores

| Token          | Hex       | Uso |
|----------------|-----------|-----|
| `purple`       | `#9200FF` | Cor principal — botão de enviar do chat; ícones ativos e seus títulos; ícones dos dropdowns; quadrado de fundo dos ícones selecionados (opacidade 30%); destaque e botões tipo 1 dos painéis; container de dropdown dentro dos painéis (opacidade 30%); efeito fog no canto superior esquerdo; ícone da mensagem de evento (exclusão de anexo) |
| `purple-light` | `#A58FC4` | Texto dos itens listados nos painéis (ex: lista de chats na `WorkPanel` do contexto Chats); ícones no Header; contorno de tabelas; setas das seções colapsáveis |
| `gray-0`       | `#26282C` | Fundo principal; container dos dropdowns do Header (opacidade 30%); fonte escura dos painéis; cor secundária da mensagem de evento (exclusão de anexo) |
| `gray-1`       | `#191A1C` | Fundo da caixa de texto principal do chat; fundo dos painéis; ícones desativados fora dos painéis; fundo do card de bloco de código |
| `gray-2`       | `#1E1F22` | Fundo do `Desktop`; mouseover do container de ícones das Bars; botões tipo 2 dos painéis; linhas dentro de tabelas |
| `gray-3`       | `#6C828B` | Cor padrão de texto dentro dos painéis; menções dentro do chat; mensagens dos usuários no chat |
| `white`        | `#FFFFFF` | Mouseover de texto dos itens listados nos painéis; títulos/textos destacados nos painéis; ícones selecionados e mouseover no Header; setas das seções colapsáveis na `WorkPanel`; texto dentro de dropdowns; ícones selecionados e seus títulos (+ mouseover); texto do agente no chat; seta dos dropdowns; ícone do anexo |
| `warn`         | `#FF6666` | Uma das 4 cores disponíveis para o badge de status opcional dos ícones da `ContextBar`/`ToolBar` (ver nota abaixo); hoje também usada no texto do dropdown de Provider/Modelo quando o provider está indisponível |
| `alert`        | `#FFCC66` | Uma das 4 cores disponíveis para o badge de status opcional dos ícones da `ContextBar`/`ToolBar` (ver nota abaixo) |
| `ok`           | `#669900` | Uma das 4 cores disponíveis para o badge de status opcional dos ícones da `ContextBar`/`ToolBar` (ver nota abaixo) |
| `update`       | `#00CCFF` | Uma das 4 cores disponíveis para o badge de status opcional dos ícones da `ContextBar`/`ToolBar` (ver nota abaixo) |

Regra geral: o título de um ícone sempre usa a mesma cor do próprio
ícone.

O badge de status (bolinha no canto superior esquerdo do ícone, ver
`Bars` em Dimensões) é **opcional** — nenhum ícone exibe badge por
padrão; cada ícone/situação decide se e quando mostrar um, e qual das
4 cores usar. Os nomes dos tokens (`warn`/`alert`/`ok`/`update`) não
prescrevem um significado fixo — servem só de rótulo para a cor em si.

`warn`/`alert`/`ok`/`update` são as cores do sistema de badge de status
dos ícones (bolinha no canto superior esquerdo do ícone) — ver `Bars`
em Dimensões, abaixo, e `ToolBar` > Comportamento.

## Tipografia

- Fonte: **D-DIN**.
- Tamanho padrão: 12px, peso 200.
- Negrito: peso 600.
- Títulos de ícones: regular, normal, 10px.
- Painéis: 11px normal; títulos/destaques: peso 700.
- Texto dentro de tabelas nos painéis: tamanho a inferir de
  `tmp/layout.png` (não especificado).
- **JetBrains Mono** — fonte secundária, só para o card de bloco de
  código no `Main` (ver `Desktop` > `Main` > Card de bloco de código).

> Os tamanhos de fonte são estimados e serão revistos após o primeiro
> protótipo pronto.

## Dimensões

Escala de espaçamento (padding/margem/gap fora do listado abaixo): a
inferir de `tmp/layout.png` pelo codificador; será refinada depois.

### Header

- Altura: 42px.
- **Bloco 1** (logo): 62px largura; 100% altura do Header; conteúdo
  centralizado vertical e horizontalmente.
- **Bloco 2** (central): largura = 100% do viewport menos blocos 1 e 3;
  100% altura; conteúdo centralizado verticalmente; subdividido em dois
  blocos internos com alinhamentos opostos (esquerda/direita).
- **Bloco 3**: 62px largura; 100% altura; conteúdo centralizado
  vertical e horizontalmente.
- Ícone (em qualquer bloco): 20x20px; 100% opacidade.

### Dropdown padrão (bloco 2 do Header)

- Container: largura conforme conteúdo (padding lateral 12px); altura
  30px; border-radius 25%; opacidade de fundo 30%; conteúdo centralizado
  verticalmente.
- Ícone SVG: até 16x16px.
- Texto: negrito, 11px.
- Seta: 8x5px.
- Tudo a 100% de opacidade, exceto o fundo do container (30%).

### Dropdown small (ex: provider/modelo)

Mesma estrutura do dropdown padrão, com diferenças: padding lateral
6px; altura 20px; texto em uppercase. Seta: 8x5px, como em todos os
dropdowns do site.

### Bars (ContextBar e ToolBar — mesma estrutura)

- Largura: 78px.
- **Bloco 1** (topo): 100% largura do Bar, altura dinâmica; ícones
  alinhados verticalmente a partir do topo; margin-bottom 6px entre
  ícones.
- **Bloco 2** (rodapé): 100% largura do Bar, altura dinâmica; ícones
  alinhados verticalmente a partir da base; margin-top 6px entre
  ícones.
- Ícones (blocos 1 e 2): centralizados horizontalmente; padding
  horizontal 6px.
- Container do ícone (`ContextBar`, blocos 1 e 2): 50x50px; padding
  top/bottom 8px; conteúdo centralizado horizontalmente. O container é
  o próprio quadrado colorido de fundo — ocupa 100% do espaço interno e
  só fica visível em ícone selecionado ou mouseover.
- Ícone SVG dentro do container: até 20x20px.
- Badge de status (opcional, ver `Requisitos Não-Funcionais` > Cores):
  bolinha pequena no canto superior esquerdo do ícone, numa das 4 cores
  do sistema de badge (`warn`/`alert`/`ok`/`update`). Todo ícone da
  `ContextBar`/`ToolBar` deve suportar esse badge, para uso futuro —
  hoje só o ícone de Configs (`ToolBar`) o usa de fato, quando o
  provider ativo está indisponível (ver `ToolBar`, acima).

### Desktop

- Largura: 100% do viewport menos `ContextBar` e `ToolBar`; largura
  mínima de **960px** — abaixo disso não há adaptação (versão
  responsiva é evolução futura, fora do MVP — ver `Evolução Futura`).
- Altura: 100% do viewport menos `Header` e `Footer`.
- Painéis (`WorkPanel`/`ToolPanel`) — 3 larguras configuráveis, altura
  sempre máxima do Desktop:
  - **normal**: 256px;
  - **small**: 128px;
  - **big**: 512px.
- `WorkPanel`: alinhada à esquerda do Desktop. Seta das seções
  colapsáveis: 8x5px, branca, 100% opacidade.
- `Main`: largura = disponível menos os painéis laterais; 100% da
  altura do Desktop.
  - Textarea do chat: texto alinhado à esquerda; margin 10px; altura
    120px; largura 100%; padding 8px; fonte 12px.
- `ToolPanel`: alinhado à direita do Desktop; é um container — layout
  interno definido pelo container da ferramenta ativa (ver seção 7 e
  seção 10).

### Footer

- Largura: 100% do viewport.
- Altura: 33px.

## Efeitos

Blur no canto superior esquerdo da tela: um círculo embaçado,
centralizado com o dropdown de Projeto mas levemente deslocado acima.
Faz parte do background do `body` da página — não pertence a nenhum
componente. Ajuste fino previsto para acontecer manualmente sobre o
protótipo.

## Atalhos de Teclado

| Atalho             | Ação                         |
|--------------------|------------------------------|
| `Esc`              | Fecha o modal ou dropdown aberto |
| `Ctrl+Shift+F`     | Abre o modal de Busca (`WorkPanel` > Chats) |
| `Ctrl+N`           | Novo chat |
| `Ctrl+Shift+N`     | Novo projeto |
| `Ctrl+Shift+A`     | Adicionar anexo |

---

# 12. Perguntas em Aberto

Nenhuma no momento.

---

# 13. Evolução Futura

- Uso de uma biblioteca de syntax highlighting para colorir o conteúdo
  do Card de bloco de código (ver `Desktop` > `Main` > Card de bloco de
  código).
- Permitir que o usuário aplique edição básica de markdown na própria
  mensagem (titulação, listas simples, tabelas e bloco de código), sem
  que isso afete a Ana negativamente — a Ana continua recebendo o texto
  normalmente; a renderização visual do markdown aparece só no
  histórico do chat, não no composer enquanto o usuário digita.
  - "```" também especifica blocos de código na mensagem do
    **usuário**, com o mesmo tratamento das mensagens da Ana (Card de
    bloco de código, com ícone de copiar).
- Links enviados pelo usuário no corpo do texto, fora de blocos de
  código, aparecem na cor `purple` e são clicáveis (abrem em outra aba
  do navegador).
- Versão responsiva do Desktop (hoje com largura mínima fixa de 960px,
  sem adaptação abaixo disso — ver `Requisitos Não-Funcionais` >
  Dimensões > Desktop).
- Acessibilidade (a11y) — não prevista ainda, planejada para o futuro.
- Notificação estilo *toast* para rejeição de anexo por limite (seleção
  múltipla acima do permitido, ou rejeição pelo Backend — ver `Main` >
  Composer).
- Validação de tipo de anexo por MIME type, não por extensão — lista de
  tipos aceitos já definida (`../../contracts/attachment-mime-types.md`),
  falta implementar a validação em si; e mecanismos de segurança contra
  anexos potencialmente maliciosos (executáveis, `.bat`, shell scripts
  etc.) — ver `GuardService` em `../06b-services.md`.
- Agente Python especializado em arquivos compactados (`.zip`, `.rar`,
  `.7z`, `.cbr`/`.cbz`): compacta e descompacta, extrai e adiciona
  arquivos dentro do compactado; e, como parte disso, identifica
  conteúdo malicioso e exclui o anexo imediatamente se encontrar algo
  suspeito — hoje esses arquivos são aceitos mas não processados (ver
  `../../contracts/attachment.md` > Limite e retenção e
  `../../contracts/attachment-mime-types.md`).
- Uso do badge de status (opcional) em outros ícones da
  `ContextBar`/`ToolBar` além de Configs — hoje só Configs usa o badge
  de fato (ver `Requisitos Não-Funcionais` > Cores e Dimensões > Bars).
- Painel de Configs com campo de status do provider (estado de falha) e
  a mensagem de erro real/técnica logo abaixo (ver `ToolBar`, acima).
- Tela em Settings pra chamar `ModelPriceService.set_price` (ver
  `../06b-services.md` e `../../contracts/model-price.md`) — hoje nem o
  cadastro de provider/credencial, nem a descoberta automática de
  modelo (`ProviderCacheService.rebuild_cache`) pedem preço; modelos
  descobertos ficam com preço zero até essa tela existir. Preço nunca é
  retroativo (ver `../../contracts/token-usage-totals.md`) — quando essa
  tela existir, editar o preço de um modelo só vai afetar uso futuro.
- UI de restauração de chats arquivados — a API já aceita filtrar por
  `status` em `GET /projects/{id}/chats` (ver `../05-api.md` > Chats),
  mas ainda não há onde visualizar/restaurar arquivados na `WorkPanel`
  (decisão pendente, ver `Item da lista de Chats`, acima).
- Integração real de git no Dropdown de Git (Pull/Push/Novo Branch/
  troca de branch) — hoje só a branch atual é exibida, e mesmo essa
  vem mockada (ver `Header` > Dropdown de Git).
- Mais ferramentas no `ToolBar` além de Gastos (Configs, Ajuda), quando
  saírem do protótipo de estilo/interação.

---

# 14. Documentação Relacionada

## Geral

- `../../00-context.md`
- `../00-development.md`

## Arquitetura

- `../01-system.md`
- `../03-backend.md`
- `../04-frontend.md`
- `../05-api.md`
- `../06-models.md`
- `../06b-services.md`
- `../07-database.md`
- `../08-redis.md`
- `../10-resilience.md`
- `../11-search.md`

## Contratos

- `../../contracts/`
- `../../contracts/attachment.md`
- `../../contracts/attachment-mime-types.md`
- `../../contracts/message.md`
- `../../contracts/project.md`
- `../../contracts/config.md`
- `../../contracts/chat.md`
- `../../contracts/topic.md`
- `../../contracts/provider.md`
- `../../contracts/provider-credential.md`
- `../../contracts/provider-subscription.md`
- `../../contracts/provider-model.md`
- `../../contracts/model-price.md`
- `../../contracts/token-usage-totals.md`
