# Projects

Status: Draft
Versão: 0.1
Última atualização: 2026-07-06
Responsável: Arquitetura

---

# 1. Objetivo

Definir o conceito e funcionamento de projeto dentro da Ana.

---

# 2. Escopo

## Responsabilidades

Este documento define:

- definição de projeto;
- gerenciamento interno;
- isolamento por projeto.

## Não Responsabilidades

Este documento não define:

- detalhes da implementação da gestão de projetos no Frontend;
- definição de banco de dados;
- arquitetura do backend.

---

# 3. Visão Geral

Um projeto representa uma pasta raiz do computador onde a Ana irá trabalhar
restritamente. A Ana é orientada a projetos, podendo assumir diferentes papeis 
conforme as configurações do projeto ativo.

## Relação com Chats

Um projeto pode ter vários chats, mas todo chat deve pertencer a um único projeto.

O projeto 'Base' é o projeto padrão que Ana inicia. Esse projeto não tem pasta
raiz e é limitado em termos de recursos se comparado a um projeto criado pelo
usuário. Todos os chats criados fora de um projeto pertencem ao Base. O projeto
Base não pode ser gerenciado pelo usuário (editado ou removido), embora seus
chats possam ser.

## Persistência

A Ana armazena em banco de dados informações sobre os projetos que já atuou e 
suas configurações para permitir a troca de projeto via UI, semelhante à 
funcionalidade de projeto das IDEs da JetBrains.

> A Ana salva os dados na tabela 'projects'.

## Manifesto

Ao criar ou abrir um projeto pela primeira vez, a Ana gera automaticamente 
(se ainda não existir) um arquivo de manifesto na raiz projeto em 
".ana/manifest.json".

```json
{
  "uuid": "49d06540-46d8-4e6d-a0bf-28b469276f8a",
  "project": "Football Manga",
  "path": "D:\\repos\\football-manga",
  "always_read": [
    "README.md",
    "ANA.md"
  ]
}
```

Esses dados podem ser usados para encontrar o projeto no banco de dados mesmo se
o caminho da pasta raiz mudar. 

## Isolamento 

Um projeto representa um escopo isolado de:

- documentação
- autorização
- anexos
- chats
- segurança
- automação

Podemos pensar no projeto como um ambiente isolado dos demais projetos. Tendo
assim seu próprio conjunto de dados, chats, agentes, filas, anexos, histórico,
memória, etc.

## Ana ignore!

O usuário poderá criar um arquivo chamado ".anaignore" na raiz do seu projeto. 
Ele funcionará como um ".gitignore" para a Ana. Os arquivos e pastas 
especificados ficarão invisíveis para Ana.

---

# 4. Integrações

A Ana sempre trabalha em um único projeto por sessão.

Não é possível o compartilhamento de recursos como configurações, memórias, 
chats e anexos entre projetos diferentes. 

---

# 5. Evolução Futura

Destaques:

- Controle de custos de token por projeto;
- Integração com github, bitbucker e outros por projeto.
- Suporte a docker e docker-compose.

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
- `07-database.md`
- `08-redis.md`

