# 03 - Backend

Status: Draft  
Versão: 0.1  
Última atualização: 2026-07-03  
Responsável: Arquitetura

---

# 1. Objetivo

Definir a organização e as responsabilidades do Backend da Ana.

O Backend é o núcleo da aplicação. Ele concentra as regras de negócio, coordena 
a comunicação entre módulos e expõe a API consumida pela Interface Web.

---

# 2. Escopo

## Responsabilidades

O Backend é responsável por:

- expor a API principal da Ana para o Frontend;
- gerenciar chats;
- gerenciar mensagens;
- gerenciar projetos;
- gerenciar anexos;
- gerenciar configurações;
- persistir dados no PostgreSQL;
- comunicar-se com providers LLM;
- publicar e consumir tarefas via Redis quando necessário;
- validar permissões e limites de acesso a projetos.

## Não Responsabilidades

O Backend não é responsável por:

- renderizar interface;
- manipular diretamente componentes visuais;
- executar lógica de UI;
- editar arquivos locais diretamente;
- executar comandos de sistema diretamente;
- conter lógica específica de um provider LLM;
- armazenar segredos em código;
- implementar agentes complexos no MVP.

---

# 3. Visão Geral

O Backend será implementado como uma aplicação Python com FastAPI.

Ele deve ser organizado por camadas simples, com responsabilidades claras.

## Camadas

### Routes

Camada responsável por receber requisições HTTP e retornar respostas.

As rotas devem:

- validar entrada básica;
- chamar services;
- retornar schemas;
- não conter regra de negócio complexa.

### Schemas

Camada de entrada e saída da API.

Responsável por definir os contratos de dados usando modelos de validação.

### Services

Camada de regra de negócio.

Responsável por:

- aplicar regras da Ana;
- coordenar repositories;
- chamar providers;
- decidir fluxos de operação.

### Repositories

Camada de acesso ao banco.

Responsável por:

- criar;
- consultar;
- atualizar;
- remover;
- aplicar queries específicas.

Repositories não devem conter regra de negócio.

### Models

Representam as entidades persistidas no PostgreSQL.

### Providers

Camada de abstração para modelos de linguagem.

Deve permitir alternar entre:

- OpenAI;
- Anthropic;
- OpenAI-compatible;
- LM Studio futuramente.

---

## Estrutura

```text
apps/api/
└── app/
    ├── main.py
    ├── core/
    │   ├── config.py
    │   ├── security.py
    │   └── logging.py
    ├── db/
    │   ├── session.py
    │   └── migrations/
    ├── models/
    ├── schemas/
    ├── routes/
    │   ├── health.py
    │   ├── settings.py
    │   ├── chats.py
    │   ├── messages.py
    │   ├── projects.py
    │   └── attachments.py
    ├── services/
    │   ├── chat_service.py
    │   ├── message_service.py
    │   ├── project_service.py
    │   ├── attachment_service.py
    │   ├── settings_service.py
    │   └── llm/
    ├── repositories/
    └── workers/
```

---

# 4. Integrações

## Frontend

O Frontend consome o Backend através da API HTTP.

O Frontend não deve acessar banco ou Redis diretamente.

## PostgreSQL

O Backend é o único módulo autorizado a acessar diretamente o banco de dados 
principal da Ana.

## Redis

O Backend usa Redis para filas, tarefas assíncronas e eventos quando necessário.

No MVP, o uso pode ser mínimo.

## Provider LLM

O Backend usa uma camada interna de providers para enviar mensagens a modelos de linguagem.

Nenhum endpoint deve depender diretamente de SDK específico de OpenAI, Anthropic ou outro provider.

---

# 5. Evolução Futura

O Backend deverá evoluir para suportar:

* autenticação;
* permissões por usuário;
* streaming de respostas;
* jobs assíncronos;
* histórico de execução;
* auditoria;
* memória;
* agentes;
* skills;
* RAG;
* automações;
* integrações externas.

Essas funcionalidades devem ser adicionadas sem quebrar a separação entre rotas, 
services, repositories e providers.

---
 
# 6. Documentação Relacionada

## Geral

* `../00-context.md`
* `../00-development.md`

## Arquitetura

* `01-system.md`
* `02-core.md`
* `04-frontend.md`
* `05-api.md`
* `integrations/openclaude.md`
* `07-database.md`
* `08-redis.md`
* `09-projects.md`

## Contratos

* `../contracts/`
