# TokenUsageTotals

Representa o total acumulado de tokens e custo consumido por um projeto,
agrupado por Provider e ProviderModel. É uma projeção em tempo real de
`token-usage.md`, não uma fonte de verdade independente.

### Responsabilidades:

- pertencer a um único projeto, Provider e ProviderModel (chave única)
- ser atualizado de forma síncrona (upsert) a cada novo TokenUsage
- somar tokens de entrada, cache (leitura + escrita agregadas — ver
  `token-usage.md`) e saída, e custo em USD — sempre **incrementando**
  pelo `cost_usd` já calculado e congelado de cada `TokenUsage`, nunca
  recalculando o total a partir do preço atual do modelo. Se o preço de
  um modelo mudar em `model-price.md`, o total acumulado até então
  permanece intacto — só os incrementos de uso *depois* da mudança
  passam a usar o preço novo (ver `../architecture/06b-services.md` >
  TokenUsageService.record)

### Não deve:

- ser atualizado de forma assíncrona ou em batch — o consumo deve
  refletir a API em tempo real
- divergir do que está registrado em `token-usage.md` (deve ser
  reconstruível a partir do log, se necessário)
- ser recalculado do zero a partir do preço vigente do modelo — isso
  reescreveria retroativamente o custo de uso já ocorrido, que deve
  permanecer congelado no valor da época de cada chamada
