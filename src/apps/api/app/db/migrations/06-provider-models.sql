-- Tabela: provider_models
-- Contract: docs/dev/contracts/provider-model.md
--
-- Pertence ao provider GLOBAL (05-providers.sql), não a uma credencial
-- nem a um projeto — o catálogo de modelos é propriedade do serviço em
-- si, compartilhado por todas as contas/credenciais desse provider (ver
-- docs/dev/architecture/06b-services.md > ProviderService, que exige o
-- solicitante ter assinatura no provider pra gerenciar seus modelos).
--
-- Preço **não** vive aqui — vive em `model_prices` (06b-model-prices.sql),
-- chaveada por (driver, provider_ref), não por esta linha; ver
-- docs/dev/architecture/06b-services.md > ModelPriceService. Nem toda
-- linha nasce de cadastro manual: `ProviderCacheService.rebuild_cache`
-- descobre o catálogo ao vivo de cada provider (todos os modelos
-- disponíveis, cadastrados por nós ou não) e cria as linhas que faltam.
--
-- `provider_ref` é o identificador técnico que o PRÓPRIO provider usa
-- pra esse modelo nas chamadas de API — formato varia por provider
-- (alguns usam um id específico, outros um slug, outros o próprio nome
-- de exibição); opaco pra nós, nunca inferido. É essa string, não o
-- `id` (UUID interno), que dá identidade estável ao modelo entre
-- exclusão e recadastro do provider dono (ver 05-providers.sql e
-- configs.active_model_ref) — `services/llm/` é quem garante que esse
-- valor não muda enquanto o modelo continuar existindo no catálogo do
-- provider (ver docs/dev/architecture/06b-services.md > Integrações >
-- Providers). É também essa mesma string, junto do `driver` do provider
-- dono, que identifica o preço do modelo em `model_prices`. `name` é só
-- rótulo de exibição (pode ser igual a `provider_ref`, mas nem sempre)
-- — nunca usado como chave de identidade.
--
-- `is_active`: mantido automaticamente por rebuild_cache — passa a
-- false quando o modelo some do catálogo ao vivo de todas as
-- credenciais que responderam na rodada (descontinuado pelo provider),
-- mas o registro fica mantido só para referência histórica (inclusive
-- de preço, em `model_prices`); nunca vira false só porque o provider
-- inteiro estava fora do ar (isso é disponibilidade transitória,
-- calculada só no cache, nunca persistida nesta tabela — ver
-- docs/dev/architecture/06b-services.md > ProviderCacheService e
-- docs/dev/architecture/08-redis.md).
CREATE TABLE provider_models (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id          UUID NOT NULL REFERENCES providers (id),
    provider_ref         TEXT NOT NULL, -- id/slug técnico do provider p/ este modelo
    name                 TEXT NOT NULL, -- rótulo de exibição, ex: 'GPT-5'
    is_active            BOOLEAN NOT NULL DEFAULT true,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (provider_id, provider_ref)
);

CREATE INDEX idx_provider_models_provider_id ON provider_models (provider_id);
