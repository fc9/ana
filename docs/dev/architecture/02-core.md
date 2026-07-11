# Core

Status: Draft
Versão: 0.1
Última atualização: 2026-07-10
Responsável: Arquitetura

---

# 1. Objetivo

Apresenta o núcleo da aplicação.

---

# 2. Escopo

## Responsabilidades

- orquestrar o fluxo das requisições;
- aplicar regras de negócio;
- comunicar-se com os demais módulos, agentes, tool e skills.

## Não Responsabilidades

Este documento não define:

- detalhes da API HTTP (rotas, schemas) — ver `05-api.md`.

---

# 3. Visão Geral

## Arquitetura

```
                  Usuário
                     │
                     ▼
        Interface Web (src/apps/web)
                     │
                     ▼
            API (src/apps/api)
                     │
                     ▼
          Ana Core (src/core/main)
                     │
     ┌───────────────┼────────────────┐
     │               │                │
     ▼               ▼                ▼
  Modules       Integrations       Shared
     │               │                │
     ▼               ▼                ▼
  Memory        Providers          Tools
 Projects       OpenClaude         Skills
  Editor           MCP             Utils
```

---

## Execução

O Core é independente da API: não depende de FastAPI nem de qualquer
detalhe da camada HTTP, e pode ser testado e evoluído isoladamente.

Essa independência é de código, não de deployment. No MVP, o Core roda
embutido no mesmo processo/container da API — a API importa e executa o
Core diretamente, sem chamada de rede entre eles. Isso evita a
complexidade de um serviço adicional (rede interna, autenticação
serviço-a-serviço, deployment próprio) numa etapa em que a prioridade é
infraestrutura simples, não escala.

Como o Core já é desacoplado no código, ele poderá ser extraído para um
container próprio mais adiante, sem reescrita, quando houver necessidade
real — por exemplo, agentes de execução longa ou orquestração assíncrona
pesada que justifiquem isolar o núcleo do processo da API.

---

## Orquestrador Ana Core

O orquestrador é 100% determinístico. Ele não "pensa". Ele apenas coordena o fluxo.

O Core como um todo deve ser **80% ou mais determinístico** — a
esmagadora maioria do fluxo (validação, carregamento de projeto/config,
trava de processamento, montagem de contexto, registro de consumo,
persistência) é código puro, sem inferência de LLM. A única etapa
genuinamente não-determinística é a chamada ao LLM em si ("Chamar o
LLM", abaixo) — por isso o Core não é 100% determinístico, só o
orquestrador que o coordena é.

Agentes e ferramentas (`shared/tools`, `shared/skills`, futuros) nunca
decidem como o LLM, nem falam com o LLM diretamente — são **100%
determinísticos**. Só o orquestrador decide quando e como chamar o LLM,
sempre através da abstração de Provider (ver "Provider LLM", abaixo).

Fluxo pretendido:

```
Receber mensagem
        │
        ▼
Validar contexto
        │
        ▼
Carregar projeto
        │
        ▼
Carregar configurações
        │
        ▼
Consultar memória (quando existir)
        │
        ▼
Selecionar skills (quando existirem)
        │
        ▼
Selecionar agentes (quando necessário)
        │
        ▼
Montar contexto
        │
        ▼
Escolher provider/modelo
        │
        ▼
Chamar o LLM
        │
        ▼
Registrar consumo de tokens
        │
        ▼
Processar tool calls
        │
        ▼
Persistir conversa
        │
        ▼
Retornar resposta
```

No MVP, várias dessas etapas simplesmente não fazem nada — exceto o
registro de consumo de tokens, que já é ativo (ver `../00-context.md` >
Consumo de Tokens). O fluxo também inclui a trava de processamento por
projeto e a decisão da expressão do avatar da Ana, ambas já ativas no
MVP (detalhado em `06b-services.md` > `MessageService`,
`start_chat`/`send_message`).

Antes de "Receber mensagem" (fora do orquestrador, na camada Service —
ver `06b-services.md` > GuardService), a mensagem passa por validação:
texto ou anexo presente, limite de anexos, tamanho mínimo de texto e
regras da primeira mensagem do chat. Se rejeitada, o Core nem chega a
ser acionado.

```
Receber mensagem
        │
        ▼
Checar/setar trava de processamento do projeto
        │
        ▼
Validar contexto
        │
        ▼
Carregar projeto
        │
        ▼
Carregar configurações
        │
        ▼
Montar contexto
        │
        ▼
Escolher provider/modelo
        │
        ▼
Chamar LLM
        │
        ▼
Registrar consumo de tokens
        │
        ▼
Decidir expressão do avatar da resposta
        │
        ▼
Persistir conversa (marca primeira mensagem/gera título, se aplicável)
        │
        ▼
Liberar trava de processamento do projeto
        │
        ▼
Retornar resposta
```

Como o MVP não processa tool calls, ações que dependeriam disso — como o
usuário pedir pela conversa para remover um anexo (ver
`../contracts/attachment.md`) — só ficam disponíveis via feature direta
do frontend/API/backend, não pelo chat.

### Provider LLM

Camada responsável pela comunicação com modelos de linguagem.

Toda interação com modelos deve ocorrer através desta abstração.

Nenhum módulo da aplicação deve depender diretamente de um provider específico.

A resposta do Provider deve incluir o consumo de tokens da chamada —
entrada, saída, e cache de leitura/escrita em separado quando o provider
distinguir os dois (ex: Anthropic) — usado para calcular o custo em USD
(`TokenUsageService.calculate_cost`, ver `06b-services.md`) e alimentar
`token_usage`/`token_usage_totals` de forma síncrona, agregando os dois
tipos de cache num único `cache_tokens` na hora de persistir (ver
`../00-context.md` > Consumo de Tokens e `07-database.md`).

---

## Memória (futuro)

A memória do Core será composta por camadas, delimitadas pelo escopo do
chat dentro do projeto:

- **memória global do projeto** — acessível a todos os chats do projeto;
- **memória pública de um topic** — resumo da memória privada de um
  topic, incorporado à memória global do projeto;
- **memória privada de um topic** — compartilhada apenas entre os chats
  que pertencem àquele topic.

Um chat sem topic acessa apenas a memória global do projeto. Um chat
dentro de um topic acessa a memória global do projeto e, adicionalmente,
a memória privada do seu próprio topic.

Este modelo não possui aplicação no MVP. Detalhes do conceito de Topic em
`../contracts/topic.md`. Tipos de memória (usuário, feedback, projeto,
referência), formato e mecânica de leitura/escrita em `12-memory.md`.

---

# 4. Integrações

## API

A API chama o Core diretamente, no mesmo processo (ver "Execução"
acima). O Core não expõe HTTP — quem faz isso é a API.

## Provider LLM

O Core usa exclusivamente a abstração de Provider (ver "Provider LLM"
acima) para comunicação com modelos de linguagem. Nunca chama um SDK
específico diretamente.

## Módulos, Integrações e Shared

O Core coordena os módulos (ex: Projects), integrações (ex: Providers e,
futuramente, OpenClaude e MCP) e utilitários compartilhados (Tools,
Skills), conforme o diagrama em "Arquitetura".

---

# 5. Evolução Futura

O Core deverá evoluir para orquestrar:

- memória (ver "Memória (futuro)" acima);
- seleção de skills;
- seleção e coordenação de agentes;
- processamento de tool calls;
- extração para container/serviço próprio, caso necessário (ver
  "Execução" acima);
- edição de arquivos do projeto sempre dentro do escopo de um commit
  git — a Ana verifica/inicia git na raiz do projeto antes de editar
  qualquer arquivo, e nunca edita fora desse escopo (ver
  `09-projects.md` > Evolução Futura).

---

# 6. Documentação Relacionada

## Geral

- `../00-context.md`
- `00-development.md`

## Arquitetura

- `01-system.md`
- `03-backend.md`
- `04-frontend.md`
- `05-api.md`
- `06-models.md`
- `06b-services.md`
- `integrations/openclaude.md`
- `07-database.md`
- `08-redis.md`
- `09-projects.md`
- `10-resilience.md`
- `11-search.md`
- `12-memory.md`

