Bloqueantes (impedem começar a codificar um módulo inteiro)

1. Não existe campo que diga qual adapter usar por Provider. providers só tem
   name, is_private, credentials. Mas 03-backend.md exige suportar OpenAI,
   Anthropic, OpenAI-compatible e (futuro) LM Studio como adapters diferentes (
   services/llm/openai/, services/llm/anthropic/...). Como o backend decide qual
   adapter chamar pra uma linha de providers? Hoje name é usado como rótulo
   livre nos exemplos ("openai", "anthropic") — se name também for o
   discriminador de tipo, isso nunca foi dito explicitamente, e colide com name
   ser um identificador estável escolhido pelo usuário (ele poderia querer
   nomear "Minha conta OpenAI"). Falta uma coluna tipo providers.kind (enum:
   openai/anthropic/openai_compatible/lmstudio) — sem isso, um agente de
   codificação vai inventar esse campo sozinho, e cada um vai inventar
   diferente.

2. Colisão de nome entre providers públicos de projetos diferentes.
   providers.name é único só por (project_id, name). Mas dois projetos
   diferentes podem cada um cadastrar um provider público chamado "OpenAI" — e
   um terceiro projeto, que enxerga os dois (is_private=false), teria dois
   providers com o mesmo nome na pilha. O tie-break de resolve_active_model (
   06b-services.md) só resolve privado-do-projeto vs. público-de-outro — não
   resolve público vs. público. Precisa de uma regra explícita: nome único
   globalmente entre públicos (índice parcial UNIQUE(name) WHERE is_private =
   false), ou um critério de desempate (ex: mais antigo vence) documentado.

3. report_unavailable(provider_id) é chamado sem provider_id no caso "removido"
   por provider inexistente. Em MessageService, o passo 2 diz: "se o status for
   removido ou indisponível, aciona report_unavailable(provider_id)". Mas no
   caso 3 de resolve_active_model ("não encontrou nenhum provider com esse
   nome" → removido), não existe provider_id nenhum resolvido — é exatamente por
   isso que o status é "removido". Só no caso 4 (provider existe, modelo
   específico é que sumiu) há um provider_id real pra passar. Isso é uma
   inconsistência lógica no fluxo documentado, não só uma lacuna — precisa
   decidir: report_unavailable só é chamado quando há de fato um provider_id
   resolvido (case 4/5), e o case 3 (provider some por completo) simplesmente
   não aciona nada (já que não tem o que recomputar).

Importantes (levam a decisões erradas/arbitrárias sem bloquear o código)

4. Cifragem de credentials: sem algoritmo, sem chave. Todo documento diz "
   cifrado pela camada de aplicação", mas nenhum define o algoritmo (AES-GCM?
   Fernet?), onde a chave mestra vive (.env? arquivo separado? gerada no
   primeiro boot?), nem o formato interno do JSON de credenciais por tipo de
   provider (api_key sozinho pra Anthropic, api_key+base_url pra
   OpenAI-compatible, só base_url pra LM Studio). Sem isso, cada implementação
   vai inventar um esquema diferente — e é dado sensível, não algo pra decidir "
   de qualquer jeito".


5. rebuild_cache — "busca a lista de modelos ao vivo" é ambíguo. Isso descobre
   modelos novos automaticamente no catálogo do provider (auto-populando
   provider_models), ou só testa a disponibilidade dos modelos já cadastrados
   manualmente via POST /providers/{id}/models? Como preço é sempre cadastrado à
   mão (ou via price_source=api, que também não tem mecanismo definido — ver
   próximo item), a leitura mais coerente é "só testa os já cadastrados", mas
   isso nunca foi dito com todas as letras. Sem essa definição, um agente pode
   implementar auto-discovery e quebrar a suposição de que todo modelo na pilha
   tem preço cadastrado.

O sistema checa todos os modelos disponíveis, já cadastrados ou não. Quanto aos
preços depois veremos como cadastrar o preço dos novos modelos, deixe-os com
preço zerado.

6. price_source = "api" — de qual API? Nem OpenAI nem Anthropic expõem preço por
   token via API pública. Se a intenção é uma tabela própria da Ana (curada
   manualmente, por provider_ref conhecido) em vez de uma chamada real ao
   provider, isso precisa ficar explícito — do jeito que está, parece prometer
   algo que não existe.

Crie um serviço e tabela para centralizar isso. Nela iremos usar referência para
cadastrar preços por modelo. Remova o conceito de price_source. Só existe uma
forma de obter o preço.

7. "Testa a conectividade (chamada leve)" não diz qual chamada. Pra cada
   adapter, qual é o ping gratuito garantido? Se cair para uma chamada de
   completion de teste, isso gasta tokens de verdade a cada ciclo de 60s, pra
   cada modelo, de todo provider cadastrado — isso precisa ser uma decisão
   consciente (ex: sempre uma chamada de listagem, nunca uma inferência real),
   não uma escolha livre do implementador.


8. Mecanismo de "enfileirar" recomputação concorrente não é uma estrutura
   concreta. 06b-services.md diz que um evento chegando durante uma recomputação
   em andamento "enfileira outra recomputação" — mas isso é uma fila de
   verdade (podendo acumular N pendências) ou deveria colapsar num único flag "
   rodar de novo ao terminar" (mesmo princípio já usado pro aviso ao Frontend,
   que é colapsado)? Sem definir isso, dá pra implementar de formas com
   comportamento bem diferente sob carga.


9. "Lock distribuído pro tick periódico não existe. Se a API rodar com mais de
   um
   worker/processo (comum em produção com Uvicorn --workers N ou múltiplas
   réplicas), cada processo teria seu próprio timer comparando last_run_at,
   todos tentando recomputar ao mesmo tempo. Precisa dizer explicitamente "MVP
   assume processo único" ou definir um lock (SETNX no Redis) — hoje fica
   implícito e um agente pode simplesmente não perceber o risco."

Processo único.

10. "Broadcast de WebSocket também assume processo único, sem dizer isso.
    RealtimeService mantém as conexões — se isso for um dicionário em memória,
    só funciona com 1 processo da API. 08-redis.md menciona pub/sub "de apoio"
    de forma genérica, mas não resolve se é necessário desde já ou só quando
    escalar."

Processo único.

11. "cache_price_per_1k não distingue cache de leitura e cache de escrita. O
    texto já reconhece isso ("cache (leitura)"), mas a Anthropic cobra cache
    write a um preço diferente (mais caro) do cache read. Se cache write não é
    modelado em lugar nenhum (nem em provider_models, nem em token_usage), o
    painel de Gastos vai calcular custo errado para quem usa prompt caching da
    Anthropic — isso é um buraco de correção financeira, não só estético."

O modelo do frontend já pressupõe claramente essa separação dos de token de
input e output, ainda computando mais 10% do input como cache. O sistema deve
registrar o consumo desses três tipos de token. O processo de calcular o custo
deve ser um processo separado do registro de tokens consumido.

Pequenas, mas geram comportamento indefinido

12. Falta o status/código HTTP pro caso "projeto sem modelo ativo configurado
    ainda". resolve_active_model retorna explicitamente esse terceiro estado (
    nem "removido" nem "indisponível" — simplesmente nunca escolhido), mas
    05-api.md > Messages só documenta 422/503 pros outros dois. O que a API
    retorna se o usuário tentar enviar mensagem num projeto que nunca configurou
    provider?
 
13. dashboard.md menciona sincronização "via cookie" entre abas do mesmo chat,
    mas isso nunca é explicado em nenhum doc de backend — e parece redundante
    com o WebSocket (que já notifica todas as sessões do projeto). Não há
    conceito de sessão/cookie em nenhum outro lugar do MVP (sem autenticação).
    Provavelmente é resquício de um design anterior que devia ter sido removido
    quando o WS assumiu esse papel — vale eu limpar isso ou você quer manter a
    menção?

conceito descontinuado.


14. "Falta validar explicitamente que staged_file_id pertence ao mesmo projeto 
    do chat/mensagem antes de virar Attachment — nunca é dito que
    MessageService/GuardService checam essa posse, então um agente pode
    simplesmente confiar no id vindo do cliente sem checagem cruzada de projeto."

---
Quer que eu vá resolvendo esses pontos com você um a um (bloqueantes primeiro) e
propague nos docs, como fizemos com a arquitetura de cache? Os itens 1, 2 e 3
são os que eu realmente pararia pra perguntar antes de escrever uma linha de
ProviderService/ProviderCacheService.

