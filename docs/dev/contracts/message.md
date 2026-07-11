# Message

Representa uma mensagem dentro de um chat.

### Responsabilidades:

- pertencer a um único chat
- possuir remetente (`user`, `assistant` ou `event`)
- possuir conteúdo e data
- possuir anexos associados (0 ou mais, via `attachment.message_id`) —
  mensagem precisa ter conteúdo **ou** ao menos um anexo; as duas coisas
  vazias tornam a mensagem inválida (rejeitada, não persistida). Se não
  houver nenhum anexo, o conteúdo precisa ter no mínimo
  `MIN_TEXT_LENGTH` caracteres (variável de ambiente, padrão 2 — ver
  `src/.env.example`); com anexo, não há mínimo de texto. Validado por
  `GuardService` antes de qualquer gravação (ver
  `../architecture/06b-services.md`)
- possuir expressão de avatar (`avatar_expression`, opcional — só em
  mensagens do remetente `assistant`) — persistida como identificador
  (string); no Schema de resposta vem resolvida para `{id, image_url,
  caption}` (imagem e legenda exibida como tooltip ao usuário — ver
  `../architecture/ui/dashboard.md` > Main > Avatar da Ana), nunca uma
  string solta que o Frontend precise mapear sozinho
- indicar se é a primeira mensagem do chat (`is_first`) — é sempre
  `true`: todo chat nasce em conjunto com sua primeira mensagem (ver
  `../architecture/ui/dashboard.md` > Main > Chat ativo). Conteúdo é
  sempre obrigatório nela (mesmo com anexo), pois a Ana usa esse texto
  para gerar o título do chat (ver
  `../architecture/ui/dashboard.md` > Main > Geração de título do chat)
- quando `is_first` (criação do chat), o Schema de resposta sempre
  inclui um campo extra com o chat gerado (`id` e `title`) — evita uma
  segunda chamada só para o Frontend descobrir o título gerado (ver
  `../architecture/06-models.md` > Message). Se essa primeira mensagem
  falhar (validação ou chamada ao LLM), nada é persistido — nem o
  `Chat`, nem esta `Message` — a resposta é só o erro

Remetente `event` representa um registro de sistema associado a um chat
**já existente** — cobre exclusão de anexo (ex: "o usuário deletou o
anexo X da mensagem Y") e falha na chamada ao LLM para uma mensagem que
não é a primeira do chat (mensagem padrão de erro, persistida no
histórico) — não é fala do usuário nem da Ana. Ver
`../architecture/ui/dashboard.md` > Main > Anexos na mensagem e Estado
de erro.

### Não deve:

- pertencer a mais de um chat
- conter lógica de IA
