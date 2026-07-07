# Database

Status: Draft
Versão: 0.1
Última atualização: 2026-07-06
Responsável: Arquitetura

---

# 1. Objetivo

Apresenta núcleo de armazenamento persistente da aplicação.

---

# 2. Escopo

## Responsabilidades

Este documento define:

```
Tabelas.
Relacionamentos.
UUID.
Índices.
Migrations
```

## Não Responsabilidades

Este documento não define:

- Nada sobre FastAPI.

---

# 3. Visão Geral

## Esquema

O código sql das tabelas, indices, relacionamentos e migrations e etc se encontra
em arquivos sql armazenados em `docs/dev/architecture/database`.

A seguir, uma breve descrição da função de cada tabela.

### meta

...

### users

...

### memories

...

### projects

...

### chats

...

### topics

...

### messages

...

### attachments

...

### providers

...

### config

...

### tasks

...

### project_expenses

...

### mcps

...

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

- `02-core.md`
- `03-backend.md`
- `04-frontend.md`
- `05-api.md`
- `integrations/openclaude.md`
- `08-redis.md`
- `09-projects.md`

