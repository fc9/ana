# Ana - Contexto do Projeto

> Este documento descreve a visão arquitetural da Ana.
> Seu objetivo é fornecer contexto suficiente para que agentes de código 
> (Codex, Claude Code, etc.) possam desenvolver o projeto MVP mantendo 
> consistência.

---

# Objetivo

Ana é uma assistente pessoal de IA local-first por Docker.

Seu objetivo da Ana é auxiliar o usuário em diferentes projetos por meio de uma 
interface conversacional, integrando modelos de linguagem, ferramentas locais e
módulos especializados.

A Ana não é apenas um chatbot, mas uma plataforma extensível construída sobre 
um núcleo de IA capaz de evoluir por novos módulos, agentes e integrações.

---

# Filosofia

A Ana deve ser:

- simples de utilizar;
- totalmente acessível via navegador;
- independente de IDE ou terminal para uso diário;
- orientada a projetos;
- arquitetura modular;
- separação entre núcleo, módulos e integrações;
- expansível;
- local-first (executável localmente);
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
- criar projetos
- trocar de projetos
- configurável com Claude ou GPT

## Projetos

Um projeto representa uma pasta raiz do computador onde a Ana irá trabalhar 
restritamente.

Todo chat deve pertencer a um único projeto, incluindo o projeto padrão `Base`.

Detalhes completos em `09-projects.md`.

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

- agentes especializados;
- memória persistênte;
- RAG;
- embeddings;
- MCP;
- automações;
- deep search;
- ferramentas avançadas;

Tudo isso será implementado futuramente.

---

# Stack

## Frontend (web)

- TypeScript
- Next.js
- Tailwind CSS

## Backend (api)

Python

Framework: FastAPI

Responsável por:

- API
- banco
- autenticação futura
- upload

## Core

Python

Responsável por:

- providers
- orquestração

## Integrações

As integrações permitem que a Ana se comunique com serviços externos.

No MVP:

- Providers LLM

Após o MVP:

- OpenClaude (primeira integração prevista; forma de aproveitamento ainda em análise)
- MCP
- outros serviços externos

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

---

# Chat

Chat representa uma conversa.

Características:

- título
- data
- status
- project

Status:

- ativo
- arquivado
- excluído

---

# Modelo de Desenvolvimento

A prioridade NÃO é criar inteligência.

A prioridade é criar infraestrutura.

A ordem desejada de implementação é:

1. Docker Básico
2. Infraestrutura
3. Backend (API)
4. Frontend & Comunicação Front/API
5. Core
6. Integrações
7. Módulos
8. Agentes

Para detalhes de codificação leia `architecture/00-development.md`.

---

# Objetivo Final desta Etapa

Ao final desta etapa o usuário deve conseguir:

- iniciar os containers
- abrir a interface web
- criar um project
- criar chats
- enviar mensagens
- conversar utilizando GPT ou Claude
- anexar arquivos
- salvar todo o histórico no PostgreSQL

A Ana deverá possuir o seu núcleo funcional. O orquestrador Main deverá ser 
capaz de:

- receber mensagem
- manipular anexos
- carregar configurações
- buscar provider
- montar prompt simples
- chamar LLM
- persistir conversa
- retornar resposta

Recursos avançados como memória persistente, agentes especializados, skills, 
MCP, automações e Deep Research permanecerão fora do escopo do MVP.

## Documentação complementar

- architecture/01-system.md
- architecture/04-frontend.md
- architecture/03-backend.md
- architecture/05-api.md
- architecture/07-database.md
- architecture/08-redis.md
- architecture/integrations/openclaude.md
