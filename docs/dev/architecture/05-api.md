# 05 - API

Status: Draft
Versão: 0.1
Última atualização: 2026-07-10
Responsável: Arquitetura

---

# 1. Objetivo

Definir os endpoints HTTP expostos pelo Backend para o Frontend.

---

# 2. Escopo

## Responsabilidades

Este documento define:

- endpoints;
- verbo HTTP e caminho;
- o que cada endpoint faz, em uma linha.

## Não Responsabilidades

Este documento não define:

- banco de dados (ver `07-database.md`);
- schemas de request/response campo a campo (camada Schemas, ver
  `06-models.md`);
- regra de negócio (camada Services, ver `06b-services.md`).

---

# 3. Visão Geral

## Convenções

- Nenhum endpoint requer autenticação no MVP.
- Valores monetários (`cost_usd` em `token_usage`/`token_usage_totals`)
  não têm endpoint de consulta linha a linha no MVP — o consumo de
  tokens é silencioso (ver `../00-context.md` > Consumo de Tokens).
  Agregados por projeto (tokens, custo, linha do tempo por modelo) são
  expostos através do Tool de Gastos (`POST /projects/{id}/tools/gastos`,
  ver `Tools`, abaixo) — não é um endpoint dedicado de custos, é a
  mesma via genérica de dados de ferramentas do `ToolPanel`.
- `DELETE /chats/{id}` é exclusão lógica (`status = deleted`), não
  remove a linha — ver `07-database.md` > Princípios > Exclusão.
- `DELETE /attachments/{id}` é exclusão física — remove a linha e o
  arquivo em `.ana/storage`, na raiz do projeto do chat (ver
  `../contracts/attachment.md`).
- `POST /projects/{id}/attachments` salva o arquivo em disco
  (`.ana/storage` do projeto) e responde imediatamente, sem processar o
  conteúdo. Escopado ao **projeto**, não a um chat — o composer permite
  anexar antes de qualquer chat existir (ver `Attachments`, abaixo).
  Processamento futuro (visão computacional, transcrição, leitura de
  documento) roda em `workers/`, de forma assíncrona, sem mudar este
  contrato.
- Erros seguem `{"detail": "<mensagem>"}`. Catálogo de erros comuns:
  - `400` — validação de request (Guard, busca com menos de 3
    caracteres, etc.), sempre com `detail` explicando qual regra falhou;
  - `404` — recurso inexistente ou já excluído;
  - `409` — conflito de estado (ex: projeto processando outra
    mensagem, ver `Messages`);
  - `422` — regra de negócio que impede a operação mesmo com request
    válido (ex: excluir o projeto `Base`);
  - `500` — falha inesperada (chamada ao provider falhou, banco
    indisponível, erro interno). Sempre inclui `detail` com a causa
    técnica — a Ana nunca esconde o erro real do usuário (ver
    `10-resilience.md` > Filosofia de tratamento de falhas);
  - `502`/`503` — provider ou dependência externa indisponível
    (distinto de `500`, que é erro interno da própria Ana).

## WebSocket

`WS /projects/{id}/realtime` — conexão aberta pelo Frontend enquanto o
projeto está aberto. Mensagens do servidor, identificadas por `type`:

- `{"type": "processing", "chat_id": "<uuid>" | null}` — muda sempre
  que `projects.processing_chat_id` muda (ver
  `../architecture/06b-services.md` > RealtimeService e
  `MessageService`). Delay máximo de 3 segundos entre a mudança real e
  o push (ver `10-resilience.md`);
- `{"type": "new_message", "chat_id": "<uuid>"}` — disparada sempre que
  uma mensagem nova é persistida num chat (resposta da Ana, evento de
  erro, ou evento de exclusão de anexo). É o gatilho para qualquer
  sessão com esse chat aberto refazer `GET /chats/{id}/messages` — não
  existe outro sinal de "chegou mensagem nova" (ver
  `../architecture/06b-services.md` > RealtimeService e
  `10-resilience.md`);
- `{"type": "provider_stack", "provider_order_updated_at": "<iso8601>", ...}` —
  só um sinal (não carrega a pilha em si), disparado só quando a
  ordenação ou a disponibilidade de algum provider/modelo visível ao
  projeto realmente mudou (nunca à toa numa checagem periódica sem
  novidade). O Frontend é obrigado a chamar
  `GET /projects/{id}/provider-stack` de volta ao recebê-lo. Limite de
  frequência **exclusivo deste tipo de mensagem** (não afeta
  `processing`/`new_message`/`system_status`): no máximo um aviso a
  cada 3 segundos por projeto; esse bloqueio se desfaz sozinho no fim
  do prazo mesmo que o Frontend nunca busque a pilha de volta (aba
  fechada, projeto trocado etc.) — ver `Provider Stack`, abaixo, e
  `../architecture/06b-services.md` > RealtimeService;
- `{"type": "system_status", ...}` — status de provider/banco/sistemas
  críticos; formato exato é evolução futura (ver `10-resilience.md`).

## Health

- `GET /health`
- `GET /version`

## Limits

Variáveis de ambiente compartilhadas com o Frontend, para validação
client-side sem duplicar/hardcodar os mesmos valores do Backend (ver
`../architecture/06b-services.md` > GuardService).

- `GET /limits` — retorna `min_text_length` (`MIN_TEXT_LENGTH`) e
  `max_attachments_per_message` (`MAX_ATTACHMENTS_PER_MESSAGE`), ver
  `src/.env.example`

## Me

Preferências globais do usuário (não há autenticação/múltiplos usuários
no MVP — representa o único usuário da Ana).

- `GET /me`
- `PATCH /me` — trocar idioma do usuário

## Currencies

- `GET /currencies` — lista para popular dropdown de moeda do projeto

## Languages

- `GET /languages` — lista para popular dropdown de idioma do usuário

## Providers

Providers são **globais** (não pertencem a nenhum projeto) — um projeto
se vincula a um provider através de uma credencial, própria (assinada)
ou pública (usada sem assinar — ver `../contracts/provider.md` e
`../contracts/provider-subscription.md`). O dropdown de Provider/Modelo
do Header não usa estes endpoints diretamente, e sim `Provider Stack`
(abaixo), que já retorna providers e modelos juntos e ordenados.

Exclusão física é rara e nunca direta: só acontece como consequência de
`DELETE /projects/{project_id}/providers/{provider_id}` (desassinar)
esvaziar a última credencial de um provider (ver
`../architecture/06b-services.md` > ProviderService.unsubscribe).

- `GET /providers?project_id={id}` — lista os visíveis ao projeto
  (com credencial pública, ou com assinatura própria); sem ordenação
  garantida
- `POST /providers` — registrar/assinar um provider: `project_id`,
  `driver`, `base_url` (quando aplicável ao `driver`), `secret`,
  `is_private`, `is_external` (opcional — sem informar, o Backend
  sugere um default por `driver`, só considerado quando o provider
  ainda não existe, ver `../contracts/provider.md`). Valida o acesso
  contra o provider antes de tocar o
  banco (`400`/`502` se inválido); se o provider/credencial já
  existirem, **não** cria nem altera nada — só assina, e a resposta
  informa como a credencial já estava registrada (pública ou privada).
  No máximo uma credencial pública por provider: pedir pública com uma
  já existente registra a nova como privada e avisa o motivo. `409` se
  `project_id` já tiver uma assinatura pra esse provider (uma conta por
  provider — pra trocar de conta é `PATCH /provider-credentials/{id}`,
  abaixo). Não altera o modelo ativo de nenhum projeto. Responde
  imediatamente, sem esperar a recomputação do cache (ver
  `../architecture/06b-services.md` > ProviderService.register)
- `GET /providers/{id}`

## Provider Credentials

Sem UI própria no MVP — editar uma credencial cadastrada viveria em "AI
Configs" (ToolBar > Configs), que está **bloqueado por hardcode no MVP**
(ver `../architecture/ui/dashboard.md` > ToolBar); o endpoint abaixo já
existe pronto (só chamável via API direta por enquanto) pra quando esse
bloqueio for removido.

- `PATCH /provider-credentials/{id}` — editar uma credencial: `project_id`
  (de quem edita — precisa já ter assinatura pra essa credencial,
  `403`/`404` caso contrário), `secret` opcional, `is_private` opcional.
  Trocar `secret` pra uma conta diferente da atual migra a assinatura de
  `project_id` pra uma credencial existente (se a conta já estiver
  cadastrada) ou recém-criada — nunca altera credenciais de outros
  assinantes (ver `../architecture/06b-services.md` >
  ProviderService.edit_credential). Responde imediatamente

## Provider Models

Só catálogo (`provider_ref`/`name`/`is_active`) — preço não é campo
aqui, vive em `ModelPrice` (ver `Model Prices`, abaixo). Mesmas regras
de cadastrar/editar (responde imediatamente) e excluir (não espera
recomputação de cache) — exige `project_id` do solicitante ter
assinatura no provider (`403`/`404` caso contrário, ver
`../architecture/06b-services.md` > ProviderService). Linhas também
nascem sozinhas, sem nenhum `POST` — `ProviderCacheService.rebuild_cache`
descobre o catálogo ao vivo de cada provider.

- `GET /providers/{id}/models` — lista para popular telas de gestão de
  modelo; sem ordenação garantida (modelos não são reordenáveis pelo
  usuário — ver `Provider Stack`, abaixo)
- `POST /providers/{id}/models` — cadastrar modelo (`project_id`,
  `provider_ref` técnico + `name` de exibição)
- `PATCH /providers/{id}/models/{model_id}` — atualizar `name`/
  `is_active` (`project_id`)
- `DELETE /providers/{id}/models/{model_id}` (`project_id`)

## Model Prices

Preço por 1K tokens de entrada/cache/saída, centralizado por `(driver,
provider_ref)` — não por `provider_id` (ver `../architecture/06b-services.md`
> ModelPriceService e `../contracts/model-price.md`). Sem registro
cadastrado, o preço é zero. **Sem Route pública ainda** — o Service
(`get_price`/`set_price`) já existe pronto, aguardando a tela de
Settings que vai chamá-lo (fora do MVP, ver
`../architecture/06b-services.md` > Evolução Futura).

## Desassinar Provider

- `DELETE /projects/{project_id}/providers/{provider_id}` — remove
  só a assinatura de `project_id` pra esse provider (só oferecido na UI
  quando essa assinatura existe, ver
  `../architecture/ui/dashboard.md` > Header > Dropdown de
  Provider/Modelo). Se, como consequência, a credencial usada ficar sem
  nenhum assinante, ela é removida fisicamente — e o provider junto,
  se também ficar sem nenhuma credencial (ver
  `../architecture/06b-services.md` > ProviderService.unsubscribe). Só
  responde `204` depois que o cache terminou de recomputar e o
  broadcast (`provider_stack`) foi enviado — é esse delay que sustenta
  o spinner do modal de confirmação na UI

## Projects

- `GET /projects` — ordenados por acesso mais recente primeiro (ver
  `../contracts/project.md`)
- `POST /projects` — criar projeto (nome, path); cria também um `Config`
  associado, com moeda padrão USD
- `GET /projects/{id}` — como efeito colateral, atualiza
  `last_accessed_at` (ver `Convenções` acima e
  `../architecture/06b-services.md` > ProjectService)
- `PATCH /projects/{id}` — renomear, trocar path
- `DELETE /projects/{id}` — exclusão lógica (`status = 'deleted'`);
  projeto `Base` não pode ser removido (regra aplicada na Service, não
  no banco — ver `09-projects.md`). Não valida "projeto ativo" — essa
  checagem é só do Frontend

## Git

- `GET /projects/{id}/git` — retorna `branch` (nome da branch atual).
  **Mockado no MVP**: não executa git de fato, valor fixo — dropdown de
  Git do Header permanece só exibição, sem Pull/Push/troca de branch
  reais (ver `../architecture/ui/dashboard.md` > Header > Dropdown de
  Git e `../architecture/06b-services.md` > GitService)

## Config

Configuração atual do projeto — moeda, provider/modelo ativo, e
preferências de UI do projeto. Ver `../contracts/config.md`.

- `GET /projects/{id}/config` — retorna também `fixed_contexts`,
  `hidden_contexts` e `hidden_tools` numa única resposta (o Frontend
  carrega toda a configuração de UI do projeto de uma vez, ao abri-lo)
- `PATCH /projects/{id}/config` — trocar moeda, provider/modelo ativo
  (`provider_id` + `model_ref` — `provider_id` é o UUID do provider
  global, `model_ref` continua sendo `provider_ref` técnico, não UUID,
  ver `../contracts/config.md`) e/ou `hidden_contexts`/`hidden_tools`. A
  troca de `provider_id`/`model_ref` é **sempre aceita** — sem teste de
  conexão síncrono, sem exigir que o projeto já tenha acesso a esse
  provider no momento (mesmo sem assinatura nem acesso público, a troca
  grava e responde `200` normalmente). Depois de gravar, o Backend
  reordena a pilha internamente (o provider escolhido sobe pro topo, se
  visível ao projeto) e aciona a recomputação do cache de disponibilidade
  em segundo plano (fire-and-forget) — o Frontend não espera nada disso,
  só é avisado depois via `provider_stack` se algo mudar (ver
  `Provider Stack`, abaixo, e `../contracts/config.md` > Troca de
  Provider/Modelo). `hidden_contexts`/`hidden_tools` continuam com
  debounce de 3s no Frontend; a troca de provider/modelo não tem
  debounce, é enviada assim que selecionada

## Provider Stack

Pilha ordenada de providers (com modelos aninhados) e disponibilidade
exibida no dropdown de Provider/Modelo do Header. Só leitura — a
ordenação nunca é escrita pelo Frontend, é sempre recalculada pelo
Backend como efeito colateral de `PATCH /projects/{id}/config` (ver
`../architecture/ui/dashboard.md` > Header > Dropdown de
Provider/Modelo e `../architecture/06b-services.md` >
ProviderCacheService).

- `GET /projects/{id}/provider-stack` — retorna a pilha (providers
  visíveis ao projeto — com credencial pública, ou com assinatura
  própria — ordenados, cada um com seus modelos vindos de
  `provider_models` — nunca ordenável pelo usuário — e uma flag
  `available` por provider, resolvida contra a credencial que esse
  projeto usaria), o modelo ativo resolvido (`provider_id`, `model_ref`,
  e um `status`: `normal`/`unavailable`/`removed` — ver
  `../architecture/06b-services.md` > `ProviderCacheService.resolve_active_model`;
  o campo `active_model` vem `null` por inteiro quando o projeto nunca
  teve modelo ativo — `configs.active_provider_id IS NULL`, não
  tratado como falha, ver `../contracts/config.md` > Modelo ativo
  removido ou indisponível), e `provider_order_updated_at` (carimbo de
  versão). Sem ordem gravada
  ainda (`configs.provider_order IS NULL`): ordena providers por
  `display_name` (alfabético), sem persistir esse fallback. Chamado no
  carregamento do projeto (novo ou reaberto) e sempre que o Frontend
  recebe o aviso `provider_stack` via WebSocket

## Chats

Não existe criação de chat isolada (sem mensagem) — ver
`POST /projects/{id}/chats`, abaixo, e
`../architecture/06b-services.md` > `MessageService.start_chat`.

- `GET /projects/{id}/chats?status=` — lista chats do projeto
  (favoritados no topo, mais recente favoritado primeiro); `status`
  opcional (default `active`) — existe para eventualmente listar
  arquivados, mas ainda não há UI de restauração (ver
  `../architecture/ui/dashboard.md` > Item da lista de Chats)
- `GET /projects/{id}/chats/search?q={query}` — busca por título do
  chat ou conteúdo de mensagens (ver `11-search.md`); `400` se `q` tiver
  menos de 3 caracteres; retorna `list[ChatRead]`
- `POST /projects/{id}/chats` — cria o chat **e** envia sua primeira
  mensagem numa chamada só (corpo igual a `MessageCreate` — `content` +
  `staged_files` opcional; texto é sempre obrigatório aqui, com ou sem
  anexo). Mesmas validações de `GuardService` de
  `POST /chats/{id}/messages` (abaixo), incluindo a resolução do modelo
  ativo via `ProviderCacheService.resolve_active_model` (`422` se
  "removido" ou "sem modelo ativo" — projeto que nunca teve um modelo
  escolhido —, `503` se "indisponível"). Se a validação, a resolução do
  modelo, ou a chamada ao LLM falhar por qualquer motivo, **nenhum chat
  é criado** — nem `Chat`, nem `Message`, nem `Attachment` — e a
  resposta é só o erro (`400`/`422`/`500`/`502`/`503`, sem mensagem de
  evento, já que não existe chat para guardá-la). Em caso de sucesso,
  `201` com a resposta da Ana e o chat gerado (`id`, `title`) sempre
  presentes (ver `../architecture/06b-services.md` >
  `MessageService.start_chat` e `../contracts/message.md`). `409
  Conflict` se o projeto já estiver
  processando outro chat
- `GET /chats/{id}`
- `PATCH /chats/{id}` — renomear, arquivar, restaurar, favoritar/
  desfavoritar (`pinned_at`)
- `DELETE /chats/{id}` — exclusão lógica (ver Convenções); também remove
  fisicamente os anexos das mensagens do chat

## Messages

- `GET /chats/{id}/messages` — histórico do chat
- `POST /chats/{id}/messages` — envia uma mensagem **adicional** a um
  chat que já existe (nunca a primeira — todo chat já nasce com uma via
  `POST /projects/{id}/chats`, acima). Aceita `staged_files` opcional,
  referências de arquivos já enviados via
  `POST /projects/{id}/attachments`; cada um vira um `Attachment` de
  fato nesse momento, vinculado à mensagem — ver
  `../architecture/06b-services.md` > MessageService. Validado por
  `GuardService` antes de qualquer gravação (ver
  `../architecture/06b-services.md` > GuardService): `400` se `content`
  e `staged_files` vierem ambos vazios (mensagem precisa ter texto ou
  anexo, ver `../contracts/message.md`); `400` se não houver
  `staged_files` e `content` tiver menos de `MIN_TEXT_LENGTH`
  caracteres (variável de ambiente, padrão 2 — ver `src/.env.example`
  e `Limits`; não se aplica quando há anexo); `400` se `staged_files`
  exceder `MAX_ATTACHMENTS_PER_MESSAGE` (variável de ambiente, padrão
  10 — ver `src/.env.example` e `Limits`); `400` se algum
  `staged_file_id` não resolver pra um arquivo staged **deste mesmo
  projeto** (id de outro projeto, inválido, ou já expirado pela
  retenção de 12h — ver `AttachmentService.resolve_staged`,
  `../architecture/06b-services.md`, e `../contracts/attachment.md`).
  Em qualquer desses casos, nada é persistido e o Core não é acionado.
  Resolve o modelo ativo do
  projeto via `ProviderCacheService.resolve_active_model` (ver
  `../architecture/06b-services.md`) antes de gravar qualquer coisa:
  `422` se o status vier "removido" (provider/modelo excluído) ou "sem
  modelo ativo" (projeto que nunca teve um modelo escolhido), `503`
  se vier "indisponível" (queda transitória) — nenhum dos dois persiste
  nada, mesmo bloqueio já refletido no Composer pelo Frontend (ver
  `../architecture/ui/dashboard.md` > Provider indisponível). Resolvido
  e disponível, dispara chamada ao LLM usando o `provider_models.id`
  encontrado:
  - **sucesso** — `201`, registra `token_usage`/`token_usage_totals` de
    forma síncrona e retorna a resposta da Ana (`role='assistant'`);
  - **falha** (técnica, ou rejeição de conteúdo pela Ana — já
    descartado "removido"/"indisponível" acima) — `201` também (a
    mensagem do usuário já foi persistida; o chat já existia antes
    desta chamada), mas retorna uma mensagem `role='event'` com o texto
    padrão de erro ("Hum, algo deu errado: ..."), persistida no
    histórico do chat (sobrevive a reload) e também registrada nos
    logs do Backend, com `project_id`/`chat_id` (ver
    `../architecture/03-backend.md` > Camadas > Logging,
    `../architecture/ui/dashboard.md` > Main > Estado de erro e
    `10-resilience.md`).

  `409 Conflict` se o projeto já estiver processando outra mensagem (ver
  `../architecture/ui/dashboard.md` > Main > Bloqueio de envio durante
  processamento)

## Attachments

- `POST /projects/{id}/attachments` — upload (multipart/form-data); só
  salva o arquivo em disco e retorna uma referência temporária
  (`staged_file_id`, ainda não é um `Attachment` — vira um de fato só
  no envio da mensagem, ver `Messages`/`Chats` acima). Escopado ao
  projeto, não a um chat (ver Convenções)
- `DELETE /projects/{id}/attachments/staged/{staged_file_id}` — remove
  um arquivo ainda staged (nunca enviado); `204`, sem gerar registro —
  usado quando o usuário remove um anexo do composer antes de enviar
  (ver `../architecture/ui/dashboard.md` > Main > Anexos na mensagem)
- `GET /attachments/{id}` — baixar/visualizar (só existe depois que a
  mensagem foi enviada)
- `DELETE /attachments/{id}` — exclusão física de um Attachment já
  existente (ver Convenções); gera uma mensagem `role = 'event'` no
  chat relatando a remoção

## Tools

Dados dos painéis do `ToolPanel` (ver
`../architecture/ui/dashboard.md` > ToolBar e
`../architecture/06b-services.md` > ToolService).

- `POST /projects/{id}/tools/{tool}` — retorna os dados do painel de
  `tool`; corpo da request pode incluir campos complementares
  específicos da ferramenta (nenhum usado ainda no MVP). Só
  `tool = "gastos"` existe de fato hoje — sempre retorna `200`, mesmo
  sem uso registrado (tokens/custo zerados, linha do tempo vazia, sem
  modelos — nunca um erro, ver
  `../architecture/ui/dashboard.md` > ToolPanel na ferramenta Gastos)

---

# 4. Integrações

## Frontend

O Frontend consome exclusivamente estes endpoints — nunca acessa banco,
Redis ou providers diretamente (ver `03-backend.md` > Integrações).

## Services

Toda rota delega para a camada Services correspondente. Rotas não
contêm regra de negócio — cada Service e seus métodos estão detalhados
em `06b-services.md`.

---

# 5. Evolução Futura

- endpoint dedicado de histórico/detalhe de custos (além do resumo
  agregado já disponível via `Tools`), quando a interface de custos for
  implementada — ver `09-projects.md` > Evolução Futura;
- autenticação e permissões por usuário;
- streaming de resposta (`POST /chats/{id}/messages`,
  `POST /projects/{id}/chats`);
- endpoints para Topic, Memory, Task e MCP, quando esses componentes
  saírem do escopo futuro (ver `07-database.md`);
- `GET /health` mais completo: status do Redis, status do banco de
  dados, acesso aos providers cadastrados, status das filas;
- mensagem `system_status` do `WS /projects/{id}/realtime` (status de
  provider/banco/sistemas críticos) — o canal WebSocket já existe no
  MVP para `processing`/`new_message`/`provider_stack`, mas o formato
  de `system_status` ainda não está desenhado (ver `10-resilience.md`);
- busca em `summaries`/`memories` (ver `11-search.md`);
- validação de anexo por MIME type (não por extensão, lista já
  definida em `../contracts/attachment-mime-types.md`) e rejeição de
  tipos potencialmente maliciosos em `POST /projects/{id}/attachments`
  — ver `../contracts/attachment.md` > Limite e retenção;
- `GET /projects/{id}/git` deixar de ser mockado (integração real com
  git) e ganhar Pull/Push/troca/renomear branch de fato (ver
  `../architecture/ui/dashboard.md` > Header > Dropdown de Git);
- `Tools` ganhar ferramentas além de Gastos (Configs, Ajuda), quando
  saírem do protótipo de estilo/interação.

---

# 6. Documentação Relacionada

## Geral

- `../00-context.md`
- `00-development.md`

## Arquitetura

- `01-system.md`
- `02-core.md`
- `03-backend.md`
- `04-frontend.md`
- `06-models.md`
- `06b-services.md`
- `integrations/openclaude.md`
- `07-database.md`
- `08-redis.md`
- `09-projects.md`
- `10-resilience.md`
- `11-search.md`

## Contratos

- `../contracts/`
- `../contracts/api-payloads.md` — payload/response de cada endpoint,
  campo a campo
- `../contracts/user.md`
- `../contracts/currency.md`
- `../contracts/language.md`
- `../contracts/project.md`
- `../contracts/config.md`
- `../contracts/chat.md`
- `../contracts/message.md`
- `../contracts/attachment.md`
- `../contracts/attachment-mime-types.md` — tipos MIME aceitos para
  anexo
- `../contracts/provider.md`
- `../contracts/provider-credential.md`
- `../contracts/provider-subscription.md`
- `../contracts/provider-model.md`
- `../contracts/model-price.md`
- `../contracts/token-usage.md`
- `../contracts/token-usage-totals.md`

## Postman

- `../database/postman/ana-collection.json`
