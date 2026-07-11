# 12 - Memória

Status: Draft
Versão: 0.1
Última atualização: 2026-07-10
Responsável: Arquitetura

---

# 1. Objetivo

Detalhar a mecânica de memória de longo prazo da Ana: como conhecimento
consolidado sobre um projeto, um usuário e as decisões tomadas ao longo
do tempo sobrevive à compactação de contexto entre chats, sessões e até
troca de provider/modelo.

Este documento assume o conceito e o eixo de **escopo** (global do
projeto, pública de topic, privada de topic) já definidos em
`../contracts/memory.md` e `02-core.md` > Memória (futuro), e acrescenta
um segundo eixo — **tipo** —, além do formato de uma unidade de
memória, o índice, e os gatilhos de leitura/escrita. Também registra a
motivação em `../research/ai-memory.md`.

> Conceito futuro em sua totalidade. Nenhuma tabela, endpoint, Model ou
> Schema aqui descrito existe no MVP — ver `../contracts/memory.md`.
> Mais que isso: a memória ainda será modelada de fato quando esse
> recurso sair do escopo futuro. Este documento é um rascunho
> exploratório — tipos, formato de nota, índice e gatilhos podem mudar
> por completo nessa modelagem futura, não só o mecanismo de
> armazenamento (ver ⚠️ em Evolução Futura).

---

# 2. Escopo

## Responsabilidades

- catalogar os tipos de memória, ortogonais ao escopo (projeto/topic)
  já definido em `../contracts/memory.md`;
- definir o formato de uma unidade de memória (uma "nota");
- definir o índice que aponta para cada nota, e como ele é carregado;
- definir quando a Ana deve escrever uma memória, e o que nunca deve
  virar uma;
- definir quando e como a Ana consulta memória antes de agir;
- definir por que esse mecanismo resiste à compactação do contexto de
  um chat.

## Não Responsabilidades

- o eixo de escopo em si (global do projeto / pública de topic /
  privada de topic) e sua relação com Chat/Topic — ver
  `../contracts/memory.md` e `../contracts/topic.md`;
- consolidação de um Topic em memória pública (ver `../contracts/topic.md`,
  futuro);
- o nível "memories" da busca, isto é, como uma memória é localizada
  por uma query (ver `11-search.md`);
- schema de banco e endpoints reais — dependem de qual mecanismo de
  armazenamento for escolhido quando o recurso sair do escopo futuro
  (ver Evolução Futura).

---

# 3. Visão Geral

## Por que memória, e não só histórico de chat

O histórico de um chat é finito e fica sujeito à janela de contexto do
provider/modelo ativo — conversas longas eventualmente precisam ser
resumidas ou truncadas (ver `../contracts/topic.md`, futuro). Memória é
a camada que existe **fora** dessa janela: sobrevive à compactação de
um chat específico, a uma nova sessão, e até à troca de provider/modelo
(ver `../research/ai-memory.md` > Memória independente do LLM/Agente).
Ela nunca substitui o histórico do chat nem a documentação do projeto —
apenas os complementa (ver `../contracts/memory.md` > Não deve).

## Tipos de memória

Eixo ortogonal ao escopo: qualquer tipo abaixo pode existir em qualquer
nível de escopo (global do projeto, público ou privado de um topic).

| Tipo         | Conteúdo                                                              | Quando gravar                                                                 |
|--------------|------------------------------------------------------------------------|--------------------------------------------------------------------------------|
| Usuário      | papel, objetivos, preferências e conhecimento do usuário sobre o projeto | ao perceber algo estável sobre como o usuário trabalha ou o que ele já sabe   |
| Feedback     | orientação explícita sobre como a Ana deve agir — correções e confirmações | toda vez que o usuário corrige uma abordagem, ou confirma uma escolha não óbvia sem contestar |
| Projeto      | decisões de arquitetura, bugs conhecidos, tentativas que não deram certo, TODOs, handoffs entre agentes | ao consolidar uma sessão/topic, ou quando uma decisão relevante é tomada       |
| Referência   | ponteiros para sistemas externos ao projeto (rastreadores, dashboards, documentação externa) | quando o usuário menciona onde encontrar mais contexto fora do projeto        |

Os tipos Usuário e Projeto mapeiam diretamente as aplicações já
antecipadas em `../research/ai-memory.md` > Possíveis aplicações na
Ana (Coder Agent e Usuário); Feedback formaliza o que esse estudo
chamou de "auto-aprendizado supervisionado"; Referência cobre o caso
de o usuário apontar onde mais procurar informação (ex: um rastreador
de bugs externo), sem que isso vire documentação do projeto em si.

## Formato de uma memória

Cada memória é um arquivo Markdown — uma "nota" — com metadados no
topo (nome, descrição de uma linha, tipo, escopo) e o conteúdo no
corpo. Memórias do tipo Feedback e Projeto estruturam o corpo como
**regra/fato**, então **Por quê** (a motivação — o que o usuário disse
ou o que aconteceu) e **Como aplicar** (quando essa memória é
relevante); isso permite julgar exceções depois, em vez de aplicar a
regra às cegas. Memórias podem se referenciar entre si por nome.

## Índice

Um índice curto — uma linha por memória, ponteiro + gancho de uma
frase — organizado por assunto, não por data. O índice do escopo
global do projeto é carregado sempre que um chat começa (mesmo
princípio de `GET /projects/{id}/config` carregar toda a configuração
de UI de uma vez, ver `05-api.md` > Config); o índice de um topic
(memória privada) só é carregado para chats que pertencem àquele
topic. O conteúdo completo de cada nota só é lido sob demanda, quando
relevante ao que está sendo feito — nunca tudo de uma vez.

## Como resiste à compactação

Memória vive fora do contexto vivo de qualquer chat: é lida do
armazenamento (arquivo ou tabela, ver Evolução Futura) a cada chat
novo, via índice. Compactar ou resumir um chat, abrir um chat novo, ou
trocar de provider/modelo não apaga nem exige reconstruir a memória —
ela é recarregada do zero a cada vez, exatamente como o índice é
recarregado a cada nova sessão neste mesmo mecanismo usado para
documentar a Ana.

## Gatilhos de escrita

- pedido explícito do usuário ("lembre disso", "anote que...");
- a Ana percebe uma correção ou confirmação não-óbvia durante a
  conversa (tipo Feedback);
- consolidação ao fim de uma sessão ou Topic longo (tipo Projeto —
  ver `../research/ai-memory.md` > Consolidação automática);
- o usuário aponta onde encontrar mais contexto fora do projeto (tipo
  Referência).

## O que NÃO vira memória

- o que já é derivável do código ou do histórico do git (git
  log/blame são a fonte, não a memória);
- estado efêmero de uma tarefa em andamento na sessão atual — isso é
  escopo do chat/Topic, não de memória de longo prazo;
- qualquer coisa já coberta pela documentação do projeto (ver
  `../contracts/memory.md` > Não deve — documentação continua sendo a
  fonte principal de verdade, memória é complementar).

## Gatilhos de leitura

- ao abrir um chat, o índice do escopo acessível àquele chat é
  carregado automaticamente (global do projeto sempre; privado do
  topic, se houver — ver `../contracts/topic.md` > Relação com
  Memória);
- antes de agir sobre algo que uma memória específica menciona (um
  arquivo, uma função, uma decisão), a Ana confirma que aquilo ainda é
  verdade — uma memória é uma foto de um momento, não uma garantia
  atual. Se o estado atual do projeto contradiz a memória, prevalece o
  estado atual, e a memória é atualizada ou removida.

---

# 4. Integrações

## Core

A etapa "Consultar memória (quando existir)" do fluxo do orquestrador
(ver `02-core.md` > Orquestrador Ana Core) é onde o índice acessível ao
chat é carregado; notas individuais são lidas sob demanda durante o
processamento, não nessa etapa.

## Topic

Consolidação de um Topic (ver `../contracts/topic.md`) é o principal
gatilho de escrita do tipo Projeto — resume decisões, bugs e handoffs
da conversa antes de compactar o histórico do chat.

## Chat

Memória nunca substitui o histórico do chat — apenas o complementa (ver
`../contracts/memory.md`).

---

# 5. Evolução Futura

- ⚠️ mecanismo final de armazenamento — este documento descreve o
  comportamento (tipos, formato, índice, gatilhos) sem assumir a
  implementação; duas candidatas: arquivos Markdown git-tracked em
  `.ana/` (alinhado com `../research/ai-memory.md` > Wiki como memória
  — auditável, editável, versionável) ou a tabela `memories` já
  esboçada em `07-database.md`. Decisão em aberto até o recurso sair do
  escopo futuro;
- endpoints de CRUD de memória e Model/Schema correspondentes, quando
  promovido a MVP;
- auto-aprendizado supervisionado — propostas de memória revisadas
  pelo usuário antes de aceitas (ver `../research/ai-memory.md` >
  Auto-aprendizado supervisionado);
- embeddings/busca híbrida para localizar memórias relevantes sem
  depender só do índice (ver `11-search.md` > Futuro);
- handoff de memória entre agentes especializados (Main, Coder,
  Researcher — ver `../research/ai-memory.md` > Handoff entre
  agentes), quando esses agentes existirem (ver `02-core.md`).

---

# 6. Documentação Relacionada

## Geral

- `../00-context.md`
- `00-development.md`

## Arquitetura

- `02-core.md`
- `05-api.md`
- `07-database.md`
- `09-projects.md`
- `11-search.md`

## Contratos

- `../contracts/memory.md`
- `../contracts/topic.md`
- `../contracts/chat.md`

## Research

- `../research/ai-memory.md`
