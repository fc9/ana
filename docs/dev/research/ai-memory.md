# Estudo de Referência — ai-memory

Status: Draft
Versão: 0.1
Última atualização: 2026-07-06
Responsável: Arquitetura

Repositório oficial:

https://github.com/akitaonrails/ai-memory

Artigos:

https://akitaonrails.com/2026/06/14/ai-memory-arquitetura-emergente-e-software-maleavel/

https://akitaonrails.com/2026/06/16/ai-memory-memoria-longo-prazo-karpathy-wiki-auto-aprendizado-hermes-projetos/

---

# 1. Objetivo

Este documento registra o estudo arquitetural do projeto ai-memory.

Seu objetivo é avaliar quais conceitos podem ser incorporados à arquitetura da
Ana.

O foco deste estudo não é reutilizar código, mas compreender o modelo de memória
utilizado pelo projeto e identificar oportunidades de integração.

---

# 2. O que é o ai-memory

O ai-memory é um sistema de memória de longo prazo para agentes de código.

Seu objetivo principal é permitir que diferentes agentes (Claude Code, Codex,
OpenAI, Gemini etc.) possam continuar trabalhando em um projeto sem precisar
reconstruir todo o contexto a cada nova sessão. :contentReference[oaicite:1]
{index=1}

Ele trata memória como uma camada independente dos modelos de IA.

---

# 3. Filosofia

A principal ideia do projeto é:

> O conhecimento do projeto deve sobreviver ao agente.

Ou seja:

- trocar de modelo;
- trocar de agente;
- interromper sessões;
- continuar dias depois;

não deve significar perda de contexto.

Essa filosofia está extremamente alinhada com a visão da Ana.

---

# 4. Conceitos interessantes

## Memória independente do LLM

A memória não pertence ao modelo.

Ela pertence ao projeto.

Isso permite utilizar diferentes modelos sobre a mesma base de conhecimento.

### Aplicação na Ana

A memória deverá pertencer ao Projeto, nunca ao Provider.

---

## Memória independente do Agente

Os agentes podem ser substituídos.

A memória permanece.

### Aplicação na Ana

Todos os agentes especializados deverão compartilhar uma mesma memória do
projeto.

---

## Handoff entre agentes

O ai-memory permite interromper uma sessão de um agente e continuar com outro
agente posteriormente.

### Aplicação na Ana

Muito interessante para:

- Main Agent
- Coder Agent
- Researcher Agent

---

## Wiki como memória

Grande parte do conhecimento consolidado é armazenado como páginas Markdown.

Isso torna a memória:

- auditável;
- editável;
- versionável.

### Aplicação na Ana

Este conceito é extremamente interessante.

A documentação poderá continuar sendo a principal fonte de verdade.

A memória poderá produzir documentos, e não apenas embeddings.

---

## Consolidação automática

Ao invés de armazenar toda conversa indefinidamente, o ai-memory consolida
sessões em conhecimento permanente. :contentReference[oaicite:2]{index=2}

### Aplicação na Ana

Muito interessante.

Ao final de uma conversa, a Ana poderá decidir:

- descartar informações temporárias;
- consolidar conhecimento útil;
- atualizar memória permanente.

---

## Auto-aprendizado supervisionado

O ai-memory possui um mecanismo de propostas de melhoria que podem ser revisadas
antes de serem incorporadas. :contentReference[oaicite:3]{index=3}

### Aplicação na Ana

Extremamente interessante.

Pode ser utilizado futuramente para:

- melhorar Skills;
- melhorar documentação;
- sugerir alterações em projetos.

---

## Memória baseada em Wiki

O projeto trata Markdown como formato principal da memória.

### Aplicação na Ana

Muito alinhado.

A Ana já utiliza Markdown para documentação.

---

# 5. Possíveis aplicações na Ana

## Coder Agent

Potencial extremamente alto.

A memória poderá registrar:

- arquitetura;
- decisões;
- bugs encontrados;
- tentativas fracassadas;
- soluções adotadas;
- TODOs;
- handoffs.

Este provavelmente será o primeiro uso da memória na Ana.

---

## Projetos

Potencial alto.

Cada projeto poderá possuir sua própria memória.

Ela deverá ser completamente isolada dos demais projetos.

---

## Chat

Potencial médio.

A memória não deve substituir o histórico do chat.

Ela deverá complementar o contexto quando necessário.

---

## Usuário

Potencial futuro.

Poderá armazenar:

- preferências;
- estilo de trabalho;
- decisões recorrentes.

---

# 6. O que NÃO copiar

Apesar das excelentes ideias, alguns pontos não devem ser incorporados
automaticamente.

## Memória como única fonte de verdade

A Ana continuará utilizando documentação como principal fonte de conhecimento.

A memória será complementar.

---

## Acoplamento ao agente

A memória não deverá pertencer ao Main Agent.

Ela deverá ser um módulo independente.

---

## Acoplamento ao Provider

A memória não deverá depender do modelo utilizado.

---

# 7. Recursos para estudar após o MVP

Prioridade alta

- arquitetura da memória;
- handoff entre agentes;
- consolidação de sessões;
- wiki como memória.

Prioridade média

- embeddings;
- banco vetorial;
- busca híbrida.

Prioridade baixa

- auto-improvement;
- curator;
- lint da memória;
- checkpoints.

---

# 8. Conclusões

O ai-memory apresenta uma das arquiteturas de memória mais interessantes
encontradas até o momento.

Sua principal contribuição não é o uso de embeddings, mas a separação entre:

- agente;
- modelo;
- memória;
- conhecimento permanente.

Esse conceito está fortemente alinhado com a visão arquitetural da Ana.

Entretanto, a Ana deverá preservar uma diferença importante:

A documentação continuará sendo a principal fonte de verdade do projeto.

A memória será utilizada para enriquecer contexto, registrar conhecimento
consolidado e permitir continuidade entre sessões, mas nunca substituirá a
documentação arquitetural nem as decisões explícitas registradas pelo usuário.
