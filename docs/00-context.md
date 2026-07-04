# Ana - Contexto do Projeto

> Este documento descreve a visão arquitetural da Ana.
> Seu objetivo é fornecer contexto suficiente para que agentes de código (Codex, Claude Code, etc.) possam desenvolver o projeto mantendo consistência.

---

# Objetivo

Ana é uma assistente pessoal de IA executada localmente através de Docker.

O objetivo da Ana **não é ser um chatbot**, mas uma plataforma capaz de organizar projetos, conversar com o usuário e manipular arquivos locais através de um módulo especializado.

A longo prazo possuirá memória, skills, agentes especializados e outras capacidades, porém **essas funcionalidades NÃO fazem parte do MVP**.

O foco inicial é construir uma base sólida, modular e sem dívida técnica.

---

# Filosofia

A Ana deve ser:

- simples de utilizar;
- totalmente acessível via navegador;
- independente de IDE ou terminal para uso diário;
- modular;
- expansível;
- executável localmente;
- preparada para funcionar offline futuramente.

O usuário deve apenas iniciar os containers no Docker Desktop e acessar um endereço como:

http://localhost:3000

Todo o restante deve acontecer pela interface web.

---

# Escopo do MVP

O MVP possui apenas as seguintes funcionalidades.

## Chat

- criar chats
- excluir chats
- arquivar chats
- restaurar chats

## Workspace

Um Workspace representa uma pasta raiz do computador.

Um workspace poderá possuir:

- nome
- caminho local
- vários chats

Cada chat pode ou não pertencer a um workspace.

## Arquivos

O usuário poderá enviar:

- arquivos
- imagens
- texto
- conteúdo do clipboard

Os anexos pertencem ao chat.

## Modelos

O modelo utilizado deve ser configurável.

Inicialmente:

- OpenAI
- Anthropic

Posteriormente:

- LM Studio
- Ollama
- OpenAI Compatible APIs

A escolha do provider deve acontecer pelas configurações da Ana.

---

# Fora do Escopo

Neste momento NÃO implementar:

- memória
- RAG
- embeddings
- agentes inteligentes
- skills
- MCP
- automações
- workflow complexo
- ferramentas profundas

Tudo isso será implementado futuramente.

---

# Arquitetura

```
Frontend
    │
    ▼
FastAPI
    │
    ├──────────────► PostgreSQL
    │
    ├──────────────► Redis
    │
    ├──────────────► LLM Provider
    │
    └──────────────► OpenClaude Runtime
```

---

# Stack

## Frontend

- TypeScript
- Next.js
- Tailwind CSS

## Backend

Python

Framework:

FastAPI

Responsável por:

- API
- banco
- providers
- autenticação futura
- upload
- orquestração básica

## Runtime de Arquivos

Node.js

(TypeScript)

Baseado no projeto OpenClaude.

O OpenClaude NÃO será utilizado como aplicação.

Sua arquitetura será adaptada e incorporada como um módulo interno da Ana.

Não existe preocupação com compatibilidade futura com OpenClaude.

Ele será tratado como uma dependência arquitetural.

Responsabilidades:

- leitura de arquivos
- escrita
- busca
- diff
- git
- shell (futuramente)
- agente de código (futuramente)

---

# Banco

PostgreSQL

A decisão pelo PostgreSQL foi tomada desde o início para evitar dívida técnica.

---

# Cache / Filas

Redis.

Inicialmente poderá ser pouco utilizado.

Sua presença existe para evitar mudanças estruturais posteriormente.

---

# Docker

A aplicação deverá ser executada através de Docker Compose.

Serviços esperados:

- web
- api
- postgres
- redis
- openclaude-runtime

---

# Organização do Projeto

```
ana/

apps/
    web/
    api/
    openclaude-runtime/

packages/
    shared-types/
    prompts/

infra/
    postgres/
    redis/

storage/
    uploads/
    workspaces/

docs/
```

---

# Workspace

Workspace representa um projeto do usuário.

Exemplo:

```
Projeto: Mangá
Path: C:\Projetos\Manga
```

Um workspace apenas informa à Ana qual pasta ela possui autorização para acessar.

Nada fora do workspace deverá ser acessado automaticamente.

---

# Chat

Chat representa uma conversa.

Características:

- título
- data
- status
- workspace opcional

Status:

- ativo
- arquivado
- excluído

---

# Modelo de Desenvolvimento

A prioridade NÃO é criar inteligência.

A prioridade é criar infraestrutura.

A ordem desejada de implementação é:

1. Docker
2. API
3. Banco
4. Frontend
5. Comunicação Front/API
6. Configuração de Providers
7. Integração OpenClaude

---

# Objetivo Final desta Etapa

Ao final desta etapa o usuário deve conseguir:

- iniciar os containers
- abrir a interface web
- criar um workspace
- criar chats
- enviar mensagens
- conversar utilizando GPT ou Claude
- anexar arquivos
- salvar todo o histórico no PostgreSQL

Sem memória.

Sem agentes.

Sem skills.

Sem automações.

Apenas uma plataforma sólida para a evolução futura da Ana.

## Documentação complementar

A arquitetura está detalhada em:

- architecture/01-system.md

Frontend:

- architecture/04-frontend.md

Backend:

- architecture/03-backend.md

API:

- architecture/05-api.md

Banco:

- architecture/07-database.md

Redis:

- architecture/08-redis.md

OpenClaude Runtime:

- architecture/06-openclaude.md
