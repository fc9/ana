# 04 - Frontend Web

Status: Draft
Versão: 0.1
Última atualização: 2026-07-03
Responsável: Arquitetura

---

# 1. Objetivo

Definir a arquitetura geral do frontend da Ana.

---

# 2. Escopo

## Responsabilidades

- gerenciamento de chats;
- gerenciamento de projects;
- configurações;
- envio de mensagens;
- upload de arquivos;
- apresentação das respostas.
 
Lidar com router, pages, features, componentes, hooks e API Client.

## Não Responsabilidades

A Interface Web não deve conter regras de negócio.

---

# 3. Visão Geral

Somente organização React.

```
App Router
↓
Pages
↓
Features
↓
Components
↓
Hooks
↓
API Client
```

Nada sobre backend.

---

# 4. Integrações

Comunica-se somente com a API backend.

---

# 5. Evolução Futura

Planejado adicionar features para:

- acompanhamento de uso de tokens (no futuro);
- configuração de providers (no futuro);
- gestão do git branches e PRs (no futuro).

Essa funcionalidade não fazem parte do MVP, embora o modelo UI das mesmas 
possam ser providênciados de antemão para testes com dados mockados.

---

# 6. Documentação Relacionada

## Geral

- `00-context.md`
- `00-development.md`

## Arquitetura

- `05-api.md`
