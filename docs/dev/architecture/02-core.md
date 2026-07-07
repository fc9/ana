# Core

Status: Draft
Versão: 0.1
Última atualização: 2026-07-06
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

- lidar com a interface de api.

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
Processar tool calls
        │
        ▼
Persistir conversa
        │
        ▼
Retornar resposta
```

No MVP, várias dessas etapas simplesmente não fazem nada:

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
Montar contexto
        │
        ▼
Escolher provider/modelo
        │
        ▼
Chamar LLM
        │
        ▼
Persistir conversa
        │
        ▼
Retornar resposta
```

### Provider LLM

Camada responsável pela comunicação com modelos de linguagem.

Toda interação com modelos deve ocorrer através desta abstração.

Nenhum módulo da aplicação deve depender diretamente de um provider específico.

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
`../contracts/topic.md`.

---

# 4. Integrações

...

---

# 5. Evolução Futura

...

---

# 6. Documentação Relacionada

## Geral

- `00-context.md`
- `00-development.md`

## Arquitetura

- `03-backend.md`
- `04-frontend.md`
- `05-api.md`
- `integrations/openclaude.md`
- `07-database.md`
- `08-redis.md`

