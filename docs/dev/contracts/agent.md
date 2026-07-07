# Agent

> Conceito futuro. Fora do escopo do MVP.

Representa uma unidade especializada capaz de planejar e executar
tarefas com maior autonomia, utilizando Skills e Tools.

### Responsabilidades (futuro):

- decidir como resolver uma tarefa dentro de sua especialidade
  (ex: coder, researcher, writer, reviewer)
- utilizar Skills e Tools disponíveis
- consultar a Memória do projeto quando necessário

### Não deve:

- substituir o Core como orquestrador principal
- acessar diretamente um Provider (deve passar pela abstração de
  Provider)
- executar fora dos limites/autorizações do projeto
