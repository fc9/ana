-- Tabela: chats
-- Contract: docs/dev/contracts/chat.md
--
-- topic_id já existe (coluna prevista), mas só passa a ser usada quando
-- Topic for implementado — futuro, ver 08-topics.sql.
--
-- pinned_at: não-nulo quando o chat está favoritado (ver
-- docs/dev/architecture/ui/dashboard.md > Item da lista de Chats).
-- Ordenação: favoritados no topo, mais recente favoritado primeiro
-- (ORDER BY pinned_at DESC NULLS LAST).
--
-- Toda linha criada aqui já nasce com ao menos 1 mensagem: a criação é
-- atômica com o envio da primeira mensagem válida (ver
-- docs/dev/architecture/06b-services.md > MessageService.start_chat).
-- Se essa primeira mensagem falhar (Guard ou chamada ao LLM), a linha
-- é descartada (hard delete) — do ponto de vista do usuário, o chat
-- nunca existiu.
CREATE TABLE chats (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id  UUID NOT NULL REFERENCES projects (id),
    topic_id    UUID NULL REFERENCES topics (id),
    title       TEXT NOT NULL,
    status      TEXT NOT NULL DEFAULT 'active'
                CHECK (status IN ('active', 'archived', 'deleted')),
    pinned_at   TIMESTAMPTZ NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_chats_project_id_status ON chats (project_id, status);
CREATE INDEX idx_chats_topic_id ON chats (topic_id);
