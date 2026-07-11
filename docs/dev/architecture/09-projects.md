# Projects

Status: Draft
Versão: 0.1
Última atualização: 2026-07-10
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

## Configurações

Todo projeto possui moeda própria (padrão: dólar americano, alterável
pelo usuário), junto do provider/modelo de IA em uso — ambos vivem numa
tabela própria (`configs`), não em `projects`. Ver
`../contracts/currency.md`, `../contracts/config.md` e `07-database.md`
> configs.

Idioma não é configuração de projeto — é preferência global do usuário,
válida para todos os seus projetos (ver `../contracts/language.md` e
`../contracts/user.md`).

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
memória, etc. (mecânica de memória — futuro — em `12-memory.md`).

## Ana ignore!

O usuário poderá criar um arquivo chamado ".anaignore" na raiz do seu projeto. 
Ele funcionará como um ".gitignore" para a Ana. Os arquivos e pastas 
especificados ficarão invisíveis para Ana.

---

# 4. Integrações

A Ana sempre trabalha em um único projeto por sessão.

Não é possível o compartilhamento de recursos como memórias, chats e
anexos entre projetos diferentes.

Duas exceções:

- idioma é preferência do usuário, não do projeto — por isso é
  naturalmente compartilhado entre todos os projetos do mesmo usuário
  (ver `## Configurações` acima). Moeda, por outro lado, é isolada por
  projeto, como os demais recursos;
- providers são recursos **globais**, não isolados por projeto:
  credenciais públicas ficam visíveis a todos os projetos, sem precisar
  assinar; credenciais privadas só a quem assina (ver
  `../contracts/provider.md`, `../contracts/provider-credential.md` e
  `../contracts/provider-subscription.md`).

---

# 5. Evolução Futura

Destaques:

- Interface dedicada de custos (histórico, limites) — o MVP já
  contabiliza tokens e custo em USD internamente, em tempo real, mas
  sem exposição na UI (ver `../00-context.md` > Consumo de Tokens);
- Integração com github, bitbucker e outros por projeto.
- Suporte a docker e docker-compose.
- A Ana sempre verifica se o projeto tem git iniciado na raiz; se não
  tiver, ela inicia um. Se o ambiente não tiver suporte a git local,
  ela comunica isso ao usuário e orienta como resolver. A Ana não faz
  nenhuma alteração nos arquivos do projeto fora do escopo de um
  commit — git é pré-requisito para qualquer edição de arquivo do
  projeto por ela.
- A Ana nunca manipula commits ou branches que ela mesma não criou, a
  menos que o usuário peça explicitamente. Se o usuário pedir uma
  reversão, a Ana opera só dentro do que ela mesma fez — nunca reverte
  commit alheio nem remove branch que não seja dela.
- A Ana pode abrir um Pull Request, mas nunca aprova um. Aprovação é
  sempre do usuário. Se o usuário pedir pra Ana aprovar um PR, ela
  identifica claramente qual PR (nunca assume) e pede confirmação
  explícita do usuário antes de agir — ver `10-resilience.md` >
  Evolução Futura (confirmação para tarefas robustas/irreversíveis).

---

# 6. Documentação Relacionada

## Geral

- `../00-context.md`
- `00-development.md`

## Arquitetura

- `01-system.md`
- `02-core.md`
- `03-backend.md`
- `04-frontend.md`
- `05-api.md`
- `06-models.md`
- `06b-services.md`
- `integrations/openclaude.md`
- `07-database.md`
- `08-redis.md`
- `10-resilience.md`
- `11-search.md`
- `12-memory.md`

