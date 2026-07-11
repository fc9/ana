# Conventional Commits — Referência

Status: Draft
Versão: 0.1
Última atualização: 2026-07-08
Responsável: Arquitetura

Fonte oficial:

https://www.conventionalcommits.org/pt-br/v1.0.0/

> Este documento existe para que a especificação completa esteja
> disponível localmente, sem depender de acesso à internet. Aplicado em
> `../architecture/00-development.md` > Padrão de Commits.

---

# 1. Estrutura da Mensagem

```
<tipo>[escopo opcional]: <descrição>

[corpo opcional]

[rodapé(s) opcional(is)]
```

---

# 2. Tipos Padrão

- **fix** — soluciona um problema (correlaciona-se com `PATCH` do SemVer);
- **feat** — inclui novo recurso (correlaciona-se com `MINOR` do SemVer);
- outros tipos permitidos: `build`, `chore`, `ci`, `docs`, `style`,
  `refactor`, `perf`, `test`.

---

# 3. Escopo

Um substantivo descritivo entre parênteses, logo após o tipo, indicando
a seção do código afetada.

Exemplo: `feat(parser): adiciona capacidade de parsear arrays.`

---

# 4. Breaking Changes

Existem duas formas de indicar uma mudança que quebra compatibilidade
(podem ser combinadas):

1. **Símbolo `!`** — logo após o tipo/escopo, antes dos dois-pontos.

   ```
   feat(api)!: envia email ao cliente quando o produto é enviado
   ```

2. **Rodapé** — `BREAKING CHANGE:` seguido de descrição.

   ```
   feat: permite objeto de config estender outros configs

   BREAKING CHANGE: a chave `extends` agora estende outro arquivo de
   configuração
   ```

Se o `!` for usado no prefixo, o rodapé `BREAKING CHANGE:` passa a ser
opcional.

---

# 5. Especificação Numerada

1. Mensagens devem ser prefixadas por um tipo (substantivo — `feat`,
   `fix` etc.), seguido opcionalmente de um escopo, opcionalmente de
   `!`, e dois-pontos e um espaço obrigatórios.
2. O tipo `feat` deve ser usado quando um commit adiciona um novo
   recurso.
3. O tipo `fix` deve ser usado quando um commit representa uma correção
   de bug.
4. Um escopo pode ser fornecido após o tipo, como um substantivo entre
   parênteses (ex: `fix(parser):`).
5. Uma descrição deve seguir imediatamente os dois-pontos e espaço do
   prefixo tipo/escopo — um resumo curto da mudança.
6. Um corpo mais longo pode ser fornecido após a descrição breve,
   provendo contexto adicional; deve começar uma linha em branco após a
   descrição.
7. Um corpo é composto de texto livre e pode conter múltiplos
   parágrafos separados por linha em branco.
8. Um ou mais rodapés podem ser fornecidos uma linha em branco após o
   corpo.
9. Cada rodapé deve conter uma palavra-chave, seguida de `: ` ou
   ` #`, seguida de um valor (formato inspirado na convenção
   *git trailer*).
10. O token de um rodapé deve usar `-` no lugar de espaços em branco
    (ex: `Acked-by`) — isso ajuda a diferenciar o rodapé de um corpo com
    múltiplos parágrafos. Exceção: `BREAKING CHANGE`, que pode conter
    espaço.
11. O valor de um rodapé pode conter espaços e novas linhas; deve
    terminar quando o próximo token/valor válido de rodapé for
    encontrado.
12. Breaking changes devem ser indicadas no prefixo do tipo/escopo ou
    como uma entrada no rodapé.
13. Se incluída como rodapé, uma breaking change deve consistir no texto
    em maiúsculas `BREAKING CHANGE`, seguido de dois-pontos, espaço e
    descrição.
14. Se incluída no prefixo, breaking changes devem ser indicadas por um
    `!` imediatamente antes do `:`. Se `!` for usado, `BREAKING CHANGE:`
    pode ser omitido do rodapé, e a descrição da mensagem deve descrever
    a mudança.
15. Tipos diferentes de `feat` e `fix` podem ser usados na mensagem
    (ex: `docs:`, `style:`, `ci:`, `refactor:`, `test:`, `chore:`).
16. As unidades de informação que compõem o Conventional Commits não
    devem ser tratadas com distinção entre maiúsculas e minúsculas pela
    implementação, com exceção de `BREAKING CHANGE`, que deve ser
    maiúsculo. `BREAKING-CHANGE` é sinônimo de `BREAKING CHANGE` quando
    usado como token de rodapé.

---

# 6. Documentação Relacionada

- `../architecture/00-development.md` > Padrão de Commits
