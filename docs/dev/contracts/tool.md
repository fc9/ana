# Tool

> Conceito futuro. Fora do escopo do MVP.

Representa uma capacidade operacional externa que pode ser utilizada
pelo Core, por Agents ou por Skills (ex: filesystem, git, shell, visão
computacional).

### Responsabilidades (futuro):

- executar uma ação específica
- retornar o resultado de forma previsível

### Não deve:

- tomar decisões
- manter estado entre execuções
- ser chamada diretamente por um Provider
