# 06b - Services

Status: Draft
Versão: 0.1
Última atualização: 2026-07-10
Responsável: Arquitetura

---

# 1. Objetivo

Definir as Services do Backend: o que cada uma faz e quais Repositories,
Models e a abstração de Providers ela coordena.

---

# 2. Escopo

## Responsabilidades

Este documento define:

- uma Service por entidade (ou grupo de entidades) do MVP;
- os métodos principais de cada Service, em nível arquitetural (sem
  assinatura Python);
- regras de negócio que atravessam mais de uma tabela.

## Não Responsabilidades

Este documento não define:

- estrutura de tabelas (ver `07-database.md`);
- Models e Schemas (ver `06-models.md`);
- endpoints (ver `05-api.md`);
- implementação (código Python) — estamos na fase de projeto.

---

# 3. Visão Geral

## Convenções

- Toda Service é chamada por uma Route, nunca por outra Route
  diretamente — a orquestração entre entidades acontece Service→Service
  (ex: `ProjectService` chama `ConfigService`), nunca Route→Route (ver
  `03-backend.md` > Camadas).
- Services retornam Models — nunca serializam para Schema. Quem faz
  essa conversão é a Route (ver `06-models.md` > Integrações > Routes).
- Regra de negócio que envolve mais de uma tabela vive na Service, nunca
  na Route nem no Repository.

## UserService

Único usuário no MVP (sem autenticação/multiusuário).

- `get_current_user()` — usado em `GET /me`;
- `update_user(name?, language_id?)` — usado em `PATCH /me`.

## ProviderService

Cobre `Provider` (global), `ProviderCredential` e `ProviderSubscription`
— não existem Services separadas pra essas três, já que as operações
relevantes (cadastrar, editar, excluir) sempre atravessam as três
tabelas juntas (ver `07-database.md` e
`docs/dev/research/identificacao-unica-de-providers.md`). Também cobre
`ProviderModel` — não existe um Service separado só para ele, dado que
sempre é acessado através de um Provider. Esta Service cuida só da
parte **estrutural** (identidade, credenciais, assinaturas, catálogo de
modelos, ordenação persistida) — disponibilidade é responsabilidade de
`ProviderCacheService` (abaixo); `ProviderService` nunca lê nem escreve
no cache diretamente.

Diferente do desenho anterior, um projeto nunca "é dono" de um
provider: providers são globais, e o vínculo de um projeto é sempre
através de uma credencial (própria, via assinatura, ou pública, sem
assinatura — ver `07-database.md` > provider_credentials/
provider_subscriptions).

- `list_visible_to_project(project_id)` — providers com pelo menos uma
  credencial pública (`is_private = false`), OU com uma
  `ProviderSubscription` do `project_id` informado (ver
  `../contracts/provider.md`). Usado em `GET /providers?project_id={id}`;
- `register(project_id, driver, base_url?, secret, is_private)` — fluxo
  único de cadastro, cobrindo tanto "provider novo" quanto "só assinar
  um provider que já existe":
  1. valida o acesso chamando o adaptador correspondente
     (`services/llm/<driver>`, ver Integrações abaixo) com o `secret`
     informado — chamada real, autenticada, contra o provider; falhando
     (credencial inválida, endpoint inacessível), rejeita imediatamente
     (`400`/`502`) sem tocar o banco;
  2. o adaptador devolve `account_or_tenant` (org id, workspace, tenant
     — ou `None`, quando o provider não distingue conta) e o `base_url`
     normalizado;
  3. calcula `canonical_instance_id` (constante `"official"` pra
     drivers de serviço único na nuvem; `base_url` normalizado, ou um
     `server_instance_id` descoberto, pra self-hosted) e procura um
     `Provider` existente com `(driver, canonical_instance_id)`; não
     encontrando, cria um novo (`display_name` do formulário, `base_url`
     gravado);
  4. procura uma `ProviderCredential` existente com `(provider_id,
     account_or_tenant)`:
     - **encontrada**: reaproveita — não cria nem altera nada (nem
       `secret`, nem `is_private`); a credencial permanece exatamente
       como já estava cadastrada, mesmo que o formulário atual peça o
       contrário. A resposta informa ao usuário que a credencial já
       existia e como está registrada (pública ou privada);
     - **não encontrada**: cria uma nova `ProviderCredential`, com o
       `is_private` pedido no formulário — **exceto** se `is_private =
       false` for pedido e o provider **já tiver** uma credencial
       pública (só pode existir uma por provider, ver `07-database.md`
       > provider_credentials): nesse caso a nova nasce como privada
       mesmo assim, e a resposta avisa esse ajuste ao usuário;
  5. cria a `ProviderSubscription (project_id, provider_id,
     credential_id)` — se `project_id` **já tiver** uma assinatura pra
     esse `provider_id` (outra conta), rejeita com `409` (um projeto só
     tem uma conta por provider — pra trocar de conta é
     `edit_credential`, abaixo, não um novo cadastro);
  6. aciona `ProviderCacheService.rebuild_cache()` em segundo plano
     (fire-and-forget) e responde imediatamente — não altera
     `configs.active_provider_id`/`active_model_ref` de nenhum projeto
     (só entra na pilha, ver `Pilha de Provider/Modelo`, abaixo);
- `edit_credential(credential_id, project_id, secret?, is_private?)` —
  só permitido se `project_id` já tiver uma `ProviderSubscription`
  apontando pra essa credencial (rejeita com `403`/`404` caso
  contrário — só quem assina edita):
  1. só `is_private` mudou (sem `secret` novo): atualiza a flag na
     própria linha — todos os assinantes dessa credencial são afetados
     igualmente, nenhuma assinatura muda de linha;
  2. `secret` novo informado: valida com o adaptador (mesmo passo 1 de
     `register`) e obtém o novo `account_or_tenant`:
     - **mesma conta de antes**: atualiza `secret` na própria linha (ex:
       chave rotacionada) — nenhuma assinatura muda de linha;
     - **conta diferente**: procura uma `ProviderCredential` existente
       em `(provider_id, novo account_or_tenant)` — encontrando,
       reaproveita (não altera) e migra `credential_id` da assinatura de
       `project_id` pra essa linha; não encontrando, cria uma nova linha
       (mesmo `is_private` de antes, salvo se também informado nesta
       chamada) e migra a assinatura pra ela. Em ambos os casos, roda a
       **checagem de órfã** (ver `unsubscribe`, passo 2, abaixo) na
       credencial que `project_id` estava deixando;
  3. aciona `ProviderCacheService.rebuild_cache()` em segundo plano;
- `unsubscribe(project_id, provider_id)` — ação de "excluir" um
  provider a partir de um projeto (só oferecida na UI quando existe uma
  `ProviderSubscription` de `project_id` pra esse `provider_id`, ver
  `../architecture/ui/dashboard.md` > Header > Dropdown de
  Provider/Modelo):
  1. remove a `ProviderSubscription(project_id, provider_id)` —
     projetos sem assinatura própria (acesso implícito via credencial
     pública) nunca tinham linha aqui, então não são tocados
     diretamente por esta ação;
  2. **checagem de órfã**, feita depois de remover a assinatura acima:
     se a `ProviderCredential` que essa assinatura usava não tiver mais
     nenhuma `ProviderSubscription` apontando pra ela (de nenhum
     projeto), remove essa credencial fisicamente — mesmo que ela fosse
     pública (é exatamente esse o caso em que projetos que usavam por
     acesso implícito, sem nunca ter assinado, perdem o acesso: a
     credencial que os atendia deixou de existir);
  3. se a credencial foi removida no passo 2: se o `Provider` não tiver
     mais **nenhuma** `ProviderCredential` restante, remove o `Provider`
     fisicamente (e suas `ProviderModel` em cascata) — se ainda restar
     qualquer outra credencial (mesmo que órfã por conta própria, a ser
     limpa depois pelo mesmo mecanismo quando for a vez dela), o
     `Provider` permanece;
  4. **espera** a recomputação do cache terminar e o broadcast
     (`provider_stack`) ser enviado antes de retornar `204` — é esse
     delay que sustenta o modal de confirmação com spinner na UI (ver
     `../architecture/ui/dashboard.md` > Header > Dropdown de
     Provider/Modelo);
- `list_models(provider_id)`, `create_model(provider_id, project_id,
  provider_ref, name)`, `update_model(model_id, project_id, name?,
  is_active?)`, `delete_model(model_id, project_id)` — CRUD de
  `ProviderModel`, só do **catálogo** (`provider_ref`/`name`/
  `is_active`) — preço não é gerenciado aqui, nunca aceito nesses
  métodos (ver `ModelPriceService`, abaixo); exige `project_id` do
  solicitante ter uma `ProviderSubscription` pra esse `provider_id` (só
  quem assina gerencia o catálogo, ver `07-database.md` >
  provider_models); mesma regra de disparo de cache de
  `register`/`edit_credential` (criar/editar não esperam; excluir
  modelo também não espera — só `unsubscribe` espera, por causa da
  cascata de credencial/provider).

### Pilha de Provider/Modelo (dropdown do Header)

A ordenação da pilha (`configs.provider_order`) nunca é sugerida ou
enviada pelo Frontend — é sempre **solicitada** (`GET`, nunca `PATCH`)
e sempre recalculada internamente pelo Backend, como efeito colateral
da troca de modelo ativo (ver `ConfigService.update_config`, abaixo) —
não existe mais um endpoint/método para o Frontend "sugerir" uma ordem.
O Frontend só lê a pilha pronta: no carregamento do projeto (novo ou
reaberto) e sempre que notificado por `provider_stack` (ver
`ui/dashboard.md` > Header > Dropdown de Provider/Modelo).

## ProviderCacheService

Módulo dedicado a manter a **disponibilidade** de credenciais —
responsabilidade que o banco de dados nunca assume (ver
`07-database.md` > provider_credentials). Única Service que lê e
escreve o cache de disponibilidade (Redis, ver `08-redis.md`); nenhuma
outra Service (nem `ProviderService`) acessa esse cache diretamente.

O worker periódico e o coalescimento de `rebuild_cache` (ambos abaixo)
guardam estado em memória de um único processo — depende da premissa de
execução de processo único do MVP (ver `03-backend.md` > Visão Geral);
não há lock distribuído entre processos/réplicas.

Disponibilidade é testada por **credencial**, não por provider: contas
diferentes do mesmo provider falham de forma independente (uma chave
revogada não afeta as demais contas desse provider), então cada
`ProviderCredential` tem seu próprio estado de disponibilidade (ver
`08-redis.md`). O catálogo de modelos não é cacheado — vem direto de
`provider_models` (tabela), já compartilhado por todas as credenciais do
mesmo provider — mas quem mantém esse catálogo sincronizado com o que o
provider realmente tem disponível é esta própria Service, via
`rebuild_cache()` (abaixo), não só o cadastro manual de modelo
(`ProviderService.create_model`). Preço é um assunto à parte, gerenciado
por `ModelPriceService` (abaixo), completamente fora do catálogo.

- `rebuild_cache(credential_ids=None)` — recomputação **integral**
  (nunca um patch parcial) das credenciais pedidas: `None` = todas as
  `ProviderCredential` existentes no banco (usado pelos gatilhos de
  evento, abaixo); uma lista específica = só essas (usado pelo ciclo
  periódico e por `report_unavailable`, que só precisam recomputar quem
  está vencido ou quem falhou agora mesmo, não todo mundo de novo). Pra
  cada credencial da rodada, chama
  `services/llm/<driver>.list_models(secret decifrado, base_url)` — uma
  única chamada que serve dois propósitos: **disponibilidade** (sucesso
  = credencial no ar, grava `provider_cache:{credential_id}.available =
  true`; falha = indisponível) e **descoberta de catálogo** (a lista
  devolvida é a fonte de verdade de quais modelos aquele provider
  realmente tem agora, cadastrados por nós ou não):
  1. para cada modelo devolvido (`provider_ref` + `name`), faz um
     upsert em `provider_models` por `(provider_id, provider_ref)`: se
     já existir, atualiza `name` (pode ter mudado) e marca `is_active =
     true`; se não existir, **cria** uma linha nova com `is_active =
     true` — nenhum preço é tocado aqui (essa tabela nem tem mais coluna
     de preço, ver `ModelPriceService`, abaixo); o modelo já fica
     selecionável e utilizável, com custo zero até alguém cadastrar o
     preço de verdade;
  2. ao final da rodada, para cada `Provider` com **pelo menos uma**
     credencial que respondeu com sucesso: todo `ProviderModel` desse
     provider cujo `provider_ref` não apareceu em **nenhuma** resposta
     bem-sucedida nesta rodada é marcado `is_active = false`
     (descontinuado pelo provider, mantido só como referência histórica,
     ver `07-database.md` > provider_models). Se **nenhuma**
     credencial desse provider respondeu (provider inteiro fora do ar),
     o catálogo não é tocado — só a disponibilidade reflete o problema,
     nunca se marca um modelo como descontinuado só porque não foi
     possível perguntar.

  Regrava `provider_cache:{credential_id}` por inteiro a cada
  credencial testada (ver `08-redis.md`). Termina sempre disparando
  `RealtimeService.broadcast_provider_stack` para os projetos afetados —
  mesmo se a ordem (`provider_order`) não mudou, a disponibilidade por
  trás dela pode ter mudado. O alcance do aviso depende da visibilidade
  da credencial afetada: mudança (inclusive remoção completa, física)
  numa credencial **privada** avisa só os projetos com
  `ProviderSubscription` para ela; mudança numa credencial **pública**
  avisa **todos os projetos**, mesmo mudança de estado de disponibilidade
  — já que acesso público implícito (sem assinatura, ver
  `provider-subscription.md`) não fica rastreado em lugar nenhum, então
  não há como saber de antemão quais projetos a usavam sem avisar todo
  mundo (mesmo princípio já usado no cadastro de uma credencial pública
  nova, ver `ProviderService.register`). É assim que um projeto usando
  um modelo cuja credencial pública pertencia a um provider removido
  fisicamente de verdade é avisado — o provider já não existe mais,
  então some do dropdown assim que essa recomputação terminar. Disparada
  por dois gatilhos independentes:
  1. **evento** — logo após o commit de qualquer `INSERT`/`UPDATE`/
     `DELETE` em `providers`/`provider_credentials`/
     `provider_subscriptions`/`provider_models` (hook na camada de
     persistência, não no Route/Controller — ver `07-database.md`), e
     também depois de `ConfigService.update_config` trocar o modelo
     ativo de um projeto (reordenar a pilha também conta como "algo
     mudou"). `ProviderService.register`/`edit_credential`/
     `create_model`/`update_model`/`update_config` disparam isso em
     segundo plano (fire-and-forget, não bloqueiam a resposta);
     `ProviderService.unsubscribe`/`delete_model` **esperam** essa
     recomputação (e o broadcast) terminar antes de retornar `204` ao
     usuário;
  2. **periódico** — não é um intervalo único: cada `ProviderCredential`
     tem seu próprio intervalo aplicável, herdado do `is_external` do
     `Provider` dono (ver `07-database.md` > providers) —
     `PROVIDER_CACHE_REFRESH_SECONDS` (variável de ambiente, padrão 60 —
     ver `src/.env.example`) pra provider local/self-hosted
     (`is_external = false`), `PROVIDER_CACHE_REFRESH_SECONDS_EXTERNAL`
     (padrão 3600, ou seja 60 minutos) pra provider externo (`is_external
     = true`) — testar um provider externo com a mesma frequência de um
     local não faz sentido (custa rate limit, possível chamada tarifada,
     e serviços de nuvem grandes caem com muito menos frequência que uma
     instalação local). O worker não roda num `sleep` fixo — a cada
     poucos segundos, para cada `ProviderCredential`, compara `now`
     contra o próprio `provider_cache:{credential_id}.checked_at` (já
     existente nesse cache, ver `08-redis.md`) e o intervalo aplicável
     daquela credencial; só as credenciais **vencidas** (ou sem entrada
     de cache ainda) entram na rodada de `rebuild_cache(credential_ids=
     [...])` daquele tick — nunca todas de uma vez só porque uma está
     vencida. `checked_at` é regravado como efeito colateral natural de
     testar a credencial, então não existe um `last_run_at` global
     separado — cada credencial carrega o próprio relógio. Isso também é
     o que permite ao gatilho de `report_unavailable` "reiniciar o
     contador": ele testa e regrava `checked_at` só daquela credencial
     específica, então o próximo vencimento dela volta a ser um
     intervalo inteiro a partir de agora, sem afetar o relógio de
     nenhuma outra credencial.

     Cadastro/edição de provider/credencial (gatilho de evento, acima)
     ignora esse vencimento — sempre testa na hora, mesmo que o intervalo
     daquela credencial ainda não tenha vencido; o vencimento só governa
     o ciclo periódico de fallback, nunca uma reação a mudança
     estrutural real.

  Corrida entre os gatilhos: **não é uma fila** — é uma única flag de
  "rodar de novo ao terminar" (mesmo princípio de coalescimento já usado
  no aviso ao Frontend, ver `RealtimeService.broadcast_provider_stack`,
  abaixo). A Service guarda, em memória do processo, se há uma
  recomputação em andamento agora e, se houver, qual é o escopo
  pendente pra próxima rodada (`None` = nada pendente; `"tudo"` = uma
  próxima rodada completa; ou um conjunto de `credential_id`s):
  1. gatilho chega e não há recomputação em andamento → começa a rodar
     na hora, para o escopo pedido;
  2. gatilho chega enquanto já há uma em andamento → **não** dispara uma
     segunda em paralelo; funde o escopo pedido no pendente (`"tudo"`
     absorve qualquer conjunto específico; dois conjuntos específicos
     se unem);
  3. ao terminar uma rodada, se houver escopo pendente, dispara
     imediatamente **uma única** rodada nova com esse escopo e zera o
     pendente antes de começar (pra que gatilhos que cheguem durante
     essa segunda rodada se acumulem num pendente novo, não se percam).

  Não importa quantos gatilhos cheguem enquanto uma recomputação está em
  andamento — no máximo mais **uma** rodada roda em seguida, nunca uma
  pra cada gatilho. Isso é independente do coalescimento do aviso ao
  Frontend (que já existia): mesmo rodando só uma vez a mais, essa rodada
  ainda pode gerar, no máximo, um aviso por projeto a cada 3 segundos
  (ver `RealtimeService.broadcast_provider_stack`, abaixo);
- `report_unavailable(credential_id)` — chamado por `MessageService`
  (`start_chat`/`send_message`) sempre que uma tentativa de envio
  encontra o modelo ativo "indisponível" (via `resolve_active_model`)
  **ou** a chamada ao LLM falha tecnicamente mesmo depois de
  `resolve_active_model` ter dito "normal" (sinal de que o cache está
  desatualizado agora mesmo). **Nunca** chamado para o estado
  "removido": nesse caso `resolve_active_model` não resolveu
  `credential_id` nenhum (o projeto não tem mais acesso a nada, ou o
  provider/modelo não existe mais) — não há o que reportar nem
  recomputar, já que não é uma falha de disponibilidade, é ausência de
  acesso. É assim que uma tentativa de envio real pode detectar uma
  queda mais rápido que o ciclo periódico daquela credencial (ver
  intervalo aplicável — interno ou externo — no gatilho **periódico**,
  acima):
  1. se `provider_cache:{credential_id}.available` já é `false`, não faz
     nada — a indisponibilidade já está refletida;
  2. senão, calcula quanto falta pro próximo vencimento **dessa
     credencial** (`checked_at + intervalo_aplicável - now`, onde o
     intervalo é `PROVIDER_CACHE_REFRESH_SECONDS` ou
     `PROVIDER_CACHE_REFRESH_SECONDS_EXTERNAL`, conforme o `is_external`
     do `Provider` dela); se faltar menos de 3 segundos, não faz nada —
     o ciclo natural já vai pegar isso quase junto. Na prática, pra
     credencial de provider externo (ciclo de 60 minutos) isso quase
     nunca acontece — `report_unavailable` acaba sendo o principal jeito
     de detectar queda rápido nesses casos, não só um atalho;
  3. senão, dispara `rebuild_cache(credential_ids=[credential_id])`
     imediatamente (fora de hora) — o que já regrava o `checked_at`
     dessa credencial como efeito colateral, reiniciando só o relógio
     dela a partir de agora, sem tocar em nenhuma outra;
- `get_stack(project_id)` — monta a pilha para
  `GET /projects/{id}/provider-stack`:
  1. lê `configs.provider_order`; se `NULL`, ordena
     `ProviderService.list_visible_to_project(project_id)` por
     `display_name` (alfabético) — fallback nunca persistido;
  2. filtra a ordem para só os `provider_id`s que ainda estão em
     `list_visible_to_project` (providers que o projeto perdeu acesso,
     ou que foram excluídos de fato, somem da pilha silenciosamente, sem
     precisar de limpeza em `provider_order`);
  3. para cada provider, resolve qual credencial esse projeto usaria
     (assinatura própria, senão a pública — mesma regra do passo 3 de
     `resolve_active_model`, abaixo) e busca `provider_cache:{credential_id}`
     (nunca o provider ao vivo) — inclui a flag `available`; a lista de
     modelos vem de `provider_models` (tabela, `is_active = true`), não
     do cache;
  4. resolve o modelo ativo via `resolve_active_model(project_id)` (ver
     abaixo) e inclui esse resultado na resposta;
- `resolve_active_model(project_id)` — traduz
  `configs.active_provider_id`/`active_model_ref` para o estado atual:
  1. se `active_provider_id` for `NULL`, retorna "sem modelo ativo"
     (projeto ainda não escolheu nenhum);
  2. busca o `Provider` por `active_provider_id` — não encontrado
     (excluído de fato) → status **removido**;
  3. resolve a credencial que esse projeto usaria pra esse provider: (a)
     se existir `ProviderSubscription(project_id, provider_id)`, usa o
     `credential_id` dela; (b) senão, procura a credencial pública
     (`is_private = false`) desse provider — no máximo uma, por
     construção (ver `07-database.md` > provider_credentials); (c) não
     achando nenhuma das duas (o projeto desassinou, a credencial que
     usava virou privada de outro projeto, ou nunca teve acesso) →
     status **removido**;
  4. encontrada a credencial, procura em `provider_models` (do
     `provider_id`, `is_active = true`) uma linha com `provider_ref`
     igual a `active_model_ref` → não encontrando, status **removido**
     também (o modelo específico foi excluído do catálogo, mesmo o
     provider/credencial ainda existindo);
  5. encontrados provider, credencial e modelo, mas
     `provider_cache:{credential_id}.available = false` → status
     **indisponível** (transitório — tudo existe, mas a checagem de
     conectividade mais recente dessa credencial falhou);
  6. tudo certo e disponível → status **normal**; retorna também o
     `provider_models.id` (UUID) e o `credential_id` resolvidos nesse
     instante, junto do `driver` do provider (pra resolver preço, ver
     `ModelPriceService`, abaixo) — é esse conjunto que `MessageService`
     usa pra chamar o LLM (`credential_id` dá acesso ao `secret`) e
     `TokenUsageService.record` usa pra gravar consumo (nunca persistido
     de volta em `configs` — resolvido de novo a cada uso).

  "Removido" e "indisponível" são estados **distintos** de propósito:
  o primeiro só se desfaz recadastrando/assinando de novo um
  provider/modelo equivalente, ou recuperando acesso (ex: a credencial
  voltar a ser pública, ou o projeto assinar de novo); o segundo se
  desfaz sozinho assim que a próxima checagem de conectividade (evento
  ou periódica) passar a bater `available = true` para aquela credencial
  — nenhum dos dois exige o usuário reabrir o dropdown e escolher de
  novo (ver `../architecture/ui/dashboard.md` > Provider indisponível).

## ModelPriceService

Única Service que lê e escreve `model_prices` — centraliza o preço de
modelo pra Ana inteira, independente de qualquer `Provider`/
`ProviderModel` específico (ver `07-database.md` > model_prices e
`../contracts/model-price.md`). Não existe mais `price_source`: só há
uma forma de obter o preço de um modelo, que é através desta Service.

- `get_price(driver, provider_ref)` — busca a linha de `model_prices`
  por `(driver, provider_ref)`; devolve os quatro valores (`input_price_per_1k`,
  `cache_read_price_per_1k`, `cache_write_price_per_1k`,
  `output_price_per_1k`); **sem linha cadastrada, devolve os quatro
  zerados** (não é erro, não cria nada) — é assim que um modelo recém
  descoberto por `ProviderCacheService.rebuild_cache` já é utilizável
  na hora, só sem custo calculado. Chamada por
  `TokenUsageService.calculate_cost` (a cada chamada ao LLM) e por
  `TokenUsageService.get_summary` (preço atual pro painel de Gastos, ver
  abaixo);
- `set_price(driver, provider_ref, input_price_per_1k,
  cache_read_price_per_1k, cache_write_price_per_1k, output_price_per_1k)`
  — upsert por `(driver, provider_ref)`; cadastra o preço de verdade
  pela primeira vez, ou atualiza um já existente. `cache_write_price_per_1k`
  fica em 0 pra provider que não distingue escrita de leitura de cache
  (a maioria). Sem Route pública ainda — a interface que vai chamar isso
  é uma tela em Settings, fora do MVP (ver `05. Evolução Futura`); o
  método já existe pronto pra quando ela for construída;
- editar um preço **nunca é retroativo**: `TokenUsageService.record`
  já grava `cost_usd` congelado no `token_usage` no instante da chamada
  (ver abaixo) — mudar `model_prices` depois nunca reescreve linhas já
  gravadas, só afeta chamadas futuras (ver `../contracts/token-usage.md`
  e `../contracts/token-usage-totals.md`).

`driver` + `provider_ref` (não `provider_id`) são a chave porque um
preço cadastrado precisa sobreviver à exclusão/recadastro do provider
dono, e ser compartilhado entre instalações diferentes do mesmo driver
que sirvam o mesmo modelo (ver
`docs/dev/research/identificacao-unica-de-providers.md`).

## ProjectService

- `list_projects(user_id)` — ordena por `last_accessed_at` mais recente
  primeiro (`NULLS LAST`), com `created_at` como critério de desempate
  (ver `../contracts/project.md`);
- `create_project(user_id, name, path)` — cria o `Project` e delega a
  `ConfigService.create_default_config` para o `Config` associado
  (moeda USD, sem provider ativo ainda);
- `get_project(id)` — como efeito colateral, grava `last_accessed_at =
  now()` (é a única forma de "tocar" o projeto — não existe endpoint
  dedicado só para isso);
- `update_project(id, name?, path?)`;
- `delete_project(id)` — bloqueia se o projeto for o `Base` (regra de
  negócio aplicada aqui, não no banco — ver `09-projects.md`); grava
  `status = 'deleted'`, nunca remove a linha (mesmo princípio de
  `ChatService.delete_chat`). Não há verificação de "projeto ativo" no
  Backend — quem impede excluir o projeto atualmente aberto é o
  Frontend (não há conceito de sessão/usuário logado no Backend para
  validar isso de forma confiável).

## GitService

- `get_current_branch(project_id)` — usado por `GET /projects/{id}/git`
  (ver `05-api.md` > Git). **Mockado no MVP**: não executa nenhum
  comando git de fato, retorna um valor fixo — a integração real fica
  para quando o dropdown de Git ganhar funcionalidade (ver
  `../architecture/ui/dashboard.md` > Header > Dropdown de Git e
  Evolução Futura).

## ConfigService

- `get_config(project_id)` — retorna também `fixed_contexts`,
  `hidden_contexts` e `hidden_tools` numa única resposta, para o
  Frontend carregar toda a configuração de UI do projeto de uma vez ao
  abri-lo (ver `../architecture/ui/dashboard.md` > ContextBar/ToolBar);
- `create_default_config(project_id)` — chamado só por
  `ProjectService.create_project`, nunca por uma Route diretamente;
  grava também os defaults de `fixed_contexts`, `hidden_contexts`
  (vazio) e `hidden_tools` (vazio) (ver `07-database.md` > configs);
- `update_config(project_id, currency_id?, provider_id?, model_ref?,
  hidden_contexts?, hidden_tools?)` — `provider_id`/`model_ref`
  substituem o antigo `provider_model_id`: gravam
  `configs.active_provider_id`/`active_model_ref` diretamente. O
  Frontend só **notifica** que o modelo em uso mudou — todo o resto
  (validar, salvar, reordenar, acionar o cache) é responsabilidade
  exclusiva desta Service:
  1. grava `active_provider_id`/`active_model_ref` — **sem testar
     conexão e sem exigir que o projeto já tenha acesso a esse provider
     no momento**. A troca é sempre aceita, mesmo que o `provider_id`
     informado não corresponda a nada visível ao projeto (ex: provider
     que o projeto nunca assinou nem enxerga como público) — não há mais
     teste síncrono de conexão bloqueando a troca em si;
     `resolve_active_model` é quem classifica isso como "removido" na
     leitura seguinte (ver `../contracts/config.md` > Troca de
     Provider/Modelo);
  2. reordena `configs.provider_order` **internamente**: se o
     `provider_id` for visível ao projeto
     (`ProviderService.list_visible_to_project`), move ele para o topo
     da pilha (mesmo princípio descrito antes para o Frontend, só que
     decidido aqui, não lá); se não for visível, não há o que mover — a
     ordem existente permanece intacta. Grava `provider_order_updated_at
     = now()` só quando a ordem muda de fato;
  3. aciona `ProviderCacheService.rebuild_cache()` de forma assíncrona
     (fire-and-forget, mesmo padrão de `ProviderService.register`) — o
     mesmo "algo mudou, cheque a disponibilidade de tudo e atualize o
     cache" disparado por cadastro/edição/exclusão de provider (ver
     `ProviderCacheService`, abaixo). É essa recomputação, ao terminar,
     que eventualmente avisa o Frontend via `provider_stack` — a troca em
     si não espera isso;
  4. responde imediatamente ao Frontend (sem esperar o passo 3).

  Como a troca nunca é bloqueada por teste de conexão, o usuário só é
  barrado de enviar mensagem em dois momentos possíveis, nenhum deles
  no instante da troca: (a) quando tentar enviar de fato e
  `MessageService` rejeitar por "removido"/"indisponível" (ver
  `resolve_active_model`, abaixo); ou (b) se o `rebuild_cache` do passo
  3 terminar antes do primeiro envio e já classificar o modelo como
  "removido"/"indisponível" — nesse caso o Frontend já bloqueia o
  Composer reativamente, via `provider_stack` (ver
  `../architecture/ui/dashboard.md` > Provider indisponível), antes
  mesmo de qualquer tentativa de envio.

  `hidden_contexts`/`hidden_tools` são gravados sem nenhuma validação
  de conteúdo (o Frontend decide o que faz sentido ocultar); o
  Frontend chama este método com debounce de 3s e de forma assíncrona
  para esses dois campos (ver `../architecture/ui/dashboard.md` >
  ContextBar/ToolBar) — a troca de `provider_name`/`model_ref` em si
  não tem debounce, é enviada assim que o usuário seleciona um modelo.

## ChatService

- `list_chats(project_id, status='active')` — ordena favoritados no
  topo (`pinned_at` mais recente primeiro), depois os demais; filtro de
  `status` existe para eventualmente listar arquivados (ver
  `07-database.md` > chats), mas ainda não há UI de restauração (ver
  `../architecture/ui/dashboard.md` > Item da lista de Chats);
- `search(project_id, query)` — busca chats do projeto cujo `title`
  bate com `query`, OU que tenham alguma `message.content` que bata
  (join/subquery); requer `len(query) >= 3`, rejeita com `400` caso
  contrário; retorna `list[Chat]` (nunca mensagens individuais) — ver
  `11-search.md`;
- `get_chat(id)`;
- `update_chat(id, title?, status?)`;
- `pin(id)` / `unpin(id)` — grava/limpa `pinned_at` (ver
  `../contracts/chat.md`);
- `delete_chat(id)` — grava `status = 'deleted'`, nunca remove a linha
  (ver `07-database.md` > Princípios > Exclusão); também remove
  fisicamente (linha + arquivo) os anexos das mensagens desse chat, sem
  esperar a retenção de 12h de `AttachmentService`;
- `generate_title(content)` — chamado só por
  `MessageService.start_chat`, nunca por uma Route diretamente.

Não existe `create_chat` isolado: um chat só nasce em conjunto com sua
primeira mensagem (ver `MessageService.start_chat`, abaixo) — "Novo
chat" na UI não toca a API (ver
`../architecture/ui/dashboard.md` > WorkPanel no contexto Chats).

## GuardService

Camada de validação do fluxo de envio de mensagem, chamada por
`MessageService` (`start_chat` ou `send_message`) **antes** de qualquer
gravação ou chamada ao Core (ver `02-core.md`). Se rejeitar, nada é
persistido (nenhuma linha em `chats`, `messages` ou `attachments`) e o
Core nem chega a ser acionado.

- `validate_message(content, staged_files, is_first)` — não recebe
  `chat_id`: quem chama já sabe se é a primeira mensagem de um chat
  novo (`is_first = true`, vindo de `start_chat`) ou uma mensagem
  adicional de um chat existente (`is_first = false`, vindo de
  `send_message` — todo chat já nasce com sua primeira mensagem, então
  `send_message` nunca precisa checar isso em `chats`). Rejeita a
  mensagem inteira, na primeira falha encontrada:
  1. `content` vazio **e** `staged_files` vazio — mensagem precisa de
     texto ou anexo (ver `../contracts/message.md`);
  2. `staged_files` vazio e `content` só-texto com menos de
     `MIN_TEXT_LENGTH` caracteres (variável de ambiente, padrão 2 — ver
     `src/.env.example` e `../contracts/message.md`) — só se aplica
     quando não há anexo; mensagem com anexo não tem mínimo de texto;
  3. `len(staged_files)` acima de `MAX_ATTACHMENTS_PER_MESSAGE`
     (variável de ambiente, padrão 10 — ver `src/.env.example` e
     `../contracts/attachment.md` > Limite e retenção);
  4. `is_first` e `content` vazio — texto é sempre obrigatório na
     primeira mensagem do chat, mesmo com anexo (a Ana precisa de
     conteúdo para gerar o título do chat — ver `ChatService` e
     `../architecture/ui/dashboard.md` > Main > Composer).

`MIN_TEXT_LENGTH` e `MAX_ATTACHMENTS_PER_MESSAGE` também são expostos
ao Frontend em `GET /limits` (ver `05-api.md` > Limits), para validação
client-side sem hardcoding dos mesmos valores.

Evolução futura (fora do MVP): validação de tipo de anexo por MIME type
(ver `../contracts/attachment.md` > Limite e retenção) e rejeição de
anexos potencialmente maliciosos (executáveis, `.bat`, shell scripts
etc.).

## MessageService

- `list_messages(chat_id)`;
- `start_chat(project_id, content, staged_files=[])` — cria o
  **primeiro** chat/mensagem de uma vez só (usado por
  `POST /projects/{id}/chats`, ver `05-api.md` > Chats). Do ponto de
  vista do usuário, um chat só existe depois que sua primeira mensagem
  é processada com sucesso — nada fica meio-criado:
  1. chama `GuardService.validate_message(content, staged_files,
     is_first=True)`; se rejeitar, retorna o erro correspondente sem
     criar nada (nem `Chat`, nem `Message`) e sem acionar o Core;
  2. se `projects.processing_chat_id` já estiver preenchido, rejeita
     com `409` (projeto ocupado processando outro chat — mesma regra
     de `send_message`, abaixo); resolve o modelo ativo via
     `ProviderCacheService.resolve_active_model(project_id)` — status
     "removido" **ou** "sem modelo ativo" (`active_provider_id`
     `NULL` — projeto que nunca teve um modelo escolhido, ver
     `../architecture/ui/dashboard.md` > Main > Composer) rejeitam com
     `422`, sem criar nada e sem chamar `report_unavailable` (não há
     `credential_id` resolvido pra reportar em nenhum dos dois — ver
     `ProviderCacheService`, abaixo); status "indisponível" também
     rejeita (`503`) sem criar nada, mas aciona
     `ProviderCacheService.report_unavailable(credential_id)` primeiro
     (ver abaixo). **Importante**: essa rejeição é local a esta chamada
     (este chat/esta tentativa de envio) — não bloqueia nenhum outro
     chat nem projeta nada pro projeto como um todo. O bloqueio amplo
     (Composer desabilitado em todos os chats/abas do projeto) é
     inteiramente responsabilidade do Frontend, que já nem deixa chegar
     aqui na prática — o botão de enviar só habilita com um modelo
     resolvido como `normal` (ver `../architecture/ui/dashboard.md` >
     Main > Composer) — essa checagem aqui é só uma última trava
     defensiva, pro caso raro do estado do Frontend estar desatualizado.
     Se houver `staged_files`, chama
     `AttachmentService.resolve_staged(project_id, staged_file_id)` pra
     cada um **antes** de criar qualquer coisa — qualquer um que não
     resolver (`staged_file_id` de outro projeto, inválido, ou já
     expirado pela retenção de 12h) rejeita a mensagem inteira com
     `400`, sem criar `Chat`/`Message`/`Attachment` nenhum (ver
     `AttachmentService`, abaixo, e `../contracts/attachment.md`) — é
     essa checagem que impede um cliente de referenciar um anexo
     staged de um projeto diferente do que está enviando a mensagem;
  3. cria a linha de `Chat` (`status = 'active'`, sem título ainda) e
     imediatamente grava `projects.processing_chat_id` = esse novo
     `chat.id` (mesma atomicidade de `send_message`, passo 3); aciona
     `RealtimeService.broadcast_processing(project_id, chat_id)`;
  4. persiste a mensagem do usuário (`role = 'user'`, `is_first =
     true`);
  5. cria as linhas de `Attachment` para cada `staged_files` (ver
     `send_message`, passo 5, mesma lógica);
  6. aciona `ChatService.generate_title(content)` e grava o título no
     `Chat` criado no passo 3;
  7. chama o LLM através da abstração de Providers (`services/llm/`),
     usando o `provider_models.id` já resolvido no passo 2;
     - **falha técnica** (a chamada em si falhou, não é rejeição de
       conteúdo): aciona
       `ProviderCacheService.report_unavailable(credential_id)` — mesmo
       `resolve_active_model` tendo dito "normal" no passo 2, essa
       falha é sinal de que o cache está desatualizado agora mesmo;
       depois disso, desfaz tudo — remove fisicamente (hard delete) o
       `Chat` criado no passo 3 e a mensagem/anexos associados, limpa
       `processing_chat_id` e aciona
       `broadcast_processing(project_id, None)`; retorna um erro (não
       uma mensagem `event` — não existe chat para guardá-la). Do ponto
       de vista do usuário e do banco, esse chat nunca existiu (ver
       `07-database.md` > chats e
       `../architecture/ui/dashboard.md` > WorkPanel no contexto
       Chats) — mas o erro **é** registrado nos logs do Backend, com
       `project_id` como campo de contexto (sem `chat_id`, já que a
       linha foi desfeita — ver `03-backend.md` > Camadas > Logging);
     - **rejeição de conteúdo pela Ana**: mesmo desfazimento acima, mas
       sem acionar `report_unavailable` — não é um problema de
       disponibilidade do provider;
     - **sucesso**: segue para os passos abaixo;
  8. registra o consumo via `TokenUsageService.record(...)`, síncrono,
     usando o `provider_models.id` resolvido no passo 2;
  9. decide `avatar_expression` da resposta (mesma resolução de
      identificador → `{id, image_url, caption}` na serialização, ver
      `send_message`, passo 8);
  10. persiste a resposta da Ana (`role = 'assistant'`, com
      `avatar_expression`);
  11. limpa `projects.processing_chat_id`; aciona
      `broadcast_processing(project_id, None)` e
      `RealtimeService.broadcast_new_message(project_id, chat_id)` (ver
      abaixo);
  12. retorna a mensagem criada, sempre acompanhada do chat gerado
      (`id` e `title`) — diferente de `send_message`, aqui esse campo
      nunca é opcional, já que esta chamada só existe para criar o
      primeiro chat (ver `../contracts/message.md` e `../06-models.md`
      > Message);
- `send_message(chat_id, content, staged_files=[])` — mensagens
  adicionais de um chat que já existe (nunca a primeira — todo chat já
  nasce com uma via `start_chat`). Fluxo completo de uma troca de
  mensagem:
  1. chama `GuardService.validate_message(content, staged_files,
     is_first=False)`; se rejeitar, retorna o erro correspondente sem
     gravar nada e sem acionar o Core;
  2. busca o `project_id` do chat; se `projects.processing_chat_id` já
     estiver preenchido, rejeita com `409` (projeto ocupado processando
     outro chat — ver `05-api.md` > Messages); resolve o modelo ativo
     via `ProviderCacheService.resolve_active_model(project_id)` —
     status "removido" **ou** "sem modelo ativo" rejeitam com `422` sem
     gravar nada e sem chamar `report_unavailable` (sem `credential_id`
     pra reportar em nenhum dos dois); status "indisponível" rejeita
     (`503`) sem gravar nada, mas aciona
     `ProviderCacheService.report_unavailable(credential_id)` primeiro
     (ver `ProviderCacheService`, acima). Mesma observação de
     `start_chat`: essa rejeição vale só para este chat/esta tentativa,
     não bloqueia o projeto inteiro — o bloqueio amplo do Composer em
     todos os chats/abas vem do Frontend reagindo a `provider_stack`,
     não desta checagem (ver `../architecture/ui/dashboard.md` >
     Provider indisponível). Se houver `staged_files`, chama
     `AttachmentService.resolve_staged(project_id, staged_file_id)` pra
     cada um **antes** de gravar qualquer coisa — qualquer um que não
     resolver (de outro projeto, inválido, ou expirado) rejeita a
     mensagem inteira com `400`, sem gravar nada (mesma checagem de
     `start_chat`, ver `AttachmentService`, abaixo, e
     `../contracts/attachment.md`);
  3. grava `projects.processing_chat_id = chat_id` — leitura e escrita
     atômicas (ex: `UPDATE ... WHERE processing_chat_id IS NULL`, numa
     única instrução), para que duas submissões concorrentes do mesmo
     projeto (duas abas, navegadores ou dispositivos diferentes) nunca
     passem as duas ao mesmo tempo (ver
     `../architecture/ui/dashboard.md` > Main > Composer); aciona
     `RealtimeService.broadcast_processing(project_id, chat_id)` (ver
     abaixo), para que qualquer sessão olhando esse projeto saiba na
     hora qual chat está sendo processado;
  4. persiste a mensagem do usuário (`role = 'user'`, `is_first =
     false`);
  5. para cada item de `staged_files` (já validado no passo 2 via
     `resolve_staged`, arquivo salvo em disco por
     `AttachmentService.upload`, ver abaixo), cria a linha de
     `Attachment` correspondente, com `message_id` da mensagem recém
     criada — é só neste passo que o Attachment passa a existir de
     fato (ver `../contracts/attachment.md`);
  6. chama o LLM através da abstração de Providers (`services/llm/`,
     ver `03-backend.md` > Camadas > Providers), usando o
     `provider_models.id` já resolvido no passo 2;
     - **falha técnica** (a chamada em si falhou — note que
       "removido"/"indisponível" já foram descartados no passo 2, então
       chegar aqui com falha técnica significa que o cache estava
       desatualizado): aciona
       `ProviderCacheService.report_unavailable(credential_id)`, além do
       resto abaixo;
     - **falha** (técnica, do item acima, ou rejeição de conteúdo pela
       Ana): persiste uma mensagem `role = 'event'` no próprio chat, com
       o texto padrão de erro ("Hum, algo deu errado: <detalhe
       técnico>") — diferente de `start_chat`, aqui o chat já existe,
       então o erro vira histórico de verdade (sobrevive a reload, ver
       `../architecture/ui/dashboard.md` > Main > Estado de erro); o
       erro também é registrado nos logs do Backend, com `project_id` e
       `chat_id` como campos de contexto (ver `03-backend.md` > Camadas
       > Logging). Pula os passos de consumo de tokens e avatar (não
       houve resposta da Ana);
     - **sucesso**: persiste a resposta da Ana (`role = 'assistant'`,
       com `avatar_expression` — passos 7-8 abaixo);
  7. (só em caso de sucesso) registra o consumo via
     `TokenUsageService.record(...)`, de forma síncrona;
  8. (só em caso de sucesso) decide `avatar_expression` da resposta,
     usando `shared/prompts/avatar-expressions.json` como referência
     (ver `../architecture/ui/dashboard.md` > Main > Avatar da Ana) —
     persiste só o identificador da expressão (string); é a Route, na
     serialização de `MessageRead`, que resolve esse identificador para
     `{id, image_url, caption}` usando o mesmo arquivo (ver `06-models.md`
     > Message) — a Service nunca monta esse objeto;
  9. limpa `projects.processing_chat_id` (`NULL`) — sempre, sucesso ou
      falha; aciona `RealtimeService.broadcast_processing(project_id,
      None)` e `RealtimeService.broadcast_new_message(project_id,
      chat_id)` (ver abaixo) — o segundo aviso é o gatilho para
      qualquer sessão com esse chat aberto buscar
      `GET /chats/{id}/messages` de novo, tanto em caso de sucesso
      (resposta da Ana) quanto de falha (mensagem de evento de erro);
  10. retorna a mensagem criada (resposta da Ana, ou a mensagem de
      evento de erro).

## AttachmentService

- `upload(project_id, file)` — salva o arquivo em disco em
  `{project.path}/.ana/storage/staged/{staged_file_id}` (`staged_file_id`
  gerado agora, UUID) e devolve essa referência temporária; **não** cria
  linha em `attachments` — Attachment só passa a existir quando a
  mensagem é enviada (ver `MessageService.start_chat`/`send_message`).
  Escopado ao **projeto**, não a um chat — o composer da tela vazia
  ("nenhum chat ainda") permite anexar antes de qualquer chat existir
  (ver `../architecture/ui/dashboard.md` > Main > Chat ativo), então a
  staging não pode depender de um `chat_id`. Responde sem processar o
  conteúdo (ver `05-api.md` > Convenções);
- `resolve_staged(project_id, staged_file_id)` — traduz um
  `staged_file_id` recebido do cliente pro caminho físico do arquivo,
  **sempre construindo o caminho a partir do `project_id` já resolvido
  pela Route/contexto da chamada** (path do chat/projeto sendo
  processado), nunca de algo embutido no próprio `staged_file_id`;
  devolve o caminho só se o arquivo existir *ali* — em
  `{project.path}/.ana/storage/staged/{staged_file_id}` daquele projeto
  específico. Um `staged_file_id` de outro projeto simplesmente não
  resolve (mesmo resultado de um id inválido ou expirado — nenhuma
  distinção de erro que revele se o id existe noutro projeto). Chamado
  por `MessageService.start_chat`/`send_message` (ver abaixo) pra cada
  item de `staged_files`, antes de criar qualquer `Attachment` — é
  assim que a posse é verificada (ver `../contracts/attachment.md`);
- `get(id)`;
- `delete(id)` — remove a linha e o arquivo físico de um Attachment já
  existente (exclusão física, ver `../contracts/attachment.md` >
  Remoção); cria também uma mensagem `role = 'event'` no chat relatando
  a remoção. Se o projeto estiver com `processing_chat_id` ativo (Ana
  processando), a criação da mensagem de evento espera a resposta da
  Ana ser persistida antes de gravar — garante que o evento sempre
  tenha `created_at` posterior à última mensagem do chat (ver
  `../architecture/ui/dashboard.md` > Main > Anexos na mensagem); aciona
  `RealtimeService.broadcast_new_message(project_id, chat_id)` depois
  de persistir o evento;
- `delete_staged(project_id, staged_file_id)` — remove um arquivo salvo
  por `upload` que ainda não virou Attachment (staged no composer,
  mensagem nunca enviada); usa `resolve_staged(project_id,
  staged_file_id)` (acima) pra achar o arquivo — mesma regra de posse
  por `project_id` da Route, nunca do que vier no id; se não resolver
  (id de outro projeto, inválido ou já expirado), responde `404` sem
  apagar nada. Resolvendo, só apaga o arquivo em disco, sem gerar
  nenhum registro (nunca existiu como Attachment). Usado por
  `DELETE /projects/{id}/attachments/staged/{staged_file_id}` — a UI
  chama isso ao clicar no badge de exclusão que aparece sobre o ícone
  do anexo, ao passar o mouse (ver
  `../architecture/ui/dashboard.md` > Main > Anexos na mensagem);
- `cleanup()` — worker periódico (`workers/`, ver `03-backend.md`);
  remove linha + arquivo físico de Attachments com `created_at` > 12h,
  e também arquivos em disco de uploads que nunca chegaram a virar
  Attachment (staged e abandonados) — ver `../contracts/attachment.md`
  > Limite e retenção. Continua existindo mesmo com `delete_staged`
  disponível: cobre os casos em que o usuário simplesmente fecha a aba
  sem remover manualmente.

## TokenUsageService

Nunca chamado por uma Route — só por `MessageService`. Calcular o custo
e registrar o consumo são dois processos **separados** dentro desta
Service — `record` nunca calcula preço sozinho, sempre delega a
`calculate_cost` primeiro.

- `calculate_cost(driver, provider_ref, input_tokens, output_tokens,
  cache_read_tokens, cache_write_tokens)` — processo **puro** de
  cálculo, sem gravar nada: busca o preço vigente via
  `ModelPriceService.get_price(driver, provider_ref)` e devolve
  `cost_usd = input_tokens × input_price_per_1k + output_tokens ×
  output_price_per_1k + cache_read_tokens × cache_read_price_per_1k +
  cache_write_tokens × cache_write_price_per_1k` (tudo por 1K, ver
  `07-database.md` > model_prices). Recebe os quatro tipos de token em
  separado — inclusive os dois de cache — mesmo que só três sejam
  persistidos (ver `record`, abaixo): é assim que um provider que cobra
  cache de escrita diferente de cache de leitura (ex: Anthropic) tem o
  custo certo, sem exigir uma quarta coluna em `token_usage`;
- `record(project_id, provider_id, provider_model_id, provider_name,
  model_name, chat_id, input_tokens, output_tokens, cache_read_tokens,
  cache_write_tokens)` — processo de **persistência**: chama
  `calculate_cost` (acima) pra obter `cost_usd`, soma
  `cache_tokens = cache_read_tokens + cache_write_tokens` num único
  agregado, insere uma linha em `token_usage` (com esse `cache_tokens`
  agregado e o `cost_usd` calculado) e faz upsert em
  `token_usage_totals` **incrementando** pelo `cost_usd` recém-calculado
  (também atualizando `provider_name`/`model_name` com o valor mais
  recente), tudo na mesma operação síncrona (ver `07-database.md` >
  Princípios > Custo em USD). `driver`/`provider_ref` (usados só dentro
  de `calculate_cost`, nunca persistidos aqui) e
  `provider_id`/`provider_model_id` vêm do resultado de
  `ProviderCacheService.resolve_active_model` no momento da chamada (ver
  `MessageService`) — nunca lidos de volta de `configs`; `provider_name`
  é o `Provider.display_name` e `model_name` o `ProviderModel.name`
  correspondentes, buscados no mesmo instante — snapshots, não FK (ver
  `07-database.md` > token_usage). **Preço nunca é retroativo**: se
  `model_prices` mudar depois (edição manual, ou futuramente pela tela
  de preços em Settings, fora do MVP), isso não altera `cost_usd` de
  nenhuma linha de `token_usage` já gravada, nem recalcula
  `token_usage_totals` do zero — o total continua sendo a soma exata do
  que cada chamada já custou na época; só chamadas de `record` feitas
  *depois* da mudança usam o preço novo;
- `get_summary(project_id)` — usado pelo Tool de Gastos (ver
  `ToolService`, abaixo). Agrega `token_usage_totals` do projeto
  (tokens e custo, por `provider_model_id`, usando `provider_name`/
  `model_name` já denormalizados como rótulo — não depende de
  `provider_models` ainda existir) e monta a "linha do tempo" de uso
  (ordem cronológica de primeiro uso de cada modelo, a partir de
  `MIN(token_usage.created_at)` por `provider_model_id`). Sem uso
  registrado ainda, retorna a mesma estrutura zerada (tokens/custo em
  0, linha do tempo vazia, nenhum modelo) — nunca um erro (ver
  `../architecture/ui/dashboard.md` > ToolPanel na ferramenta Gastos).

  Além disso, pra cada item da linha do tempo, tenta resolver
  `provider_model_id` → `ProviderModel` (`provider_id`/`provider_ref`) →
  `Provider.driver`, e então chama
  `ModelPriceService.get_price(driver, provider_ref)` pra anexar
  `current_price` (**vigente agora** — os quatro valores: entrada,
  cache leitura, cache escrita, saída) — `null` assim que qualquer passo
  dessa cadeia não resolver (provider/modelo excluído). Esse campo é
  puramente informativo (mostra o preço que uma chamada nova pagaria
  hoje, ver `../architecture/ui/dashboard.md` > Card de modelo > Preço)
  e não contamina a garantia de resiliência do resto da resposta:
  Tokens e Custo continuam vindo só do log (`token_usage_totals`, que só
  guarda `cache_tokens` agregado, nunca a divisão leitura/escrita — ver
  `calculate_cost`, acima), nunca dependendo de `provider_models`/
  `model_prices` ainda existirem — só `current_price` em si pode
  faltar;

## ToolService

Dispatcher genérico para os painéis do `ToolPanel` (ver
`../architecture/ui/dashboard.md` > ToolBar). Usado por
`POST /projects/{id}/tools/{tool}` (ver `05-api.md` > Tools).

- `query(project_id, tool, payload={})` — despacha pelo identificador
  de `tool`; no MVP só `tool = "gastos"` existe de fato, delegando a
  `TokenUsageService.get_summary(project_id)`. `payload` existe para
  ferramentas futuras que precisem de parâmetros complementares
  (nenhuma usa isso ainda) — o formato de resposta é específico de cada
  `tool`, sem contrato genérico único.

## RealtimeService

Gerencia as conexões WebSocket e faz o broadcast de eventos em tempo
real para o Frontend (ver `../10-resilience.md` > Monitoramento de
status em tempo real). Nenhuma outra Service acessa WebSocket
diretamente — sempre passa por aqui.

Conexões vivem num dicionário em memória do processo (`project_id` →
sessões WebSocket abertas) — depende da mesma premissa de processo
único do MVP (ver `03-backend.md` > Visão Geral): uma sessão conectada
ao processo A nunca recebe um broadcast disparado a partir do processo
B. Sem pub/sub nenhum por trás disso por enquanto — não é necessário
com processo único, só quando o Backend escalar pra mais de um processo/
réplica (ver `08-redis.md` e `05. Evolução Futura`, abaixo).

- `broadcast_processing(project_id, chat_id_or_none)` — notifica todas
  as sessões conectadas ao projeto de que `processing_chat_id` mudou
  (setado ou limpo). Chamado por `MessageService.start_chat`/
  `send_message` (ver acima);
- `broadcast_new_message(project_id, chat_id)` — notifica que uma nova
  mensagem foi persistida naquele chat (resposta da Ana, mensagem
  `event` de erro, ou `event` de exclusão de anexo). É o gatilho para
  qualquer sessão com esse chat aberto refazer
  `GET /chats/{id}/messages` — o Frontend nunca infere isso só a partir
  de `processing` voltar a `null` (ver `../architecture/ui/dashboard.md`
  > Main > Scroll do histórico e `../10-resilience.md`). Chamado por
  `MessageService.start_chat`/`send_message` e por
  `AttachmentService.delete`;
- `broadcast_provider_stack(project_id, stack)` — notifica a pilha
  ordenada de Provider/Modelo (`configs.provider_order` já resolvido
  com os modelos do cache), com `provider_order_updated_at` como
  carimbo de versão. Chamado por `ProviderCacheService.rebuild_cache`
  (a reordenação em si acontece dentro de `ConfigService.update_config`,
  que só grava `provider_order`; quem efetivamente avisa o Frontend é
  sempre o `rebuild_cache` disparado em seguida). O Frontend só aplica a pilha
  recebida se ela for mais nova que a atual, e é **obrigado** a chamar
  `GET /projects/{id}/provider-stack` toda vez que recebe esse aviso
  (ver `ui/dashboard.md` > Header > Dropdown de Provider/Modelo).

  Só dispara se algo **realmente mudou** desde a última recomputação:
  `rebuild_cache` compara a ordenação e a disponibilidade de cada
  provider/modelo visível ao projeto contra o que já estava em cache
  antes de sobrescrever — se os dois forem idênticos (comum numa
  checagem periódica sem novidade), não notifica nada. Sem essa
  comparação, toda checagem periódica notificaria à toa.

  O envio de avisos é auto-limitado por projeto (estado transitório em
  Redis, não em `configs` — mesmo princípio de `provider_cache`). **Esse
  limite vale só para `provider_stack`** — `broadcast_processing`,
  `broadcast_new_message` e futuramente `broadcast_system_status` não
  são afetados, cada canal tem sua própria lógica:
  1. depois de enviar um aviso pra um projeto, nenhum aviso novo de
     `provider_stack` é enviado pra esse mesmo projeto por **3
     segundos**, contados a partir do envio — não importa quantas
     recomputações encontrem mudança real nesse meio-tempo; elas só
     marcam que há mudança pendente, sem notificar de novo;
  2. esse bloqueio de 3s se desfaz sozinho no fim do prazo, **mesmo que
     o Frontend nunca chame `GET /provider-stack`** (aba fechada,
     usuário trocou de projeto, etc.) — não depende da resposta do
     Frontend pra destravar;
  3. em paralelo, sempre que `GET /projects/{id}/provider-stack` for
     chamado — não importa quando, dentro ou depois do bloqueio de 3s —
     o Backend responde do mesmo jeito e descarta qualquer mudança
     pendente que estivesse esperando pra notificar (a própria resposta
     dessa chamada já entrega o estado mais atual, então notificar de
     novo seria redundante). Se não havia nada pendente, a chamada não
     muda nada além de responder;
  4. quando o bloqueio de 3s termina, se ainda houver mudança pendente
     que não foi descartada por uma chamada (passo 3), um único aviso
     sai nesse momento, refletindo o estado mais atual — e reinicia o
     bloqueio de 3s.

  Na prática, nunca existe mais de um aviso "no ar" por projeto, a
  frequência máxima de avisos por projeto é de um a cada 3 segundos, e
  nenhum aviso sai à toa quando nada muda de fato;
- `broadcast_system_status(...)` — notifica status de provider, banco e
  demais sistemas críticos (ver `../10-resilience.md`); evolução
  futura, ainda não desenhado em detalhe.

---

# 4. Integrações

## Repositories

Toda Service coordena um ou mais Repositories (um por Model, ver
`06-models.md`) — nunca executa SQL diretamente.

## Providers (`services/llm/`)

`MessageService`, `ProviderService` e `ProviderCacheService` são as
únicas Services que chamam a abstração de Providers — a primeira pra
conversar com o modelo, as outras duas pra validar acesso/testar
conectividade (ver abaixo). Nenhuma outra Service deve depender dela.

`providers.driver` é quem decide qual adaptador trata as chamadas de um
provider — `services/llm/openai/`, `services/llm/anthropic/`,
`services/llm/openai_compatible/`, `services/llm/lmstudio/` etc. (ver
`07-database.md` > providers); um dispatcher simples (`driver` →
classe do adaptador) fica em `services/llm/`, nunca espalhado pelas
Services que o consomem.

Todo adaptador expõe, no mínimo:

- `validate_and_identify(base_url?, secret)` — chamado por
  `ProviderService.register`/`edit_credential` (ver acima), com o
  `secret` em texto puro recebido do Frontend nessa única chamada de
  validação — cifrado logo em seguida, antes de persistir (ver
  `CredentialCipher`, abaixo), nunca gravado nem logado em texto puro.
  Faz uma chamada real, autenticada, contra o provider pra confirmar que
  o `secret` funciona, e devolve `account_or_tenant` (org id, workspace,
  tenant — ou `None`, quando o provider não distingue conta) junto do
  `base_url` normalizado (ver
  `docs/dev/research/identificacao-unica-de-providers.md`). Nunca
  inventa esses valores — replica exatamente o que o provider confirma,
  ou levanta erro se a validação falhar;
- `list_models(secret, base_url?)` — chamado por
  `ProviderCacheService.rebuild_cache`, usando o segredo **decifrado**
  de uma `ProviderCredential` específica (ver `CredentialCipher`,
  abaixo). Serve dois propósitos ao mesmo tempo: é a checagem de
  conectividade **leve** (sem custo de inferência real — uma chamada de
  listagem, nunca uma chamada de completion; sucesso = credencial no ar,
  falha = indisponível) e é a fonte da descoberta de catálogo (a lista
  devolvida alimenta o upsert em `provider_models`, ver
  `ProviderCacheService.rebuild_cache`, acima) — checa **todos** os
  modelos disponíveis pra aquela credencial no momento, cadastrados por
  nós ou não;
- para cada modelo do catálogo, dois campos distintos: um identificador
  **técnico estável usado pelo próprio provider** para chamadas de API
  (formato varia por provider — pode ser um id específico, um slug, ou
  coincidir com o nome de exibição) e um **nome de exibição** (rótulo
  legível, que pode mudar sem o modelo mudar de identidade) — nunca
  inventados, sempre replicando o que o provider retorna. O primeiro
  vira `provider_models.provider_ref`, o segundo vira
  `provider_models.name` (ver `07-database.md` > provider_models). É
  `provider_ref` — nunca `name` — que `configs.active_model_ref` guarda
  como referência durável (ver `ProviderCacheService`, abaixo): como o
  adaptador garante que esse identificador técnico não muda enquanto o
  modelo continuar existindo no catálogo do provider, `ProviderCacheService`
  consegue reconhecer "ainda é o mesmo modelo" mesmo entre recomputações
  de disponibilidade.

## Cifragem de credenciais (`core/security.py` > `CredentialCipher`)

Utilitário de infraestrutura (não é uma Service) usado por
`ProviderService` (cifra ao gravar) e por `ProviderCacheService`/
`MessageService` (decifra sob demanda, em memória, só pelo tempo da
chamada) — nenhuma outra camada acessa o segredo decifrado. Esquema
completo em `docs/dev/research/cifragem de credenciais.md`; resumo:

- **AES-256-GCM** (criptografia autenticada — detecta alteração do
  ciphertext no banco, além de escondê-lo), chave de 256 bits, nonce de
  96 bits gerado aleatório e nunca reaproveitado entre operações (nem
  entre gravações da mesma credencial);
- **AAD** (dado autenticado, não cifrado, mas protegido contra
  substituição) ligando o ciphertext a `id`/`provider_id`/
  `encryption_version` da própria linha de `ProviderCredential` — evita
  que o ciphertext de uma credencial seja copiado pra outra linha sem
  que a decifragem falhe;
- `encrypt(secret, credential_id, provider_id)` — chamado por
  `ProviderService.register` (credencial nova) e `edit_credential`
  (secret trocado) antes do `INSERT`/`UPDATE`; grava `encrypted_secret`,
  `encryption_nonce`, `encryption_key_id` (chave mestra vigente no
  momento) e `encryption_version`; calcula também `secret_hint` (sufixo
  mascarado do `secret` original, ex: `sk-proj-••••••••••••aB31`) — a
  única forma de "exibir" a credencial sem decifrar de verdade;
- `decrypt(credential)` — chamado por `ProviderCacheService.rebuild_cache`
  (teste de conectividade) e por `MessageService` (chamada real ao LLM,
  via `resolve_active_model` → `credential_id`, ver
  `ProviderCacheService`, acima) bem antes de usar o segredo; o valor
  decifrado nunca é persistido de volta, nunca entra em log (ver
  `03-backend.md` > Camadas > Logging), e é descartado assim que a
  chamada ao adaptador retorna;
- **rotação**: `encryption_key_id` permite conviver com mais de uma
  chave mestra durante uma transição — ao decifrar uma linha cifrada com
  uma chave antiga, a Service recifra com a chave vigente e atualiza
  `encrypted_secret`/`encryption_nonce`/`encryption_key_id` da mesma
  linha, de forma preguiçosa (no próximo uso), sem exigir uma migração
  em lote;
- **chave mestra**: nunca persistida no banco, no Git ou na imagem
  Docker — carregada uma vez na inicialização do Backend a partir de um
  Docker secret (arquivo montado, somente leitura) ou variável de
  ambiente no MVP (`ANA_CREDENTIALS_MASTER_KEY`/`ANA_CREDENTIALS_KEY_ID`,
  ver `src/.env.example`), mantida só em memória depois disso.

## Routes

Toda Route delega para exatamente uma Service pública. Uma Service pode
ter mais de um caller quando justificado — não só Routes, também outra
Service (ex: `ConfigService` é chamada pela Route de config e,
internamente, por `ProjectService.create_project`; isso é esperado).

---

# 5. Evolução Futura

- lock distribuído (ex: `SETNX` no Redis) pro worker periódico e pro
  coalescimento de `ProviderCacheService.rebuild_cache` (ver acima),
  quando o Backend deixar de rodar como processo único (ver
  `03-backend.md` > Visão Geral) — hoje ambos dependem de estado em
  memória de um processo só;
- pub/sub no Redis pra `RealtimeService` (ver acima), também só quando
  o Backend escalar pra mais de um processo/réplica — hoje as conexões
  WebSocket vivem num dicionário em memória de um processo só, e um
  broadcast disparado num processo não alcança sessões conectadas a
  outro;
- tela em Settings pra chamar `ModelPriceService.set_price` (acima) —
  nem o cadastro de provider/credencial (`ProviderService.register`),
  nem a descoberta automática (`ProviderCacheService.rebuild_cache`,
  acima) pedem preço; modelos descobertos automaticamente ficam com
  preço zero (`ModelPriceService.get_price` sem linha cadastrada) até
  essa tela existir e alguém cadastrar o preço de verdade. Detalhamento
  de campos/fluxo (Route, layout) fora de escopo por enquanto — a
  Service já existe pronta, só falta o endpoint/UI;
- Services para Topic, Memory, Task e MCP, quando esses componentes
  saírem do escopo futuro (ver `07-database.md`);
- streaming de resposta em `MessageService` (`start_chat` e
  `send_message`, ver `05-api.md` > Evolução Futura);
- processamento assíncrono de anexos (visão computacional, transcrição)
  via `workers/`, plugado em `AttachmentService` sem mudar seu contrato
  público (ver `05-api.md` > Convenções);
- `GuardService` validar o tipo de anexo por MIME type de fato (lista
  já definida em `../contracts/attachment-mime-types.md`) e rejeitar
  anexos potencialmente maliciosos (executáveis, `.bat`, shell scripts
  etc.); agente Python especializado em arquivos compactados — compacta
  e descompacta, extrai e adiciona arquivos dentro do compactado, e,
  como parte disso, identifica conteúdo malicioso e exclui o anexo
  imediatamente se encontrar algo suspeito;
- `GitService.get_current_branch` deixar de ser mockado — integração
  real com o git da pasta do projeto, e funcionalidade real para
  Pull/Push/Novo Branch/troca de branch (ver
  `../architecture/ui/dashboard.md` > Header > Dropdown de Git);
- `ToolService` ganhar ferramentas além de Gastos (Configs, Ajuda),
  quando saírem do protótipo de estilo/interação (ver
  `../architecture/ui/dashboard.md` > ToolBar).

---

# 6. Documentação Relacionada

## Geral

- `../00-context.md`
- `00-development.md`

## Arquitetura

- `01-system.md`
- `02-core.md`
- `03-backend.md`
- `04-frontend.md`
- `05-api.md`
- `06-models.md`
- `integrations/openclaude.md`
- `07-database.md`
- `08-redis.md`
- `09-projects.md`
- `10-resilience.md`
- `11-search.md`

## Contratos

- `../contracts/`
- `../contracts/attachment.md`
- `../contracts/attachment-mime-types.md`
- `../contracts/message.md`
- `../contracts/project.md`
- `../contracts/config.md`
- `../contracts/chat.md`
- `../contracts/provider.md`
- `../contracts/provider-credential.md`
- `../contracts/provider-subscription.md`
- `../contracts/provider-model.md`
- `../contracts/model-price.md`
- `../contracts/token-usage.md`
- `../contracts/token-usage-totals.md`
