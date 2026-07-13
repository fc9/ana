# Pattern 0002: fatia vertical fina (Route → Service → Repository → Model)

## Problema

Cada entidade do MVP (ver `06-models.md`) precisa de um Model, um ou
mais Schemas, um Repository, uma Service e uma Route — mas para
entidades simples (só leitura, sem regra de negócio própria, ex:
Currency/Language), é tentador pular camadas "porque não tem lógica
nenhuma ainda". Isso quebra a consistência estrutural que
`03-backend.md` > Camadas exige, e complica adicionar regra de negócio
depois (a camada já devia existir).

## Solução adotada

Implementar as 5 camadas sempre, mesmo quando a Service é uma
passagem direta pro Repository — exemplo de referência completo:
Currency (`src/apps/api/app/{models,schemas,repositories,services,routes}/currency*.py`,
ver plano `../../plans/plan-002-fastapi-app-skeleton.md`):

1. **Model** (`models/currency.py`): `Mapped`/`mapped_column`
   espelhando a migration 1:1 (tipos, nullability, `server_default`
   quando o banco já tem `DEFAULT`).
2. **Schema** (`schemas/currency.py`): `CurrencyRead(BaseModel)` com
   `model_config = ConfigDict(from_attributes=True)` — permite
   `Schema.model_validate(model_instance)` direto na Route.
3. **Repository** (`repositories/currency.py`): função assíncrona
   simples (`list_active(session)`), só query — sem decidir nada, só
   executa `select()`.
4. **Service** (`services/currency_service.py`): repassa pro
   Repository. Fica "vazia" de propósito até a entidade ganhar regra
   de negócio de verdade — é o lugar certo pra crescer depois, sem
   precisar tocar Route/Repository.
5. **Route** (`routes/currencies.py`): `Depends(get_session)`
   (`app/db/session.py`), chama a Service, serializa a lista via
   `Schema.model_validate(...)` — nunca devolve o Model direto.

## Quando usar

Toda entidade nova do MVP que só precisar de leitura (`GET`), sem
regra de negócio ainda — ex: próxima entidade a implementar depois
desta.

## Quando evitar

Quando a entidade já nasce com regra de negócio real (validação,
efeitos colaterais, orquestração de mais de um Repository) — nesse
caso a Service já não é "fina", mas a estrutura de arquivos (uma
camada por responsabilidade) continua a mesma, só o conteúdo da
Service muda.

## Vantagens

- consistência: toda entidade do backend se navega da mesma forma,
  não importa a complexidade;
- Service "fina" hoje vira o lugar óbvio de crescer regra de negócio
  amanhã, sem mexer nas outras camadas.

## Limitações

- verboso pra entidades muito simples (5 arquivos pequenos pra um
  `SELECT` só) — aceito conscientemente, ver Não Evitar em
  `00-development.md` > Filosofia de Implementação (`baixo
  acoplamento`, `responsabilidade única` pesam mais que reduzir
  contagem de arquivos aqui).

## Arquivos relacionados

- `src/apps/api/app/models/currency.py`
- `src/apps/api/app/schemas/currency.py`
- `src/apps/api/app/repositories/currency.py`
- `src/apps/api/app/services/currency_service.py`
- `src/apps/api/app/routes/currencies.py`
- `docs/dev/architecture/03-backend.md` > Camadas
