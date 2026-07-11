-- Tabela: memories (futuro — fora do escopo do MVP)
-- Contract: docs/dev/contracts/memory.md
--
-- topic_id nulo = memória global do projeto; preenchido = memória de
-- um topic (pública ou privada, conforme scope).
CREATE TABLE memories (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id  UUID NOT NULL REFERENCES projects (id),
    topic_id    UUID NULL REFERENCES topics (id),
    scope       TEXT NOT NULL
                CHECK (scope IN ('project_global', 'topic_public', 'topic_private')),
    content     TEXT NOT NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (
        (scope = 'project_global' AND topic_id IS NULL)
        OR (scope IN ('topic_public', 'topic_private') AND topic_id IS NOT NULL)
    )
);

CREATE INDEX idx_memories_project_id ON memories (project_id);
CREATE INDEX idx_memories_topic_id ON memories (topic_id);
