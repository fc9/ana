# API — Payloads

Status: Draft
Versão: 0.1
Última atualização: 2026-07-10
Responsável: Arquitetura

---

# 1. Objetivo

Definir o payload de request e o corpo de response de cada endpoint
listado em `../architecture/05-api.md`, campo a campo, com exemplos.

---

# 2. Escopo

## Responsabilidades

- corpo de request (JSON ou multipart) de cada endpoint;
- corpo de response de cada endpoint, com exemplo realista;
- códigos de status HTTP relevantes por endpoint.

## Não Responsabilidades

- verbo/caminho e descrição de uma linha de cada endpoint (ver
  `../architecture/05-api.md`);
- nome dos campos por Model/Schema, sem exemplo (ver
  `../architecture/06-models.md`);
- regra de negócio por trás de cada endpoint (ver
  `../architecture/06b-services.md`).

---

# 3. Convenções

- Todo `id` é UUID v4. Os exemplos abaixo reusam os mesmos UUIDs por
  entidade ao longo do documento, para facilitar acompanhar o fluxo.
- Datas em ISO 8601 (`YYYY-MM-DDTHH:mm:ssZ`).
- Nenhum endpoint requer autenticação no MVP (ver `05-api.md` >
  Convenções) — sem header `Authorization` nos exemplos.
- Erros seguem o formato padrão do FastAPI: `{"detail": "<mensagem>"}`.
  Catálogo completo de códigos em `../architecture/05-api.md` >
  Convenções. Exemplos genéricos, aplicáveis a qualquer endpoint:

  Response `500` (falha inesperada — chamada ao provider falhou, banco
  indisponível, erro interno; `detail` sempre traz a causa técnica):

  ```json
  {
    "detail": "Erro ao chamar o provider: connection timeout after 30s."
  }
  ```

  Response `502` (provider externo indisponível):

  ```json
  {
    "detail": "Provider openai indisponível (502 Bad Gateway)."
  }
  ```

  Response `503` (dependência externa fora do ar, ex: banco):

  ```json
  {
    "detail": "Banco de dados indisponível no momento."
  }
  ```

  Response `404` (recurso inexistente ou já excluído — mesmo formato em
  qualquer entidade):

  ```json
  {
    "detail": "Chat não encontrado."
  }
  ```
- Limites configuráveis por variável de ambiente (ver `src/.env.example`)
  usam o valor padrão nos exemplos deste documento (ex:
  `MAX_ATTACHMENTS_PER_MESSAGE=10`).
- IDs de exemplo reutilizados neste documento:

| Entidade         | UUID de exemplo                         |
|------------------|------------------------------------------|
| User             | `11111111-1111-1111-1111-111111111111`   |
| Project          | `22222222-2222-2222-2222-222222222222`   |
| Config           | `33333333-3333-3333-3333-333333333333`   |
| Currency (USD)   | `44444444-4444-4444-4444-444444444444`   |
| Language (en)    | `55555555-5555-5555-5555-555555555555`   |
| Provider         | `66666666-6666-6666-6666-666666666666`   |
| ProviderModel    | `77777777-7777-7777-7777-777777777777`   |
| Chat             | `88888888-8888-8888-8888-888888888888`   |
| Message (user)   | `99999999-9999-9999-9999-999999999999`   |
| Message (Ana)    | `aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa`   |
| Attachment       | `bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb`   |

---

# 4. Health

### `GET /health`

Response `200`:

```json
{
  "status": "ok"
}
```

> Evolução futura (ver `../architecture/05-api.md` > Evolução Futura):
> resposta mais completa, incluindo status do Redis, status do banco de
> dados, acesso aos providers cadastrados e status das filas.

### `GET /version`

Response `200`:

```json
{
  "version": "0.1.0"
}
```

---

# 5. Limits

### `GET /limits`

Response `200` (`LimitsRead`):

```json
{
  "min_text_length": 2,
  "max_attachments_per_message": 10
}
```

---

# 6. Me

### `GET /me`

Response `200` (`UserRead`):

```json
{
  "id": "11111111-1111-1111-1111-111111111111",
  "name": "Fabio",
  "language_id": "55555555-5555-5555-5555-555555555555",
  "created_at": "2026-07-01T10:00:00Z",
  "updated_at": "2026-07-01T10:00:00Z"
}
```

### `PATCH /me`

Request (`UserUpdate` — campos opcionais):

```json
{
  "name": "Fabio",
  "language_id": "55555555-5555-5555-5555-555555555555"
}
```

Response `200` (`UserRead`): igual ao `GET /me`.

---

# 7. Currencies

### `GET /currencies`

Response `200` (`list[CurrencyRead]`):

```json
[
  {
    "id": "44444444-4444-4444-4444-444444444444",
    "code": "USD",
    "name": "US Dollar",
    "symbol": "$",
    "rate_to_usd": 1.0,
    "is_active": true,
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-01T00:00:00Z"
  },
  {
    "id": "cccccccc-cccc-cccc-cccc-cccccccccccc",
    "code": "BRL",
    "name": "Brazilian Real",
    "symbol": "R$",
    "rate_to_usd": 5.42,
    "is_active": true,
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-01T00:00:00Z"
  }
]
```

---

# 8. Languages

### `GET /languages`

Response `200` (`list[LanguageRead]`):

```json
[
  {
    "id": "55555555-5555-5555-5555-555555555555",
    "code": "en",
    "name": "English",
    "endonym": "English",
    "is_active": true,
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-01T00:00:00Z"
  },
  {
    "id": "dddddddd-dddd-dddd-dddd-dddddddddddd",
    "code": "pt-BR",
    "name": "Portuguese (Brazil)",
    "endonym": "Português (Brasil)",
    "is_active": true,
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-01T00:00:00Z"
  }
]
```

---

# 9. Providers

Providers são **globais** — sem `project_id` próprio (ver
`../architecture/07-database.md` > providers e `provider.md`).

### `GET /providers?project_id={id}`

Response `200` (`list[ProviderRead]` — providers visíveis ao projeto,
com credencial pública ou com assinatura própria; sem ordenação
garantida — o dropdown do Header usa `Provider Stack`, não este
endpoint):

```json
[
  {
    "id": "66666666-6666-6666-6666-666666666666",
    "driver": "openai",
    "canonical_instance_id": "official",
    "display_name": "OpenAI",
    "base_url": null,
    "is_external": true,
    "created_at": "2026-07-01T10:00:00Z",
    "updated_at": "2026-07-01T10:00:00Z"
  }
]
```

### `POST /providers`

Registrar/assinar — cadastra o provider e/ou a credencial só se ainda
não existirem; se já existirem, apenas assina (ver
`../architecture/06b-services.md` > `ProviderService.register`):

```json
{
  "project_id": "22222222-2222-2222-2222-222222222222",
  "driver": "openai",
  "base_url": null,
  "secret": "sk-...",
  "is_private": false,
  "is_external": true
}
```

> `is_external` é opcional — sem informar, o Backend sugere um default
> por `driver` (`true` pra `openai`/`anthropic`/`openai_compatible`,
> `false` pra `lmstudio`/`ollama`); só é considerado quando o provider
> ainda não existe (criação nova), já que decide o intervalo do teste
> periódico de conectividade (ver `../architecture/06b-services.md` >
> ProviderCacheService).

Não altera o modelo ativo de nenhum projeto — só acrescenta o provider
à pilha dos projetos que passam a enxergá-lo; dispara recomputação do
cache em segundo plano, sem esperar, e depois `provider_stack` no
`WS /projects/{id}/realtime` para os projetos afetados (ver `Realtime`,
abaixo).

Response `201`:

```json
{
  "provider": {
    "id": "66666666-6666-6666-6666-666666666666",
    "driver": "openai",
    "canonical_instance_id": "official",
    "display_name": "OpenAI",
    "base_url": null,
    "is_external": true,
    "created_at": "2026-07-01T10:00:00Z",
    "updated_at": "2026-07-01T10:00:00Z"
  },
  "credential": {
    "id": "88888888-8888-8888-8888-888888888888",
    "is_private": false,
    "secret_hint": "sk-proj-••••••••••••aB31",
    "already_existed": false
  },
  "subscription_id": "99999999-9999-9999-9999-999999999999"
}
```

> `already_existed: true` + uma mensagem indicam que o Backend só
> assinou uma credencial já cadastrada (sem criar/alterar nada); se o
> pedido for de credencial pública mas o provider já tiver uma pública
> registrada, `is_private` volta `true` na resposta (a nova nasce
> privada) com o motivo explicado na mensagem (ver
> `../contracts/provider-credential.md`).

`409 Conflict` se `project_id` já tiver uma assinatura pra esse
provider (uma conta por provider, por projeto — ver
`../contracts/provider-subscription.md`); use
`PATCH /provider-credentials/{id}` (abaixo) pra trocar de conta.

### `GET /providers/{id}`

Response `200`: igual ao item de `GET /providers?project_id={id}`.

---

# 9b. Provider Credentials

### `PATCH /provider-credentials/{id}`

Request (`ProviderCredentialUpdate` — campos opcionais, exige o
`project_id` já ter assinatura pra essa credencial):

```json
{
  "project_id": "22222222-2222-2222-2222-222222222222",
  "secret": "sk-novo-valor",
  "is_private": true
}
```

Se o novo `secret` corresponder a uma conta diferente da atual, a
assinatura de `project_id` migra para outra credencial (existente ou
recém-criada) — nunca altera credenciais de outros assinantes (ver
`../architecture/06b-services.md` > `ProviderService.edit_credential`).

Response `200` (`ProviderCredentialRead` — `secret_hint` só, nunca o
segredo cifrado/nonce/chave, ver `../architecture/06b-services.md` >
CredentialCipher):

```json
{
  "id": "88888888-8888-8888-8888-888888888888",
  "provider_id": "66666666-6666-6666-6666-666666666666",
  "account_or_tenant": "org-abc123",
  "secret_hint": "sk-••••••••••••novo",
  "is_private": true,
  "created_at": "2026-07-01T10:00:00Z",
  "updated_at": "2026-07-09T09:00:00Z"
}
```

`403`/`404` se `project_id` não tiver assinatura pra essa credencial;
`400`/`502` se o `secret` não validar contra o provider.

### `DELETE /projects/{project_id}/providers/{provider_id}`

Desassinar (o "excluir" da UI) — remove só a assinatura de
`project_id`; nunca uma exclusão física direta (ver
`../contracts/provider-subscription.md`). Se a credencial usada ficar
sem nenhum assinante, é removida fisicamente — e o provider junto, se
também ficar sem nenhuma credencial.

Só responde `204` depois que o cache terminou de recomputar e o
broadcast (`provider_stack`) foi enviado — é esse delay que sustenta o
spinner do modal de confirmação na UI (ver
`../architecture/06b-services.md` > `ProviderService.unsubscribe`).

Response `204`: sem corpo. `404` se `project_id` não tiver assinatura
pra esse `provider_id`.

---

# 10. Provider Models

Exige `project_id` do solicitante ter assinatura no provider (ver
`../architecture/06b-services.md` > ProviderService). Só catálogo
(`provider_ref`/`name`/`is_active`) — preço não é campo de nenhum
payload aqui, vive só em `ModelPrice` (ver `model-price.md` e
`../architecture/06b-services.md` > ModelPriceService; sem Route pública
ainda, aguardando a tela de Settings). Linhas também nascem sozinhas,
sem nenhum `POST` — `ProviderCacheService.rebuild_cache` descobre o
catálogo ao vivo de cada provider e cria as que ainda não existem.

### `GET /providers/{id}/models`

Response `200` (`list[ProviderModelRead]`; sem ordenação garantida —
modelos nunca são reordenáveis pelo usuário, ver `Provider Stack`,
abaixo):

```json
[
  {
    "id": "77777777-7777-7777-7777-777777777777",
    "provider_id": "66666666-6666-6666-6666-666666666666",
    "provider_ref": "gpt-5-2026-01-15",
    "name": "GPT-5",
    "is_active": true,
    "created_at": "2026-07-01T10:00:00Z",
    "updated_at": "2026-07-01T10:00:00Z"
  },
  {
    "id": "dddddddd-dddd-dddd-dddd-dddddddddddd",
    "provider_id": "66666666-6666-6666-6666-666666666666",
    "provider_ref": "gpt-5-nano-2026-03-01",
    "name": "GPT-5 Nano",
    "is_active": true,
    "created_at": "2026-07-09T09:20:00Z",
    "updated_at": "2026-07-09T09:20:00Z"
  }
]
```

> `provider_ref` é o id/slug técnico que o próprio provider usa (opaco
> pra nós); `name` é só rótulo de exibição — os dois podem ser iguais
> em alguns providers e diferentes em outros. O segundo item acima é um
> exemplo de modelo descoberto automaticamente (`rebuild_cache` viu
> `gpt-5-nano-2026-03-01` no catálogo ao vivo) — sem preço cadastrado
> ainda, `ModelPriceService.get_price("openai", "gpt-5-nano-2026-03-01")`
> devolve zero até alguém cadastrar de verdade (ver `model-price.md`).

### `POST /providers/{id}/models`

Request (`ProviderModelCreate`):

```json
{
  "project_id": "22222222-2222-2222-2222-222222222222",
  "provider_ref": "gpt-5-2026-01-15",
  "name": "GPT-5"
}
```

Response `201` (`ProviderModelRead`): igual ao item de
`GET /providers/{id}/models`. `403`/`404` se `project_id` não tiver
assinatura pra esse provider.

### `PATCH /providers/{id}/models/{model_id}`

Request (`ProviderModelUpdate` — campos opcionais, mais `project_id`):

```json
{
  "project_id": "22222222-2222-2222-2222-222222222222",
  "name": "GPT-5 (2026-01)",
  "is_active": true
}
```

Response `200` (`ProviderModelRead`): igual ao `POST`.

### `DELETE /providers/{id}/models/{model_id}?project_id={id}`

Response `204`: sem corpo.

---

# 11. Projects

### `GET /projects`

Response `200` (`list[ProjectRead]` — ordenados por `last_accessed_at`
mais recente primeiro, `NULLS LAST`):

```json
[
  {
    "id": "22222222-2222-2222-2222-222222222222",
    "user_id": "11111111-1111-1111-1111-111111111111",
    "name": "Football Manga",
    "path": "D:\\repos\\football-manga",
    "processing_chat_id": null,
    "status": "active",
    "last_accessed_at": "2026-07-09T08:00:00Z",
    "created_at": "2026-07-01T10:00:00Z",
    "updated_at": "2026-07-01T10:00:00Z"
  }
]
```

### `POST /projects`

Request (`ProjectCreate`):

```json
{
  "name": "Football Manga",
  "path": "D:\\repos\\football-manga"
}
```

Response `201` (`ProjectRead`): igual ao item acima. Cria também um
`Config` associado (moeda padrão USD) — ver `POST /projects/{id}/config`
(implícito, sem chamada própria).

### `GET /projects/{id}`

Response `200`: igual ao item de `GET /projects`. Como efeito
colateral, atualiza `last_accessed_at` para o momento da chamada.

### `PATCH /projects/{id}`

Request (`ProjectUpdate` — campos opcionais):

```json
{
  "name": "Football Manga 2",
  "path": "D:\\repos\\football-manga-2"
}
```

Response `200` (`ProjectRead`): igual ao `POST /projects`.

### `DELETE /projects/{id}`

Response `204`: sem corpo. Exclusão lógica (`status = "deleted"`), não
remove a linha. Não valida "projeto ativo" — essa checagem é só do
Frontend (ver `../architecture/ui/dashboard.md` > Conteúdo expandido —
Projeto).

Response `422` (projeto `Base`):

```json
{
  "detail": "O projeto Base não pode ser removido."
}
```

---

# 12. Git

### `GET /projects/{id}/git`

**Mockado no MVP** — não executa git de fato.

Response `200` (`GitStatusRead`):

```json
{
  "branch": "main"
}
```

---

# 13. Config

### `GET /projects/{id}/config`

Response `200` (`ConfigRead` — carrega toda a configuração de UI do
projeto numa única resposta, ao abri-lo):

```json
{
  "id": "33333333-3333-3333-3333-333333333333",
  "project_id": "22222222-2222-2222-2222-222222222222",
  "currency_id": "44444444-4444-4444-4444-444444444444",
  "active_provider_id": "66666666-6666-6666-6666-666666666666",
  "active_model_ref": "gpt-5-2026-01-15",
  "fixed_contexts": ["chats", "files", "git"],
  "hidden_contexts": [],
  "hidden_tools": ["shell"],
  "created_at": "2026-07-01T10:00:00Z",
  "updated_at": "2026-07-01T10:00:00Z"
}
```

### `PATCH /projects/{id}/config`

Request (`ConfigUpdate` — campos opcionais; `provider_id`/`model_ref`
substituem o antigo `provider_model_id`, ver
`../architecture/06b-services.md` > `ProviderCacheService.resolve_active_model`):

```json
{
  "currency_id": "cccccccc-cccc-cccc-cccc-cccccccccccc",
  "provider_id": "cccccccc-cccc-cccc-cccc-cccccccccccc",
  "model_ref": "claude-sonnet-5-2026-01-15"
}
```

Request (troca de `hidden_contexts`/`hidden_tools` — disparada pelo
Frontend só após 3s sem novas mudanças, de forma assíncrona):

```json
{
  "hidden_contexts": ["git"],
  "hidden_tools": ["shell", "browser"]
}
```

Response `200` (`ConfigRead`): igual ao `GET`. `fixed_contexts` não
aceita escrita por este endpoint (sem UI de edição no MVP).

A troca de `provider_id`/`model_ref` é **sempre aceita** — sem teste de
conexão síncrono, mesmo que o par informado não corresponda a nada
visível ao projeto no momento (ex: provider que o projeto nunca assinou
nem enxerga como público). O Backend apenas grava a escolha, reordena
`provider_order` internamente (o provider escolhido sobe pro topo, se
visível) e aciona a recomputação do cache de disponibilidade em segundo
plano — sem bloquear esta resposta. Não existe mais `400`/`502` de
"teste de conexão falhou" neste endpoint (ver
`../architecture/06b-services.md` > ConfigService e
`../architecture/ui/dashboard.md` > Provider indisponível para onde o
bloqueio de envio realmente acontece).

`provider_order`/`provider_order_updated_at` não fazem parte de
`ConfigRead`/`ConfigUpdate` — ver `Provider Stack`, abaixo.

---

# 14. Provider Stack

Só leitura — a ordenação nunca é escrita pelo Frontend (ver
`../architecture/06b-services.md` > ProviderCacheService).

### `GET /projects/{id}/provider-stack`

Response `200` (`ProviderStackRead`):

```json
{
  "active_model": {
    "provider_id": "66666666-6666-6666-6666-666666666666",
    "model_ref": "gpt-5-2026-01-15",
    "provider_model_id": "77777777-7777-7777-7777-777777777777",
    "status": "normal"
  },
  "provider_order_updated_at": "2026-07-09T08:00:00Z",
  "providers": [
    {
      "id": "66666666-6666-6666-6666-666666666666",
      "display_name": "OpenAI",
      "available": true,
      "models": [
        { "id": "77777777-7777-7777-7777-777777777777", "provider_ref": "gpt-5-2026-01-15", "name": "GPT-5" },
        { "id": "dddddddd-dddd-dddd-dddd-dddddddddddd", "provider_ref": "gpt-5-mini-2026-01-15", "name": "GPT-5 Mini" }
      ]
    },
    {
      "id": "cccccccc-cccc-cccc-cccc-cccccccccccc",
      "display_name": "Anthropic",
      "available": false,
      "models": [
        { "id": "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee", "provider_ref": "claude-sonnet-5-2026-01-15", "name": "Claude Sonnet 5" }
      ]
    }
  ]
}
```

> `status` do `active_model` é `normal`, `unavailable` (provider/
> credencial/modelo existem, mas a checagem de conectividade mais
> recente dessa credencial falhou) ou `removed` (provider excluído,
> projeto sem acesso — desassinou ou a credencial virou privada de
> outro projeto —, ou modelo excluído do catálogo). Nos dois últimos
> casos, `provider_model_id` vem `null` (não há UUID real pra
> resolver), mas `provider_id`/`model_ref` continuam presentes — vêm
> direto de `configs` (ver `../architecture/ui/dashboard.md` > Provider
> indisponível). Se o `provider_id` também não existir mais de fato
> (exclusão física do provider — evento raro), o dropdown recorre a um
> rótulo genérico ("Provider removido") em vez de um nome específico,
> já que não há mais `display_name` nenhum pra resolver:

```json
{
  "active_model": {
    "provider_id": "ffffffff-ffff-ffff-ffff-ffffffffffff",
    "model_ref": "claude-opus-legacy",
    "provider_model_id": null,
    "status": "removed"
  },
  "provider_order_updated_at": "2026-07-09T08:00:00Z",
  "providers": [
    { "id": "66666666-6666-6666-6666-666666666666", "display_name": "OpenAI", "available": true, "models": [
      { "id": "77777777-7777-7777-7777-777777777777", "provider_ref": "gpt-5-2026-01-15", "name": "GPT-5" }
    ] }
  ]
}
```

Sem `configs.provider_order` gravado ainda: `providers` vem ordenado
alfabeticamente por `display_name`, sem persistir esse fallback. Chamado no
carregamento do projeto (novo ou reaberto) e sempre que o Frontend
recebe o aviso `provider_stack` via WebSocket — nunca por sugestão
própria.

---

# 15. Chats

### `GET /projects/{id}/chats?status=`

`status` opcional (default `active`). Response `200` (`list[ChatRead]`
— favoritados no topo):

```json
[
  {
    "id": "88888888-8888-8888-8888-888888888888",
    "project_id": "22222222-2222-2222-2222-222222222222",
    "title": "Como estruturar o midfield 4-3-3",
    "status": "active",
    "pinned_at": "2026-07-08T09:00:00Z",
    "created_at": "2026-07-05T14:00:00Z",
    "updated_at": "2026-07-08T09:00:00Z"
  }
]
```

### `GET /projects/{id}/chats/search?q={query}`

Busca por título do chat ou conteúdo de mensagens (ver
`../architecture/11-search.md`). Retorna sempre `list[ChatRead]`, nunca
mensagens isoladas — mesmo formato de item que `GET
/projects/{id}/chats`.

Response `200` (`list[ChatRead]`, exemplo para `q=contra-ataque`):

```json
[
  {
    "id": "88888888-8888-8888-8888-888888888888",
    "project_id": "22222222-2222-2222-2222-222222222222",
    "title": "Como estruturar o midfield 4-3-3",
    "status": "active",
    "pinned_at": "2026-07-08T09:00:00Z",
    "created_at": "2026-07-05T14:00:00Z",
    "updated_at": "2026-07-08T09:00:00Z"
  }
]
```

Response `400` (`q` com menos de 3 caracteres):

```json
{
  "detail": "A busca precisa ter no mínimo 3 caracteres."
}
```

### `POST /projects/{id}/chats`

Cria o chat **e** envia sua primeira mensagem numa chamada só — não
existe criação de chat isolada (ver `../architecture/06b-services.md`
> `MessageService.start_chat`). Texto é sempre obrigatório, com ou sem
anexo.

Request (mesmo corpo de `MessageCreate`, ver `Messages`, abaixo):

```json
{
  "content": "Qual a melhor formação para um time rápido no contra-ataque?",
  "staged_files": []
}
```

Response `201` (`MessageRead` — resposta da Ana; o campo `chat` nunca é
opcional aqui, diferente de `POST /chats/{id}/messages`):

```json
{
  "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
  "chat_id": "88888888-8888-8888-8888-888888888888",
  "role": "assistant",
  "content": "Um 4-3-3 com pontas velozes tende a explorar bem o contra-ataque...",
  "avatar_expression": {
    "id": "estudei_para_responder",
    "image_url": "https://cdn.example.com/avatar/estudei_para_responder.gif",
    "caption": "Estudei bastante para essa resposta"
  },
  "is_first": false,
  "attachments": [],
  "created_at": "2026-07-09T08:00:05Z",
  "chat": {
    "id": "88888888-8888-8888-8888-888888888888",
    "title": "Como estruturar o midfield 4-3-3"
  }
}
```

Response `400` (sem texto — mesmas regras de `GuardService` de
`POST /chats/{id}/messages`, abaixo; **nenhum chat é criado**):

```json
{
  "detail": "A primeira mensagem do chat precisa ter texto."
}
```

Response `500`/`502` (falha ao chamar o LLM, ou a Ana rejeitou o
conteúdo — **nenhum chat é criado**, nada persistido, sem mensagem de
evento):

```json
{
  "detail": "Erro ao chamar o provider: connection timeout after 30s."
}
```

Response `409` (projeto já processando outro chat):

```json
{
  "detail": "Este projeto já está processando outra mensagem."
}
```

### `GET /chats/{id}`

Response `200`: igual ao item de `GET /projects/{id}/chats`.

### `PATCH /chats/{id}`

Request (`ChatUpdate` — campos opcionais; exemplos separados):

Renomear:

```json
{
  "title": "Novo título"
}
```

Arquivar/restaurar:

```json
{
  "status": "archived"
}
```

Favoritar/desfavoritar:

```json
{
  "pinned_at": "2026-07-09T08:30:00Z"
}
```

```json
{
  "pinned_at": null
}
```

Response `200` (`ChatRead`): igual ao item de
`GET /projects/{id}/chats`.

### `DELETE /chats/{id}`

Response `204`: sem corpo. Exclusão lógica (`status = "deleted"`);
remove fisicamente os anexos das mensagens do chat.

---

# 16. Messages

### `GET /chats/{id}/messages`

Response `200` (`list[MessageRead]`):

```json
[
  {
    "id": "99999999-9999-9999-9999-999999999999",
    "chat_id": "88888888-8888-8888-8888-888888888888",
    "role": "user",
    "content": "Qual a melhor formação para um time rápido no contra-ataque?",
    "avatar_expression": null,
    "is_first": true,
    "attachments": [],
    "created_at": "2026-07-09T08:00:00Z"
  },
  {
    "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
    "chat_id": "88888888-8888-8888-8888-888888888888",
    "role": "assistant",
    "content": "Um 4-3-3 com pontas velozes tende a explorar bem o contra-ataque...",
    "avatar_expression": {
      "id": "estudei_para_responder",
      "image_url": "https://cdn.example.com/avatar/estudei_para_responder.gif",
      "caption": "Estudei bastante para essa resposta"
    },
    "is_first": false,
    "attachments": [],
    "created_at": "2026-07-09T08:00:05Z"
  }
]
```

### `POST /chats/{id}/messages`

Mensagem **adicional** a um chat que já existe — nunca a primeira (ver
`POST /projects/{id}/chats`, acima).

Request (`MessageCreate`):

```json
{
  "content": "Qual a melhor formação para um time rápido no contra-ataque?",
  "staged_files": []
}
```

Com anexo (texto opcional quando há ao menos um anexo, fora da
primeira mensagem):

```json
{
  "content": "Segue o print da formação atual",
  "staged_files": ["a3f1e9c0-1b2d-4e6a-9f3a-7c8d5e2b1a90"]
}
```

Response `201` (`MessageRead` — resposta da Ana, já persistida; sem
campo `chat`, já que o Frontend já conhecia esse chat):

```json
{
  "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
  "chat_id": "88888888-8888-8888-8888-888888888888",
  "role": "assistant",
  "content": "Um 4-3-3 com pontas velozes tende a explorar bem o contra-ataque...",
  "avatar_expression": {
    "id": "estudei_para_responder",
    "image_url": "https://cdn.example.com/avatar/estudei_para_responder.gif",
    "caption": "Estudei bastante para essa resposta"
  },
  "is_first": false,
  "attachments": [],
  "created_at": "2026-07-09T08:00:05Z"
}
```

Response `201`, quando a chamada ao LLM falha (técnica, ou rejeição de
conteúdo pela Ana) — o chat já existia, então o erro vira uma mensagem
`event` persistida no histórico (sobrevive a reload), em vez de um erro
solto:

```json
{
  "id": "ffffffff-ffff-ffff-ffff-ffffffffffff",
  "chat_id": "88888888-8888-8888-8888-888888888888",
  "role": "event",
  "content": "Hum, algo deu errado: connection timeout after 30s.",
  "avatar_expression": null,
  "is_first": false,
  "attachments": [],
  "created_at": "2026-07-09T08:00:05Z"
}
```

Response `422` (modelo ativo do projeto foi removido, ou o projeto nunca
teve um modelo escolhido — ambos resolvidos via
`ProviderCacheService.resolve_active_model` antes de gravar qualquer
coisa; nada é persistido). Na prática o Frontend já não deixa chegar
aqui — o botão de enviar só habilita com um modelo resolvido como
`normal` (ver `../architecture/ui/dashboard.md` > Main > Composer):

```json
{
  "detail": "Provider do modelo foi removido. Escolha outro modelo."
}
```

```json
{
  "detail": "Nenhum modelo selecionado. Escolha um modelo antes de enviar."
}
```

Response `503` (modelo ativo existe, mas está indisponível no momento —
transitório; nada é persistido):

```json
{
  "detail": "Provider indisponível no momento. Tente novamente em instantes."
}
```

Response `400` (`content` e `staged_files` ambos vazios — mensagem
precisa ter texto ou anexo):

```json
{
  "detail": "A mensagem precisa ter texto ou anexo."
}
```

Response `400` (só texto, sem anexo, com menos de `MIN_TEXT_LENGTH`
caracteres — variável de ambiente, padrão 2, ver `src/.env.example`):

```json
{
  "content": "K",
  "staged_files": []
}
```

```json
{
  "detail": "O texto precisa ter no mínimo 2 caracteres."
}
```

Response `400` (`staged_files` acima de `MAX_ATTACHMENTS_PER_MESSAGE`,
variável de ambiente — padrão 10, ver `src/.env.example`):

```json
{
  "detail": "Limite de 10 anexos por envio excedido."
}
```

Response `400` (algum `staged_file_id` não resolveu pra um arquivo
staged **deste projeto** — de outro projeto, inválido, ou já expirado
pela retenção de 12h; ver `../architecture/06b-services.md` >
`AttachmentService.resolve_staged` e `attachment.md`):

```json
{
  "detail": "Um ou mais anexos não foram encontrados ou expiraram. Anexe os arquivos novamente."
}
```

Response `409` (projeto já processando outra mensagem):

```json
{
  "detail": "Este projeto já está processando outra mensagem."
}
```

---

# 17. Attachments

### `POST /projects/{id}/attachments`

Request: `multipart/form-data`, campo `file`. Escopado ao projeto, não
a um chat — o composer permite anexar antes de qualquer chat existir.

Response `200` (referência temporária — ainda não é um `Attachment`):

```json
{
  "staged_file_id": "a3f1e9c0-1b2d-4e6a-9f3a-7c8d5e2b1a90",
  "type": "image",
  "filename": "formacao.png"
}
```

### `DELETE /projects/{id}/attachments/staged/{staged_file_id}`

Response `204`: sem corpo. Remove só o arquivo em disco — o anexo
nunca existiu como `Attachment` (mensagem nunca enviada).

### `GET /attachments/{id}`

Só existe depois que a mensagem que o originou foi enviada.

Response `200` (`AttachmentRead`):

```json
{
  "id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
  "message_id": "99999999-9999-9999-9999-999999999999",
  "type": "image",
  "storage_path": ".ana/storage/formacao.png",
  "created_at": "2026-07-09T08:00:00Z"
}
```

Response `404` (referência ainda staged, nunca enviada, ou inexistente):

```json
{
  "detail": "Attachment não encontrado."
}
```

### `DELETE /attachments/{id}`

Response `204`: sem corpo. Gera uma mensagem `role = "event"` no chat
relatando a remoção (ver `../architecture/ui/dashboard.md` > Main >
Anexos na mensagem):

```json
{
  "id": "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee",
  "chat_id": "88888888-8888-8888-8888-888888888888",
  "role": "event",
  "content": "O usuário deletou o anexo formacao.png da mensagem 99999999-9999-9999-9999-999999999999.",
  "avatar_expression": null,
  "is_first": false,
  "attachments": [],
  "created_at": "2026-07-09T08:05:00Z"
}
```

> A mensagem de evento acima não é o corpo de resposta do `DELETE`
> (que é `204` vazio) — é criada como efeito colateral e aparece depois
> num `GET /chats/{id}/messages` subsequente. Dispara `new_message` no
> `WS /projects/{id}/realtime` (ver `Realtime`, abaixo).

---

# 18. Tools

### `POST /projects/{id}/tools/gastos`

Request: `{}` (nenhum campo complementar usado no MVP).

Response `200` (`GastosToolRead` — mesmo sem uso registrado, retorna a
estrutura zerada, nunca um erro):

```json
{
  "currency": {
    "id": "44444444-4444-4444-4444-444444444444",
    "code": "USD",
    "symbol": "$"
  },
  "tokens": { "input": 12400, "output": 3200, "total": 15600 },
  "cost": { "input": -0.0155, "cache": -0.0004, "output": -0.032, "total": -0.0479 },
  "timeline": [
    {
      "provider_model_id": "77777777-7777-7777-7777-777777777777",
      "name": "gpt-5",
      "percent": 62.5,
      "cost_usd": -0.03,
      "current_price": {
        "input_price_per_1k": 1.25,
        "cache_read_price_per_1k": 0.125,
        "cache_write_price_per_1k": 1.50,
        "output_price_per_1k": 10.0
      }
    },
    {
      "provider_model_id": "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee",
      "name": "claude-sonnet-5",
      "percent": 37.5,
      "cost_usd": -0.0179,
      "current_price": null
    }
  ]
}
```

> `current_price` é o preço **vigente agora** em `ModelPrice` (o
> que uma chamada nova pagaria hoje, ver `model-price.md`) — `null`
> quando o `ProviderModel` já não existe mais (excluído, ou provider
> excluído junto), já que não há mais `driver`/`provider_ref` pra
> resolver o preço. `cost_usd` nunca depende disso: já vem congelado do
> log, correto mesmo com
> `current_price: null` (ver `../architecture/06b-services.md` >
> `TokenUsageService.get_summary` e
> `../architecture/ui/dashboard.md` > Card de modelo > Preço).

Sem uso registrado ainda:

```json
{
  "currency": { "id": "44444444-4444-4444-4444-444444444444", "code": "USD", "symbol": "$" },
  "tokens": { "input": 0, "output": 0, "total": 0 },
  "cost": { "input": 0, "cache": 0, "output": 0, "total": 0 },
  "timeline": []
}
```

---

# 19. Realtime (WebSocket)

### `WS /projects/{id}/realtime`

Conexão aberta pelo Frontend enquanto o projeto está aberto (ver
`../architecture/05-api.md` > WebSocket). Mensagens do servidor,
identificadas por `type`:

```json
{
  "type": "processing",
  "chat_id": "88888888-8888-8888-8888-888888888888"
}
```

```json
{
  "type": "processing",
  "chat_id": null
}
```

```json
{
  "type": "new_message",
  "chat_id": "88888888-8888-8888-8888-888888888888"
}
```

```json
{
  "type": "provider_stack",
  "provider_order_updated_at": "2026-07-09T08:10:00Z"
}
```

> `system_status` (status de provider/banco/sistemas críticos) ainda
> não tem formato definido — evolução futura (ver
> `../architecture/10-resilience.md`).

---

# 20. Documentação Relacionada

## Geral

- `../00-context.md`
- `../architecture/00-development.md`

## Arquitetura

- `../architecture/05-api.md`
- `../architecture/06-models.md`
- `../architecture/06b-services.md`
- `../architecture/07-database.md`
- `../architecture/08-redis.md`
- `../architecture/10-resilience.md`
- `../architecture/11-search.md`
- `../architecture/ui/dashboard.md`

## Contratos

- `./`

## Postman

- `../database/postman/ana-collection.json`
