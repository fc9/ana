-- Tabela: users
-- Contract: docs/dev/contracts/user.md
--
-- Sem autenticação no MVP (ver contract) — apenas identificação básica.
-- Credenciais/login ficam para quando a autenticação for implementada.
--
-- language_id é preferência global do usuário, usada em toda a Ana
-- (futuramente também na UI) — ver contracts/language.md. Moeda NÃO
-- fica aqui: é configuração por projeto (ver 07-projects.sql). Sem
-- DEFAULT no banco (não é possível referenciar uma linha de seed em um
-- DEFAULT de coluna) — a aplicação atribui 'en' na criação do usuário.
CREATE TABLE users (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    language_id  UUID NOT NULL REFERENCES languages (id),
    name         TEXT NOT NULL,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_users_language_id ON users (language_id);
