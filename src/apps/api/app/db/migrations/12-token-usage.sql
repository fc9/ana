-- Tabela: token_usage
-- Contract: docs/dev/contracts/token-usage.md
--
-- Log imutável: uma linha por chamada a um provider. cache_tokens é a
-- soma de cache de leitura (cache read) + cache de escrita (cache
-- write, quando o provider distingue, ex: Anthropic) — só 3 tipos
-- agregados são persistidos (entrada, cache, saída), mesmo que o
-- cálculo do custo em si use os dois preços de cache separadamente
-- antes de agregar (ver docs/dev/architecture/06b-services.md >
-- TokenUsageService.calculate_cost). cost_usd é calculado no momento da
-- chamada, usando o preço vigente em model_prices — sempre em USD (ver
-- Princípios em 07-database.md).
--
-- provider_id/provider_model_id são UUID sem FK (mesmo padrão de
-- projects.processing_chat_id, ver 04-projects.sql): providers e
-- provider_models são excluídos fisicamente, e este log não pode perder
-- registro histórico de custo só porque o provider foi removido depois
-- — a linha permanece válida com uma referência "pendurada" (dangling)
-- se isso acontecer. provider_name/model_name são um SNAPSHOT do nome
-- de exibição no momento da chamada (não uma FK) — garante que o
-- painel de Gastos (ver docs/dev/architecture/ui/dashboard.md >
-- ToolPanel na ferramenta Gastos) sempre tenha um rótulo pra mostrar,
-- mesmo que o provider/modelo tenha sido excluído depois.
CREATE TABLE token_usage (
    id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id         UUID NOT NULL REFERENCES projects (id),
    provider_id        UUID NOT NULL,
    provider_model_id  UUID NOT NULL,
    provider_name      TEXT NOT NULL,
    model_name         TEXT NOT NULL,
    chat_id            UUID NULL REFERENCES chats (id),
    input_tokens       BIGINT NOT NULL DEFAULT 0,
    cache_tokens       BIGINT NOT NULL DEFAULT 0,
    output_tokens      BIGINT NOT NULL DEFAULT 0,
    cost_usd           NUMERIC(14,6) NOT NULL DEFAULT 0,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_token_usage_project_id ON token_usage (project_id);
CREATE INDEX idx_token_usage_provider_id ON token_usage (provider_id);
CREATE INDEX idx_token_usage_provider_model_id ON token_usage (provider_model_id);
CREATE INDEX idx_token_usage_chat_id ON token_usage (chat_id);
