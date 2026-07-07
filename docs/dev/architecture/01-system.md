# 01 - Arquitetura do Sistema

Status: Draft
Versão: 0.1
Última atualização: 2026-07-03
Responsável: Arquitetura

> Este documento descreve a arquitetura de alto nível da Ana.
>
> Seu objetivo é apresentar como o sistema está organizado, quais são seus 
> módulos principais e como eles se relacionam.
>
> Este documento não aborda detalhes de implementação. Para isso consulte a 
> documentação específica de cada módulo.

---

# 1. Objetivo

Definir a arquitetura geral da plataforma Ana.

A arquitetura deve servir como base para toda a evolução do sistema, permitindo 
que novos módulos sejam adicionados sem necessidade de grandes refatorações.

O sistema deve ser modular, desacoplado e organizado por responsabilidades bem 
definidas.

---

# 2. Escopo

## Responsabilidades

Este documento define:

- a organização geral da plataforma;
- os módulos que compõem o sistema;
- as responsabilidades de cada módulo;
- como os módulos se relacionam;
- os princípios arquiteturais adotados.

## Não Responsabilidades

Este documento não define:

- tecnologias específicas;
- implementação de módulos;
- estrutura de código;
- endpoints da API;
- modelo de banco de dados;
- detalhes do Frontend;
- detalhes do Backend.

Esses assuntos são tratados em documentos específicos.

---

# 3. Visão Geral

A Ana é composta por módulos independentes, cada um responsável por uma área 
específica do sistema.

A comunicação entre módulos deve ocorrer por interfaces públicas, evitando 
dependências diretas entre implementações.

A arquitetura prioriza baixo acoplamento e alta coesão.

## Estrutura de Pastas

```
ana/
├── docs/
│   ├── dev/
│   └── system/
│ 
├── infra/
│   ├── postgres/
│   └── redis/
│ 
├── storage/
│   ├── uploads/
│   └── projects/
│
└── src/
    ├── apps/
    │   ├── web/ # interface web (Next.js), consome a API via HTTP
    │   └── api/ # ponte HTTP + banco + autenticação + persistência + contratos externos da aplicação
    │
    ├── core/ # núcleo de orquestração da Ana; roda no mesmo processo da API no MVP
    │   └── main/ # script principal da Ana
    │  
    ├── modules/
    │   ├── attachments/
    │   ├── chat/
    │   ├── projects/
    │   ├── files/     # futuro
    │   ├── git/       # futuro
    │   ├── diff/      # futuro
    │   ├── memory/    # futuro
    │   ├── research/  # futuro
    │   ├── settings/
    │   └── editor/    # futuro
    │
    ├── agents/ # futuro — fora do escopo do MVP
    │   ├── coder/
    │   ├── researcher/
    │   ├── writer/
    │   └── reviewer/
    │
    ├── integrations/
    │   ├── providers/
    │   │   ├── openai/
    │   │   ├── anthropic/
    │   │   ├── lmstudio/  # futuro
    │   │   └── ollama/    # futuro
    │   │
    │   ├── openclaude/ # futuro
    │   └── mcp/        # futuro — fora do escopo do MVP
    │
    └── shared/
        ├── tools/  # futuro — fora do escopo do MVP
        │   ├── filesystem/
        │   ├── git/
        │   ├── shell/
        │   └── images/
        │       └── computer-vision/
        │
        ├── skills/ # futuro — fora do escopo do MVP
        │   ├── markdown/
        │   ├── coding/
        │   ├── research/
        │   └── files/
        │
        ├── prompts/
        ├── types/
        └── utils/
```

> Itens marcados com `# futuro` estão fora do escopo do MVP (ver
> `00-context.md` > Fora do Escopo) e não devem ser implementados nesta
> etapa — apenas as pastas sem marcação fazem parte do MVP.

## Componentes

### Interface Web

Responsável pela interação com o usuário. Detalhes em `04-frontend.md`.

---

### API

Representa o backend da aplicação. Detalhes em `03-backend.md`.

---

### Core 

Representa o núcleo da aplicação. No MVP roda no mesmo processo/container da
API (não é um serviço Docker próprio). Detalhes em `02-core.md`.

---

### Integrações

Camada de comunicação com serviços externos: providers de LLM (OpenAI,
Anthropic no MVP). OpenClaude é a primeira integração prevista após o MVP
— a forma de aproveitamento ainda está em análise (ver
`integrations/openclaude.md`). MCP e demais integrações vêm depois.
Detalhes em `03-backend.md`.

---

### Agentes

Unidades especializadas capazes de planejar e executar tarefas com maior
autonomia (ex: coder, researcher). Fora do escopo do MVP.

---

### Banco de Dados

Responsável pelo armazenamento persistente da aplicação.

Exemplos:

- chats;
- mensagens;
- projetos;
- configurações;
- anexos.

Não contém regras de negócio.

Detalhes em `07-database.md`.

---

### Redis

Responsável por funcionalidades assíncronas da plataforma.

Inicialmente utilizado apenas como infraestrutura.

Futuramente poderá suportar:

- filas;
- cache;
- eventos;
- streaming;
- tarefas em segundo plano.

---

# 4. Integrações Internas

Os módulos devem comunicar-se exclusivamente por contratos bem definidos.

Não é permitido que um módulo acesse diretamente estruturas internas de outro módulo.

As integrações devem preservar o baixo acoplamento entre os componentes do sistema.

As integrações específicas de cada módulo são documentadas em seus respectivos documentos.

---

# 5. Evolução Futura

A arquitetura foi planejada para crescer de forma incremental.

Novos módulos deverão ser adicionados preservando a separação de 
responsabilidades existente.

Entre as futuras evoluções previstas estão:

- sistema de memória;
- agentes especializados;
- skills;
- automações;
- gerenciamento de contexto;
- RAG;
- ferramentas adicionais;
- módulos específicos por domínio;
- Core como serviço/container independente da API, caso necessário.

Essas funcionalidades deverão ser implementadas como componentes independentes,
evitando alterações estruturais na arquitetura existente.

---

# 6. Documentação Relacionada

## Geral

- `00-context.md`
- `00-development.md`

## Arquitetura

- `02-core.md`
- `03-backend.md`
- `04-frontend.md`
- `05-api.md`
- `integrations/openclaude.md`
- `07-database.md`
- `08-redis.md`
- `09-projects.md`
