# Memory

> Conceito futuro. Sem aplicação prática no MVP. Mecânica detalhada
> (tipos, formato, índice, gatilhos de leitura/escrita) em
> `../architecture/12-memory.md`.

Representa uma unidade de conhecimento consolidado, usada para
enriquecer o contexto enviado ao modelo.

### Responsabilidades (futuro):

- pertencer a um único projeto
- possuir um escopo: memória global do projeto, memória pública de um
  topic, ou memória privada de um topic
- ser produzida a partir de conversas consolidadas (ver `topic.md`)
- enriquecer o contexto de um chat, sem substituir o histórico do chat

### Não deve:

- ser a única fonte de verdade do sistema (a documentação do projeto
  continua sendo a fonte principal — ver `../research/ai-memory.md`)
- ser acessível fora do escopo a que pertence (memória privada de um
  topic não pode vazar para chats de outros topics)
- depender de um Provider específico

### Relação com Chat, Topic e Project

- todo chat lê e pode contribuir para a memória do escopo a que tem
  acesso (ver `topic.md` > Relação com Memória);
- a memória privada de um topic é resumida na memória pública do
  próprio topic;
- a memória pública de um topic é incorporada à memória global do
  projeto.
