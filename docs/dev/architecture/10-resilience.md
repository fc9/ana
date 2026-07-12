# 10 - Resiliência

Status: Draft
Versão: 0.1
Última atualização: 2026-07-10
Responsável: Arquitetura

---

# 1. Objetivo

Definir a filosofia de tratamento de falhas da Ana, catalogar os
cenários de falha conhecidos (o que se aplica ao MVP e o que fica para
o futuro), e especificar a observabilidade de ações (tabela `actions`,
futuro).

Determinismo do Core e de agentes/ferramentas é tratado em
`02-core.md` > Orquestrador Ana Core — este documento assume esse
princípio e foca em como a Ana reage quando algo dá errado.

---

# 2. Escopo

## Responsabilidades

- filosofia de tratamento de falha (detectar, explicar, retry,
  rollback, salvar estado, git a favor);
- catálogo de cenários de falha, com status MVP/futuro;
- monitoramento de status em tempo real (provider, banco, sistemas
  críticos) via WebSocket (MVP);
- especificação futura da tabela `actions`.

## Não Responsabilidades

- determinismo do Core/agentes/ferramentas (ver `02-core.md`);
- implementação de tool calls, memória, agentes (fora do MVP, ver
  `02-core.md` > Evolução Futura);
- comportamento de UI detalhado (ver `ui/dashboard.md`).

---

# 3. Visão Geral

## Filosofia de tratamento de falhas

Para qualquer cenário de falha (catalogados abaixo), a Ana deve:

- **detectar** a falha;
- **explicar** o que aconteceu ao usuário — nunca esconder;
- permitir **retry** (tentar de novo);
- permitir **rollback** (desfazer);
- **salvar o estado** no momento da falha — registrado nos logs
  técnicos do Backend, com `project_id` (e `chat_id`/`provider_id`
  quando aplicável) como campo de contexto, filtrável por projeto (ver
  `03-backend.md` > Camadas > Logging);
- nunca corromper o projeto — usa o **git a seu favor** (commits como
  pontos de recuperação; ver `09-projects.md` > Evolução Futura, sobre
  a Ana sempre operar dentro do escopo de um commit).

## Catálogo de cenários de falha

| Cenário                                                         | Status | Observação |
|------------------------------------------------------------------|--------|------------|
| Modelo respondeu mal / erro na chamada ao LLM                    | MVP    | Em chat já existente, vira mensagem `role='event'` persistida no histórico (sobrevive a reload) — ver `ui/dashboard.md` > Main > Estado de erro. Na primeira mensagem de um chat novo, nada é persistido (o chat nunca chega a existir) — ver `06b-services.md` > `MessageService.start_chat` |
| Provider caiu                                                     | MVP    | Detecção em tempo real (≤3s) + bloqueio imediato — ver seção abaixo |
| Anexo inválido                                                    | MVP    | Coberto por `GuardService` (ver `06b-services.md`) |
| Ação parcialmente aplicada por provider indisponível              | MVP    | Coberto pela trava atômica `processing_chat_id` (ver `06b-services.md`) |
| Arquivo não existe ou inacessível na rede                         | Futuro | Depende do módulo Files/Editor (fora do MVP) |
| Tool falhou ou travou                                             | Futuro | Tool calls fora do MVP (ver `02-core.md`) |
| Memória recuperou coisa errada                                    | Futuro | Memória fora do MVP |
| Execução de script bloqueada pelo sistema                         | Futuro | Depende de shell/tools (fora do MVP) |
| Comando travou                                                    | Futuro | Idem |
| Modelo local ficou lento                                          | Futuro | Latência/timeout não é monitorado no MVP, só disponibilidade (ver `06b-services.md` > ProviderCacheService) — afeta qualquer provider, local ou externo |
| Ação parcialmente aplicada por falta de escopo/disco/internet      | Futuro | Depende de operações de arquivo (fora do MVP) |
| Reverter/amend do commit de uma tarefa                            | Futuro | Depende da Ana editar arquivos via git (ver `09-projects.md` > Evolução Futura) |

Catálogo de códigos HTTP correspondentes (400/404/409/422/500/502/503)
em `05-api.md` > Convenções.

## Monitoramento de status em tempo real (MVP)

Canal único `WS /projects/{id}/realtime` (ver `05-api.md` >
WebSocket), com mensagens tipadas:

- `processing` — já concreto no MVP: reflete `projects.processing_chat_id`,
  disparado por `RealtimeService.broadcast_processing` a cada vez que
  `MessageService.start_chat`/`send_message` seta ou limpa a trava (ver
  `06b-services.md`). Delay máximo de 3 segundos entre a mudança real e
  o push;
- `new_message` — já concreto no MVP: dispara sempre que uma mensagem
  nova é persistida num chat (resposta da Ana, evento de erro, ou
  evento de exclusão de anexo), via
  `RealtimeService.broadcast_new_message`. É o único gatilho para uma
  sessão saber que deve refazer `GET /chats/{id}/messages` — a
  transição de `processing` para `null` não é, por si só, garantia de
  que há conteúdo novo pra buscar (embora na prática sempre haja, ver
  `06b-services.md` > MessageService);
- `provider_stack` — já concreto no MVP: dispara só quando a ordenação
  ou a disponibilidade de algum provider/modelo visível ao projeto
  realmente mudou (troca de modelo que reordena a pilha internamente —
  nunca uma reordenação feita pelo usuário no Frontend, ver
  `../contracts/config.md` > Troca de Provider/Modelo —, provider
  cadastrado/removido, ou checagem de disponibilidade que encontrou
  diferença — nunca à toa numa checagem sem novidade), via
  `RealtimeService.broadcast_provider_stack`. É só um sinal (com
  `provider_order_updated_at` como carimbo de versão) — o Frontend é
  obrigado a buscar `GET /projects/{id}/provider-stack` de volta ao
  recebê-lo. Limite de frequência **só para esse tipo de mensagem**
  (não afeta `processing`/`new_message`/`system_status`): no máximo um
  aviso a cada 3 segundos por projeto; o bloqueio se desfaz sozinho no
  fim do prazo mesmo que o Frontend nunca busque a pilha de volta (ver
  `06b-services.md` > RealtimeService e `ui/dashboard.md` > Header >
  Dropdown de Provider/Modelo);
- `system_status` — status do provider ativo, banco de dados e demais
  sistemas críticos. O canal já existe, mas o formato exato dessa
  mensagem ainda não está desenhado (ver `05-api.md` > Evolução
  Futura) — o requisito de delay máximo de 3 segundos já vale desde já
  para quando for implementado.

## Provider caiu (MVP)

- O Frontend identifica quedas/exclusões do provider/modelo ativo via
  `provider_stack` (não `system_status` — esse canal continua reservado
  a banco/sistemas críticos, evolução futura, ver acima), dentro do
  prazo de 3 segundos. O mecanismo é o mesmo cache de disponibilidade
  usado para montar o dropdown de Provider/Modelo, não um monitor
  separado (ver `06b-services.md` > ProviderCacheService e
  `08-redis.md`).
- Dois estados distintos, ambos bloqueando o envio de mensagens até o
  usuário trocar de modelo ou a situação se resolver sozinha:
  **indisponível** (provider/credencial/modelo existem, mas a checagem
  de conectividade mais recente dessa credencial falhou — transitório,
  some sozinho quando a próxima checagem passar) e **removido**
  (provider excluído de fato, projeto perdeu acesso — desassinou, ou a
  credencial virou privada de outro projeto —, ou modelo excluído do
  catálogo — só se resolve restabelecendo o acesso ou o modelo). Ver
  `ui/dashboard.md` > Main > Provider indisponível para o
  comportamento de UI completo (avisos diferentes para cada caso).
- A detecção não depende só do ciclo periódico do cache — que nem é um
  intervalo único: `PROVIDER_CACHE_REFRESH_SECONDS` (padrão 60s) pra
  provider local/self-hosted, `PROVIDER_CACHE_REFRESH_SECONDS_EXTERNAL`
  (padrão 3600s, 60 minutos) pra provider externo (`providers.is_external`,
  ver `06b-services.md` > ProviderCacheService) — testar um serviço de
  nuvem com a mesma frequência de um servidor local custaria rate limit
  à toa. Se uma tentativa de envio real esbarrar numa indisponibilidade
  que o cache ainda não sabia, isso é reportado na hora ao
  `ProviderCacheService`, que recomputa fora de hora quando vale a pena
  (ver `06b-services.md` > `ProviderCacheService.report_unavailable`) —
  na prática, o pior caso de espera é o ciclo normal daquela credencial
  (~60s local, até 60 minutos externo), mas o caminho comum (alguém
  tentando enviar) costuma detectar bem mais rápido — pra provider
  externo, esse caminho acaba sendo o principal, não só um atalho.
- Comportamento de UI (cor do dropdown, badge no ícone de Configs) em
  `ui/dashboard.md` > Header e ToolBar.
- Ao trocar de provider/modelo, a troca é **sempre aceita** — sem teste
  de conexão síncrono bloqueando-a. O usuário só é barrado de enviar
  mensagem depois, via um dos dois estados acima (indisponível/
  removido), nunca no instante da troca (ver `../contracts/config.md` >
  Troca de Provider/Modelo).

## Processamento entre chats e abas (MVP)

Consequência de `processing` (ver acima) — comportamento de UI
detalhado em `ui/dashboard.md` > Main:

- enquanto a Ana processa, os demais chats do projeto ficam com 50% de
  opacidade e a troca de chat ativo é bloqueada;
- reabrir o projeto (trocar e voltar, ou nova aba) seleciona
  automaticamente o chat em processamento;
- o mesmo chat aberto em duas ou mais abas do navegador reflete ações
  entre si imediatamente, incluindo o avatar "trabalhando" em todas —
  de graça via WebSocket (o canal é por projeto, não por aba; nenhum
  mecanismo de cookie envolvido).

## Actions (evolução futura)

Fora do MVP. Para dar visibilidade ao que a Ana faz ao alterar
arquivos, rodar comandos e gerar código, toda ação que envolva
manipulação de arquivos do projeto ou operações em banco de dados deve
gerar um registro vinculado ao chat (e ao topic, se houver), numa
tabela `actions`:

- `chat_id`
- `topic_id` (opcional)
- `intent`
- `tool_used`
- `input`
- `result`
- `affected_files`
- `diff`
- `error` (opcional)
- `next_decision`

Esse registro nunca bloqueia o retorno da resposta ao usuário — é
gravado de forma assíncrona (fila, ver `08-redis.md`), para não atrasar
a resposta da Ana esperando a escrita em `actions`.

---

# 4. Integrações

## Core

O Core é quem detecta e propaga falhas de chamada ao LLM (ver
`02-core.md` > Orquestrador Ana Core). Ferramentas e agentes futuros
(100% determinísticos) reportam falha ao Core, nunca decidem sozinhos
como reagir a ela.

## Frontend

O Frontend é responsável por exibir o "Estado de erro" (ver
`ui/dashboard.md` > Main) e por refletir o status do provider, banco e
demais sistemas críticos em tempo real, via WebSocket.

---

# 5. Evolução Futura

- suporte a logs, diffs e histórico de ações (tabela `actions`, ver
  acima);
- mensagens internas resumidas — visibilidade do raciocínio da Ana sem
  poluir o chat visível ao usuário;
- rollback via git — já coberto pelo princípio de edição sempre dentro
  do escopo de um commit (ver `09-projects.md` > Evolução Futura);
- confirmação explícita do usuário antes de tarefas robustas ou
  irreversíveis;
- os cenários de falha marcados "Futuro" na tabela acima, à medida que
  os módulos correspondentes (Files, Editor, tools, memória, agentes)
  saírem do escopo futuro (ver `02-core.md` > Evolução Futura).

---

# 6. Documentação Relacionada

## Geral

- `../00-context.md`
- `00-development.md`

## Arquitetura

- `02-core.md`
- `03-backend.md`
- `05-api.md`
- `06b-services.md`
- `08-redis.md`
- `09-projects.md`
- `ui/dashboard.md`

## Contratos

- `../contracts/config.md`
- `../contracts/attachment.md`
