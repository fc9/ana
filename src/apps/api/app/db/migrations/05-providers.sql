-- Tabela: providers
-- Contract: docs/dev/contracts/provider.md
--
-- Registro GLOBAL de instalação/serviço de inferência — não pertence a
-- nenhum projeto (diferente do desenho anterior). Um projeto nunca
-- "cadastra um provider próprio": ele assina uma credencial de um
-- provider já existente, ou provoca a criação de um novo quando nenhum
-- provider com essa identidade existe ainda (ver 05b-provider-credentials.sql,
-- 05c-provider-subscriptions.sql e docs/dev/architecture/06b-services.md
-- > ProviderService).
--
-- Identidade (ver docs/dev/research/identificacao-unica-de-providers.md):
-- `driver` é o adaptador técnico usado (decide qual implementação de
-- services/llm/ tratar as chamadas, ver
-- docs/dev/architecture/06b-services.md > Integrações > Providers) —
-- CHECK restringe ao conjunto de adaptadores que de fato existem em
-- services/llm/ hoje; adicionar um driver novo (ex: um provider futuro)
-- exige migration pra estender essa lista, mesmo padrão já usado em
-- chats.status/messages.role/attachments.type.
-- `canonical_instance_id` identifica a INSTALAÇÃO/serviço, não a conta:
-- 'official' para serviços únicos na nuvem (openai, anthropic), ou o
-- endpoint normalizado (ou um server_instance_id, quando o servidor
-- expõe um) para self-hosted (lmstudio, ollama, openai_compatible) — ver
-- normalize_base_url no documento de pesquisa acima.
--
-- Contas/credenciais distintas do MESMO serviço (ex: duas contas OpenAI
-- diferentes) são o mesmo `providers` row, com múltiplas linhas em
-- provider_credentials — a conta nunca faz parte da identidade do
-- provider (ver 05b-provider-credentials.sql).
--
-- Exclusão é física, mas rara: só acontece quando a última credencial
-- desse provider fica órfã (sem nenhum assinante — ver
-- 05c-provider-subscriptions.sql e docs/dev/architecture/06b-services.md
-- > ProviderService.unsubscribe).
--
-- `is_external`: marca se o provider é alcançado pela internet (serviço
-- de nuvem de terceiros) ou é local/self-hosted (mesma máquina ou rede
-- local) — decide o intervalo do teste periódico de conectividade
-- (PROVIDER_CACHE_REFRESH_SECONDS para local, muito mais espaçado
-- PROVIDER_CACHE_REFRESH_SECONDS_EXTERNAL para externo — ver
-- docs/dev/architecture/06b-services.md > ProviderCacheService), já que
-- provider externo custa (rate limit, possível chamada tarifada) testar
-- com tanta frequência quanto um servidor local. Default sugerido por
-- `driver` no cadastro (true pra 'openai'/'anthropic'/'openai_compatible',
-- false pra 'lmstudio'/'ollama'), mas sempre explícito e sobrescrevível
-- — quem cadastra sabe melhor onde o serviço realmente está.
CREATE TABLE providers (
    id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver                 TEXT NOT NULL
                           CHECK (driver IN ('openai', 'anthropic',
                                              'openai_compatible',
                                              'lmstudio', 'ollama')),
    canonical_instance_id  TEXT NOT NULL, -- 'official', ou endpoint normalizado/server_instance_id
    display_name           TEXT NOT NULL, -- rótulo de exibição, ex: 'OpenAI', 'LM Studio — Notebook'
    base_url               TEXT NULL,     -- endpoint real de chamada (self-hosted); NULL quando o driver já implica a URL
    is_external            BOOLEAN NOT NULL DEFAULT true,
    created_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at             TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (driver, canonical_instance_id)
);
