# ModelPrice

Representa o preço por 1K tokens de um modelo — única fonte de preço da
Ana. Não existe conceito de origem do preço (`price_source`): só há uma
forma de obter o preço de um modelo, que é consultar esta entidade via
`ModelPriceService` (ver `../architecture/06b-services.md`).

### Responsabilidades:

- ser identificado por **`driver` + `provider_ref`** — a identidade
  técnica e portável do modelo (ver `provider-model.md`), **não** pelo
  `provider_id` de uma instância específica de provider. Isso é
  proposital: um preço já cadastrado sobrevive à exclusão/recadastro do
  provider dono, e é compartilhado entre instalações diferentes do
  mesmo driver que sirvam o mesmo modelo (ex: dois servidores
  `openai_compatible` espelhando o mesmo endpoint) — ver
  `docs/dev/research/identificacao-unica-de-providers.md`
- possuir preço por 1K tokens de entrada, saída, e **dois** preços de
  cache — leitura e escrita — já que alguns providers (ex: Anthropic)
  cobram valores bem diferentes pros dois; provider que não distingue
  simplesmente não usa o preço de escrita (fica zero, ver
  `../architecture/06b-services.md` > `TokenUsageService.calculate_cost`)
- não exigir cadastro prévio: um `(driver, provider_ref)` sem linha
  cadastrada tem preço **zero** — nunca um erro, nunca bloqueia o uso do
  modelo (ver `provider-model.md` e `../architecture/06b-services.md` >
  `ProviderCacheService.rebuild_cache`)
- ser totalmente independente do ciclo de vida de `Provider`/
  `ProviderModel` — sem relacionamento de ORM, sem FK

### Não deve:

- conter lógica de negócio
- ser lido/escrito por qualquer Service além de `ModelPriceService`
- ser retroativo: editar um preço nunca altera `token_usage`/
  `token_usage_totals` já gravados — só chamadas feitas depois da edição
  usam o preço novo (ver `token-usage.md` e `token-usage-totals.md`)

### Cadastro

Hoje não existe nenhum fluxo de cadastro de preço no MVP — nem o
registro de provider/credencial, nem a descoberta automática de modelo
pedem preço em momento algum. Uma tela em Settings pra cadastrar/editar
preços é evolução futura (ver `../architecture/06b-services.md` >
ModelPriceService e Evolução Futura); o Service já expõe `set_price`
pronto pra quando essa tela existir, sem Route pública ainda.
