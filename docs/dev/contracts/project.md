# Project

Representa uma pasta autorizada pelo usuário.

### Responsabilidades:

- pertencer a um único usuário
- possuir uma Configs associada (moeda, provider/modelo ativo — ver
  `config.md`)
- limitar acesso
- agrupar chats
- servir de contexto
- possuir memória (futuro)
- possuir trava de processamento (`processing_chat_id`, opcional) —
  identifica o chat sendo processado pela Ana no momento; enquanto
  não-nula, novas mensagens em qualquer chat do projeto são rejeitadas
  (ver `../architecture/ui/dashboard.md` > Main > Bloqueio de envio
  durante processamento)
- possuir status (`active`, `deleted`) — exclusão é lógica; o projeto
  `Base` nunca muda de status
- possuir data de último acesso (`last_accessed_at`, opcional) —
  atualizada sempre que o projeto é aberto/trocado; usada para ordenar
  a lista de projetos do mais recente para o menos recente (ver
  `../architecture/ui/dashboard.md` > Conteúdo expandido — Projeto)

### Não deve:

- armazenar mensagens
- armazenar configurações
- possuir lógica de IA
