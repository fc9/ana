-- Tabela: model_prices
-- Contract: docs/dev/contracts/model-price.md
--
-- Centraliza o preço de um modelo — única fonte de preço da Ana, sem
-- distinção de origem (não existe mais price_source: só existe uma
-- forma de obter o preço, que é consultar esta tabela via
-- ModelPriceService, ver docs/dev/architecture/06b-services.md).
--
-- Chaveada por (driver, provider_ref) — NÃO por provider_id: o mesmo
-- modelo pode ser servido por mais de uma instalação do mesmo driver
-- (ex: dois servidores openai_compatible espelhando o mesmo endpoint),
-- e um preço já cadastrado sobrevive à exclusão/recadastro do provider
-- dono, sem precisar ser digitado de novo (ver
-- docs/dev/research/identificacao-unica-de-providers.md). Por isso não
-- há FK pra `providers`/`provider_models` aqui — a tabela é
-- deliberadamente independente do ciclo de vida de qualquer provider
-- específico. `driver` ainda tem o mesmo CHECK de 05-providers.sql
-- (mesmo conjunto fechado de adaptadores) — sem FK pra validar o valor,
-- um erro de digitação aqui faria `get_price` nunca encontrar a linha
-- (preço silenciosamente zero, sem sinal de erro).
--
-- Sem linha cadastrada para um (driver, provider_ref) = preço zero até
-- alguém cadastrar de verdade (hoje sem mecanismo de UI — tela em
-- Settings, fora do MVP, ver
-- docs/dev/architecture/06b-services.md > ModelPriceService). Editar um
-- preço nunca é retroativo — token_usage/token_usage_totals já gravados
-- mantêm o custo calculado com o preço vigente na época de cada chamada
-- (ver docs/dev/contracts/token-usage.md).
--
-- `cache_read_price_per_1k` / `cache_write_price_per_1k`: preços
-- distintos pra cache de leitura e cache de escrita — alguns providers
-- (ex: Anthropic) cobram valores bem diferentes pros dois (escrita é
-- normalmente mais cara). `token_usage`/`token_usage_totals` continuam
-- guardando só 3 tipos agregados de token (entrada, saída, cache =
-- leitura + escrita somadas — ver docs/dev/contracts/token-usage.md),
-- mas o cálculo do custo em si usa os dois preços separadamente antes
-- de agregar a contagem pra persistir (ver
-- docs/dev/architecture/06b-services.md > TokenUsageService.calculate_cost).
-- Provider que não distingue escrita de leitura (a maioria) simplesmente
-- não usa `cache_write_price_per_1k` (fica 0, sem custo de escrita
-- computado).
CREATE TABLE model_prices (
    id                       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver                   TEXT NOT NULL
                             CHECK (driver IN ('openai', 'anthropic',
                                                'openai_compatible',
                                                'lmstudio', 'ollama')),
    provider_ref             TEXT NOT NULL,
    input_price_per_1k       NUMERIC(12,6) NOT NULL DEFAULT 0,
    cache_read_price_per_1k  NUMERIC(12,6) NOT NULL DEFAULT 0,
    cache_write_price_per_1k NUMERIC(12,6) NOT NULL DEFAULT 0,
    output_price_per_1k      NUMERIC(12,6) NOT NULL DEFAULT 0,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (driver, provider_ref)
);
