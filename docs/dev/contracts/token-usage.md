# TokenUsage

Representa o consumo de tokens de uma única chamada a um provider (uma
troca de mensagem).

### Responsabilidades:

- pertencer a um único projeto, Provider e ProviderModel
- referenciar opcionalmente o chat de origem, para rastreabilidade
- possuir tokens de entrada, cache (leitura **e** escrita somadas num
  único agregado — só 3 tipos persistidos aqui, mesmo que o cálculo do
  custo use os dois preços de cache separadamente antes de agregar, ver
  `model-price.md` e
  `../architecture/06b-services.md` > `TokenUsageService.calculate_cost`)
  e saída
- possuir o custo em USD daquela chamada, calculado no momento com o
  preço **vigente naquele instante** em `ModelPrice`, e congelado
  daí em diante — se o preço do modelo mudar depois (edição manual, ou
  futuramente pela tela de preços em Settings, fora do MVP), essa linha
  já gravada nunca é recalculada; só chamadas feitas depois da mudança
  usam o preço novo (ver `model-price.md` e
  `../architecture/06b-services.md` > `TokenUsageService.record`)

### Não deve:

- ser alterado após criado (é um registro de log, imutável)
- armazenar valor em outra moeda que não USD
- ser a fonte consultada para exibir totais (ver `token-usage-totals.md`)
