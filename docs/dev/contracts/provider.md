# Provider

Representa uma instalação ou serviço de inferência acessível por um
driver e endpoint específicos (ex: OpenAI, Anthropic, um servidor
OpenAI-compatible, uma instalação de LM Studio). **Global** — não
pertence a projeto algum (ver
`docs/dev/research/identificacao-unica-de-providers.md`).

Contas de acesso (credenciais) e o vínculo de cada projeto a uma delas
vivem em entidades próprias — ver `provider-credential.md` e
`provider-subscription.md`.

### Responsabilidades:

- ser identificado por `driver` (qual adaptador de `services/llm/`
  trata as chamadas — `openai`, `anthropic`, `openai_compatible`,
  `lmstudio`...) + `canonical_instance_id` (a instalação/serviço,
  não a conta — `'official'` pra serviços únicos na nuvem, endpoint
  normalizado ou `server_instance_id` pra self-hosted). `UNIQUE
  (driver, canonical_instance_id)` — o sistema nunca permite cadastrar
  o mesmo provider duas vezes;
- ter um ou mais `ProviderCredential` associados — contas distintas do
  mesmo serviço (ex: duas contas OpenAI diferentes) são o mesmo
  Provider, nunca dois;
- expor seu catálogo de modelos em `provider-model.md` — compartilhado
  por todas as credenciais desse provider (preço não é responsabilidade
  do Provider nem do catálogo — ver `model-price.md`);
- indicar se é alcançado pela internet (`is_external`) ou é local/
  self-hosted — decide o intervalo do teste periódico de conectividade
  (ver `../architecture/06b-services.md` > ProviderCacheService); tem um
  default sugerido por `driver` no cadastro, mas é sempre explícito e
  sobrescrevível;
- ser excluído fisicamente, mas só como consequência de ficar sem
  nenhuma credencial (ver `provider-credential.md` > Exclusão em
  cascata) — nunca por uma ação direta de "excluir provider".

### Não deve:

- conter lógica de negócio da Ana
- ter `project_id`, `is_private` ou credenciais próprias — isso vive em
  `ProviderCredential`
- ser referenciado diretamente por módulos (o acesso deve passar pela
  camada de abstração de Provider)

### Fluxo de cadastro/assinatura

Descrito por completo em `../architecture/06b-services.md` >
ProviderService.register — resumo:

1. valida o acesso contra o provider (chamada real, autenticada) antes
   de tocar o banco;
2. procura um Provider existente com a mesma identidade
   (`driver`+`canonical_instance_id`); cria um novo só se não existir,
   com `is_external` informado no cadastro (ou o default sugerido por
   `driver`, se omitido);
3. procura uma `ProviderCredential` existente para a conta identificada
   na validação; se já existir, **reaproveita sem alterar** (nem
   `secret`, nem `is_private`) — só informa ao usuário como já está
   registrada; se não existir, cria uma nova (respeitando a regra de
   "no máximo uma credencial pública por provider", ver
   `provider-credential.md`);
4. cria a assinatura do projeto solicitante para essa credencial (ver
   `provider-subscription.md`) — rejeita se o projeto já tiver uma
   assinatura pra esse provider (uma conta por provider, por projeto).

Cadastrar/assinar nunca muda o modelo ativo (`config.md` >
`active_provider_id`/`active_model_ref`) de nenhum projeto — só
acrescenta uma opção na pilha.
