# Attachment

Representa um arquivo, imagem, áudio, vídeo, texto ou conteúdo de
clipboard enviado pelo usuário.

### Responsabilidades:

- pertencer sempre a uma única mensagem (nunca nulo) — e,
  consequentemente, a um único chat e projeto (derivados via
  `message.chat_id`/`chat.project_id`, não armazenados diretamente
  aqui)
- possuir tipo (file, image, audio, video, text, clipboard)
- poder ser removido pelo usuário, deixando de ser considerado pela Ana

A linha de Attachment só passa a existir no momento em que a mensagem é
enviada (mesma transação). Antes disso, o arquivo já está salvo em
disco, mas ainda não é um Attachment — ver "Limite e retenção".

### Não deve:

- pertencer a mais de uma mensagem
- conter lógica de IA

### Limite e retenção

- Máximo de anexos por envio (por mensagem), configurável via a
  variável de ambiente `MAX_ATTACHMENTS_PER_MESSAGE` (padrão: 10 — ver
  `src/.env.example`). Sem limite total por projeto.
- Frontend impede exceder o limite antes mesmo de enviar (ver
  `../architecture/ui/dashboard.md` > Main > Composer); o Backend
  também valida e rejeita o envio inteiro (mensagem + anexos) se o
  limite for excedido, como segunda barreira — validado por
  `GuardService` antes de qualquer gravação (ver
  `../architecture/06b-services.md`).
- Lista de tipos de anexo aceitos (por MIME type, não por extensão) já
  definida em `attachment-mime-types.md` — inclui arquivos compactados
  (`zip`, `rar`, `7z`, `cbr`/`cbz` e variantes de quadrinhos/mangá),
  aceitos mas sem processar/inspecionar o conteúdo interno no MVP. A
  validação de fato por MIME type (em vez de extensão) é evolução
  futura, fora do MVP — ver nota abaixo.
- Upload antes do envio (composer) só grava o arquivo em disco — ainda
  não existe como Attachment (sem linha, sem `message_id`). Vira
  Attachment de fato só quando a mensagem é enviada. O upload é
  escopado ao **projeto**, não a um chat (`POST /projects/{id}/attachments`)
  — o composer permite anexar antes de qualquer chat existir, já que
  todo chat só nasce junto da sua primeira mensagem (ver
  `../architecture/ui/dashboard.md` > Main > Chat ativo).
- Um `staged_file_id` só vira Attachment de fato se pertencer ao
  **mesmo projeto** do chat/mensagem que está sendo enviado — o Backend
  sempre resolve o arquivo a partir do `project_id` já conhecido pela
  Route (nunca de algo embutido no id vindo do cliente), então um id
  cadastrado por engano ou de propósito num projeto diferente
  simplesmente não resolve (`AttachmentService.resolve_staged`, ver
  `../architecture/06b-services.md`) — rejeita a mensagem inteira com
  `400`, igual a um id inválido ou já expirado pela retenção de 12h,
  sem revelar se o id existe em outro projeto.
- Arquivo/Attachment é **descartável por padrão**: permanece por 12
  horas, a não ser que o usuário o remova manualmente antes disso, ou
  peça explicitamente para a Ana removê-lo. Uma limpeza periódica
  (worker) remove: linhas de Attachment com mais de 12h, e também
  arquivos em disco que nunca chegaram a virar um Attachment (upload
  no composer que nunca foi enviado).
- Anexo nunca se torna permanente por si só. Se o usuário quer manter o
  conteúdo enviado (documentação, print, mídia, link para baixar algo),
  precisa pedir explicitamente para a Ana salvar aquilo em algum lugar
  do projeto — nesse momento deixa de ser "anexo" e vira um arquivo
  comum do projeto.
- Arquivo produzido pela própria Ana nunca é considerado anexo — já
  nasce salvo na pasta do projeto.

> Evolução futura (fora do MVP): implementar a validação de tipo por
> MIME type de fato (hoje só a lista está definida, não a validação);
> e um agente Python especializado em arquivos compactados — compacta e
> descompacta, extrai e adiciona arquivos dentro do compactado, e,
> como parte disso, identifica conteúdo malicioso e exclui o anexo
> imediatamente se encontrar algo suspeito — ver
> `attachment-mime-types.md` > seção "file".

Ver `../architecture/ui/dashboard.md` > Main > Armazenamento e retenção
de anexos.

### Remoção

O usuário pode remover um anexo a qualquer momento, diretamente pela
interface (frontend/API/backend) ou solicitando a remoção no próprio
chat. Em ambos os casos, a Ana deixa de considerar aquele anexo.

Se o anexo já é um Attachment de fato (mensagem enviada), a remoção
gera uma mensagem de sistema (`role = 'event'`) no próprio chat,
relatando o ocorrido (ver `../contracts/message.md`). Se o arquivo
ainda está só no composer (staged, mensagem não enviada, sem linha em
`attachments` ainda), a remoção é direta via
`DELETE /projects/{id}/attachments/staged/{staged_file_id}` — apaga o
arquivo em disco, sem gerar registro. Na UI, o ícone do anexo mostra um
badge de exclusão ao passar o mouse — não é a remoção em si, é o
gatilho para revelar o botão (ver
`../architecture/ui/dashboard.md` > Main > Anexos na mensagem).

Ao soft-deletar um chat (ou a mensagem que originou o anexo, quando
mensagens passarem a ser deletáveis individualmente), os anexos
associados são removidos fisicamente, sem esperar a retenção de 12h.

> No MVP, apenas a remoção direta pela interface está disponível — a
> remoção solicitada em conversa depende de tool calls, que ficam fora
> do fluxo simplificado do Core no MVP (ver `../architecture/02-core.md`).
