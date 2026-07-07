# Mapa Conceitual

Este capítulo apresenta a relação entre os principais conceitos utilizados na 
arquitetura da Ana.

O objetivo é facilitar a compreensão do papel de cada componente e como eles 
interagem.

---

## Visão Geral

```text
                                   Usuário
                                      │
                                      ▼
                                    Core
                                    (Ana)
                                      │
         ┌──────────────┬─────────────┼──────────────┬──────────────┐
         │              │             │              │              │
         ▼              ▼             ▼              ▼              ▼
      Skills         Memory        Agents        Providers        Tools
         │              │             │              │              │
         │              │             │              │              │
         └──────────────┴─────────────┴──────────────┴──────────────┘
                                      │
                                      ▼
                                   Context
                                      │
                                      ▼
                                   Prompt
                                      │
                                      ▼
                                     API
                                      │
                                      ▼
                                  Provider
                                      │
                                      ▼
                                 Modelo (LLM)
                                      │
                                      ▼
                                  Resposta
```

---

## Fluxo de Execução

Uma conversa normalmente segue este fluxo:

```text
Usuário
    │
    ▼
Ana Core recebe a solicitação
    │
    ├── Recupera memória
    ├── Carrega skills
    ├── Seleciona ferramentas
    ├── Seleciona agentes
    ├── Consulta documentação do projeto (quando existir)
    └── Monta o contexto
            │
            ▼
        Prompt Final
            │
            ▼
      API do Provider
            │
            ▼
           LLM
            │
            ▼
        Resposta
            │
            ▼
Conversation Engine
    │
    ├── Executa ferramentas (se necessário)
    ├── Atualiza memória
    └── Envia resposta ao usuário
```

---

## Hierarquia dos Conceitos

É comum confundir alguns termos. A relação correta é:

```text
Assistente (Ana)
│
├── Core
│   │
│   ├── Skills
│   ├── Agents
│   ├── Memory
│   ├── Tools
│   └── Providers
│
└── Interface Web
```

---

## Ferramentas

As ferramentas executam ações.

Elas **não tomam decisões**.

```text
Core
          │
          ▼
        Tool
          │
          ▼
Filesystem
Git
Shell
HTTP
Banco de Dados
```

---

## Providers

O Provider é apenas uma camada de acesso ao modelo.

```text
Conversation Engine
          │
          ▼
      Provider
          │
          ▼
     OpenAI API
Anthropic API
LM Studio
Ollama
```

---

## Modelos

Um Provider pode oferecer diversos modelos.

```text
OpenAI
├── GPT-5
├── GPT-5 Mini
└── GPT-4.1

Anthropic
├── Claude Sonnet
└── Claude Opus

LM Studio
├── Qwen
├── Gemma
├── Llama
└── Mistral
```

---

## Memória

A memória não conversa diretamente com o modelo.

Ela apenas fornece contexto.

```text
Memória
     │
     ▼
Core
     │
     ▼
Prompt
```

---

## Skills

Uma Skill define **como executar** uma tarefa.

Ela normalmente contém:

- instruções;
- contexto;
- exemplos;
- ferramentas permitidas.

Ela **não executa código**.

---

## Agentes

Um agente decide como resolver um problema.

Pode utilizar:

- memória;
- skills;
- ferramentas;
- outros agentes.

---

## Ferramentas x Skills x Agentes

```text
Agente
│
├── toma decisões
├── cria planos
└── usa Skills e Ferramentas

Skill
│
├── define comportamento
└── fornece conhecimento especializado

Ferramenta
│
├── executa ações
└── não toma decisões
```

---

## Relação entre API, Provider e Modelo

```text
Core
        │
        ▼
API do Provider
        │
        ▼
Provider
        │
        ▼
Modelo
```

Exemplo:

```text
Core
        │
        ▼
POST /chat/completions
        │
        ▼
OpenAI
        │
        ▼
GPT-5
```

---

## Onde a Ana termina?

A responsabilidade da Ana termina no envio do Prompt para o Provider.

```text
Ana
│
├── contexto
├── memória
├── skills
├── agentes
├── ferramentas
├── prompt
└── provider
        │
        ▼
────────────────────────────────────────────
Responsabilidade do Provider
────────────────────────────────────────────
        │
        ▼
LLM
        │
        ▼
Resposta
```

---

## Resumo

```text
Usuário
    │
    ▼
Ana Core
    │
    ├── Skills
    ├── Memory
    ├── Agents
    ├── Tools
    └── Providers
             │
             ▼
            LLM
             │
             ▼
         Resposta
```

O Core é o componente responsável por coordenar toda a interação entre a Ana, 
seus módulos internos e o modelo de linguagem.
