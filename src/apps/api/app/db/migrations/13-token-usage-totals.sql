-- Tabela: token_usage_totals
-- Contract: docs/dev/contracts/token-usage-totals.md
--
-- Rollup em tempo real: uma linha por (project, provider_model).
-- Atualizada via upsert síncrono a cada novo token_usage — nunca
-- recalculada em batch. O consumo total de um projeto é a soma destas
-- linhas para aquele project_id (poucas linhas, leitura rápida); o
-- consumo por provider é a soma filtrando por provider_id.
--
-- provider_id/provider_model_id são UUID sem FK, mesmo motivo de
-- token_usage (ver 12-token-usage.sql): sobrevive à exclusão física do
-- provider/modelo. provider_name/model_name são snapshot do nome de
-- exibição — atualizados a cada upsert com o nome mais recente
-- conhecido (não travam no primeiro uso), mas nunca ficam vazios
-- mesmo que o provider seja excluído depois.
CREATE TABLE token_usage_totals (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id         UUID NOT NULL REFERENCES projects (id),
    provider_id        UUID NOT NULL,
    provider_model_id  UUID NOT NULL,
    provider_name      TEXT NOT NULL,
    model_name         TEXT NOT NULL,
    input_tokens       BIGINT NOT NULL DEFAULT 0,
    cache_tokens       BIGINT NOT NULL DEFAULT 0,
    output_tokens      BIGINT NOT NULL DEFAULT 0,
    cost_usd           NUMERIC(14,6) NOT NULL DEFAULT 0,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (project_id, provider_model_id)
);

CREATE INDEX idx_token_usage_totals_project_id ON token_usage_totals (project_id);
CREATE INDEX idx_token_usage_totals_provider_id ON token_usage_totals (provider_id);
CREATE INDEX idx_token_usage_totals_provider_model_id ON token_usage_totals (provider_model_id);
