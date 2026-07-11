-- Tabela: meta
-- Contract: nenhum (tabela técnica, ver docs/dev/architecture/07-database.md).
--
-- Extensão necessária para gen_random_uuid(), usado em todas as tabelas
-- de domínio a partir daqui.
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Armazena metadados internos do banco (ex: versão do schema aplicado).
-- Não segue a convenção de UUID (ver 07-database.md > Princípios).
CREATE TABLE meta (
    key         TEXT PRIMARY KEY,
    value       TEXT NOT NULL,
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
