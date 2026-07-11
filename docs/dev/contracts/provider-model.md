# ProviderModel

Representa um modelo específico de um Provider (ex: `gpt-5` da OpenAI).
Pertence ao Provider **global** (ver `provider.md`) — compartilhado por
todas as `provider-credential.md` desse provider; gerenciar (cadastrar
modelo) exige o solicitante ter assinatura no provider (ver
`../architecture/06b-services.md` > ProviderService). Preço **não** é
responsabilidade desta entidade — vive inteiramente em `model-price.md`.

### Responsabilidades:

- pertencer a um único Provider
- possuir dois identificadores distintos: `provider_ref` (id/slug
  técnico que o próprio provider usa nas chamadas de API — opaco pra
  nós, nunca inventado) e `name` (rótulo de exibição, pode diferir de
  `provider_ref` e mudar sem o modelo mudar de identidade). É
  `provider_ref` — nunca `name` — que dá identidade estável ao modelo
  usada por `config.md` > `active_model_ref`, e que (junto do `driver`
  do Provider dono) identifica o preço do modelo em `model-price.md`
  (ver `../architecture/06b-services.md` > ProviderCacheService e
  ModelPriceService)
- nascer tanto de cadastro manual (`POST /providers/{id}/models`,
  só `provider_ref`/`name` — nunca preço) quanto de **descoberta
  automática**: `ProviderCacheService.rebuild_cache` consulta o catálogo
  ao vivo de cada provider (todos os modelos disponíveis pra uma
  credencial, cadastrados por nós ou não) e faz upsert por
  `(provider_id, provider_ref)` — modelo já existente só tem
  `name`/`is_active` atualizados; modelo novo nasce sem preço
  cadastrado, o que `ModelPriceService.get_price` trata como preço zero
  (ver `model-price.md`)
- ter `is_active` mantido automaticamente por essa mesma descoberta —
  `false` quando o modelo some do catálogo ao vivo (descontinuado pelo
  provider), preservando o registro só como referência histórica; nunca
  marcado `false` só porque o provider inteiro ficou temporariamente
  inacessível (isso é disponibilidade transitória, não descontinuação —
  ver abaixo)
- **não** ter disponibilidade própria: quem é checado e cacheado (Redis)
  é a `provider-credential.md` usada pra acessar o provider, não o
  modelo — o catálogo de modelos em si (esta tabela) é lido direto do
  banco, sempre compartilhado por todas as credenciais do provider (ver
  `../architecture/08-redis.md` e `../architecture/06b-services.md` >
  ProviderCacheService). Disponibilidade é recomputada por completo (por
  credencial) a cada cadastro/edição/exclusão de provider/credencial/
  assinatura (evento), a cada `PROVIDER_CACHE_REFRESH_SECONDS`/
  `PROVIDER_CACHE_REFRESH_SECONDS_EXTERNAL` (fallback periódico, padrão
  60s pra provider local e 60 minutos pra externo, conforme
  `providers.is_external` — já que providers de LLM não avisam queda
  via webhook, e testar um serviço de nuvem tão seguido quanto um
  servidor local custaria rate limit à toa), e também quando uma
  tentativa real de envio de mensagem encontra uma indisponibilidade que
  o cache ainda não sabia. Toda recomputação dispara um novo aviso de
  pilha (`provider_stack`) aos
  projetos que enxergam a credencial afetada

### Não deve:

- pertencer a mais de um Provider
- conter lógica de negócio
- possuir campo de preço ou de origem de preço (`price_source` não
  existe mais — ver `model-price.md`)
