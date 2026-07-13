# Lesson 0003: User (`GET`/`PATCH /me`)

Branch: `user-me-endpoints` — plano em
`../../plans/plan-003-user-me-endpoints.md`.

## Objetivo da tarefa

Implementar a entidade `User` (`GET`/`PATCH /me`), a primeira do MVP
com escrita (`PATCH`) e a primeira sem seed via migration.

## Principais desafios encontrados

- `03-users.sql` não semeia nenhuma linha (diferente de
  `currencies`/`languages`) — o usuário único precisa nascer em tempo
  de execução, não havia nenhum mecanismo pra isso ainda documentado
  além de um comentário na migration.
- Nenhum endpoint anterior (Currency/Language/health/limits) tinha
  caso de erro real — este foi o primeiro ponto exigindo um caminho
  de erro de domínio → HTTP.

## Decisões arquiteturais relevantes

- `UserService.get_current_user()` virou get-or-create: cria a única
  linha na primeira chamada (idioma `en`, nome padrão), sem lock —
  MVP é single-process/single-user, sem concorrência real nesse
  caminho.
- Criado `app/core/exceptions.py` (`NotFoundError`) + handler em
  `main.py` — primeira peça de infraestrutura de erro da aplicação,
  desenhada pra ser reaproveitada por qualquer entidade futura que
  precise validar uma FK opcional (ver Pattern
  `../patterns/pattern-0003-domain-exception-to-http.md`).

## Problemas enfrentados

Nenhum problema técnico novo desta vez (diferente das duas etapas
anteriores, que tiveram gotchas de ambiente Windows) — implementação
correu de acordo com o planejado.

## Soluções adotadas

N/A — sem problema a resolver além do desenho normal da funcionalidade.

## Recomendações para futuras implementações

- Sempre que uma entidade nova precisar validar uma FK recebida por
  payload (`*_id` opcional em `Update`), reaproveitar `NotFoundError` —
  não criar uma exceção específica por entidade.
- `get_current_user()` é o único lugar que cria a linha de `User` —
  qualquer teste que rode `PATCH /me` deve buscar o estado atual via
  `GET /me`/`GET /languages` antes de decidir os valores do payload
  (nunca assumir um `id` fixo), já que os testes compartilham o
  Postgres de dev, não um banco descartável por execução (ver
  `plan-002` > Testes).
