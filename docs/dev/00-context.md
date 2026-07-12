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
- favoritar/desfavoritar chats (fixa no topo da lista)

## Projetos

Um projeto representa uma pasta raiz do computador onde a Ana irá trabalhar 
restritamente.

- criar projetos
- trocar de projetos
- excluir projetos — não é possível excluir o projeto ativo; a exclusão
  apenas muda o status do projeto no banco de dados e remove a pasta
  `.ana/` da raiz do projeto (a pasta raiz do usuário e seu conteúdo não
  são tocados)

Todo chat deve pertencer a um único projeto, incluindo o projeto padrão `Base`.

Detalhes completos em `09-projects.md`.

## Arquivos

O usuário poderá enviar:

- arquivos
- imagens
- áudio
- vídeo
- texto
- conteúdo do clipboard

Os anexos pertencem ao chat e, opcionalmente, a uma mensagem específica
(nulo enquanto o anexo ainda não foi enviado).

O usuário também pode remover um anexo diretamente pela interface,
fazendo com que a Ana deixe de considerá-lo. Remoção solicitada em
conversa depende de tool calls e fica fora do MVP (ver `02-core.md`).

## Modelos

O modelo utilizado deve ser configurável.

- OpenAI
- Anthropic
- OpenAI Compatible APIs
- LM Studio
- Ollama

A escolha do provider deve acontecer pelas configurações da Ana.

## Consumo de Tokens

A Ana contabiliza internamente o consumo de tokens e o custo em USD, de
forma silenciosa — sem interface própria no MVP (ver `09-projects.md` >
Evolução Futura).

Cada troca de mensagem com um provider registra tokens de entrada, cache
(leitura e escrita de prompt cacheado somadas) e saída daquela chamada,
além do custo em USD calculado na hora com o preço cadastrado do modelo
— usando os preços de cache de leitura e escrita separadamente quando o
provider distingue os dois (ex: Anthropic), mesmo que só o total
agregado de tokens seja guardado. A partir disso, a Ana mantém em tempo
real:

- consumo de tokens e custo por provider;
- consumo de tokens e custo por modelo;
- consumo total de tokens e custo do projeto.

Como o usuário pode trocar de provider a qualquer momento, o consumo do
projeto soma o uso de todos os providers/modelos já utilizados nele.

O custo é sempre calculado e armazenado em USD. A conversão para a moeda
do projeto (padrão USD, configurável — ver `09-projects.md` >
Configurações) acontece apenas ao servir a informação pela API.

O registro é síncrono, feito no mesmo fluxo da chamada ao LLM, para que a
API sempre sirva dados atualizados a um frontend reativo — não é uma
tarefa assíncrona via Redis.

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

Chat representa uma conversa dentro de um projeto. Detalhes completos em
`contracts/chat.md`.

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
- registrar consumo de tokens
- persistir conversa
- retornar resposta

Recursos avançados como memória persistente, agentes especializados, skills, 
MCP, automações e Deep Research permanecerão fora do escopo do MVP.

## Documentação complementar

- architecture/01-system.md
- architecture/02-core.md
- architecture/03-backend.md
- architecture/04-frontend.md
- architecture/05-api.md
- architecture/06-models.md
- architecture/06b-services.md
- architecture/07-database.md
- architecture/08-redis.md
- architecture/09-projects.md
- architecture/integrations/openclaude.md
