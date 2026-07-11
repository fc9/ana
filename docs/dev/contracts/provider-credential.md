# ProviderCredential

Representa uma **conta** de acesso a um `provider.md` — duas contas
diferentes do mesmo serviço (ex: conta pessoal e conta da empresa,
ambas na OpenAI) são duas credenciais sob o mesmo Provider, nunca dois
Providers.

### Responsabilidades:

- pertencer a um único Provider
- carregar `account_or_tenant` — identificador de conta devolvido pelo
  próprio provider na validação de acesso (org id, workspace, tenant);
  anulável, já que nem todo provider distingue conta (ex: instalação
  local de LM Studio sem autenticação)
- armazenar o segredo de acesso cifrado com **AES-256-GCM** pela camada
  de aplicação (`core/security.py` > `CredentialCipher`) — nonce
  aleatório e exclusivo por operação, AAD ligando o ciphertext a esta
  própria credencial (impede reaproveitar o ciphertext em outra linha),
  `encryption_key_id` guardando qual chave mestra cifrou (permite
  rotação futura sem recifrar tudo de uma vez) — ver
  `docs/dev/research/cifragem de credenciais.md` e
  `../architecture/06b-services.md` > CredentialCipher. O banco nunca
  recebe a credencial em texto puro, e nenhum Schema `Read` expõe o
  ciphertext, o nonce ou a chave — só um `secret_hint` (sufixo mascarado,
  ex: `sk-proj-••••••••••••aB31`) pra UI exibir sem decifrar
- indicar se é privada (só quem assina enxerga/usa) ou pública
  (qualquer projeto usa sem precisar assinar — padrão para o primeiro
  cadastro de um provider)
- nunca ser duplicada: `UNIQUE (provider_id, conta)` impede cadastrar a
  mesma conta duas vezes
- ter no máximo **uma** credencial pública por provider — evita
  ambiguidade sobre qual credencial um projeto sem assinatura própria
  usaria. Se um cadastro pedir pública com outra já existente pro mesmo
  provider, o sistema registra a nova como privada e avisa o motivo (não
  rejeita o cadastro)
- ter sua disponibilidade (está no ar? a conta ainda é válida?)
  checada e mantida só em cache (Redis), por credencial — nunca
  persistida aqui; ver `../architecture/08-redis.md` e
  `../architecture/06b-services.md` > ProviderCacheService

### Não deve:

- conter lógica de negócio
- ser identificada pelo segredo de acesso (chaves podem ser rotacionadas
  e não devem ser tratadas como identidade — ver
  `docs/dev/research/identificacao-unica-de-providers.md`)

### Edição

Editar uma credencial (`secret` e/ou `is_private`) só é permitido a um
projeto que já tenha assinatura para ela. Trocar só `is_private` altera
a própria linha — todos os assinantes são afetados igualmente. Trocar
`secret` (recebido em texto puro nesta chamada, cifrado antes de
persistir — ver `CredentialCipher`) valida a nova conta contra o
provider:

- **mesma conta de antes** (ex: chave rotacionada): atualiza a própria
  linha, sem mexer em nenhuma assinatura;
- **conta diferente**: migra a assinatura do editor para uma credencial
  existente (se a nova conta já estiver cadastrada) ou recém-criada —
  nunca altera credenciais de outros assinantes. A credencial que o
  editor estava deixando passa pela checagem de órfã abaixo.

Ver `../architecture/06b-services.md` > ProviderService.edit_credential.

### Exclusão em cascata

Não existe "excluir uma credencial" como ação direta — ela é removida
fisicamente só quando fica **órfã**: a última `ProviderSubscription`
que apontava pra ela é removida (ver `provider-subscription.md` >
Desassinar), inclusive quando isso deixa projetos que a usavam por
acesso público (sem nunca ter assinado) sem acesso algum. Quando uma
credencial é removida dessa forma e o Provider dono fica sem nenhuma
credencial restante, o Provider também é removido fisicamente (e seus
`ProviderModel` em cascata).
