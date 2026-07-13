# 00 - Desenvolvimento

Status: Draft  
Versão: 0.1  
Última atualização: 2026-07-12  
Responsável: Arquitetura

---

# 1. Objetivo

Definir o processo oficial de desenvolvimento da Ana.

Este documento estabelece as regras para planejamento, implementação, testes, 
revisão e integração de novas funcionalidades.

Todo desenvolvimento realizado no projeto deve seguir este documento.

---

# 2. Escopo

## Responsabilidades

Este documento define:

- fluxo de desenvolvimento;
- filosofia de implementação;
- regras gerais de desenvolvimento;
- convenções para implementação de tarefas;
- critérios mínimos de qualidade.

## Não Responsabilidades

Este documento não define:

- arquitetura do sistema;
- estrutura do banco de dados;
- APIs;
- organização do frontend;
- organização do backend.

Esses assuntos possuem documentação própria.

---

# 3. Visão Geral

## Filosofia de Implementação

Todo código produzido para a Ana deve priorizar simplicidade, legibilidade e 
facilidade de manutenção.

### Preferir

- código simples;
- baixo acoplamento;
- módulos pequenos;
- responsabilidade única;
- alta legibilidade;
- princípios SOLID;
- cobertura de testes automatizados;
- documentação sempre que necessário.

### Evitar

- abstrações prematuras;
- arquitetura excessivamente complexa;
- dependências desnecessárias;
- plugins sem justificativa;
- duplicação de código;
- otimizações prematuras.

---

## Workflow

### 1. Criação da Branch

Toda solicitação de desenvolvimento deve ocorrer em uma branch dedicada.

A branch deve ser criada a partir da branch principal (`main`).

Nenhuma implementação deve ocorrer diretamente na `main`.

---

### 2. Levantamento de Contexto

Nesta etapa o agente deve reunir todo o contexto necessário antes de propor uma solução.

Ele deve consultar:

* documentação arquitetural relevante;
* contratos envolvidos;
* base de conhecimento (`docs/dev/knowledge/`);
* código existente relacionado à tarefa.

O objetivo é compreender o estado atual do sistema antes de elaborar qualquer 
plano de implementação.

#### Regra de precedência.

```
Arquitetura
        ↑
Contratos
        ↑
Knowledge
```

1. **Arquitetura** define como o sistema deve ser organizado.
2. **Contratos** definem os conceitos e interfaces.
3. **Knowledge** apenas complementa com experiências práticas.

Se houver conflito, a arquitetura sempre prevalece até que o usuário decida 
alterá-la. Os contratos prevalecem acima apenas do knowledge. Knowledge não
está sujeito a arquitetura e aos contratos até que o usuário decida atualizar a 
documentação.

---

### 3. Planejamento

Somente após concluir o levantamento de contexto, o agente deve elaborar o plano
de implementação.

O plano deve considerar:

* requisitos da tarefa;
* arquitetura vigente;
* padrões existentes;
* aprendizados registrados na base de conhecimento.

O plano deve conter, no mínimo:

- objetivo;
- requisitos da tarefa;
- etapas de implementação;
- critérios de aceite;
- estratégia de testes.

O plano deve ser salvo em:

```
docs/dev/plans/
```

Nome do arquivo:

```
plan-[numero-sequencial]-[nome-da-branch].md
```

Diferente de um registro posterior, o arquivo já nasce salvo nessa
pasta **antes** de ser apresentado ao usuário — não depois da
aprovação. O plano deve ser apresentado ao usuário para aprovação.
Enquanto a aprovação não chega, cada ajuste pedido pelo usuário
atualiza esse mesmo arquivo (nunca cria um segundo arquivo para a
mesma etapa) — o conteúdo salvo reflete sempre a versão mais recente
em discussão, aprovada ou não.

Nenhum desenvolvimento pode iniciar sem aprovação explícita do plano pelo
usuário.

---

### 4. Desenvolvimento

Após aprovação do plano:

1. Implementar os testes automatizados, quando aplicável.
2. Implementar a funcionalidade.
3. Revisar toda a implementação.
4. Executar os testes.
5. Atualizar a documentação afetada.
6. Realizar o commit das alterações.

Quando não for possível criar testes automatizados, o motivo deve ser registrado no plano.

---

### 5. Revisão

Antes de considerar a implementação concluída, verificar:

- requisitos atendidos;
- aderência ao plano;
- testes aprovados;
- documentação atualizada;
- ausência de erros conhecidos.

---

### 6. Validação do Usuário

Após concluir o desenvolvimento:

- informar o usuário;
- aguardar validação.

Caso sejam solicitados ajustes:

- permanecer na mesma branch;
- atualizar o plano;
- solicitar nova aprovação;
- implementar as alterações.

---

### 7. Encerramento

Sem Pull Request — a integração à `main` é sempre por merge local
(ver Captura de Conhecimento, abaixo), não por PR no GitHub.

Após confirmação do usuário de que a tarefa foi concluída, apresentar
um resumo da implementação:

1. objetivo cumprido;
2. arquivos alterados;
3. impactos relevantes.

Informar o usuário quando esse resumo estiver concluído.

---

### 8. Captura de Conhecimento

Após apresentar o resumo (Encerramento, acima), registrar os
aprendizados obtidos durante o desenvolvimento.

O objetivo desta etapa é transformar a experiência adquirida durante a 
implementação em documentação reutilizável para futuras tarefas.

Dependendo da natureza do aprendizado, um ou mais documentos deverão ser 
criados, ou atualizados nas seguintes pastas:

```
docs/dev/knowledge/
```

#### Lessons

Registrar um resumo da implementação contendo:

- objetivo da tarefa;
- principais desafios encontrados;
- decisões arquiteturais relevantes;
- problemas enfrentados;
- soluções adotadas;
- recomendações para futuras implementações.

Local:

```
docs/dev/knowledge/lessons/
```

---

#### Patterns

Quando uma solução representar um padrão reutilizável no projeto, documentá-la.

Exemplos:

- organização de módulos;
- estratégia de persistência;
- arquitetura de componentes;
- comunicação entre módulos.

Local:

```
docs/dev/knowledge/patterns/
```

---

#### Anti-patterns

Sempre que uma abordagem gerar retrabalho, bugs, baixa legibilidade ou outros 
problemas relevantes, registrar sua ocorrência.

Cada documento deve explicar:

- o problema;
- por que ocorreu;
- consequências;
- abordagem recomendada.

Local:

```
docs/dev/knowledge/anti-patterns/
```

---

#### Recipes

Quando uma implementação representar um fluxo recorrente, documentá-la como uma
receita reutilizável.

Cada Recipe deve conter:

- objetivo;
- pré-requisitos;
- arquivos normalmente envolvidos;
- sequência recomendada de implementação;
- estratégia de testes;
- documentação normalmente afetada;
- prompt recomendado para execução da tarefa por agentes de código.

Local:

```
docs/dev/knowledge/recipes/
```

Os documentos de conhecimento são commitados na mesma branch da
tarefa. Depois, mesclar a branch na `main` localmente (sem PR) e
informar o usuário que a captura de conhecimento também está
mesclada. Após concluir, retornar para a branch principal (`main`).

---

## Padrão de Commits

Toda mensagem de commit segue [Conventional Commits](https://www.conventionalcommits.org/pt-br/v1.0.0/)
— referência completa em `../research/conventional-commits.md`, para
consulta sem depender de acesso à internet.

### Estrutura

```
<tipo>[escopo opcional]: <descrição>

[corpo opcional]

[rodapé(s) opcional(is)]
```

### Tipos

- `feat` — novo recurso;
- `fix` — correção de bug;
- `build`, `chore`, `ci`, `docs`, `style`, `refactor`, `perf`, `test` —
  demais tipos, conforme a natureza da alteração.

### Escopo

Substantivo entre parênteses após o tipo, indicando a área afetada (ex:
`feat(api): ...`, `fix(chat): ...`).

### Breaking Changes

Indicadas de uma das formas abaixo (podem ser combinadas):

- `!` logo após o tipo/escopo, antes dos dois-pontos (ex:
  `feat(api)!: ...`);
- rodapé `BREAKING CHANGE: <descrição>` (`BREAKING-CHANGE` é sinônimo).

Se o `!` for usado, o rodapé `BREAKING CHANGE:` passa a ser opcional.

### Regras

- tipo e descrição são obrigatórios; escopo, corpo e rodapés são
  opcionais;
- a descrição breve segue direto após `tipo[escopo]:` (com espaço);
- o corpo, se existir, vem após uma linha em branco e pode ter múltiplos
  parágrafos;
- rodapés, se existirem, vêm após uma linha em branco do corpo; usam
  hífen no lugar de espaço no nome do token (ex: `Acked-by:`), exceto
  `BREAKING CHANGE`;
- tipo, escopo e rodapés não diferenciam maiúsculas de minúsculas,
  exceto `BREAKING CHANGE`, que deve ser maiúsculo.

---

## Tipos de Alteração

### Nível 1 — Implementação

Alterações localizadas.

Exemplos:

- correção de bugs;
- melhorias visuais;
- refatorações internas;
- novos componentes;
- novos endpoints.

Não alteram a arquitetura do sistema.

---

### Nível 2 — Estrutural

Alterações que modificam contratos ou arquitetura.

Exemplos:

- banco de dados;
- APIs públicas;
- arquitetura;
- contratos;
- comunicação entre módulos;
- estrutura dos projetos.

Toda alteração de Nível 2 exige aprovação explícita do usuário antes da implementação.

---

# 4. Integrações

Este documento é utilizado em conjunto com toda a documentação arquitetural.

Antes de iniciar uma implementação, o agente deve consultar os documentos 
relacionados ao módulo afetado.

Caso existam conflitos entre documentos, o usuário deve ser consultado antes da
implementação.

---

# 5. Evolução Futura

Este documento deverá evoluir para contemplar:

- padrões de codificação;
- convenções de nomenclatura;
- estratégia de versionamento;
- política de testes;
- política de documentação;
- política de segurança;
- convenções para agentes especializados;
- base de conhecimento do projeto.

---

# 6. Documentação Relacionada

## Geral

- `../00-context.md`

## Arquitetura

- `01-system.md`
- `02-core.md`
- `03-backend.md`
- `04-frontend.md`
- `05-api.md`
- `06-models.md`
- `06b-services.md`
- `07-database.md`
- `08-redis.md`
- `09-projects.md`
- `10-resilience.md`
- `11-search.md`
- `12-memory.md`
- `integrations/openclaude.md`
- `ui/dashboard.md`

## Base de Conhecimento

- `../knowledge/`

## Pesquisa

- `../research/conventional-commits.md`

---

# 7. Regras Gerais

- Sempre solicitar aprovação antes de remover arquivos ou diretórios, exceto
  quando solicitado explicitamente pelo usuário.
- Nunca alterar documentação arquitetural sem autorização do usuário.
- Nunca modificar arquivos fora do escopo da tarefa.
- Nunca introduzir novas dependências sem justificar sua necessidade.
- Sempre atualizar a documentação quando alterar o comportamento do sistema.
- Nunca alterar contratos públicos sem aprovação do usuário.
- Sempre preservar compatibilidade com a arquitetura definida na documentação.
- Em caso de dúvida sobre requisitos ou documentação, interromper a 
  implementação e consultar o usuário.

