# Como desenvolver?

Sempre leia este documente antes de começar a codificar.

# Filosofia de Implementação

Preferir:

- código simples
- baixo acoplamento
- módulos pequenos
- responsabilidade única
- alta legibilidade
- Use princípios SOLID
- cobertura de testes automatizados

Evitar:

- abstrações prematuras
- arquitetura excessivamente complexa
- plugins desnecessários
- dependências pesadas

## Workflow

1. Toda tarefa (solicitação de desenvolvimento) deve ser feita numa branch 
   especifica para tal. Crie uma branch nova a partir da `main` e atue dentro 
   dela.
2. Antes de desenvolver, SEMPRE crie um plano passo-a-passo de implementação da 
   tarefa. Esse plano deve ter cobertura de testes automatizados quando cabível.
3. Apresente o plano ao usuário e aguarde aprovação. O plano DEVE ser revisado 
   e aprovado explicitamente pelo usuário. 
4. SOMENTE após aprovação, salve o plano em 
   "docs/plans/plan-[mumero-sequencial]-[branch-name].md".
5. Inicie o desenvolvimento:
  - Crie os testes automatizados.
  - Execute o desenvolvimento do plano.
  - Revise se todos os requisitos foram atendidos. Volte e ajuste se necessário, 
    somente após atender todos os requisitos e passar nos testes automatizados 
    a revisão estará concluída.
  - Commite as alterações.
5. Informe a conclusão do desenvolvimento ao usuário e aguarde o retorno dele.
6. Se o usuário solicitar ajustes ou correções. Continue na mesma branch, 
   atualize o plano e submeta as alterações ao usuário para aprovação. Aprovado,
   atualize o arquivo do plano em "docs/plans/" e execute-o. Volte ao passo 5.
7. Aprovado o desenvolvimento pelo usuário, confirme com o usuário se a tarefa
   está concluída caso ele não o tenha feito. Confirmado a conclusão, abra um 
   pool request para a branch `main`.
8. Volte para branch principal (main).

## Regras

- Sempre solicite aprovação para deletar arquivos ou pastas, exceto quando o
  usuário solicitar explicitamente no chat.

- ------------------------------------------------------------------------------

# 00 - Desenvolvimento

Status: Draft  
Versão: 0.1  
Última atualização: 2026-07-03  
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
* base de conhecimento (`docs/knowledge/`);
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

O plano deve ser apresentado ao usuário.

Nenhum desenvolvimento pode iniciar sem aprovação explícita do plano pelo
usuário.

---

### 4. Registro do Plano

Após aprovação, o plano deve ser salvo em:

```
docs/plans/
```

Nome do arquivo:

```
plan-[numero-sequencial]-[nome-da-branch].md
```

---

### 5. Desenvolvimento

Após aprovação do plano:

1. Implementar os testes automatizados, quando aplicável.
2. Implementar a funcionalidade.
3. Revisar toda a implementação.
4. Executar os testes.
5. Atualizar a documentação afetada.
6. Realizar o commit das alterações.

Quando não for possível criar testes automatizados, o motivo deve ser registrado no plano.

---

### 6. Revisão

Antes de considerar a implementação concluída, verificar:

- requisitos atendidos;
- aderência ao plano;
- testes aprovados;
- documentação atualizada;
- ausência de erros conhecidos.

---

### 7. Validação do Usuário

Após concluir o desenvolvimento:

- informar o usuário;
- aguardar validação.

Caso sejam solicitados ajustes:

- permanecer na mesma branch;
- atualizar o plano;
- solicitar nova aprovação;
- implementar as alterações.

---

### 8. Encerramento

Após confirmação do usuário de que a tarefa foi concluída:

1. Abrir Pull Request para `main`;
2. Incluir um resumo da implementação;
3. Listar os arquivos alterados;
4. Descrever impactos relevantes.

---

### 9. Captura de Conhecimento

Após a abertura do Pull Request, registrar os aprendizados obtidos durante o 
desenvolvimento.

O objetivo desta etapa é transformar a experiência adquirida durante a 
implementação em documentação reutilizável para futuras tarefas.

Dependendo da natureza do aprendizado, um ou mais documentos deverão ser 
criados, ou atualizados nas seguintes pastas:

```
docs/knowledge/
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
docs/knowledge/lessons/
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
docs/knowledge/patterns/
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
docs/knowledge/anti-patterns/
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
docs/knowledge/recipes/
```

Após concluir a captura de conhecimento, retornar para a branch principal (`main`).

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

- `00-context.md`

## Arquitetura

- `architecture/01-system.md`
- `architecture/02-runtime.md`
- `architecture/03-backend.md`
- `architecture/04-frontend.md`
- `architecture/05-api.md`
- `architecture/06-openclaude.md`
- `architecture/07-database.md`
- `architecture/08-redis.md`

## Base de Conhecimento

- `docs/knowledge/`

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

