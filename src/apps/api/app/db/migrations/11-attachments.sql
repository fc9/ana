-- Tabela: attachments
-- Contract: docs/dev/contracts/attachment.md
--
-- Pertence sempre a 1 message (nunca nulo) — a linha só é criada no
-- momento do envio, na mesma transação da mensagem (ver
-- docs/dev/architecture/06b-services.md > MessageService.start_chat/
-- send_message). Antes do envio, o arquivo já está salvo em disco
-- (.ana/storage), mas ainda sem linha em attachments — ver
-- AttachmentService.upload/resolve_staged.
-- Chat e projeto do anexo são derivados via message_id ->
-- messages.chat_id -> chats.project_id; não há chat_id/project_id
-- diretos aqui (evita redundância).
-- Exclusão é física (ver 07-database.md > attachments): remover a linha
-- também remove o arquivo em .ana/storage, na raiz do projeto do chat.
-- Limite de 10 anexos por envio e retenção de 12h (descartável por
-- padrão) são regras de aplicação, não constraints de banco — ver
-- docs/dev/contracts/attachment.md.
CREATE TABLE attachments (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id    UUID NOT NULL REFERENCES messages (id),
    type          TEXT NOT NULL
                  CHECK (type IN ('file', 'image', 'audio', 'video',
                                  'text', 'clipboard')),
    storage_path  TEXT NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_attachments_message_id ON attachments (message_id);
