# Config

Representa a configuração atual de um projeto: moeda em uso e o
Provider/ProviderModel de IA ativo. Substitui o antigo Config Ana-wide
(singleton, extinto) — configuração deixou de ser global e passou a ser
por projeto. Tabela física: `configs` (uma linha por projeto).

### Responsabilidades:

- pertencer a um único projeto (1:1)
- possuir uma Currency (padrão: USD)
- possuir um Provider/ProviderModel ativo (opcional — um projeto pode
  não ter provider configurado ainda), guardado como
  `active_provider_id` (UUID direto — Provider agora é global e só
  some fisicamente num evento raro, ver `provider.md`) +
  `active_model_ref` (chave estável — `ProviderModel.provider_ref`,
  não o `id`, já que modelos específicos ainda podem sumir do catálogo
  independente do provider sobreviver, ver `provider-model.md` e
  `../architecture/06b-services.md` > ProviderCacheService)
- ser a única fonte consultada pela Ana para saber moeda, provider ou
  modelo de um projeto
- possuir a lista de contextos fixos da `ContextBar` (`fixed_contexts`
  — ver `../architecture/ui/dashboard.md` > ContextBar), com o mesmo
  default gravado em todo projeto na criação; sem UI de edição no MVP
- possuir a lista de contextos e ferramentas ocultos por escolha do
  usuário (`hidden_contexts`, `hidden_tools` — ver
  `../architecture/ui/dashboard.md` > ContextBar/ToolBar > Menu de
  exibição), editável no MVP
- possuir a pilha ordenada de providers do dropdown de Provider/Modelo
  (`provider_order`, com `provider_order_updated_at` como carimbo de
  versão) — reordenada internamente pelo Backend, nunca pelo Frontend
  (ver `../architecture/ui/dashboard.md` > Header > Dropdown de
  Provider/Modelo e `../architecture/06b-services.md` > ConfigService)

### Não deve:

- ser consultado diretamente em `project.md` — a moeda/provider/modelo
  de um projeto sempre passa por aqui, nunca por uma cópia em Project
- conter lógica de negócio
- conter credenciais (isso é responsabilidade do Provider)

### Troca de Provider/Modelo

O Frontend só **notifica** que o modelo em uso mudou, informando o par
`(provider_id, model_ref)`. Todo o resto é responsabilidade do Backend:
validar, salvar a escolha, reordenar a pilha (o provider escolhido sobe
pro topo) e acionar o sistema de cache pra recomputar a disponibilidade
de tudo (ver `../architecture/06b-services.md` >
`ConfigService.update_config`).

A troca é **sempre aceita** — não existe teste de conexão síncrono
bloqueando-a, e o par informado não precisa sequer corresponder a algo
que o projeto tenha acesso no momento (pode se referir a um provider
que o projeto nunca assinou nem enxerga como público, ou já excluído).
O Frontend não espera confirmação nenhuma disso além do `200` imediato.
O usuário só é barrado de enviar mensagem em dois momentos, nunca no
instante da troca: ao tentar enviar de fato e ser rejeitado (ver
`message.md`), ou quando o próprio sistema de cache termina de
recomputar e classifica o modelo como indisponível/removido antes do
primeiro envio (ver `../architecture/ui/dashboard.md` > Provider
indisponível).

### Modelo ativo removido ou indisponível

Depois que um modelo já está ativo, dois estados distintos podem
acontecer, sempre detectados no fluxo de atualização do cache de
disponibilidade (ver `../architecture/06b-services.md` >
ProviderCacheService), nunca exigindo o usuário reabrir o dropdown:

- **removido** — o provider foi excluído de fato, ou o projeto perdeu
  acesso a ele (desassinou, ou a credencial que usava virou privada de
  outro projeto), ou o modelo específico foi removido do catálogo. Some
  da pilha, mas a referência guardada (`active_provider_id`/
  `active_model_ref`) continua sendo exibida, em vermelho, com aviso
  claro. Volta ao normal sozinho se o acesso for restabelecido (provider
  recadastrado, credencial assinada de novo, ou modelo do mesmo
  `provider_ref` reaparecer no catálogo);
- **indisponível** — o provider e o modelo ainda existem, mas a
  checagem de conectividade mais recente falhou (transitório). Mesma
  indicação visual, mas aviso diferente (não é exclusão). Volta ao
  normal sozinho assim que a próxima checagem confirmar disponibilidade.

Em ambos os casos, o envio de mensagens do projeto fica bloqueado até o
usuário trocar de modelo ou a situação se resolver sozinha (ver
`../architecture/ui/dashboard.md` > Provider indisponível).

Um terceiro estado, **sem modelo ativo** (`active_provider_id` `NULL` —
projeto que nunca teve um modelo escolhido), bloqueia o envio da mesma
forma, mas não é tratado como falha: não há nome nenhum pra exibir em
vermelho, nem aviso — o dropdown só convida a escolher um modelo pela
primeira vez. Na prática, o Frontend já impede o botão de enviar de
habilitar nesse estado (ver `../architecture/ui/dashboard.md` > Main >
Composer), então a rejeição do Backend pra esse caso é só uma trava
defensiva.
