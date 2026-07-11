-- Tabela: configs
-- Contract: docs/dev/contracts/config.md
--
-- Substitui a antiga tabela config (singleton, Ana-wide, extinta): a
-- configuração deixou de ser global e passou a ser por projeto — uma
-- linha por projeto, com moeda e IA em uso (provider/modelo ativo). É
-- aqui, e só aqui, que a Ana consulta moeda/provider/modelo de um
-- projeto — nunca em projects diretamente.
--
-- Existir como tabela separada de projects resolve a dependência
-- circular projects/providers/provider_models: projects não precisa
-- saber de provider algum, então providers pode referenciar projects
-- sem problema, e configs (criada por último) referencia os três.
--
-- active_provider_id / active_model_ref (anuláveis: um projeto pode
-- existir sem provider configurado ainda) identificam o provider/modelo
-- ativo do projeto. Diferente do desenho anterior, `providers` agora é
-- GLOBAL e só é excluído fisicamente quando fica sem nenhuma credencial
-- (evento raro, ver 05c-provider-subscriptions.sql) — por isso
-- `active_provider_id` já pode ser o UUID direto de `providers.id`, sem
-- precisar de uma chave por nome (essa instabilidade só existia quando
-- provider era propriedade de um projeto e podia ser excluído a
-- qualquer momento). `active_model_ref` continua sendo o
-- `provider_models.provider_ref` (id/slug técnico do modelo) — modelos
-- específicos ainda podem sumir do catálogo independente do provider
-- sobreviver, então essa parte da referência continua por chave
-- estável, não por UUID.
--
-- Sem FK de banco pra `providers` (mesmo padrão de
-- `projects.processing_chat_id`): mesmo `providers` sendo estável, o
-- projeto pode perder ACESSO ao provider (desassinar, ou a credencial
-- que usava virar privada de outro projeto) sem que a linha de
-- `providers` desapareça — resolver "o projeto ainda enxerga esse
-- provider?" é regra de negócio
-- (`ProviderCacheService.resolve_active_model`), não uma FK. Se não
-- houver mais acesso (ou o provider tiver sido excluído de fato), esse
-- é o estado "removido" (ver docs/dev/architecture/ui/dashboard.md >
-- Provider indisponível).
-- currency_id não é anulável — a aplicação atribui USD na criação do
-- projeto.
--
-- Campos futuros previstos aqui (não implementados agora): temperatura
-- e demais parâmetros de IA por projeto.
--
-- fixed_contexts: lista dos contextos da ContextBar que o usuário não
-- pode ocultar (ver docs/dev/architecture/ui/dashboard.md > ContextBar).
-- Sem UI de edição no MVP — a aplicação grava o mesmo default em todo
-- projeto na criação (ver ConfigService.create_default_config); a
-- edição pelo usuário fica para quando entrar em Settings (futuro).
--
-- hidden_contexts / hidden_tools: contextos da ContextBar e ferramentas
-- da ToolBar que o usuário escolheu ocultar via "Menu de exibição" (ver
-- docs/dev/architecture/ui/dashboard.md > ContextBar/ToolBar). Editável
-- no MVP via PATCH /projects/{id}/config, com debounce de 3s no
-- Frontend antes de enviar (ver docs/dev/architecture/06b-services.md
-- > ConfigService).
--
-- provider_order: pilha ordenada de provider_id (JSONB, array de UUID)
-- usada para montar o dropdown de Provider/Modelo do Header — ver
-- docs/dev/architecture/ui/dashboard.md > Header > Dropdown de
-- Provider/Modelo. NULL até a primeira gravação (ordenação padrão é
-- alfabética por nome de provider, calculada em tempo de leitura,
-- nunca persistida como fallback). provider_order_updated_at é o
-- carimbo de versão usado pelo Frontend/broadcast para saber se uma
-- pilha recebida é mais nova que a atual (ver
-- docs/dev/architecture/06b-services.md > ProviderService).
CREATE TABLE configs (
    id                        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id                UUID NOT NULL UNIQUE REFERENCES projects (id),
    currency_id               UUID NOT NULL REFERENCES currencies (id),
    active_provider_id        UUID NULL, -- sem FK, ver comentário acima
    active_model_ref          TEXT NULL,
    fixed_contexts            JSONB NOT NULL
                              DEFAULT '["chats", "files", "git"]',
    hidden_contexts           JSONB NOT NULL DEFAULT '[]',
    hidden_tools              JSONB NOT NULL DEFAULT '[]',
    provider_order            JSONB NULL,
    provider_order_updated_at TIMESTAMPTZ NULL,
    created_at                TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at                TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_configs_currency_id ON configs (currency_id);

-- View de conveniência: junta projects + configs num único lugar de
-- leitura. Não tenta resolver o provider/modelo ativo
-- (active_provider_id/active_model_ref) — essa resolução depende de
-- verificar acesso (assinatura própria ou credencial pública) contra
-- provider_subscriptions/provider_credentials, o que não cabe numa view
-- SQL simples; fica a cargo de ProviderCacheService.resolve_active_model
-- (ver docs/dev/architecture/06b-services.md).
CREATE VIEW project_overview AS
SELECT
    p.id,
    p.user_id,
    p.name,
    p.path,
    c.currency_id,
    p.created_at,
    p.updated_at
FROM projects p
LEFT JOIN configs c ON c.project_id = p.id;
