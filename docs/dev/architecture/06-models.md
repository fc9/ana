# 06 - Models e Schemas

Status: Draft
Versão: 0.1
Última atualização: 2026-07-10
Responsável: Arquitetura

---

# 1. Objetivo

Definir os Models (SQLAlchemy) e Schemas (Pydantic) do Backend, um par
por entidade do MVP.

---

# 2. Escopo

## Responsabilidades

Este documento define:

- Models: mapeamento SQLAlchemy de cada tabela;
- relacionamentos entre Models;
- Schemas: contratos Pydantic de entrada e saída da API.

## Não Responsabilidades

Este documento não define:

- estrutura de tabelas, índices, migrations (ver `07-database.md`);
- lógica de negócio (camada Services, ver `06b-services.md`);
- endpoints (ver `05-api.md`).

---

# 3. Visão Geral

## Convenções

- **Models**: SQLAlchemy 2.0 (`Mapped`/`mapped_column`), assíncrono
  (`AsyncSession`). Um Model por tabela, todos herdam de uma `Base`
  declarativa comum (`db/base.py`).
- **Schemas**: Pydantic v2. Sufixo `Read` para resposta, `Create` para
  criação, `Update` para atualização parcial (campos opcionais).
- Nem toda entidade tem os três: `Create`/`Update` só existem onde
  `05-api.md` expõe escrita direta. Tabelas de log (`TokenUsage`,
  `TokenUsageTotals`) não têm nenhum Schema — nunca são escritas por
  payload de cliente, só pela Service (ver `06b-services.md` >
  TokenUsageService).
- Nenhum Schema `Read` expõe `encrypted_secret`/`encryption_nonce`/
  `encryption_key_id` (ProviderCredential) — só `secret_hint` (sufixo
  mascarado) sai do Model para o Schema, nunca o segredo decifrável.
- Tabelas `(futuro)` em `07-database.md` (`Topic`, `Memory`, `Task`,
  `MCP`) não têm Model nem Schema ainda.

## Currency

Model: `id`, `code`, `name`, `symbol`, `rate_to_usd`, `is_active`,
`created_at`, `updated_at` (ver `../contracts/currency.md`).

Schemas: `CurrencyRead`. Sem `Create`/`Update` — lista fixa via seed,
sem endpoint de escrita (ver `05-api.md` > Currencies).

## Language

Model: `id`, `code`, `name`, `endonym`, `is_active`, `created_at`,
`updated_at` (ver `../contracts/language.md`).

Schemas: `LanguageRead`. Sem `Create`/`Update`, mesmo motivo de Currency.

## User

Model: `id`, `language_id`, `name`, `created_at`, `updated_at` (ver
`../contracts/user.md`).
Relacionamento: `language` (Language), `projects` (list[Project]).

Schemas: `UserRead`, `UserUpdate` (`name`, `language_id`) — usados em
`GET`/`PATCH /me`.

## Provider

Model: `id`, `driver`, `canonical_instance_id`, `display_name`,
`base_url`, `is_external`, `created_at`, `updated_at`. Global — sem
`project_id` (diferente do desenho anterior): identidade é
`UNIQUE(driver, canonical_instance_id)`, não por projeto (ver
`../contracts/provider.md` e
`docs/dev/research/identificacao-unica-de-providers.md`). `is_external`
decide o intervalo do teste periódico de conectividade em
`ProviderCacheService` (ver `06b-services.md`) — default sugerido por
`driver` no cadastro, sempre explícito e sobrescrevível.
Relacionamento: `credentials` (list[ProviderCredential]), `models`
(list[ProviderModel]). Exclusão é física, mas rara — só quando a última
credencial fica órfã (ver `ProviderCredential`, abaixo).

Schemas: `ProviderRead`. Sem `Create`/`Update` diretos: um Provider só
nasce/muda como efeito colateral de `ProviderService.register`/
`edit_credential` (ver `06b-services.md`) — nunca por payload próprio.

## ProviderCredential

Model: `id`, `provider_id`, `account_or_tenant`, `encrypted_secret`,
`encryption_nonce`, `encryption_key_id`, `encryption_version`,
`secret_hint`, `is_private`, `created_at`, `updated_at`.
`account_or_tenant` é o identificador de conta devolvido pelo próprio
provider na validação de acesso (anulável — nem todo provider distingue
conta). O segredo em si é cifrado com AES-256-GCM antes de chegar ao
Model (`encrypted_secret`/`encryption_nonce`/`encryption_key_id`/
`encryption_version` — ver `06b-services.md` > CredentialCipher e
`docs/dev/research/cifragem de credenciais.md`) — esses quatro campos
nunca saem do Model para nenhum Schema. `secret_hint` guarda só um
sufixo mascarado pra UI (não é sensível por si só, pode ser exposto).
`is_private`: no máximo uma credencial pública por provider (ver
`07-database.md` > provider_credentials). Relacionamento: `provider`
(Provider), `subscriptions` (list[ProviderSubscription]).

Schemas: `ProviderCredentialRead` (inclui `secret_hint`; nunca
`encrypted_secret`/`encryption_nonce`/`encryption_key_id`). Sem `Create`
isolado: uma credencial só nasce via `ProviderService.register` (junto
de uma assinatura, ver `06b-services.md`); `ProviderCredentialUpdate`
(`secret` opcional — string em texto puro, cifrada pela Service antes
de persistir, nunca chega a existir como campo de Model —, `is_private`
opcional, `project_id` do editor) — usado em
`PATCH /provider-credentials/{id}`, exige o editor já ter uma
assinatura prévia para essa credencial (ver `../contracts/provider-credential.md`).

## ProviderSubscription

Model: `id`, `project_id`, `provider_id`, `credential_id`,
`created_at`. Vínculo de um projeto a uma credencial — dá acesso de
fato a uma credencial privada, ou acesso rastreado a uma pública (ver
`../contracts/provider-subscription.md`). `UNIQUE(project_id,
provider_id)`: um projeto só assina uma conta por provider.
Relacionamento: `project` (Project), `provider` (Provider), `credential`
(ProviderCredential).

Schemas: `ProviderSubscriptionRead`. Sem `Create`/`Update` diretos: só
nasce/migra como efeito colateral de `ProviderService.register`/
`edit_credential`; só é removida via `ProviderService.unsubscribe` (ver
`06b-services.md`) — nunca por payload próprio.

## ProviderModel

Model: `id`, `provider_id`, `provider_ref`, `name`, `is_active`,
`created_at`, `updated_at`. Pertence ao Provider global — catálogo
compartilhado por todas as credenciais desse provider (gerenciar exige
o solicitante ter assinatura, ver `06b-services.md` > ProviderService).
`provider_ref` é o id/slug técnico que o próprio provider usa para o
modelo (opaco pra nós); `name` é só rótulo de exibição. É `provider_ref`
— nunca `name` — que `Config.active_model_ref` guarda como referência
estável, e que (junto do `driver` do provider) identifica o preço do
modelo em `ModelPrice`, abaixo — **preço não é campo deste Model** (ver
`../contracts/provider-model.md`). Relacionamento: `provider`
(Provider).

Schemas: `ProviderModelRead`, `ProviderModelCreate` (inclui
`provider_ref`), `ProviderModelUpdate`.

## ModelPrice

Model: `id`, `driver`, `provider_ref`, `input_price_per_1k`,
`cache_read_price_per_1k`, `cache_write_price_per_1k`,
`output_price_per_1k`, `created_at`, `updated_at`. Tabela
**independente**, sem relacionamento de ORM com Provider/ProviderModel
— centraliza o preço de um modelo por identidade técnica portável
(`driver` + `provider_ref`, `UNIQUE`), não pelo `provider_id` de uma
instância específica (ver `06b-services.md` > ModelPriceService e
`../contracts/model-price.md`). Não existe mais `price_source`: só há
uma forma de obter o preço, que é ler esta tabela — sem linha
cadastrada, todo preço é zero. Preço de cache é dois valores distintos
— leitura e escrita — já que alguns providers cobram valores diferentes
pros dois (ver `TokenUsageService.calculate_cost`, `06b-services.md`);
provider que não distingue simplesmente não usa
`cache_write_price_per_1k` (fica 0). Editar um preço nunca é
retroativo: `TokenUsage`/`TokenUsageTotals` já gravados mantêm o custo
calculado com o preço vigente na época de cada chamada.

Schemas: `ModelPriceRead`. Sem `Create` isolado: uma linha só nasce
quando alguém cadastra um preço de verdade (mecanismo/tela ainda não
desenhado — Settings, fora do MVP); `ModelPriceUpdate`
(`input_price_per_1k`/`cache_read_price_per_1k`/
`cache_write_price_per_1k`/`output_price_per_1k`, identificado por
`driver`+`provider_ref`) — usado por `ModelPriceService.set_price`, sem
Route pública ainda.

## Project

Model: `id`, `user_id`, `name`, `path`, `processing_chat_id`, `status`,
`last_accessed_at`, `created_at`, `updated_at` (ver
`../contracts/project.md`). `processing_chat_id` é
a trava de envio por projeto (ver `07-database.md` > projects e
`../architecture/ui/dashboard.md` > Main > Bloqueio de envio durante
processamento) — não referencia `Chat` via relationship do ORM (sem FK
de banco, ver `04-projects.sql`), só guarda o UUID. `status` aceita
`active`/`deleted` (exclusão lógica; o projeto `Base` nunca muda de
status). `last_accessed_at` é anulável, atualizado como efeito
colateral de `GET /projects/{id}` (sem endpoint dedicado de "toque"),
usado para ordenar `GET /projects` (ver `06b-services.md` >
ProjectService).
Relacionamento: `user` (User), `config` (Config, 1:1), `chats`
(list[Chat]).

Schemas: `ProjectRead`, `ProjectCreate` (`name`, `path`),
`ProjectUpdate` (`name`, `path`).

## Config

Model: `id`, `project_id`, `currency_id`, `active_provider_id`,
`active_model_ref`, `fixed_contexts`, `hidden_contexts`,
`hidden_tools`, `provider_order`, `provider_order_updated_at`,
`created_at`, `updated_at`. `fixed_contexts` é uma lista (JSONB) dos
contextos da `ContextBar` que o usuário não pode ocultar (ver
`../architecture/ui/dashboard.md` > ContextBar). `hidden_contexts` e
`hidden_tools` são listas (JSONB) dos contextos/ferramentas ocultados
por escolha do usuário — sem validação de conteúdo na Service (ver
`06b-services.md` > ConfigService). `active_provider_id` (UUID,
anulável) é o `id` direto de `Provider` — providers agora são globais e
só somem fisicamente num evento raro (última credencial órfã), então a
referência por UUID é estável o bastante; sem FK de ORM, já que o
projeto pode perder **acesso** ao provider (desassinar, credencial virar
privada de outro projeto) sem a linha de `Provider` desaparecer.
`active_model_ref` (anulável) continua por chave estável —
`ProviderModel.provider_ref`, não o `id` — já que modelos específicos
ainda podem sumir do catálogo independente do provider sobreviver. Em
qualquer um dos casos sem correspondência (provider inexistente, ou
existente mas sem acesso do projeto, ou modelo removido do catálogo), o
`id` real de `ProviderModel` é resolvido em tempo de uso por
`ProviderCacheService.resolve_active_model`, nunca persistido aqui.
`provider_order` (JSONB, lista de UUID de `Provider`, anulável) e
`provider_order_updated_at` (anulável) formam a pilha ordenada do
dropdown de Provider/Modelo — aqui o UUID sempre foi aceitável, porque a
pilha é sempre recomputada contra o cache e o acesso atual do projeto a
cada leitura, nunca a única fonte da verdade (ver `06b-services.md` >
ProviderCacheService). Relacionamento: `project` (Project), `currency`
(Currency). Sem relacionamento de ORM direto com Provider/ProviderModel
— mesmo `active_provider_id` sendo um UUID, a resolução de acesso
completa (existe? o projeto enxerga?) é regra de negócio, não uma FK.

Schemas: `ConfigRead` (inclui `fixed_contexts`, `hidden_contexts` e
`hidden_tools` numa única resposta), `ConfigUpdate` (`currency_id`,
`provider_id` opcional, `model_ref` opcional, `hidden_contexts`
opcional, `hidden_tools` opcional) — usados em `GET`/`PATCH
/projects/{id}/config`. `fixed_contexts` não entra em `ConfigUpdate`:
sem UI de edição no MVP (ver `../contracts/config.md`). Sem `Create`
explícito: criado pela Service junto do `Project`, nunca por payload
próprio.

`provider_order`/`active_provider_id`/`active_model_ref` não são
lidos/escritos por `ConfigRead`/`ConfigUpdate` — têm Schema próprio,
só leitura: `ProviderStackRead` (pilha de providers ordenados, cada um
com seus modelos aninhados na ordem do cache mais uma flag
`available`; o modelo ativo resolvido, com `status`:
`normal`/`unavailable`/`removed`, ou `active_model` inteiro `null`
quando o projeto nunca teve modelo ativo (`active_provider_id IS
NULL` — ver `../contracts/config.md` > Modelo ativo removido ou
indisponível); e `provider_order_updated_at`) —
usado em `GET /projects/{id}/provider-stack` (ver `05-api.md` >
Provider Stack e `06b-services.md` > ProviderCacheService). Sem
`ProviderStackUpdate`: a ordenação nunca é escrita pelo Frontend, é
recalculada internamente por `ConfigService.update_config` como efeito
colateral da troca de modelo ativo.

## Chat

Model: `id`, `project_id`, `title`, `status`, `pinned_at`,
`created_at`, `updated_at` (ver `../contracts/chat.md`). `title` é
anulável no banco — só fica
`NULL` durante a janela interna de `MessageService.start_chat` (linha
criada antes de `ChatService.generate_title` rodar); `ChatRead` nunca
serializa um chat com `title` ausente, já que uma falha nesse
meio-tempo descarta a linha inteira (ver `06b-services.md` >
MessageService). `pinned_at` é anulável — não-nulo quando o chat está
favoritado (ver `../architecture/ui/dashboard.md` > Item da lista de
Chats). `topic_id` existe na tabela mas não é mapeado no
Model ainda — coluna reservada para quando Topic existir (ver
`07-database.md` > chats). Relacionamento: `project` (Project),
`messages` (list[Message]). Sem relacionamento direto com Attachment —
acessível via `message.attachments` de cada mensagem do chat.

Schemas: `ChatRead`, `ChatUpdate` (`title`, `status`, `pinned_at`).
`GET /projects/{id}/chats/search` reutiliza `ChatRead` — busca nunca
retorna mensagens isoladas, sempre chats (ver `11-search.md`). Sem
`ChatCreate`: não existe criação de chat isolada — todo chat nasce
junto da sua primeira mensagem, via `MessageCreate` em
`POST /projects/{id}/chats` (ver `06b-services.md` >
`MessageService.start_chat` e `Message`, abaixo).

## Message

Model: `id`, `chat_id`, `role`, `content`, `avatar_expression`,
`is_first`, `created_at`. `role` aceita `user`, `assistant` ou `event`
(mensagem de sistema, ex: exclusão de anexo — ver
`../contracts/message.md`). `avatar_expression` é anulável, só
preenchido em mensagens `role='assistant'` — no Model/banco é só o
identificador da expressão (string, ex: `"estudei_para_responder"`),
resolvido para `{id, image_url, caption}` na serialização do `MessageRead`
(ver `../architecture/ui/dashboard.md` > Main > Avatar da Ana e
`shared/prompts/avatar-expressions.json`, `01-system.md`). `is_first`
marca a primeira mensagem de um chat (aciona a geração do título, ver
`06b-services.md` > MessageService). Relacionamento: `chat` (Chat),
`attachments` (list[Attachment]).

Schemas: `MessageRead`, `MessageCreate` (`content`,
`staged_files` opcional — referências de `AttachmentService.upload`,
viram `Attachment` de fato nesse envio) — `role`, `chat_id`,
`avatar_expression` e `is_first` nunca vêm do cliente; `role` é sempre
`'user'` na criação. `MessageCreate` é reaproveitado por dois
endpoints com respostas ligeiramente diferentes (ver
`06b-services.md` > MessageService):

- `POST /projects/{id}/chats` (`start_chat`, sempre a primeira mensagem
  de um chat novo): sucesso persiste a resposta da Ana
  (`role='assistant'`) e `MessageRead` sempre inclui o campo extra com
  o chat gerado (`id` e `title` — nunca opcional aqui, ver
  `../contracts/message.md`); falha não persiste nada e retorna erro
  (sem `MessageRead`, sem chat criado);
- `POST /chats/{id}/messages` (`send_message`, chat já existente):
  sucesso persiste `role='assistant'`, sem o campo de chat (o chat já
  era conhecido pelo Frontend); falha persiste e retorna `role='event'`
  com o texto padrão de erro, também sem o campo de chat.

## Attachment

Model: `id`, `message_id`, `type`, `storage_path`, `created_at` (ver
`../contracts/attachment.md`). `message_id` nunca é nulo — a linha só é criada no momento do envio da
mensagem (mesma transação, ver `06b-services.md` >
AttachmentService/MessageService). Chat e projeto são derivados via
`message.chat_id`/`chat.project_id`, sem coluna direta aqui.
Relacionamento: `message` (Message).

Schemas: `AttachmentRead`. Sem `Create`: upload multipart/form-data
antes do envio (`POST /projects/{id}/attachments` — escopado ao
projeto, não ao chat, já que o composer permite anexar antes de
qualquer chat existir, ver `06b-services.md` > AttachmentService) só
grava o arquivo em disco e devolve um `staged_file_id`; a linha de
`Attachment` em si é criada pela Service junto da mensagem, nunca por
payload próprio. `DELETE /projects/{id}/attachments/staged/{staged_file_id}`
remove um arquivo ainda staged, sem Schema de resposta (`204`).

## Git (mockado)

Sem Model — não é uma tabela, é um valor lido do sistema de arquivos
(no futuro; hoje mockado). Schema: `GitStatusRead` (`branch: str`),
usado em `GET /projects/{id}/git` (ver `05-api.md` > Git e
`06b-services.md` > GitService).

## Limits

Sem Model — reflete variáveis de ambiente do Backend, não uma tabela.
Schema: `LimitsRead` (`min_text_length: int`, `max_attachments_per_message: int`),
usado em `GET /limits` (ver `05-api.md` > Limits e `src/.env.example`).

## TokenUsage / TokenUsageTotals

Model de cada um, espelhando `07-database.md` > token_usage /
token_usage_totals campo a campo (ver `../contracts/token-usage.md` e
`../contracts/token-usage-totals.md`).

Sem Schema `Read` próprio — nunca expostos linha a linha pela API.
Escritos exclusivamente por `TokenUsageService` (ver `06b-services.md`).
Agregados (não as linhas cruas) são expostos através de
`GastosToolRead` (tokens, custo e linha do tempo por modelo, cada item
com `current_price` opcional — preço vigente agora em `ModelPrice`
(entrada, cache leitura, cache escrita, saída), `null` quando o modelo
já não existe mais, ver `ToolService`/`TokenUsageService.get_summary` em
`06b-services.md`), usado na resposta de `POST /projects/{id}/tools/gastos`
(ver `05-api.md` > Tools). Zerado (não ausente) quando o projeto não tem
uso registrado ainda.

---

# 4. Integrações

## Services

Services são as únicas consumidoras diretas dos Repositories (e, por
consequência, dos Models) — ver `06b-services.md`. Uma Route nunca
acessa um Model ou Repository sem passar por uma Service.

## Repositories

Toda query usa os Models diretamente via `AsyncSession`. Repositories
não devem retornar Schemas — isso é responsabilidade da Route.

## Routes

Toda resposta HTTP serializa a partir de um Schema `Read`, nunca do
Model diretamente (evita vazar colunas internas, ex: `encrypted_secret`
de `ProviderCredential`).

---

# 5. Evolução Futura

- Models e Schemas para Topic, Memory, Task e MCP, quando esses
  componentes saírem do escopo futuro (ver `07-database.md`);
- Schemas de TokenUsage/TokenUsageTotals, quando a interface de custos
  for implementada (ver `09-projects.md` > Evolução Futura).

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
- `05-api.md`
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
- `../contracts/provider.md`
- `../contracts/provider-credential.md`
- `../contracts/provider-subscription.md`
- `../contracts/provider-model.md`
- `../contracts/model-price.md`
- `../contracts/token-usage.md`
- `../contracts/token-usage-totals.md`
