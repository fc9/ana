# 08 - Redis

Status: Draft
Versão: 0.1
Última atualização: 2026-07-11
Responsável: Arquitetura

---

# 1. Objetivo

Apresentar o uso do Redis na Ana. Hoje quase vazio — só cache de
disponibilidade de providers — mas preparado para os demais usos já
previstos (filas, streaming/pub-sub, workers).

---

# 2. Escopo

## Responsabilidades

- cache;
- filas;
- streaming/pub-sub;
- workers.

## Não Responsabilidades

- lógica de negócio (ver `06b-services.md`);
- persistência durável — o Redis nunca é a fonte de verdade de nada;
  qualquer dado aqui é cache ou estado transitório, reconstruível a
  partir do banco (ver `07-database.md`).

---

# 3. Visão Geral

Inicialmente quase vazio. Mas preparado — usos concretos já previstos
(ver `10-resilience.md`):

## Filas

Registro assíncrono em `actions` (evolução futura) — não pode bloquear
a resposta ao usuário.

## Workers

O mesmo worker que recomputa o cache de disponibilidade no ciclo
periódico (ver `Cache`, abaixo) é o uso concreto já ativo desta
camada; o worker de fila de `actions` (acima) é o próximo, quando a
tabela existir.

## Streaming / Pub-Sub

**Não usado no MVP** — `RealtimeService` mantém as conexões WebSocket
num dicionário em memória de um único processo (ver `06b-services.md`
> RealtimeService e `03-backend.md` > Visão Geral, premissa de processo
único), então um broadcast (`processing`, `new_message`,
`provider_stack` e futuramente `system_status`) sempre alcança toda
sessão conectada sem precisar de nada no Redis. Pub/sub vira necessário
só quando o Backend escalar pra mais de um processo/réplica — aí um
processo precisa publicar o evento pra que os outros, cada um com suas
próprias conexões, também o repassem pras sessões que atendem (ver
`05-api.md` > Evolução Futura, sobre `system_status` ainda não ter
formato definido).

## Cache

Só disponibilidade — por **credencial**, não por provider (contas
diferentes do mesmo provider falham de forma independente, ver
`06b-services.md` > ProviderCacheService), chave
`provider_cache:{credential_id}` →
`{"available": bool, "checked_at": <iso8601>}`. O catálogo de modelos
**não** é cacheado — vem direto de `provider_models` (tabela), já
compartilhado por todas as credenciais do mesmo provider; é a própria
`rebuild_cache` quem mantém essa tabela sincronizada com o catálogo ao
vivo de cada provider (descoberta automática de modelo novo — ver
`06b-services.md` > ProviderCacheService e `07-database.md` >
provider_models). Preço é assunto à parte, centralizado em
`model_prices`/`ModelPriceService`, sem nenhum preço cadastrado, o
valor é zero (ver `07-database.md` > model_prices). É essa cópia de
disponibilidade em cache, nunca o provider ao vivo, que alimenta a
montagem da pilha de Provider/Modelo do dropdown do Header — o banco
de dados não guarda disponibilidade transitória, só a cache (ver
`06b-services.md` > ProviderCacheService e `ui/dashboard.md` > Header >
Dropdown de Provider/Modelo).

Cada credencial testada é sempre recomputada por inteiro (não um patch
parcial). Três gatilhos:

- **evento**: logo após qualquer `INSERT`/`UPDATE`/`DELETE` em
  `providers`/`provider_credentials`/`provider_subscriptions`/
  `provider_models` (hook depois do commit, ver `06b-services.md` >
  ProviderCacheService) — cobre cadastro, edição, assinatura e
  remoção; sempre testa na hora, ignorando o intervalo abaixo;
- **periódico**: intervalo por **credencial**, não global — depende de
  `providers.is_external` do provider dono:
  `PROVIDER_CACHE_REFRESH_SECONDS` (variável de ambiente, padrão 60 —
  ver `src/.env.example`) pra provider local/self-hosted,
  `PROVIDER_CACHE_REFRESH_SECONDS_EXTERNAL` (padrão 3600, 60 minutos)
  pra provider externo (custa rate limit/possível tarifa testar um
  serviço de nuvem com a mesma frequência de um servidor local) —
  fallback pra quando a disponibilidade muda sem nenhuma ação de
  cadastro (o provider caiu ou voltou sozinho), já que providers de LLM
  não avisam isso via webhook. Sem chave transitória global: o worker
  compara `now` contra o próprio `checked_at` já gravado em cada
  `provider_cache:{credential_id}` (em vez de um `sleep` fixo), e só as
  credenciais vencidas entram na rodada daquele tick — uma recomputação
  fora de hora (ver próximo item) reinicia só o relógio da credencial
  recomputada, atualizando o `checked_at` dela;
- **por tentativa de envio**: quando `MessageService` encontra o modelo
  ativo indisponível numa tentativa de envio real — seja porque o cache
  já sabia, seja porque a chamada ao LLM falhou na hora mesmo o cache
  dizendo disponível — aciona
  `ProviderCacheService.report_unavailable`, que só recomputa de fato
  se a indisponibilidade ainda não estiver refletida no cache **e** o
  próximo vencimento periódico **daquela credencial** não estiver a
  menos de 3 segundos de distância (ver `06b-services.md` >
  ProviderCacheService) — pra credencial de provider externo (ciclo de
  60 minutos), esse é, na prática, o principal jeito de detectar queda
  rápido, não só um atalho ocasional.

Toda recomputação só dispara broadcast via WebSocket (`provider_stack`)
aos projetos afetados se a ordenação ou a disponibilidade realmente
mudou desde a última vez — checagem periódica sem novidade não
notifica nada. Quando dispara, o broadcast em si é auto-limitado por
projeto, só para esse tipo de mensagem — não afeta `processing`/
`new_message` (ver `06b-services.md` >
`RealtimeService.broadcast_provider_stack`): no máximo um aviso a cada
3 segundos por projeto, com o bloqueio se desfazendo sozinho no fim do
prazo mesmo que o Frontend nunca busque a pilha de volta. Esse estado
(bloqueado há quanto tempo / mudança pendente) também é transitório,
vive só aqui — nunca em `configs`.

---

# 4. Integrações

## Backend

`ProviderCacheService` e `RealtimeService` são os únicos consumidores
do Redis hoje — cache de disponibilidade e (futuramente) pub/sub,
respectivamente. Nenhum outro módulo acessa o Redis diretamente (ver
`06b-services.md`).

---

# 5. Evolução Futura

- streaming/pub-sub, quando o Backend escalar para mais de um
  processo/réplica (ver `Streaming / Pub-Sub`, acima);
- fila de `actions`, quando essa tabela existir (ver `10-resilience.md`
  > Actions);
- formato da mensagem `system_status`, ainda não definido (ver
  `05-api.md` > Evolução Futura).

---

# 6. Documentação Relacionada

## Geral

- `../00-context.md`
- `00-development.md`

## Arquitetura

- `03-backend.md`
- `05-api.md`
- `06b-services.md`
- `07-database.md`
- `10-resilience.md`
- `ui/dashboard.md`
