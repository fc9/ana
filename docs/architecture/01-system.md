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
- detalhes do Runtime;
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

## Componentes

### Interface Web

Responsável pela interação com o usuário.

Principais funções:

- gerenciamento de chats;
- gerenciamento de workspaces;
- configurações;
- envio de mensagens;
- upload de arquivos;
- apresentação das respostas.

A Interface Web não deve conter regras de negócio.

---

### API Principal

Representa o núcleo da aplicação.

Responsável por:

- orquestrar o fluxo das requisições;
- aplicar regras de negócio;
- persistir dados;
- comunicar-se com os demais módulos;
- disponibilizar serviços para o Frontend.

---

### Runtime Local

Responsável pelas operações executadas diretamente no computador do usuário.

Exemplos:

- leitura de arquivos;
- escrita;
- busca;
- geração de diff;
- integração com Git;
- execução controlada de comandos.

O Runtime é um módulo independente da API.

---

### Banco de Dados

Responsável pelo armazenamento persistente da aplicação.

Exemplos:

- chats;
- mensagens;
- workspaces;
- configurações;
- anexos.

Não contém regras de negócio.

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

### Provider LLM

Camada responsável pela comunicação com modelos de linguagem.

Toda interação com modelos deve ocorrer através desta abstração.

Nenhum módulo da aplicação deve depender diretamente de um provider específico.

---

# 4. Integrações

Os módulos devem comunicar-se exclusivamente através de contratos bem definidos.

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
- módulos específicos por domínio.

Essas funcionalidades deverão ser implementadas como componentes independentes,
evitando alterações estruturais na arquitetura existente.

---

# 6. Documentação Relacionada

## Geral

- `00-context.md`
- `00-development.md`

## Arquitetura

- `02-runtime.md`
- `03-backend.md`
- `04-frontend.md`
- `05-api.md`
- `06-openclaude.md`
- `07-database.md`
- `08-redis.md`
