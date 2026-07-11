-- Tabela: provider_subscriptions
-- Contract: docs/dev/contracts/provider-subscription.md
--
-- Uma assinatura é o vínculo de um projeto a UMA credencial de um
-- provider — é o que dá a um projeto acesso de fato (pra usar e pra
-- gerenciar) a uma credencial privada, ou acesso rastreado a uma
-- pública (ver 05b-provider-credentials.sql). Usar uma credencial
-- pública sem nunca ter assinado (acesso implícito) não gera linha
-- aqui — só o projeto que efetivamente cadastrou/assinou aparece (ver
-- docs/dev/architecture/06b-services.md > ProviderService).
--
-- `UNIQUE (project_id, provider_id)`: um projeto só pode ter UMA conta
-- assinada por provider — trocar de conta é sempre uma migração da
-- MESMA linha de assinatura para outro `credential_id` (edição de
-- credencial), nunca uma segunda assinatura para o mesmo provider (ver
-- docs/dev/architecture/06b-services.md > ProviderService.edit_credential).
--
-- `provider_id` é redundante com `credential_id.provider_id` (a
-- credencial já aponta pro provider) — mantido aqui por conveniência de
-- consulta (filtrar "assinaturas do projeto X pro provider Y" sem JOIN)
-- e para a UNIQUE acima.
--
-- Exclusão ("desassinar", ver contract) é física — remove só esta
-- linha, nunca a credencial ou o provider por trás dela (a menos que a
-- credencial fique órfã como consequência, ver
-- docs/dev/architecture/06b-services.md > ProviderService.unsubscribe).
CREATE TABLE provider_subscriptions (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id     UUID NOT NULL REFERENCES projects (id),
    provider_id    UUID NOT NULL REFERENCES providers (id),
    credential_id  UUID NOT NULL REFERENCES provider_credentials (id),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (project_id, provider_id)
);

CREATE INDEX idx_provider_subscriptions_project_id ON provider_subscriptions (project_id);
CREATE INDEX idx_provider_subscriptions_credential_id ON provider_subscriptions (credential_id);
