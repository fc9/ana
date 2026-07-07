# MCP

> Conceito futuro. Fora do escopo do MVP — inclusive posterior ao
> OpenClaude no roadmap de integrações (ver `00-context.md` > Stack >
> Integrações).

Representa a configuração de um servidor MCP (Model Context Protocol)
disponibilizado para a Ana.

### Responsabilidades (futuro):

- pertencer a um único projeto (ou ser global — a decidir)
- armazenar a configuração de conexão do servidor MCP
- expor as ferramentas do servidor para agentes/Core

### Não deve:

- conter lógica de negócio da Ana
- ser acessado diretamente por módulos fora da camada de integrações
