# Chat

Representa uma conversa dentro de um projeto.

### Responsabilidades:

- pertencer a um único projeto
- pertencer a nenhum ou um topic (futuro)
- agrupar mensagens
- agrupar anexos
- possuir título, data e status (active, archived, deleted)
- possuir data de favoritado (`pinned_at`, opcional) — chats favoritados
  ficam no topo da lista, ordenados do mais recente favoritado para o
  mais antigo (ver `../architecture/ui/dashboard.md` > Item da lista de
  Chats)
- ser localizável por busca de título ou de conteúdo de suas mensagens
  (ver `../architecture/11-search.md`)
- nascer sempre em conjunto com sua primeira mensagem — não existe
  criação de chat isolada; se a primeira mensagem falhar (validação ou
  chamada ao LLM), o chat não chega a existir (ver
  `../architecture/06b-services.md` > `MessageService.start_chat` e
  `../contracts/message.md`)

### Não deve:

- pertencer a mais de um projeto ou topic
- conter lógica de IA
- existir sem ao menos uma mensagem
