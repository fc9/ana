# Database

Status: Draft
Versão: 0.1
Última atualização: 2026-07-10
Responsável: Arquitetura

---

# 1. Objetivo

Apresenta núcleo de armazenamento persistente da aplicação.

---

# 2. Escopo

## Responsabilidades

Este documento define:

- tabelas;
- views;
- relacionamentos;
- convenção de UUID;
- índices;
- migrations.

## Não Responsabilidades

Este documento não define:

- lógica de aplicação (FastAPI, services, rotas).

---

# 3. Visão Geral

## Princípios

- **UUID:** toda tabela de domínio usa UUID como chave primária (exceção:
  `meta`, que é tabela técnica). Isso permite que um Project mantenha sua
  identidade mesmo que o caminho local mude — ver manifesto em
  `09-projects.md`.
- **Timestamps:** toda tabela de domínio possui `created_at`. `updated_at`
  é adicionado apenas onde a entidade pode ser editada após a criação.
- **Exclusão:** segue o padrão de status quando o contract já prevê
  estados (ex: `chats.status = deleted`), evitando uma coluna de
  soft-delete redundante. Tabelas sem conceito de status usam exclusão
  física (a decidir caso a caso).
- **Chaves estrangeiras:** cada tabela pertence a no máximo um "dono"
  direto (ex: `chats.project_id`), conforme definido nos contracts.
  Relacionamentos opcionais (ex: `chats.topic_id`) são FKs anuláveis e
  representam "pertence a nenhum", nunca ausência de dado.
- **Índices:** toda chave estrangeira é indexada. Colunas usadas para
  filtrar listagens (ex: `chats.status`) recebem índice composto com a
  FK correspondente.
- **Custo em USD:** todo valor monetário é calculado e armazenado em
  USD (`token_usage.cost_usd`, `token_usage_totals.cost_usd`). Conversão
  para a moeda do projeto (`configs.currency_id`) acontece só ao servir
  pela API, usando `currencies.rate_to_usd` — nunca é armazenada por
  moeda.

## Esquema

O código sql das tabelas, indices, relacionamentos e migrations e etc se encontra
em arquivos sql armazenados em `src/apps/api/app/db/migrations/` (ver
`03-backend.md` > Estrutura). Ainda não são aplicadas — estamos na fase
de projeto.

A seguir, uma breve descrição da função de cada tabela. Tabelas marcadas
com `(futuro)` não fazem parte do MVP — ver `../00-context.md` > Fora do
Escopo.

### meta

Tabela técnica, sem contract associado. Armazena metadados internos do
banco (ex: versão do schema/migrations aplicadas). Não segue a convenção
de UUID.

### currencies

Contract: `../contracts/currency.md`.

Relacionamentos: nenhuma FK obrigatória — global, referenciada por
`configs.currency_id`.

Campos-chave: código ISO 4217, símbolo, `rate_to_usd` (nulo até ser
configurado/atualizado; USD é sempre 1).

### languages

Contract: `../contracts/language.md`.

Relacionamentos: nenhuma FK obrigatória — global, referenciada por
`users.language_id`.

Campos-chave: código BCP 47, nome, endônimo.

### users

Contract: `../contracts/user.md`.

Representa o usuário da Ana. Sem autenticação no MVP — os campos ficam
limitados a identificação básica (ex: nome); credenciais e login ficam
para quando a autenticação for implementada.

Relacionamentos: 1 user → N projects; pertence a 1 language (preferência
global, usada em toda a Ana — não é configuração de projeto).

### projects

Contract: `../contracts/project.md`.

Relacionamentos: pertence a 1 user; agrupa N chats; possui 1 configs
(1:1).

Campos-chave: caminho da pasta raiz local, UUID do manifesto
(`.ana/manifest.json`, ver `09-projects.md`). Moeda, provider e modelo
NÃO ficam aqui — vivem em `configs` (ver abaixo). Idioma também não fica
aqui — é preferência do usuário (ver `users`). O projeto padrão `Base` é
uma linha especial sem pasta raiz.

`processing_chat_id` (FK anulável, sem constraint de banco — ver
`04-projects.sql`): trava de envio por projeto enquanto a Ana processa
uma mensagem (ver `../architecture/ui/dashboard.md` > Main > Bloqueio de
envio durante processamento). Não-nulo = projeto ocupado; também
identifica o chat de origem, para onde a resposta deve retornar.

`status` (`active`/`deleted`, default `active`): exclusão lógica —
`DELETE /projects/{id}` apenas troca o status, nunca remove a linha; o
projeto `Base` nunca muda de status (regra aplicada na Service, ver
`06b-services.md` > ProjectService). `last_accessed_at` (anulável):
atualizado como efeito colateral de `GET /projects/{id}`, sem endpoint
dedicado de "toque"; usado para ordenar `GET /projects` (mais recente
primeiro). Índice `idx_projects_user_id_status` cobre `(user_id,
status)`.

### providers

Contract: `../contracts/provider.md`.

Relacionamentos: nenhum — tabela **global**, não pertence a projeto
algum (diferente do desenho anterior, onde cada provider tinha um
`project_id` dono). Um projeto nunca cadastra "seu próprio" provider:
ele assina uma credencial de um provider existente, ou provoca a
criação de um novo quando nenhum provider com essa identidade existe
ainda (ver `provider_credentials`/`provider_subscriptions`, abaixo, e
`docs/dev/research/identificacao-unica-de-providers.md`).

Campos-chave: `driver` (adaptador técnico — `openai`, `anthropic`,
`openai_compatible`, `lmstudio`, `ollama` — `CHECK` restringe a esse
conjunto fechado, mesmo padrão de `chats.status`/`messages.role`/
`attachments.type`; adicionar um driver novo exige migration — decide
qual implementação de `services/llm/` trata as chamadas, ver
`../architecture/06b-services.md` > Integrações > Providers) e
`canonical_instance_id` (identifica a
**instalação/serviço**, não a conta — `'official'` para serviços únicos
na nuvem, endpoint normalizado ou `server_instance_id` para self-hosted).
`UNIQUE (driver, canonical_instance_id)` — duas contas diferentes do
mesmo serviço (ex: duas contas OpenAI) são o MESMO `providers` row, com
múltiplas linhas em `provider_credentials`; a conta nunca faz parte da
identidade do provider.

`is_external` (BOOLEAN, default `true`): marca se o provider é
alcançado pela internet (serviço de nuvem de terceiros) ou é local/
self-hosted (mesma máquina ou rede local) — decide o intervalo do teste
periódico de conectividade em `ProviderCacheService`
(`PROVIDER_CACHE_REFRESH_SECONDS` pra local, bem mais espaçado
`PROVIDER_CACHE_REFRESH_SECONDS_EXTERNAL` — 60 minutos por padrão — pra
externo, já que testar um provider de nuvem com a mesma frequência de
um servidor local custa rate limit e possível chamada tarifada à toa).
Default sugerido por `driver` no cadastro (`true` pra `openai`/
`anthropic`/`openai_compatible`, `false` pra `lmstudio`/`ollama`), mas
sempre explícito e sobrescrevível (ver `../architecture/06b-services.md`
> ProviderCacheService).

Modelos ficam em `provider_models` (catálogo, compartilhado por todas
as credenciais desse provider); preço fica à parte, em `model_prices`
(abaixo); credenciais de acesso ficam em `provider_credentials`; o
vínculo de um projeto a uma credencial fica em `provider_subscriptions`
— nenhuma dessas vive nesta tabela.

**Exclusão é física, mas rara**: só acontece quando a última credencial
desse provider fica órfã (sem nenhum assinante, ver
`provider_subscriptions`, abaixo) — bem menos frequente que no desenho
anterior, já que múltiplos projetos podem compartilhar a mesma
credencial. `token_usage`/`token_usage_totals` não têm FK para esta
tabela (propositalmente, ver essas tabelas abaixo) — um log de custo
nunca pode ficar bloqueado ou perder registro histórico por causa dessa
exclusão. Reação em tempo real a cadastro/edição/exclusão de credencial
(recomputar cache, notificar Frontend) é responsabilidade de
`ProviderCacheService`, não desta tabela (ver
`../architecture/06b-services.md`).

### provider_credentials

Contract: `../contracts/provider-credential.md`.

Relacionamentos: pertence a 1 provider.

Uma credencial é uma **conta** de acesso a um provider — duas contas
diferentes do mesmo serviço (ex: conta pessoal e conta da empresa, ambas
na OpenAI) são duas linhas aqui, sob o mesmo `provider_id`.

Campos-chave: `account_or_tenant` (identificador de conta devolvido pelo
próprio provider na validação de acesso — org_id, workspace, tenant;
anulável, já que nem todo provider distingue conta, ex: LM Studio local
sem autenticação); segredo cifrado com AES-256-GCM (ver
`docs/dev/research/cifragem de credenciais.md` e
`../architecture/06b-services.md` > CredentialCipher) — `encrypted_secret`
(ciphertext), `encryption_nonce` (aleatório, único por operação),
`encryption_key_id` (qual chave mestra cifrou, permite rotação),
`encryption_version` (versão do formato/algoritmo) e `secret_hint`
(sufixo mascarado, ex: `sk-proj-••••••••••••aB31`, pra UI exibir sem
decifrar) — o banco nunca recebe a credencial em texto puro; `is_private`
(`false` = pública, qualquer projeto usa sem assinar; `true` = privada,
só quem assina enxerga/usa).

`UNIQUE (provider_id, COALESCE(account_or_tenant, ''))` impede duplicar
a mesma conta (o sistema não permite cadastrar a mesma credencial duas
vezes). No máximo **uma** credencial pública por provider (índice único
parcial `WHERE is_private = false`) — evita ambiguidade de qual
credencial um projeto sem assinatura própria usaria; se um cadastro
pedir pública com outra já existente, o Backend registra a nova como
privada e avisa o motivo (ver `../architecture/06b-services.md` >
ProviderService).

### provider_subscriptions

Contract: `../contracts/provider-subscription.md`.

Relacionamentos: pertence a 1 project; referencia 1 provider (redundante
com `credential_id.provider_id`, mantido por conveniência de consulta) e
1 credential.

Uma assinatura é o vínculo de um projeto a uma credencial — dá acesso de
fato (pra usar e pra gerenciar) a uma credencial privada, ou acesso
rastreado a uma pública. Usar uma credencial pública sem nunca ter
assinado (acesso implícito) não gera linha aqui.

`UNIQUE (project_id, provider_id)`: um projeto só pode ter **uma** conta
assinada por provider — trocar de conta é sempre uma migração da mesma
linha de assinatura para outro `credential_id` (edição de credencial),
nunca uma segunda assinatura pro mesmo provider (ver
`../architecture/06b-services.md` > ProviderService.edit_credential).

Exclusão ("desassinar") é física — remove só a linha de assinatura,
nunca a credencial ou o provider por trás dela, a menos que a credencial
fique órfã como consequência (zero assinantes) — nesse caso a
credencial também é removida fisicamente, e o provider junto, se também
ficar sem nenhuma credencial (ver `../architecture/06b-services.md` >
ProviderService.unsubscribe).

### provider_models

Contract: `../contracts/provider-model.md`.

Relacionamentos: pertence a 1 provider (global — o catálogo de modelos é
propriedade do serviço em si, compartilhado por todas as contas/
credenciais desse provider; gerenciar exige o solicitante ter assinatura
no provider, ver `../architecture/06b-services.md` > ProviderService).

Campos-chave: `provider_ref` — id/slug técnico que o próprio provider
usa para este modelo nas chamadas de API (formato varia por provider;
opaco pra nós). É essa string, não o `id` UUID interno nem `name`, que
dá identidade estável ao modelo entre exclusão e recadastro do provider
dono (ver `configs`, abaixo), e é essa mesma string, junto do `driver`
do provider dono, que identifica o preço do modelo em `model_prices`
(abaixo) — **preço não é campo desta tabela**. `name` é só rótulo de
exibição — pode diferir de `provider_ref` e mudar sem o modelo mudar de
identidade, nunca usado como chave.

Linhas não nascem só de cadastro manual: `ProviderCacheService.rebuild_cache`
descobre o catálogo de cada provider ao vivo (chamando `services/llm/`
com cada credencial) e faz upsert por `(provider_id, provider_ref)` —
modelo já cadastrado tem só `name`/`is_active` atualizados; modelo novo
nasce sem preço nenhum cadastrado ainda (ver `model_prices`, abaixo).
`is_active` reflete esse mesmo processo — passa a `false` quando o
modelo some do catálogo ao vivo de todas as credenciais que responderam
na rodada (não quando o provider inteiro está fora do ar, caso em que o
catálogo simplesmente não é tocado); mantido mesmo `false` só para
referência histórica. Diferente da disponibilidade transitória
(provider/credencial no ar agora), que nunca é persistida aqui — ver
`configs` e `../08-redis.md`.

### model_prices

Contract: `../contracts/model-price.md`.

Relacionamentos: nenhum — tabela **independente**, sem FK pra
`providers`/`provider_models`. Centraliza o preço de um modelo — única
fonte de preço da Ana; não existe mais `price_source` (só uma forma de
obter o preço: consultar esta tabela via
`../architecture/06b-services.md` > ModelPriceService).

Campos-chave: `driver` (mesmo `CHECK` fechado de `providers.driver` —
sem FK aqui pra validar o valor, um erro de digitação faria
`ModelPriceService.get_price` nunca encontrar a linha, preço
silenciosamente zero, sem sinal de erro) + `provider_ref` (`UNIQUE`) —
chaveada pela identidade **técnica e portável** do modelo, não pelo
`provider_id` de uma instância específica: um preço já cadastrado
sobrevive à exclusão/recadastro do provider dono, e é compartilhado
entre instalações
diferentes do mesmo driver que sirvam o mesmo `provider_ref` (ex: dois
servidores `openai_compatible` espelhando o mesmo modelo). Preço por 1K
tokens de entrada, saída, e **dois** preços de cache — leitura
(`cache_read_price_per_1k`) e escrita (`cache_write_price_per_1k`),
já que alguns providers (ex: Anthropic) cobram valores bem diferentes
pros dois; provider que não distingue simplesmente não usa
`cache_write_price_per_1k` (fica em 0). Sem linha para um `(driver,
provider_ref)`, todo preço é considerado zero (ver
`../architecture/06b-services.md` > ModelPriceService), até alguém
cadastrar de verdade (tela em Settings, fora do MVP). Editar o preço
**nunca é retroativo** — `token_usage`/`token_usage_totals` já gravados
mantêm o custo calculado com o preço vigente na época de cada chamada
(ver `token_usage`, abaixo, e `../contracts/token-usage.md`).

### configs

Contract: `../contracts/config.md`.

Substitui a antiga tabela `config` (singleton, Ana-wide, extinta) —
configuração deixou de ser global e passou a ser por projeto.

Relacionamentos: pertence a 1 project (1:1, `project_id` é `UNIQUE`);
referencia 1 currency.

Campos-chave: moeda (padrão: USD — atribuída pela aplicação na criação
do projeto, não por `DEFAULT` de banco), `fixed_contexts` (JSONB —
contextos da `ContextBar` que o usuário não pode ocultar, ver
`../architecture/ui/dashboard.md` > ContextBar; mesmo default gravado
em todo projeto na criação, sem UI de edição no MVP). `hidden_contexts`
e `hidden_tools` (JSONB, default `[]`): contextos/ferramentas ocultados
por escolha do usuário, editáveis via `PATCH /projects/{id}/config`
com debounce de 3s no Frontend (ver `../architecture/ui/dashboard.md` >
Menu de exibição).

`active_provider_id` (UUID, anulável) + `active_model_ref` (TEXT,
anulável): modelo ativo do projeto. Diferente do desenho anterior,
`providers` agora é **global** e só é excluído fisicamente quando fica
sem nenhuma credencial (evento raro, ver `provider_subscriptions`,
acima) — por isso `active_provider_id` já pode ser o UUID direto de
`providers.id`, sem precisar de uma chave por nome (essa instabilidade
só existia quando provider era propriedade de um projeto e podia ser
excluído a qualquer momento). `active_model_ref` continua sendo
`provider_models.provider_ref` (id/slug técnico do modelo) — modelos
específicos ainda podem sumir do catálogo independente do provider
sobreviver, então essa parte da referência continua por chave estável,
não por UUID. Sem FK de banco pra `providers`: mesmo `providers` sendo
estável, o projeto pode perder **acesso** a ele (desassinar, ou a
credencial que usava virar privada de outro projeto) sem que a linha de
`providers` desapareça — resolver "o projeto ainda enxerga esse
provider?" é regra de negócio (checa `provider_subscriptions`/
`provider_credentials.is_private`), não uma FK. O UUID real de
`provider_models` (para preço, chamada ao LLM etc.) é resolvido em tempo
de uso por `ProviderCacheService.resolve_active_model` (ver
`../architecture/06b-services.md`) — se não houver mais acesso, ou o
provider tiver sido excluído de fato, esse é o estado "removido" (ver
`../architecture/ui/dashboard.md` > Provider indisponível).

`provider_order` (JSONB, array de UUID de `providers`, anulável) e
`provider_order_updated_at` (anulável): pilha ordenada de providers
usada para montar o dropdown de Provider/Modelo do Header. `NULL` até a
primeira gravação — nesse caso a ordem exibida é alfabética por
`display_name`, calculada em tempo de leitura (nunca persistida como
fallback). Ids de providers que o projeto perdeu acesso (ou que foram
excluídos de fato) são filtrados silenciosamente na leitura, sem
precisar limpar essa lista — a pilha é sempre recomputada contra o
acesso atual do projeto a cada leitura, nunca é a única fonte da
verdade (ver `../architecture/06b-services.md` > ProviderCacheService).
`provider_order_updated_at` serve de carimbo de versão: o Frontend só
aplica uma pilha recebida via WebSocket se ela for mais nova que a
atual (ver `../architecture/ui/dashboard.md` > Header > Dropdown de
Provider/Modelo).

É a única tabela consultada pela Ana para saber moeda, provider ou
modelo de um projeto — nunca `projects` diretamente.

Existir separada de `projects` resolve a dependência circular entre
`projects`/`providers`/`provider_models`: `projects` não referencia
provider algum, e `providers` agora é global (também não referencia
`projects`) — só `provider_subscriptions` referencia os dois. `configs`
(criada por último) fecha a referência ao provider/modelo ativo sem
criar ciclo algum.

Uma view `project_overview` (definida na mesma migration) junta
`projects` + `configs` (moeda) para leitura conveniente — não tenta
resolver o provider/modelo ativo (isso exige checar
`provider_subscriptions`/`provider_credentials.is_private`, via
`ProviderCacheService.resolve_active_model`, fora do escopo de uma view
SQL simples).

### topics (futuro)

Contract: `../contracts/topic.md`.

Relacionamentos: pertence a 1 project; agrupa N chats (via
`chats.topic_id`).

Campos-chave: nome, memória pública (ver `memories`).

### chats

Contract: `../contracts/chat.md`.

Relacionamentos: pertence a 1 project; pertence a 0 ou 1 topic (FK
anulável, futuro); agrupa N messages; agrupa N attachments.

Campos-chave: título (`title`, anulável — `NULL` só durante a janela
interna de `MessageService.start_chat`, entre criar a linha e
`ChatService.generate_title` rodar; nunca fica `NULL` de fato pro
Frontend, já que uma falha nesse meio-tempo descarta o chat inteiro,
ver `06b-services.md` > MessageService), status (active, archived,
deleted), `pinned_at` (anulável — não-nulo quando o chat está
favoritado, ver `../architecture/ui/dashboard.md` > Item da lista de
Chats). Ordenação de favoritados: mais recente favoritado primeiro
(`ORDER BY pinned_at DESC NULLS LAST`).

Índice recomendado: `(project_id, status)`, para listagem de chats
ativos por projeto.

`GET /projects/{id}/chats/search` busca por `title` OU por conteúdo de
`messages.content` (via `ILIKE`, sem índice dedicado no MVP —
otimização de busca, ex: GIN/tsvector, é evolução futura, ver
`11-search.md`).

Toda linha só é criada em conjunto com sua primeira mensagem (ver
`messages`, abaixo, e `../architecture/06b-services.md` >
`MessageService.start_chat`) — não existe chat sem ao menos uma
mensagem. `GET /projects/{id}/chats?status=` aceita filtrar por status
(default: só `active`), usado para eventualmente listar chats
arquivados (UI de restauração ainda pendente, ver
`../architecture/ui/dashboard.md` > Item da lista de Chats).

### messages

Contract: `../contracts/message.md`.

Relacionamentos: pertence a 1 chat.

Campos-chave: remetente (`role`: `user`, `assistant` ou `event`),
conteúdo. `role = 'event'` é um registro de sistema associado ao chat —
cobre tanto exclusão de anexo (ex: "o usuário deletou o anexo X da
mensagem Y") quanto falha na chamada ao LLM para uma mensagem que **não**
é a primeira do chat (ex: "Hum, algo deu errado: <detalhe técnico>") —
não é fala do usuário nem da Ana. Quando a falha ocorre na primeira
mensagem de um chat (ainda sem `chat_id` persistido), nenhuma linha é
gravada — ver `chats`, acima, e `../architecture/06b-services.md` >
`MessageService`. `avatar_expression` (anulável, só preenchido em
mensagens `assistant`) e `is_first` (marca a primeira mensagem de um
chat, para acionar a geração automática do título) — ver
`../architecture/ui/dashboard.md` > Main > Avatar da Ana e Geração de
título do chat.

Índice recomendado: `chat_id`, para carregar o histórico do chat.

### attachments

Contract: `../contracts/attachment.md`.

Relacionamentos: pertence sempre a 1 message (nunca nulo) — e,
transitivamente, a 1 chat e 1 projeto (via `message.chat_id` e
`chat.project_id`; não há `chat_id`/`project_id` diretos aqui, evita
redundância). A linha só é criada no momento do envio da mensagem, na
mesma transação (ver `../architecture/06b-services.md` >
`MessageService.start_chat`/`send_message`) — antes disso, o arquivo já
está salvo em `.ana/storage`, mas ainda sem linha em `attachments` (ver
AttachmentService.upload).

Campos-chave: tipo (file, image, audio, video, text, clipboard),
referência ao arquivo em `.ana/storage`, na raiz do projeto do chat.

Limite de 10 anexos por envio e retenção de 12h (descartável por
padrão, removido antes por exclusão manual ou pedido explícito à Ana)
são regras de aplicação, não constraints de banco — ver
`../contracts/attachment.md`. A limpeza por retenção roda como worker
(ver `../architecture/06b-services.md` > AttachmentService), usando o
`created_at` já existente para linhas de `attachments`, e o horário do
próprio arquivo em disco para uploads que nunca chegaram a virar uma
mensagem enviada (arquivo órfão em `.ana/storage`, sem linha
correspondente).

Exclusão: física — o contract não define status para attachment, então
a remoção (ver `../contracts/attachment.md` > Remoção) apaga a linha e o
arquivo em `.ana/storage`. Ao soft-deletar um chat (`status =
'deleted'`), os anexos das mensagens desse chat também são removidos
fisicamente na hora, sem esperar as 12h de retenção.

### token_usage

Contract: `../contracts/token-usage.md`.

Relacionamentos: pertence a 1 project; referencia `provider_id`/
`provider_model_id` **sem FK** (UUID solto, mesmo padrão de
`projects.processing_chat_id`) — providers/provider_models são
excluídos fisicamente (ver `providers`, acima), e este log não pode
perder registro histórico de custo só porque o provider foi removido
depois. Referencia opcionalmente 1 chat.

Campos-chave: tokens de entrada, cache (leitura + escrita somadas — só
3 tipos agregados persistidos, ver `model_prices`, acima, e
`../contracts/token-usage.md`) e saída; custo em USD calculado com o
preço **vigente no instante da chamada** e congelado dali em diante —
mudar o preço em `model_prices` depois (edição manual hoje; futuramente,
tela de preços em Settings, fora do MVP) nunca recalcula linhas já
gravadas, só afeta chamadas futuras (ver `../contracts/model-price.md`);
`provider_name`/`model_name` — snapshot do nome de exibição no momento
da chamada (não FK), garante rótulo pro painel de Gastos mesmo com o
provider excluído depois. Log imutável, uma linha por chamada ao
provider.

### token_usage_totals

Contract: `../contracts/token-usage-totals.md`.

Relacionamentos: pertence a 1 project; referencia `provider_id`/
`provider_model_id` sem FK, mesmo motivo de `token_usage` (chave única
em `(project_id, provider_model_id)` — unicidade para upsert, não
integridade referencial).

Campos-chave: soma acumulada de tokens e custo em USD — sempre
**incrementada** pelo `cost_usd` já congelado de cada `token_usage`
novo, nunca recalculada do zero a partir do preço atual do modelo (ver
`../contracts/token-usage-totals.md`); `provider_name`/`model_name`
(mesmo snapshot de `token_usage`, mas atualizado a cada upsert com o
nome mais recente conhecido). Atualizada via upsert síncrono a cada
`token_usage` inserido — é a tabela consultada para exibir consumo por
provider, por modelo e total do projeto (soma das linhas daquele
`project_id`); se o preço de um modelo mudar no meio do histórico, o
total aqui continua exato (é soma do que cada chamada realmente custou
na época), mesmo que já não corresponda a "tokens × preço atual".

### memories (futuro)

Contract: `../contracts/memory.md`.

Relacionamentos: pertence a 1 project; `topic_id` anulável — nulo
significa memória global do projeto; preenchido significa memória de um
topic (pública ou privada, conforme campo de escopo).

Campos-chave: escopo (global, pública de topic, privada de topic),
conteúdo.

⚠️ Esboço sujeito a mudar: `12-memory.md` propõe tipo (usuário,
feedback, projeto, referência) como eixo adicional, e arquivos
Markdown git-tracked em `.ana/` como alternativa a esta tabela —
mecanismo final ainda em aberto, ver `12-memory.md` > Evolução Futura.

### tasks (futuro)

Contract: `../contracts/task.md`.

Relacionamentos: pertence a 1 project.

Campos-chave: descrição, agendamento, status de execução.

### mcps (futuro)

Contract: `../contracts/mcp.md`.

Relacionamentos: nenhuma FK obrigatória — MCP é global, não pertence a
um projeto específico.

Campos-chave: nome, configuração de conexão.

---

# 4. Integrações

## Backend

O Backend é o único módulo autorizado a acessar diretamente o banco de
dados principal da Ana (ver `03-backend.md`).

Nenhum outro módulo, agente ou integração deve executar queries
diretamente contra o PostgreSQL.

---

# 5. Evolução Futura

As tabelas marcadas como `(futuro)` neste documento (`topics`, `memories`,
`tasks`, `mcps`) serão ativadas conforme as funcionalidades
correspondentes forem implementadas — ver `../00-context.md` > Fora do
Escopo.

Outras evoluções previstas:

- suporte a autenticação (colunas de credenciais em `users`);
- histórico/auditoria de alterações;
- Agent, Skill e Tool ainda não possuem tabela própria — a necessidade de
  persistência será avaliada quando esses componentes forem
  implementados.

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
- `06-models.md`
- `06b-services.md`
- `integrations/openclaude.md`
- `08-redis.md`
- `09-projects.md`
- `10-resilience.md`
- `11-search.md`
- `12-memory.md`

## Contratos

- `../contracts/`

