-- Tabela: mcps (futuro — fora do escopo do MVP)
-- Contract: docs/dev/contracts/mcp.md
-- Global — não pertence a um projeto específico.
CREATE TABLE mcps (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name        TEXT NOT NULL UNIQUE,
    config      JSONB NOT NULL DEFAULT '{}',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
