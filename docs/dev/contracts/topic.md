# Topic

> Conceito futuro. Sem aplicação prática no MVP — este contrato existe
> apenas para registrar o conceito antes da implementação.

Representa um agrupamento de chats dentro de um projeto, usado para
delimitar o escopo da memória compartilhada entre eles (ver
`../architecture/12-memory.md` para a mecânica de tipos, formato e
gatilhos de leitura/escrita da memória em si).

### Responsabilidades (futuro):

- pertencer a um único projeto
- agrupar chats de um mesmo projeto
- produzir uma memória privada, compartilhada apenas entre os chats do
  próprio topic
- produzir uma memória pública, que resume a memória privada e passa a
  fazer parte da memória global do projeto

### Não deve:

- pertencer a mais de um projeto
- expor a memória privada para chats fora do topic
- substituir a memória global do projeto

### Relação com Chat

- todo chat pertence a nenhum ou um topic;
- todo topic possui nenhum ou vários chats.

### Relação com Memória

- todo chat tem acesso à memória global do projeto;
- todo chat dentro de um topic tem acesso adicional à memória privada
  daquele topic;
- a memória pública de cada topic é incorporada à memória global do
  projeto, ficando acessível a todos os chats do projeto (com ou sem
  topic);
- a memória privada de um topic nunca é acessível a chats de outros
  topics, nem a chats sem topic.
