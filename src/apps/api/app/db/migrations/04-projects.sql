-- Tabela: projects
-- Contract: docs/dev/contracts/project.md
--
-- O projeto padrão 'Base' é uma linha especial sem pasta raiz (path
-- NULL) e não pode ser renomeado/removido pelo usuário — regra aplicada
-- na camada de serviço, não no banco.
--
-- O id desta tabela É o uuid usado no manifesto ".ana/manifest.json"
-- (ver 09-projects.md) — não há coluna de manifesto separada.
--
-- Moeda, provider e modelo NÃO ficam aqui: vivem em project_configs
-- (ver 07-project-configs.sql), que também resolve a dependência
-- circular entre projects/providers/provider_models. Idioma também não
-- fica aqui: é preferência global do usuário (ver users.language_id).
--
-- processing_chat_id: trava de envio por projeto (ver
-- docs/dev/architecture/ui/dashboard.md > Main > Bloqueio de envio
-- durante processamento). Setado com o id do chat sendo processado no
-- início de MessageService.send_message, limpo (NULL) ao final
-- (sucesso ou erro); enquanto não-nulo, novas mensagens em qualquer
-- chat do projeto são rejeitadas. Sem REFERENCES chats(id): projects é
-- criado nesta migration (04), antes de chats (09) — mesma dependência
-- circular já resolvida para projects/providers/configs. Integridade
-- referencial fica por conta da aplicação.
--
-- status: exclusão lógica do projeto (ver ../contracts/project.md).
-- Projeto Base nunca muda de status (regra de Service, não de banco).
--
-- last_accessed_at: atualizado como efeito colateral de GET
-- /projects/{id} (abrir/trocar para o projeto) — usado para ordenar
-- GET /projects do mais recentemente acessado pro menos (ver
-- docs/dev/architecture/ui/dashboard.md > Conteúdo expandido — Projeto).
CREATE TABLE projects (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id              UUID NOT NULL REFERENCES users (id),
    name                 TEXT NOT NULL,
    path                 TEXT NULL,
    processing_chat_id   UUID NULL,
    status               TEXT NOT NULL DEFAULT 'active'
                         CHECK (status IN ('active', 'deleted')),
    last_accessed_at     TIMESTAMPTZ NULL,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_projects_user_id ON projects (user_id);
CREATE INDEX idx_projects_user_id_status ON projects (user_id, status);
