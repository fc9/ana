# Glossário de IA

> Documento de referência para compreender conceitos utilizados durante a
> modelagem e desenvolvimento da Ana.

---

# IA (Artificial Intelligence)

Campo da computação que busca desenvolver sistemas capazes de executar tarefas 
que normalmente exigiriam inteligência humana.

Exemplos:

* reconhecer imagens;
* conversar;
* traduzir idiomas;
* dirigir veículos;
* recomendar produtos.

IA é um termo extremamente amplo.

---

# IA Generativa

Subárea da IA especializada em gerar conteúdo novo.

Pode gerar:

* texto;
* imagens;
* áudio;
* vídeo;
* código;
* música.

Exemplos:

* ChatGPT
* Claude
* Gemini
* MidJourney
* Stable Diffusion

---

# LLM (Large Language Model)

Modelo de IA treinado para compreender e gerar linguagem natural.

É o "motor de raciocínio" utilizado pelos assistentes modernos.

Exemplos:

* GPT-5
* Claude Sonnet
* Gemini
* Qwen
* Llama

Importante:

Um LLM não é um assistente.

Ele apenas recebe um prompt e produz uma resposta.

---

# Modelo de IA

Um modelo é um arquivo (ou conjunto de pesos matemáticos) treinado para executar
determinada tarefa.

Exemplo:

```text
GPT-5
```

é um modelo.

```text
Claude Sonnet
```

também é um modelo.

A Ana **não é um modelo**.

Ela utiliza modelos.

---

# Assistente de IA

Aplicação construída sobre um ou mais modelos.

Exemplo:

```text
Usuário

↓

Ana

↓

GPT
```

A Ana decide:

* contexto
* memória
* ferramentas
* prompt

O GPT apenas responde.

---

# Provider

Serviço responsável por disponibilizar um modelo de IA.

Exemplos:

* OpenAI
* Anthropic
* Google
* OpenRouter

No contexto da Ana:

```text
Ana

↓

Provider

↓

Modelo
```

## Diferença para Provider do Laravel

Apesar do nome ser igual, o conceito é diferente.

Laravel:

Provider = registra serviços da aplicação.

IA:

Provider = empresa ou API que fornece acesso ao modelo.

---

# API de IA

Interface HTTP utilizada para conversar com um modelo.

Exemplo:

```
POST /chat/completions
```

A API recebe:

* mensagens
* modelo
* parâmetros

E retorna:

* resposta do modelo.

---

# LM Studio

Aplicação desktop que permite executar modelos de IA localmente.

Possui:

* download de modelos
* servidor OpenAI Compatible
* gerenciamento de GPU

É uma alternativa offline.

---

# Ollama

Servidor local para execução de modelos.

Possui filosofia semelhante ao Docker.

Exemplo:

```
ollama run llama3
```

É mais focado em servidores.

---

# OpenClaude

Projeto open-source inspirado no Claude Code.

Não é um modelo.

Não é um LLM.

É um agente de código.

Possui:

* ferramentas
* shell
* git
* filesystem
* MCP
* skills

Na Ana ele será tratado como um módulo especializado.

---

# Tool (Ferramenta)

Capacidade externa que um modelo pode utilizar.

Exemplos:

* ler arquivo
* executar shell
* consultar banco
* chamar API

Importante:

Uma Tool executa ações.

Ela não toma decisões.

---

# Skill

Conjunto reutilizável de instruções para executar uma tarefa específica.

Exemplos:

* escrever documentação
* criar CRUD
* revisar código

Uma Skill normalmente define:

* comportamento
* contexto
* ferramentas permitidas
* formato esperado da resposta

---

# Agente

Camada responsável por decidir como resolver um problema.

Um agente pode:

* utilizar ferramentas;
* consultar memória;
* executar várias etapas;
* elaborar planos.

Exemplo:

```
Usuário

↓

Agente

↓

Ferramentas

↓

Resposta
```

---

# Agente Autônomo

Agente capaz de executar múltiplas ações sem intervenção do usuário.

Exemplo:

```
Planejar

↓

Pesquisar

↓

Ler arquivos

↓

Modificar código

↓

Executar testes

↓

Gerar relatório
```

A autonomia sempre deve possuir limites e permissões.

---

# MCP (Model Context Protocol)

Padrão criado para conectar modelos de IA a ferramentas externas.

Permite que um modelo utilize:

* arquivos
* banco de dados
* Git
* navegador
* APIs
* IDEs

O MCP padroniza a comunicação entre modelos e ferramentas.

---

# Runtime

Ambiente onde determinado código é executado.

Exemplos:

* Node.js
* Python
* JVM

No contexto da Ana, este termo não corresponde a um componente da arquitetura.
Operações locais (arquivos, git, shell) são tratadas como Tools, dentro de
`shared/tools` (ver `architecture/01-system.md`).

---

# Memória

Informações utilizadas para enriquecer o contexto enviado ao modelo.

Existem diversos tipos.

## Curta duração

Contexto da conversa atual.

## Longa duração

Informações persistidas.

## Vetorial

Busca semântica por similaridade.

---

# Banco Vetorial

Banco especializado em armazenar embeddings.

Não realiza busca por texto.

Realiza busca por significado.

Exemplos:

* Chroma
* Pinecone
* Qdrant
* Weaviate

---

# Embedding

Representação numérica de um texto.

Permite calcular similaridade entre conteúdos.

Exemplo:

```
"cachorro"

↓

[0.12, -0.45, ...]
```

---

# Fine-tuning

Processo de continuar treinando um modelo existente para uma tarefa específica.

É caro.

Nem sempre necessário.

Hoje, muitas aplicações preferem:

* prompts;
* memória;
* RAG.

---

# Treinamento

Processo de ensinar um modelo durante sua criação.

Envolve milhões ou bilhões de exemplos.

É completamente diferente de usar um modelo.

---

# RAG (Retrieval-Augmented Generation)

Técnica onde documentos são recuperados antes de consultar o modelo.

Fluxo:

```
Pergunta

↓

Busca documentos

↓

Contexto

↓

LLM
```

---

# Context Window

Quantidade máxima de contexto que um modelo consegue processar em uma única requisição.

---

# Prompt

Conjunto de instruções enviado ao modelo.

Pode conter:

* mensagens;
* documentos;
* exemplos;
* contexto;
* ferramentas.

---

# System Prompt

Prompt utilizado para definir o comportamento do modelo.

Normalmente é invisível para o usuário.

---

# Token

Unidade utilizada pelos modelos para representar texto.

Não corresponde exatamente a palavras.

Modelos possuem limite máximo de tokens.

---

# Context Builder

Componente responsável por montar o contexto enviado ao modelo.

Pode combinar:

* conversa;
* memória;
* documentos;
* skills;
* ferramentas.

---

# Conversation Engine

Camada responsável por coordenar toda interação com o modelo.

Pode decidir:

* provider;
* memória;
* agentes;
* tools;
* skills.

É um conceito que provavelmente fará parte da arquitetura da Ana.

---

# Visão Computacional

Área da IA especializada em interpretar imagens e vídeos.

Permite:

* reconhecer objetos;
* identificar pessoas;
* ler documentos;
* segmentar imagens.

---

# CNN (Convolutional Neural Network)

Arquitetura clássica para reconhecimento de imagens.

Foi durante muitos anos a principal técnica em visão computacional.

---

# YOLO

("You Only Look Once")

Modelo especializado em detecção de objetos em tempo real.

Muito utilizado em:

* câmeras;
* robótica;
* carros autônomos.

---

# GAN (Generative Adversarial Network)

Arquitetura composta por duas redes neurais:

* Gerador
* Discriminador

Muito utilizada para geração de imagens antes da popularização dos modelos de difusão.

---

# Modelo de Difusão

Arquitetura moderna para geração de imagens.

Exemplos:

* Stable Diffusion
* Flux
* SDXL

Hoje substituiu grande parte das GANs.

---

# Hugging Face

Maior plataforma de distribuição de modelos de IA.

Equivale ao GitHub dos modelos de IA.

Também fornece:

* datasets;
* bibliotecas;
* Spaces;
* documentação.

---

# Hooks

No contexto de agentes como OpenClaude, Hooks são pontos de extensão executados 
antes, durante ou após determinadas operações.

Exemplos:

* antes de editar um arquivo;
* após executar um comando;
* antes de chamar uma ferramenta.

Permitem personalizar o comportamento do agente.

---

# Módulo

Componente funcional da aplicação.

Exemplo:

```
Memory
Chat
Projects
```

Um módulo representa uma capacidade da Ana.

---

# Serviço (Service)

Parte da aplicação responsável por executar uma responsabilidade específica.

Exemplo:

```
ProjectService

ChatService
```

É um conceito interno da arquitetura.

---

# Pacote (Package)

Biblioteca reutilizável.

Pode ser compartilhada entre vários módulos.

Exemplo:

```
shared-types

utils

common
```

---

# Ferramenta (Tool)

Capacidade operacional disponibilizada para um agente.

Exemplo:

```
Filesystem

Git

Shell

HTTP
```

Ferramentas normalmente executam ações externas ao modelo.

---

# Projeto

Na arquitetura da Ana, representa um projeto do usuário.

Um projeto define:

* pasta raiz;
* documentação do projeto;
* contexto autorizado;
* arquivos acessíveis.

É um conceito específico da Ana, diferente do significado genérico de 
"workspace" em outras aplicações.

---
