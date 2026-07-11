-- Tabela: provider_credentials
-- Contract: docs/dev/contracts/provider-credential.md
-- Cifragem: docs/dev/research/cifragem de credenciais.md
--
-- Uma credencial é uma CONTA de acesso a um provider (05-providers.sql)
-- — ex: duas contas OpenAI diferentes (pessoal e da empresa) são duas
-- linhas aqui, sob o mesmo `provider_id`. `account_or_tenant` é o
-- identificador de conta devolvido pelo próprio provider na validação
-- de acesso (org_id, workspace, tenant — ver
-- docs/dev/research/identificacao-unica-de-providers.md); anulável
-- porque nem todo provider distingue conta (ex: LM Studio local sem
-- autenticação).
--
-- Cifragem do segredo (AES-256-GCM, ver
-- docs/dev/architecture/06b-services.md > CredentialCipher):
-- `encrypted_secret` é o ciphertext (a tag de autenticação de 16 bytes
-- do GCM vem concatenada, conforme a biblioteca); `encryption_nonce` é
-- gerado aleatório e não pode ser reaproveitado entre operações;
-- `encryption_key_id` identifica qual chave mestra cifrou esta linha
-- (permite rotação — várias chaves podem coexistir temporariamente);
-- `encryption_version` versiona o formato/algoritmo em si (permite
-- migrar de algoritmo no futuro sem quebrar linhas antigas). O AAD
-- (dado autenticado, não cifrado, mas protegido contra alteração) liga
-- o ciphertext a `id`/`provider_id`/`encryption_version` desta própria
-- linha — impede copiar o ciphertext de uma credencial para outra sem
-- que a decifragem falhe. `secret_hint` guarda só um sufixo mascarado
-- (ex: 'sk-proj-••••••••••••aB31') para a UI exibir a credencial sem
-- precisar decifrar o segredo de verdade. O banco nunca recebe nem
-- guarda o segredo em texto puro em coluna nenhuma.
--
-- `is_private`: false (pública) = qualquer projeto pode USAR sem
-- assinar (ver 05c-provider-subscriptions.sql); true (privada) = só
-- quem tem assinatura enxerga/usa. No máximo UMA credencial pública por
-- provider — se um cadastro pedir pública com outra já existente, o
-- Backend registra a nova como privada e avisa o motivo (ver
-- docs/dev/architecture/06b-services.md > ProviderService.register).
--
-- UNIQUE por (provider_id, conta) evita duplicar a mesma conta —
-- COALESCE trata contas sem account_or_tenant (NULL) como uma única
-- "conta" por provider (ex: só faz sentido uma credencial local de LM
-- Studio por instalação).
CREATE TABLE provider_credentials (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    provider_id          UUID NOT NULL REFERENCES providers (id),
    account_or_tenant    TEXT NULL,
    encrypted_secret     BYTEA NOT NULL,
    encryption_nonce     BYTEA NOT NULL,
    encryption_key_id    TEXT NOT NULL,
    encryption_version   SMALLINT NOT NULL DEFAULT 1,
    secret_hint          TEXT NOT NULL, -- ex: 'sk-proj-••••••••••••aB31', nunca o segredo real
    is_private           BOOLEAN NOT NULL DEFAULT false,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_provider_credentials_identity
    ON provider_credentials (provider_id, COALESCE(account_or_tenant, ''));

-- No máximo uma credencial pública por provider (ver comentário acima).
CREATE UNIQUE INDEX idx_provider_credentials_one_public
    ON provider_credentials (provider_id) WHERE is_private = false;

CREATE INDEX idx_provider_credentials_provider_id ON provider_credentials (provider_id);
