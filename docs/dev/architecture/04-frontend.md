# 04 - Frontend Web

Status: Draft
Versão: 0.1
Última atualização: 2026-07-10
Responsável: Arquitetura

---

# 1. Objetivo

Definir a arquitetura geral do frontend da Ana.

---

# 2. Escopo

## Responsabilidades

- gerenciamento de chats;
- gerenciamento de projects;
- gerenciamento de providers e modelos (`provider_models`), incluindo
  cadastro e preço por 1K tokens;
- exibição da pilha ordenada de Provider/Modelo no dropdown do Header,
  incluindo reordenação local e sincronização com o Backend (ver
  `ui/dashboard.md` > Header > Dropdown de Provider/Modelo);
- configurações: moeda do projeto, idioma do usuário;
- envio de mensagens;
- upload e remoção de anexos;
- apresentação das respostas;
- busca dos dados de cada painel do `ToolPanel` (ex: Gastos) via
  endpoint genérico de ferramentas, exibindo spinner enquanto carrega;
- monitoramento de status em tempo real do provider ativo, banco de
  dados e demais sistemas críticos, via WebSocket (ver
  `10-resilience.md` > Monitoramento de status em tempo real);
- sincronização entre chats e abas enquanto a Ana processa uma
  mensagem: opacidade reduzida e bloqueio de troca nos demais chats do
  projeto, seleção automática do chat em processamento ao reabrir o
  projeto, e sincronização imediata entre abas do mesmo chat — tudo via
  WebSocket (o canal é por projeto, não por aba; sem cookie nenhum
  envolvido, ver `10-resilience.md` > Processamento entre chats e abas e
  `ui/dashboard.md` > Main > Bloqueio de envio durante processamento).
 
Lidar com router, pages, features, componentes, hooks e API Client.

## Não Responsabilidades

A Interface Web não deve conter regras de negócio.

---

# 3. Visão Geral

## Camadas

```
App Router          — rotas finas (Next.js), delegam para Pages
↓
Pages               — composição de tela, monta Features
↓
Features            — lógica e UI de domínio (uma pasta por área)
↓
Components          — UI genérica, sem lógica de domínio
↓
Hooks                → Stores (estado de UI: Zustand)
                     → API Client (dados de servidor: TanStack Query)
```

- **TanStack Query**: dados que vêm do Backend (chats, mensagens,
  projects, providers etc.) — cache, revalidação e polling (ex: painel
  Gastos, que atualiza em tempo real enquanto aberto).
- **Zustand**: só estado de UI local (contexto/ferramenta selecionada,
  colapso de `WorkPanel`/`ToolPanel`) — nunca dados vindos da API.

Nada sobre backend.

## Estrutura

```text
apps/web/
├── postcss.config.mjs              # plugin @tailwindcss/postcss
├── public/                         # servido direto por URL (Next.js) — favicon, manifest, imagens com URL estável
│   └── favicon.ico
│
└── src/
    ├── assets/                     # importado direto no código (não servido por URL) — logo, ilustrações
    │   └── images/
    │
    ├── app/                        # Next.js App Router — rotas finas, delegam para pages/
    │   ├── layout.tsx              # Shell: Header + Desktop + Footer
    │   ├── page.tsx                # → DashboardPage (contexto padrão: Chats)
    │   ├── chat/
    │   │   └── [chatId]/
    │   │       └── page.tsx        # → DashboardPage com chat ativo
    │   └── globals.css             # @import "tailwindcss" + @import "../styles/tokens.css"
    │
    ├── pages/
    │   └── dashboard/
    │       └── DashboardPage.tsx   # composição: Header + ContextBar + Desktop + ToolBar + Footer
    │
    ├── features/
    │   ├── header/                 # logo, dropdown projeto, dropdown git, notificações, dropdown provider/modelo
    │   ├── context-bar/             # ContextBar: ícones de contexto, Settings, menu de exibição
    │   ├── tool-bar/                 # ToolBar: ícones de ferramenta (Configs, Gastos, Ajuda)
    │   ├── work-panel/
    │   │   └── chats/                # WorkPanel no contexto Chats: novo chat, buscar, Works, lista
    │   ├── main/
    │   │   └── chat/                 # área de conversa, composer, mensagens
    │   ├── tool-panel/
    │   │   ├── configs/               # ToolPanel > ferramenta Configs
    │   │   └── gastos/                # ToolPanel > ferramenta Gastos
    │   ├── projects/                  # criar, renomear, trocar projeto
    │   ├── providers/                 # cadastro/edição de provider e modelo
    │   └── attachments/                # upload/remoção de anexo
    │
    ├── components/
    │   ├── ui/                         # botão, dropdown, ícone, avatar etc.
    │   └── icons/                      # SVGs importados como componentes React
    │
    ├── hooks/
    │   ├── use-panel-selection.ts      # seleção de contexto/ferramenta + colapso do painel correspondente
    │   └── use-panel-preferences.ts    # mostrar/ocultar ícones (hidden_contexts/hidden_tools); debounce de 3s + PATCH assíncrono (ver 10-resilience.md)
    │
    ├── stores/                          # Zustand — só estado de UI
    │   ├── dashboard-store.ts           # contexto/ferramenta selecionada, estado de colapso
    │   └── realtime-store.ts            # processing_chat_id e status de provider/banco/sistemas críticos (system_status, futuro), alimentado por realtime-client.ts — new_message e provider_stack não passam por aqui (ver lib/realtime-client.ts)
    │
    ├── lib/
    │   ├── api-client/                  # mesmo recorte de entidades do Backend (ver 06-models.md)
    │   │   ├── chats.ts                 # inclui busca (ver 11-search.md) e POST /projects/{id}/chats (cria chat + 1ª mensagem)
    │   │   ├── messages.ts
    │   │   ├── projects.ts
    │   │   ├── git.ts                    # GET /projects/{id}/git — mockado no MVP
    │   │   ├── providers.ts             # inclui GET .../provider-stack (só leitura — nunca escrita pelo Frontend)
    │   │   ├── provider-models.ts
    │   │   ├── configs.ts
    │   │   ├── currencies.ts
    │   │   ├── languages.ts
    │   │   ├── attachments.ts           # escopado ao projeto, não ao chat
    │   │   ├── tools.ts                  # POST /projects/{id}/tools/{tool}
    │   │   ├── limits.ts                 # GET /limits
    │   │   └── me.ts
    │   ├── query-client.ts               # configuração do TanStack Query
    │   └── realtime-client.ts            # conexão WebSocket (ver 10-resilience.md): `processing`/`system_status` (futuro) atualizam realtime-store (Zustand); `new_message` invalida a query de mensagens do chat afetado; `provider_stack` escreve direto no cache do TanStack Query (é dado de servidor, não estado de UI — ver Camadas, acima) — nenhum dos dois passa por realtime-store
    │
    ├── styles/
    │   ├── tokens.css                     # design tokens via @theme (Tailwind v4) — cores, espaçamento, fontes
    │   ├── fonts/                          # arquivos de fonte (.woff2), self-hosted
    │   └── fonts.ts                        # next/font/local, carrega os arquivos de fonts/
    │
    └── types/                              # tipos TS espelhando os Schemas do Backend (ver 06-models.md)
```

Os nomes de `features/` seguem o vocabulário de `ui/dashboard.md`
(`ContextBar`, `WorkPanel`, `Main`, `ToolBar`, `ToolPanel`).

Ícones SVG são importados como componentes React (`components/icons/`),
não como arquivo estático em `public/` — os estados visuais (selecionado,
hover, desabilitado) dependem de herdar cor via `currentColor`, o que só
funciona com SVG inline.

Estilização: Tailwind CSS v4 (config em CSS via `@theme`, sem
`tailwind.config.ts`). Os design tokens (paleta de cores, espaçamento,
fontes — ver as lacunas levantadas para `ui/dashboard.md`) são definidos
em `styles/tokens.css` e viram utility classes do Tailwind diretamente,
sem camada de config JS intermediária.

Reset de CSS: só o Preflight do próprio Tailwind (ativado junto com
`@import "tailwindcss"`) — sem normalize.css como dependência separada.
O Preflight já é baseado no normalize.css e vai além (remove margins
padrão, força `border-box`); adicionar os dois geraria reset duplicado
e risco de conflito de cascade.

Sem suporte a SCSS/Sass — decisão explícita, não uma lacuna. O Tailwind
v4 usa Lightning CSS por baixo (nesting e custom properties nativos),
cobrindo o que o projeto precisa sem uma segunda linguagem de
estilização. Se surgir uma necessidade real (mixins, loops), o Next.js
suporta Sass nativamente bastando adicionar o pacote `sass` — sem
retrofit custoso.

---

# 4. Integrações

Comunica-se somente com a API backend, sempre através de `lib/api-client/`
— nenhuma Feature faz `fetch` direto (ver `05-api.md`).

---

# 5. Evolução Futura

Planejado adicionar features para:

- interface dedicada de custos (histórico detalhado por período, além
  do resumo agregado já exibido no painel Gastos do MVP — ver
  `ui/dashboard.md` > ToolPanel na ferramenta Gastos e `../00-context.md`
  > Consumo de Tokens);
- gestão de git branches e PRs (no futuro) — respeitando as regras de
  segurança da Ana com git (nunca mexe em commit/branch que não é dela,
  nunca aprova PR, só abre — ver `09-projects.md` > Evolução Futura).

Essa funcionalidade não faz parte do MVP, embora o modelo UI da mesma
possa ser providenciado de antemão para testes com dados mockados.

---

# 6. Documentação Relacionada

## Geral

- `../00-context.md`
- `00-development.md`

## Arquitetura

- `01-system.md`
- `02-core.md`
- `03-backend.md`
- `05-api.md`
- `06-models.md`
- `06b-services.md`
- `integrations/openclaude.md`
- `07-database.md`
- `08-redis.md`
- `09-projects.md`
- `10-resilience.md`
- `11-search.md`
- `ui/dashboard.md`
