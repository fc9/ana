# 03 - Backend

Status: Draft  
Versão: 0.1  
Última atualização: 2026-07-10  
Responsável: Arquitetura

---

# 1. Objetivo

Definir a organização e as responsabilidades do Backend da Ana.

O Backend é o núcleo da aplicação. Ele concentra as regras de negócio, coordena 
a comunicação entre módulos e expõe a API consumida pela Interface Web.

---

# 2. Escopo

## Responsabilidades

O Backend é responsável por:

- expor a API principal da Ana para o Frontend;
- gerenciar chats;
- gerenciar mensagens;
- gerenciar projetos, incluindo a moeda de cada projeto;
- gerenciar anexos;
- gerenciar configurações, incluindo o idioma do usuário;
- gerenciar providers, credenciais e assinaturas (`providers`/
  `provider_credentials`/`provider_subscriptions`), o catálogo de
  modelos (`provider_models`) e o preço centralizado (`model_prices`);
- persistir dados no PostgreSQL;
- comunicar-se com providers LLM;
- registrar consumo de tokens por mensagem, provider, modelo e projeto;
- converter custo em USD para a moeda do projeto ao servir pela API;
- publicar e consumir tarefas via Redis quando necessário;
- validar permissões e limites de acesso a projetos.

## Não Responsabilidades

O Backend não é responsável por:

- renderizar interface;
- manipular diretamente componentes visuais;
- executar lógica de UI;
- editar arquivos locais diretamente;
- executar comandos de sistema diretamente;
- conter lógica específica de um provider LLM;
- armazenar segredos em código;
- implementar agentes complexos no MVP.

---

# 3. Visão Geral

O Backend será implementado como uma aplicação Python com FastAPI.

Ele deve ser organizado por camadas simples, com responsabilidades claras.

**Premissa de execução do MVP: processo único** — um único worker/réplica
do Backend (ex: `uvicorn` sem `--workers N`, sem múltiplas réplicas atrás
de um load balancer). Isso é explícito porque alguns mecanismos já
desenhados dependem de estado em memória de um processo só — o worker de
checagem periódica e o coalescimento de `ProviderCacheService.rebuild_cache`
(ver `06b-services.md` > ProviderCacheService) são o exemplo mais direto:
rodando mais de um processo, cada um teria seu próprio relógio e sua
própria flag de coalescimento, todos tentando recomputar ao mesmo tempo
sem saber um do outro. Escalar pra múltiplos processos exige um lock
distribuído (ex: `SETNX` no Redis) que ainda não existe — fica registrado
como evolução futura, não como lacuna do desenho atual.

## Camadas

### Routes

Camada responsável por receber requisições HTTP e retornar respostas.

As rotas devem:

- validar entrada básica;
- chamar services;
- retornar schemas;
- não conter regra de negócio complexa.

### Schemas

Camada de entrada e saída da API.

Responsável por definir os contratos de dados usando modelos de
validação. Um Schema por entidade, detalhado em `06-models.md`.

### Services

Camada de regra de negócio.

Responsável por:

- aplicar regras da Ana;
- coordenar repositories;
- chamar providers;
- registrar consumo de tokens (`token_usage`/`token_usage_totals`) de
  forma síncrona a cada chamada ao provider;
- decidir fluxos de operação.

Uma Service por entidade (ou grupo de entidades), com seus métodos
detalhados em `06b-services.md`.

### Repositories

Camada de acesso ao banco.

Responsável por:

- criar;
- consultar;
- atualizar;
- remover;
- aplicar queries específicas.

Repositories não devem conter regra de negócio.

### Models

Representam as entidades persistidas no PostgreSQL — um Model por
tabela definida em `07-database.md`, detalhados campo a campo em
`06-models.md`. Tabelas marcadas `(futuro)` em `07-database.md`
(`topics`, `memories`, `tasks`, `mcps`) não têm Model no MVP.

### Providers

Camada de abstração para modelos de linguagem.

Deve permitir alternar entre:

- OpenAI;
- Anthropic;
- OpenAI-compatible;
- LM Studio futuramente.

Toda chamada deve retornar o consumo de tokens junto da resposta —
entrada, saída, e cache de leitura/escrita separados quando o provider
distinguir os dois (ex: Anthropic cobra preços diferentes pra cada).
O Backend calcula o custo em USD usando o preço cadastrado em
`model_prices` (`TokenUsageService.calculate_cost`, ver `06b-services.md`)
e grava em `token_usage`/`token_usage_totals` de forma síncrona, no
mesmo fluxo da chamada — agregando os dois tipos de cache num único
`cache_tokens` na hora de persistir.

### Logging

Log estruturado (JSON lines, não texto livre) — todo log é um registro
com campos fixos, não uma frase solta. Igual ao histórico financeiro
(`token_usage`/`token_usage_totals`, sempre por `project_id`, ver
`07-database.md`), logs também precisam ser filtráveis por projeto —
Ana é orientada a projetos, e um projeto é um escopo isolado de
segurança/automação (ver `09-projects.md` > Isolamento), então saber o
que aconteceu só num projeto específico (sem vasculhar log de todos os
outros) é requisito, não um "bônus".

Campos de contexto obrigatórios, quando existirem no momento do log:

- `project_id` — sempre que a operação está no escopo de um projeto
  (a grande maioria dos logs do Backend); ausente só em log
  verdadeiramente global (ex: `main.py` subindo, migration rodando,
  tick do worker antes de saber quais projetos afeta);
- `chat_id` — quando a operação está no escopo de um chat (ex: erro na
  chamada ao LLM em `MessageService`, ver `06b-services.md` e
  `../contracts/message.md`);
- `provider_id`/`provider_model_id` — quando a operação envolve um
  provider específico (ex: `ProviderCacheService` checando
  disponibilidade, ver `06b-services.md`).

`project_id` é propagado via `contextvars` a partir da Route (extraído
do path, ex: `/projects/{id}/...`) — Services e camadas internas não
precisam repassar isso manualmente em cada chamada de log; o logger
injeta sozinho o que estiver no contexto da requisição atual. Workers
(ex: `ProviderCacheService.rebuild_cache` rodando por conta própria, não
disparado por uma Route) setam o contexto manualmente antes de logar,
por projeto afetado.

Nenhum dado sensível (segredo decifrado de `ProviderCredential`, texto
de mensagem do usuário) entra em log — só metadados (ids, contagens,
códigos de erro).

---

## Estrutura

```text
apps/api/
└── app/
    ├── main.py
    ├── core/
    │   ├── config.py
    │   ├── security.py         # CredentialCipher (AES-256-GCM, ver 06b-services.md)
    │   └── logging.py         # log estruturado, project_id via contextvars (ver Camadas > Logging)
    ├── db/
    │   ├── session.py
    │   └── migrations/        # SQL numerado (00-16), espelha 07-database.md
    ├── models/
    │   ├── currency.py
    │   ├── language.py
    │   ├── user.py
    │   ├── provider.py
    │   ├── provider_credential.py
    │   ├── provider_subscription.py
    │   ├── provider_model.py
    │   ├── model_price.py
    │   ├── project.py
    │   ├── config.py           # model da tabela configs — 1:1 com project
    │   ├── chat.py
    │   ├── message.py
    │   ├── attachment.py
    │   ├── token_usage.py
    │   └── token_usage_totals.py
    ├── schemas/                # mesmo recorte de models/
    ├── routes/
    │   ├── health.py
    │   ├── limits.py             # GET /limits (MIN_TEXT_LENGTH, MAX_ATTACHMENTS_PER_MESSAGE)
    │   ├── me.py                # idioma do usuário (não há auth/multiusuário no MVP)
    │   ├── currencies.py
    │   ├── languages.py
    │   ├── providers.py
    │   ├── provider_credentials.py # PATCH /provider-credentials/{id} e DELETE /projects/{id}/providers/{id}
    │   ├── provider_stack.py     # /projects/{id}/provider-stack
    │   ├── projects.py
    │   ├── git.py                # /projects/{id}/git — mockado no MVP
    │   ├── config.py            # /projects/{id}/config
    │   ├── chats.py             # inclui /chats/search e POST /projects/{id}/chats (ver 11-search.md)
    │   ├── messages.py
    │   ├── attachments.py       # POST /projects/{id}/attachments (escopado ao projeto, não ao chat)
    │   ├── tools.py               # POST /projects/{id}/tools/{tool}
    │   └── realtime.py          # WS /projects/{id}/realtime (ver 10-resilience.md)
    ├── services/
    │   ├── user_service.py
    │   ├── provider_service.py  # cadastro/assinatura/edição, pilha de Provider/Modelo (ver 06b-services.md)
    │   ├── provider_cache_service.py # disponibilidade por credencial (Redis, ver 06b-services.md)
    │   ├── model_price_service.py # centraliza preço por (driver, provider_ref), ver 06b-services.md
    │   ├── git_service.py        # mockado no MVP
    │   ├── project_service.py
    │   ├── config_service.py
    │   ├── chat_service.py
    │   ├── guard_service.py     # valida a mensagem antes do Core ser acionado
    │   ├── message_service.py   # start_chat (atômico) e send_message
    │   ├── attachment_service.py
    │   ├── token_usage_service.py # calculate_cost separado de record; get_summary usado pelo Tool de Gastos
    │   ├── tool_service.py        # dispatcher genérico do ToolPanel
    │   ├── realtime_service.py  # broadcast de eventos via WebSocket (ver 06b-services.md)
    │   └── llm/
    ├── repositories/           # mesmo recorte de models/
    └── workers/                 # inclui refresh do cache de disponibilidade por credencial (PROVIDER_CACHE_REFRESH_SECONDS / _EXTERNAL, conforme providers.is_external)
```

---

# 4. Integrações

## Frontend

O Frontend consome o Backend através da API HTTP.

O Frontend não deve acessar banco ou Redis diretamente.

## PostgreSQL

O Backend é o único módulo autorizado a acessar diretamente o banco de dados 
principal da Ana.

## Redis

O Backend usa Redis para filas, tarefas assíncronas e eventos quando necessário.

No MVP, o uso pode ser mínimo.

## Provider LLM

O Backend usa uma camada interna de providers para enviar mensagens a modelos de linguagem.

Nenhum endpoint deve depender diretamente de SDK específico de OpenAI, Anthropic ou outro provider.

---

# 5. Evolução Futura

O Backend deverá evoluir para suportar:

* autenticação;
* permissões por usuário;
* streaming de respostas;
* jobs assíncronos;
* histórico de execução;
* auditoria;
* memória;
* agentes;
* skills;
* RAG;
* automações;
* integrações externas.

Essas funcionalidades devem ser adicionadas sem quebrar a separação entre rotas, 
services, repositories e providers.

---
 
# 6. Documentação Relacionada

## Geral

* `../00-context.md`
* `00-development.md`

## Arquitetura

* `01-system.md`
* `02-core.md`
* `04-frontend.md`
* `05-api.md`
* `06-models.md`
* `06b-services.md`
* `integrations/openclaude.md`
* `07-database.md`
* `08-redis.md`
* `09-projects.md`
* `10-resilience.md`
* `11-search.md`

## Contratos

* `../contracts/`
