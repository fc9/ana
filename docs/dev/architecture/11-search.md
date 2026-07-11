# 11 - Busca

Status: Draft
Versão: 0.1
Última atualização: 2026-07-10
Responsável: Arquitetura

---

# 1. Objetivo

Definir os níveis de busca disponíveis na Ana (hoje e no futuro) e
especificar o endpoint de busca do MVP.

---

# 2. Escopo

## Responsabilidades

- catálogo dos níveis de busca, com status MVP/futuro;
- especificação do endpoint de busca do MVP (chats + mensagens).

## Não Responsabilidades

- schema de `summaries`/`memories` (futuro, quando esses conceitos
  saírem do escopo futuro — ver `../contracts/memory.md` e mecânica de
  tipos/formato/índice em `12-memory.md`);
- UI do modal de busca (ver `ui/dashboard.md` > Modal de Busca).

---

# 3. Visão Geral

## Níveis de busca

| Nível                | Conteúdo                                    | Bom para                                                              | Status |
|-----------------------|----------------------------------------------|-------------------------------------------------------------------------|--------|
| Chat (título) e Topic  | título do chat, nome do tópico                | filtrar conversas por assunto                                            | MVP (só título de chat — Topic é futuro, ver `../contracts/topic.md`) |
| Messages               | mensagens reais do chat                       | buscar trecho exato, auditoria, recuperar detalhes, citações              | MVP |
| Summaries              | resumos de conversa, por bloco ou sessão      | entender contexto geral, saber onde procurar, não carregar conversa gigante | Futuro |
| Memories               | fatos ou decisões extraídas                   | preferências do usuário, decisões de projeto, estado atual, configs, nomes importantes | Futuro |

## Endpoint (MVP)

`GET /projects/{id}/chats/search?q={query}` (ver `05-api.md` > Chats)

- busca por `chats.title` OU conteúdo de qualquer `messages.content`
  pertencente ao chat (join/subquery), restrita ao projeto;
- requer no mínimo 3 caracteres em `q` (ver `ui/dashboard.md` > Modal
  de Busca — o Frontend já não dispara a busca antes disso; o Backend
  também valida, `400` se `q` tiver menos de 3 caracteres);
- retorna `list[ChatRead]` — resultado é sempre uma lista de chats
  (não uma lista de mensagens individuais), mesmo quando o que bateu
  foi o conteúdo de uma mensagem;
- implementação MVP: `ILIKE` simples (case-insensitive), sem índice de
  full-text dedicado — volume esperado não justifica a otimização
  ainda; um índice `GIN`/`tsvector` fica para se/quando a performance
  exigir.

## Futuro

Quando Topic, Summary e Memory existirem, o endpoint de busca deve
aceitar um parâmetro de escopo (`scope=chats|messages|summaries|memories`)
para restringir onde procurar — e, eventualmente, combinar múltiplos
níveis num resultado unificado, com algum critério de relevância.

---

# 4. Integrações

## Frontend

Consome `GET /projects/{id}/chats/search` para o Modal de Busca (ver
`ui/dashboard.md`).

## Services

`ChatService.search(project_id, query)` implementa a busca (ver
`06b-services.md`).

---

# 5. Evolução Futura

- busca em `summaries` e `memories`, quando esses conceitos saírem do
  escopo futuro;
- parâmetro de escopo (`scope=`) para restringir o nível de busca;
- índice de full-text (`tsvector`/`GIN`) em `messages.content` e
  `chats.title`, se o volume de dados justificar.

---

# 6. Documentação Relacionada

## Geral

- `../00-context.md`
- `00-development.md`

## Arquitetura

- `05-api.md`
- `06-models.md`
- `06b-services.md`
- `07-database.md`
- `12-memory.md`
- `ui/dashboard.md`

## Contratos

- `../contracts/chat.md`
- `../contracts/message.md`
- `../contracts/topic.md`
- `../contracts/memory.md`
