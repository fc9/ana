# Base de Conhecimento

Status: Draft  
Versão: 0.1  
Última atualização: 2026-07-03  
Responsável: Arquitetura

> Esta pasta contém conhecimento adquirido durante o desenvolvimento da Ana e
> deve ser consultada pelos agentes de código durante o planejamento e 
> implementação de novas tarefas.

---

# 1. Objetivo

A pasta `docs/dev/dev/knowledge` reúne o conhecimento adquirido durante o 
desenvolvimento da Ana.

Seu objetivo é transformar a experiência obtida em cada implementação em 
documentação reutilizável, permitindo que desenvolvedores e agentes de código 
aprendam com decisões passadas e reutilizem soluções já validadas.

Esta documentação complementa a documentação arquitetural do projeto.

---

# 2. Estrutura

```text
docs/dev/
└── knowledge/
    ├── lessons/
    ├── patterns/
    ├── anti-patterns/
    └── recipes/
```

Cada subdiretório possui um propósito específico.

---

# 3. Categorias

## Lessons

Registra o aprendizado obtido durante uma implementação específica.

Cada documento deve responder perguntas como:

- O que foi desenvolvido?
- Quais dificuldades surgiram?
- Quais decisões importantes foram tomadas?
- O que faria diferente?
- O que deve ser lembrado futuramente?

Exemplo:

```text
lesson-0003-provider-abstraction.md
```

Criar um novo documento sempre que uma implementação gerar conhecimento relevante.

---

## Patterns

Documenta soluções que se mostraram reutilizáveis ao longo do projeto.

Um Pattern deve explicar:

- problema;
- solução adotada;
- quando utilizar;
- quando evitar;
- vantagens;
- limitações;
- exemplos de uso;
- arquivos relacionados.

Criar um Pattern somente quando houver potencial de reutilização.

---

## Anti-patterns

Documenta abordagens que causaram problemas durante o desenvolvimento.

Cada documento deve explicar:

- problema observado;
- contexto;
- consequências;
- causa raiz;
- abordagem recomendada.

O objetivo não é registrar erros, mas evitar que eles se repitam.

---

## Recipes

Recipes descrevem procedimentos de implementação para tarefas recorrentes.

Cada Recipe deve conter:

- objetivo;
- pré-requisitos;
- sequência recomendada;
- arquivos normalmente envolvidos;
- estratégia de testes;
- documentação normalmente afetada;
- prompt recomendado para agentes de código.

Exemplo:

```text
recipe-create-crud.md
```

Recipes representam a forma recomendada de executar tarefas recorrentes dentro do projeto.

---

# 4. Quando criar novos documentos

Criar documentação nesta pasta sempre que uma implementação gerar conhecimento que possa ser reutilizado futuramente.

Nem toda tarefa exige novos documentos.

Criar documentação apenas quando houver ganho real para o projeto.

---

# 5. Convenções

- Um documento deve pertencer a apenas uma categoria.
- Sempre reutilizar documentos existentes antes de criar novos.
- Evitar duplicação de conhecimento.
- Atualizar documentos existentes quando o aprendizado evoluir.
- Utilizar nomes curtos e descritivos.
- Sempre que possível, relacionar documentos entre si.

---

# 6. Documentação Relacionada

## Geral

- `../00-context.md`
- `../00-development.md`

## Arquitetura

- `../architecture/`

## Contratos

- `../contracts/`
