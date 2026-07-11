# ProviderSubscription

Representa o vínculo de um projeto a uma `provider-credential.md` — dá
acesso de fato (pra usar e pra gerenciar) a uma credencial privada, ou
acesso rastreado a uma pública.

### Responsabilidades:

- pertencer a um único projeto e apontar para uma única credencial (de
  um único provider)
- garantir que um projeto tenha no máximo **uma** assinatura por
  provider (`UNIQUE (project_id, provider_id)`) — ou seja, uma única
  conta por provider por projeto. Trocar de conta é sempre uma migração
  da mesma assinatura para outra credencial (ver
  `provider-credential.md` > Edição), nunca uma segunda assinatura
- múltiplos projetos podem ter, cada um, sua própria linha de
  assinatura apontando para a **mesma** credencial — assinar não
  duplica a credencial, só o vínculo
- ser criada automaticamente ao cadastrar/assinar um provider (ver
  `provider.md` > Fluxo de cadastro/assinatura) — nunca por payload
  próprio isolado

### Não deve:

- conter lógica de negócio
- existir para acesso público **implícito** (usar uma credencial
  pública sem nunca ter cadastrado/assinado não gera linha aqui — ver
  abaixo)

### Acesso público implícito vs. assinatura

Todo projeto enxerga e usa credenciais públicas de qualquer provider,
sem precisar de uma `ProviderSubscription` — é assim que a lista de
providers visíveis a um projeto (`provider.md` > pilha) inclui
credenciais que ninguém daquele projeto assinou. Essa é uma diferença
importante: um acesso **implícito** (sem assinatura) não é durável — se
a credencial pública em questão for convertida para privada, ou
excluída por falta de assinantes (ver abaixo), quem só a usava
implicitamente perde o acesso. Só quem tem uma `ProviderSubscription`
de fato continua com acesso garantido enquanto a credencial existir.

### Desassinar

"Excluir um provider" pela UI de um projeto é sempre desassinar — nunca
uma exclusão física direta:

1. remove só a linha de `ProviderSubscription(project_id, provider_id)`
   do solicitante;
2. se, com isso, a credencial que essa assinatura usava não tiver mais
   nenhuma assinatura restante (de nenhum projeto), ela é removida
   fisicamente — mesmo que fosse pública (é exatamente esse o caso em
   que projetos com acesso implícito, sem nunca ter assinado, perdem o
   acesso);
3. se a credencial foi removida no passo 2 e o Provider dela não tiver
   mais nenhuma credencial restante, o Provider também é removido
   fisicamente.

A opção de desassinar só aparece na UI para um projeto que realmente
tem uma `ProviderSubscription` — quem só usa uma credencial pública sem
nunca ter assinado não vê essa opção (não tem o que remover). Ver
`../architecture/06b-services.md` > ProviderService.unsubscribe.
