-- Tabela: messages
-- Contract: docs/dev/contracts/message.md
--
-- role = 'event' representa um registro de sistema associado ao chat
-- (ex: "o usuário deletou o anexo X da mensagem Y") — não é fala do
-- usuário nem da Ana. avatar_expression só é preenchido em mensagens
-- role = 'assistant' (ver docs/dev/architecture/ui/dashboard.md > Main
-- > Avatar da Ana). is_first marca a primeira mensagem de um chat, para
-- a Ana saber que deve gerar o título do chat como parte do
-- processamento.
CREATE TABLE messages (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_id             UUID NOT NULL REFERENCES chats (id),
    role                TEXT NOT NULL
                        CHECK (role IN ('user', 'assistant', 'event')),
    content             TEXT NOT NULL,
    avatar_expression   TEXT NULL,
    is_first            BOOLEAN NOT NULL DEFAULT false,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_messages_chat_id ON messages (chat_id);
