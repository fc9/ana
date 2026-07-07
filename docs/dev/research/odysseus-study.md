# Estudo de Referência — Odysseus

Status: Draft  
Versão: 0.1  
Última atualização: 2026-07-06  
Responsável: Arquitetura

Repositório oficial:

https://github.com/pewdiepie-archdaemon/odysseus

> Importante: este documento representa um estudo de arquitetura realizado antes
> da conclusão do MVP. As conclusões aqui registradas podem ser revistas 
> conforme a arquitetura da Ana evoluir.

---

# 1. Objetivo

Este documento registra o estudo arquitetural do projeto **Odysseus** como fonte
de inspiração para a evolução da Ana.

O objetivo **não é transformar a Ana em um fork do Odysseus**, nem copiar sua
implementação, mas identificar conceitos, módulos e soluções maduras que possam
ser reaproveitados futuramente.

Este documento deverá ser revisitado após a conclusão do MVP da Ana.

---

# 2. Licença

O Odysseus utiliza a licença **AGPL-3.0**.

Antes de reutilizar qualquer trecho de código deverá ser realizada uma análise
da licença e de seus impactos sobre o projeto.

Até segunda ordem, este documento considera apenas o reaproveitamento de:

- arquitetura;
- conceitos;
- organização;
- ideias;
- fluxos de funcionamento.

Não considera cópia direta de código.

---

# 3. Visão Geral

O Odysseus é uma plataforma self-hosted para utilização de modelos de IA.

Sua arquitetura reúne diversos recursos encontrados em plataformas modernas de 
IA, como:

- múltiplos providers;
- agentes;
- memória;
- ferramentas;
- MCP;
- pesquisa profunda;
- editor de documentos;
- gerenciamento de arquivos.

Grande parte desses recursos também fazem parte da visão de longo prazo da Ana.

---

# 4. Recursos Identificados

## Chat

### O que é

Sistema de conversação entre usuário e modelos de IA.

### Aproveitamento

O MVP da Ana possuirá um chat simples.

Não há necessidade de copiar nenhuma funcionalidade específica.

---

## Providers

### O que é

Camada de abstração para comunicação com modelos.

Exemplos:

- OpenAI
- Anthropic
- LM Studio
- Ollama

### Aproveitamento

O conceito será utilizado integralmente.

A Ana deverá comunicar-se exclusivamente através de Providers.

Nenhum módulo deverá depender diretamente de um modelo específico.

---

## Agentes

### O que é

Unidades inteligentes especializadas responsáveis por resolver tarefas 
específicas.

Exemplos:

- escrever código;
- pesquisar;
- revisar documentos.

### Aproveitamento

A Ana possuirá agentes especializados.

Os agentes serão implementados em:

```
src/agents
```

O funcionamento interno do Odysseus poderá servir de referência quando esta 
etapa for iniciada.

---

## Memória

### O que é

Sistema responsável por recuperar contexto de longo prazo.

O Odysseus utiliza memória vetorial.

### Aproveitamento

A Ana também possuirá memória.

Entretanto, a documentação continuará sendo a principal fonte de verdade do 
sistema.

A memória deverá complementar o contexto, nunca substituir a documentação 
arquitetural.

---

## Banco Vetorial

### O que é

Banco especializado em armazenar embeddings para busca semântica.

### Aproveitamento

Estudar futuramente:

- Chroma
- Qdrant
- Weaviate

A decisão será tomada após o MVP.

---

## Skills

### O que é

Conjunto reutilizável de instruções para resolver tarefas específicas.

### Aproveitamento

A Ana utilizará Skills.

As Skills deverão utilizar Tools existentes ao invés de implementar lógica duplicada.

Uma Skill poderá agregar várias Tools.

---

## Ferramentas (Tools)

### O que é

Capacidades operacionais disponibilizadas aos agentes.

Exemplos:

- filesystem;
- git;
- shell;
- imagens.

### Aproveitamento

A arquitetura será bastante semelhante.

As Tools deverão permanecer reutilizáveis por:

- Core;
- módulos;
- agentes;
- Skills.

---

## OpenClaude

### O que é

Projeto open-source focado em assistência para desenvolvimento de software.

Disponibiliza diversas ferramentas relacionadas a código.

### Aproveitamento

O OpenClaude não será utilizado como aplicação.

Será tratado como uma integração da Ana.

Inicialmente deverá fornecer suporte para:

- ferramentas de código;
- manipulação de arquivos;
- Git;
- Shell;
- outras capacidades relacionadas ao desenvolvimento.

Sua arquitetura poderá ser adaptada conforme necessário.

---

## MCP

### O que é

Model Context Protocol.

Permite disponibilizar ferramentas externas aos modelos.

### Aproveitamento

Será implementado futuramente.

A arquitetura da Ana deverá prever uma pasta:

```
src/integrations/mcp
```

O funcionamento será estudado após estabilização do MVP.

---

## Upload de Arquivos

### O que é

Sistema de anexos utilizado durante as conversas.

### Aproveitamento

A Ana também possuirá sistema de anexos.

Os anexos deverão pertencer às mensagens do chat.

---

## Visão Computacional

### O que é

Capacidade do modelo interpretar imagens.

### Aproveitamento

A arquitetura deverá permitir envio de imagens aos Providers compatíveis.

Não será implementado no MVP.

---

## Deep Research

### O que é

Fluxo composto por:

- pesquisa;
- leitura de fontes;
- síntese;
- geração de relatório.

### Aproveitamento

A Ana deverá possuir um módulo de Research.

Inicialmente apenas como estrutura.

O funcionamento poderá ser inspirado no Odysseus.

---

## Editor de Documentos

### O que é

Editor integrado com assistência de IA.

### Aproveitamento

Não será copiado diretamente.

A Ana deverá possuir um Editor orientado a projetos.

O objetivo será editar arquivos pertencentes ao projeto atual.

O editor deverá integrar-se naturalmente com:

- chat;
- anexos;
- agentes;
- Tools.

---

## Comparação de Modelos

### O que é

Permite executar o mesmo prompt em múltiplos modelos.

### Aproveitamento

Possível implementação futura.

Poderá auxiliar na escolha do melhor Provider para determinada tarefa.

---

## Cookbook

### O que é

Documentação para utilização de modelos locais.

### Aproveitamento

A ideia poderá ser incorporada futuramente à documentação da Ana.

---

# 5. Recursos que NÃO fazem parte do MVP

Os seguintes recursos deverão permanecer fora do MVP:

- agentes especializados;
- memória;
- banco vetorial;
- MCP;
- Deep Research;
- comparação de modelos;
- visão computacional;
- editor inteligente;
- automações.

---

# 6. Arquitetura

A principal conclusão obtida com este estudo foi que a Ana deverá manter uma 
arquitetura própria.

O Odysseus será tratado como fonte de inspiração, não como modelo arquitetural.

Algumas decisões importantes tomadas durante a modelagem da Ana foram:

- o Core da Ana continuará sendo o centro do sistema;
- módulos permanecerão determinísticos;
- agentes serão especializados;
- integrações externas permanecerão isoladas;
- documentação continuará sendo a principal fonte de conhecimento do projeto.

---

# 7. Plano de Revisão

Após a conclusão do MVP deverão ser estudados novamente os seguintes módulos do 
Odysseus:

1. Agentes;
2. Memória;
3. Skills;
4. Tools;
5. OpenClaude;
6. MCP;
7. Deep Research;
8. Editor;
9. Visão Computacional.

Cada um destes itens deverá originar um estudo específico antes de sua
implementação na Ana.

---

# 8. Conclusão

O Odysseus valida diversas decisões arquiteturais já tomadas durante o 
desenvolvimento da Ana.

Apesar disso, a Ana possui objetivos diferentes.

Enquanto o Odysseus é uma plataforma completa para utilização de IA, a Ana está 
sendo projetada como uma plataforma modular, orientada a projetos e preparada 
para evoluir através de módulos, agentes e integrações independentes.

Por esse motivo, o Odysseus deverá ser utilizado como referência arquitetural e 
fonte de boas ideias, preservando sempre a identidade e a arquitetura própria da
Ana.
